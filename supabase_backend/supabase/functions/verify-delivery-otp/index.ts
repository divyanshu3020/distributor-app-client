// Supabase Edge Function: verify-delivery-otp
// Description: Distributor enters OTP shared verbally by driver. Verifies OTP, marks order delivered,
// and sends clearance message directly to the driver's phone.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface VerifyOtpRequest {
  orderId: string;
  otp: string;
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

    // Check user auth
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { orderId, otp } = (await req.json()) as VerifyOtpRequest;
    if (!orderId || !otp) {
      return new Response(JSON.stringify({ error: "orderId and otp are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Retrieve order
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

    // Role check
    const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
    const isOwner = order.distributor_id === user.id;
    const isStaffOrAdmin = profile && (profile.role === "super_admin" || profile.role === "staff");

    if (!isOwner && !isStaffOrAdmin) {
      return new Response(JSON.stringify({ error: "Forbidden: You are not authorized for this order" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Validate that order has an active OTP
    if (!order.delivery_otp_hash || !order.delivery_otp_expires_at) {
      return new Response(
        JSON.stringify({ error: "No active OTP found. Please tap 'Acknowledge Arrival' first." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check expiry
    const now = new Date();
    const expiry = new Date(order.delivery_otp_expires_at);
    if (now > expiry) {
      return new Response(
        JSON.stringify({ error: "OTP has expired. Please tap 'Resend OTP' to generate a fresh code." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Hash user-provided OTP
    const encoder = new TextEncoder();
    const inputHashBuffer = await crypto.subtle.digest(
      "SHA-256",
      encoder.encode(`${otp.trim()}_${orderId}_bhagwati_salt`)
    );
    const inputHash = Array.from(new Uint8Array(inputHashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    if (inputHash !== order.delivery_otp_hash) {
      return new Response(
        JSON.stringify({ error: "Invalid OTP code. Please verify with the driver and re-enter." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OTP Verified! Update order state to delivered
    const deliveredAt = new Date().toISOString();
    const { error: updateError } = await supabase
      .from("orders")
      .update({
        status: "delivered",
        delivered_at: deliveredAt,
        delivery_otp_hash: null,
        delivery_otp_expires_at: null,
      })
      .eq("id", orderId);

    if (updateError) {
      return new Response(JSON.stringify({ error: "Failed to mark order as delivered" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Clear driver handover message
    const distributorName = order.distributor?.business_name || order.distributor?.full_name || "the distributor";
    const driverClearanceMessage = `Bhagwati Plastics CLEARANCE: OTP verified successfully! Please hand over goods for Order #${order.order_number} to ${distributorName}. Delivery is complete.`;
    console.log(`[DISPATCH CLEARANCE SMS TO DRIVER ${order.driver_phone}]: ${driverClearanceMessage}`);

    // If real SMS provider configured, send clearance message to driver
    if (smsApiKey && smsApiKey !== "your-sms-provider-api-key" && order.driver_phone) {
      try {
        if (smsProvider === "msg91") {
          await fetch("https://control.msg91.com/api/v5/flow", {
            method: "POST",
            headers: { "authkey": smsApiKey, "Content-Type": "application/json" },
            body: JSON.stringify({
              template_id: "driver_clearance_template",
              mobiles: order.driver_phone.replace(/\D/g, ""),
              order_number: order.order_number,
              distributor: distributorName,
            }),
          });
        }
      } catch (smsErr) {
        console.error("Failed to send driver clearance SMS:", smsErr);
      }
    }

    // Create notifications for distributor
    await supabase.from("notifications").insert({
      user_id: order.distributor_id,
      title: "Delivery Completed!",
      body: `Order #${order.order_number} has been verified and delivered successfully. Handover clearance sent to driver.`,
      type: "order_update",
      metadata: { orderId: order.id, status: "delivered" },
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "OTP verified. Order marked as delivered. Clearance notice dispatched to driver.",
        deliveredAt: deliveredAt,
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
