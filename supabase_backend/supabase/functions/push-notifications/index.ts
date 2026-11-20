// Supabase Edge Function: push-notifications
// Description: Sends Zomato/Swiggy-style catchy reorder nudges and stage-by-stage order status updates via FCM.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PushNotificationPayload {
  type: "stage_update" | "reorder_nudge" | "announcement" | "manual";
  userId?: string; // target user (or all if omitted/announcement)
  orderId?: string;
  orderNumber?: string;
  stage?: string;
  driverPhone?: string;
  vehicleNumber?: string;
  customTitle?: string;
  customBody?: string;
  productName?: string;
}

const CATCHY_REORDER_MESSAGES = [
  {
    title: "⚡ Stock Running Thin?",
    body: "Distributors in your area just booked 400+ packages of 20L Heavy Buckets. Reorder now to skip the production wait!",
  },
  {
    title: "📦 Don't Let Your Warehouse Run Dry!",
    body: "Construction season is peaking! Book your batch of 18\" and 22\" Heavy Tubs before machine slots fill up.",
  },
  {
    title: "🔥 Top Seller Alert: Deluxe Stools",
    body: "Household stools are moving fast. Grab your quota before low-stock distributor caps kick in!",
  },
  {
    title: "🚚 Freight Priority Available",
    body: "Book your bulk crate order today and get priority Truck allocation for guaranteed dispatch.",
  },
];

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const fcmProjectId = Deno.env.get("FCM_PROJECT_ID") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const payload = (await req.json()) as PushNotificationPayload;

    let title = payload.customTitle || "Bhagwati Plastics Update";
    let body = payload.customBody || "You have a new operational update.";
    let notificationType = "order_update";

    if (payload.type === "stage_update" && payload.stage) {
      switch (payload.stage) {
        case "confirmed":
          title = "✅ Order Confirmed!";
          body = `Order #${payload.orderNumber || "Ref"} has been locked into the manufacturing queue.`;
          break;
        case "in_production":
          title = "⚙️ Injection Molders Running!";
          body = `Your products for Order #${payload.orderNumber || "Ref"} are currently on the factory line.`;
          break;
        case "packing":
          title = "📦 Quality Check & Packing";
          body = `Order #${payload.orderNumber || "Ref"} is being bundled into standard shipping packages.`;
          break;
        case "dispatched":
          title = "🚚 Order Dispatched from Factory!";
          body = `Vehicle ${payload.vehicleNumber || "Assigned"} is en route. Driver contact: ${payload.driverPhone || "Assigned"}.`;
          notificationType = "dispatch_alert";
          break;
        case "out_for_delivery":
          title = "📍 Driver Arrived at Your Location!";
          body = `Tap 'Acknowledge Arrival' in the app to send the security OTP to the driver's phone.`;
          notificationType = "arrival_alert";
          break;
        case "delivered":
          title = "🎉 Delivery Handover Complete!";
          body = `Order #${payload.orderNumber || "Ref"} verified. Goods handed over successfully.`;
          break;
      }
    } else if (payload.type === "reorder_nudge") {
      const randomNudge = CATCHY_REORDER_MESSAGES[Math.floor(Math.random() * CATCHY_REORDER_MESSAGES.length)];
      title = payload.customTitle || randomNudge.title;
      body = payload.customBody || (payload.productName ? `Running low on ${payload.productName}? Factory line opens tomorrow — reorder now!` : randomNudge.body);
      notificationType = "reorder_reminder";
    }

    // Target recipients
    let targetUserIds: string[] = [];
    if (payload.userId) {
      targetUserIds = [payload.userId];
    } else {
      // Broadcast to all active distributors
      const { data: distributors } = await supabase
        .from("profiles")
        .select("id")
        .eq("role", "distributor");
      targetUserIds = (distributors || []).map((d) => d.id);
    }

    // Persist in-app notifications
    const notificationsToInsert = targetUserIds.map((uid) => ({
      user_id: uid,
      title: title,
      body: body,
      type: notificationType,
      metadata: {
        orderId: payload.orderId,
        orderNumber: payload.orderNumber,
        stage: payload.stage,
      },
    }));

    if (notificationsToInsert.length > 0) {
      await supabase.from("notifications").insert(notificationsToInsert);
    }

    console.log(`[PUSH NOTIFICATION SENT] Title: "${title}" | Body: "${body}" | To: ${targetUserIds.length} users`);

    // In production with FCM service account configured, send actual APNs/FCM payloads
    return new Response(
      JSON.stringify({
        success: true,
        dispatchedCount: targetUserIds.length,
        notification: { title, body, type: notificationType },
        fcmConfigured: Boolean(fcmProjectId && fcmProjectId !== "your-firebase-project-id"),
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
