// Supabase Edge Function: send-delivery-otp
// Description: Triggered when Distributor taps "Acknowledge Arrival". Generates 6-digit OTP and sends to driver's phone.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SendOtpRequest {
  orderId: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const smsProvider = Deno.env.get("OTP_SMS_PROVIDER") ?? "msg91";
    const smsApiKey = Deno.env.get("OTP_SMS_API_KEY") ?? "";
    const smsSenderId = Deno.env.get("OTP_SMS_SENDER_ID") ?? "BHAGWT";
    const otpExpirySeconds = parseInt(Deno.env.get("OTP_EXPIRY_SECONDS") ?? "300", 10);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const userClient = createClient(supabaseUrl, authHeader.replace("Bearer ", ""), {
      global: { headers: { Authorization: authHeader } },
    });

    // Verify authenticated user
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { orderId } = (await req.json()) as SendOtpRequest;
    if (!orderId) {
      return new Response(JSON.stringify({ error: "orderId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch order details
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*, distributor:profiles!distributor_id(*)")
      .eq("id", orderId)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Role verification: user must be the distributor or staff/admin
    const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
    const isOwner = order.distributor_id === user.id;
    const isStaffOrAdmin = profile && (profile.role === "super_admin" || profile.role === "staff");

    if (!isOwner && !isStaffOrAdmin) {
      return new Response(JSON.stringify({ error: "Forbidden: You are not authorized for this order" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!["dispatched", "out_for_delivery"].includes(order.status)) {
      return new Response(
        JSON.stringify({ error: `Cannot trigger OTP: Order is currently '${order.status}'. Must be dispatched.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!order.driver_phone) {
      return new Response(
        JSON.stringify({ error: "Driver phone number is not assigned for this order yet." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate cryptographically secure 6-digit OTP
    const randomArray = new Uint32Array(1);
    crypto.getRandomValues(randomArray);
    const otp = (100000 + (randomArray[0] % 900000)).toString();

    // Hash OTP using SHA-256 with order ID salt
    const encoder = new TextEncoder();
    const dataToHash = encoder.encode(`${otp}_${orderId}_bhagwati_salt`);
    const hashBuffer = await crypto.subtle.digest("SHA-256", dataToHash);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const otpHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    const expiresAt = new Date(Date.now() + otpExpirySeconds * 1000).toISOString();

    // Update order with OTP hash and expiry timestamp
    const { error: updateError } = await supabase
      .from("orders")
      .update({
        delivery_otp_hash: otpHash,
        delivery_otp_expires_at: expiresAt,
        arrival_acknowledged_at: new Date().toISOString(),
        status: "out_for_delivery",
      })
      .eq("id", orderId);

    if (updateError) {
      return new Response(JSON.stringify({ error: "Failed to persist OTP verification details" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Dispatch SMS/WhatsApp to the Driver
    const driverMessage = `Bhagwati Plastics: Delivery OTP for Order #${order.order_number} is ${otp}. Valid for 5 minutes. Share this OTP with the distributor upon physical arrival.`;
    console.log(`[DISPATCH SMS TO DRIVER ${order.driver_phone}]: ${driverMessage}`);

    // If real SMS provider API key configured, make HTTP call
    if (smsApiKey && smsApiKey !== "your-sms-provider-api-key") {
      try {
        if (smsProvider === "msg91") {
          await fetch("https://control.msg91.com/api/v5/otp", {
            method: "POST",
            headers: { "authkey": smsApiKey, "Content-Type": "application/json" },
            body: JSON.stringify({
              template_id: "delivery_otp_template",
              mobile: order.driver_phone.replace(/\D/g, ""),
              otp: otp,
            }),
          });
        }
      } catch (smsErr) {
        console.error("SMS Provider dispatch failed:", smsErr);
      }
    }

    // Notify distributor inside app
    await supabase.from("notifications").insert({
      user_id: order.distributor_id,
      title: "Driver Has Arrived!",
      body: `OTP has been sent to the driver's phone (${maskPhoneNumber(order.driver_phone)}). Ask the driver for the code and enter it to accept delivery.`,
      type: "arrival_alert",
      metadata: { orderId: order.id, orderNumber: order.order_number },
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "Delivery OTP successfully dispatched to driver's phone.",
        driverPhoneMasked: maskPhoneNumber(order.driver_phone),
        expiresAt: expiresAt,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function maskPhoneNumber(phone: string): string {
  const clean = phone.trim();
  if (clean.length < 6) return clean;
  return `${clean.slice(0, 3)}****${clean.slice(-3)}`;
}
