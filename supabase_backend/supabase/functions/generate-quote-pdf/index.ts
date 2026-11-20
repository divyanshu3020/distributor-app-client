// Supabase Edge Function: generate-quote-pdf
// Description: Locks in exact pricing and vehicle fare upon order placement, creates official Quotation,
// and returns printable/downloadable HTML/PDF invoice data.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface GenerateQuoteRequest {
  orderId: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { orderId } = (await req.json()) as GenerateQuoteRequest;
    if (!orderId) {
      return new Response(JSON.stringify({ error: "orderId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch order, items, distributor, vehicle tier
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select(`
        *,
        distributor:profiles!distributor_id(*),
        vehicle_tier:vehicle_tiers!vehicle_tier_id(*)
      `)
      .eq("id", orderId)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: items, error: itemsError } = await supabase
      .from("order_items")
      .select("*")
      .eq("order_id", orderId);

    if (itemsError || !items || items.length === 0) {
      return new Response(JSON.stringify({ error: "Order items not found" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Calculate final locked totals
    const finalSubtotal = items.reduce((sum, item) => sum + Number(item.total_price), 0);
    const vehicleFare = Number(order.vehicle_fare_approx || order.vehicle_tier?.base_fare || 0);
    const taxRate = 0.18; // 18% GST standard on polymer products
    const taxAmount = (finalSubtotal + vehicleFare) * taxRate;
    const grandTotal = finalSubtotal + vehicleFare + taxAmount;

    const quoteNumber = `QT-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, "0")}-${order.order_number.replace(/\D/g, "").slice(-4) || Math.floor(1000 + Math.random() * 9000)}`;

    // Upsert official locked quotation
    const { data: quotation, error: quoteError } = await supabase
      .from("quotations")
      .upsert({
        order_id: orderId,
        quote_number: quoteNumber,
        distributor_id: order.distributor_id,
        final_subtotal: finalSubtotal,
        vehicle_fare: vehicleFare,
        tax_amount: taxAmount,
        grand_total: grandTotal,
        status: "locked",
      }, { onConflict: "order_id" })
      .select()
      .single();

    if (quoteError) {
      return new Response(JSON.stringify({ error: `Quotation error: ${quoteError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate printable HTML invoice representation
    const invoiceHtml = generateInvoiceHtml({
      order,
      items,
      distributor: order.distributor,
      quotation,
      vehicleTier: order.vehicle_tier,
      taxAmount,
      grandTotal,
    });

    return new Response(
      JSON.stringify({
        success: true,
        quotation: quotation,
        invoiceHtml: invoiceHtml,
        summary: {
          subtotal: finalSubtotal,
          vehicleFare: vehicleFare,
          taxAmount: taxAmount,
          grandTotal: grandTotal,
          vehicleTierName: order.vehicle_tier?.name ?? "Standard Delivery",
        },
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

function generateInvoiceHtml(data: any): string {
  const { order, items, distributor, quotation, vehicleTier, taxAmount, grandTotal } = data;
  const itemsHtml = items.map((item: any, idx: number) => `
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${idx + 1}</td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0;">
        <strong>${item.product_name}</strong>
        ${item.is_made_to_order ? '<br/><span style="color: #d97706; font-size: 11px; font-weight: 600;">[MADE TO ORDER / BACKORDER]</span>' : '<br/><span style="color: #059669; font-size: 11px;">[Ready Stock]</span>'}
      </td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${item.quantity_packages} pkgs (${item.quantity_units} pcs)</td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right;">₹${Number(item.unit_price).toFixed(2)}</td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right; font-weight: 600;">₹${Number(item.total_price).toFixed(2)}</td>
    </tr>
  `).join("");

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Quotation ${quotation.quote_number}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #1e293b; margin: 0; padding: 24px; background: #fff; }
    .header { display: flex; justify-content: space-between; border-bottom: 2px solid #0284c7; padding-bottom: 16px; margin-bottom: 24px; }
    .title { font-size: 24px; font-weight: 800; color: #0f172a; }
    .subtitle { font-size: 13px; color: #64748b; margin-top: 4px; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 4px; background: #0284c7; color: #fff; font-size: 12px; font-weight: 700; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }
    .box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; }
    .box h4 { margin: 0 0 8px 0; color: #0284c7; font-size: 14px; text-transform: uppercase; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 13px; }
    th { background: #0f172a; color: #fff; text-align: left; padding: 10px; font-weight: 600; }
    .totals { width: 320px; margin-left: auto; margin-bottom: 24px; font-size: 13px; }
    .totals tr td { padding: 6px 0; }
    .totals tr.grand { border-top: 2px solid #0f172a; font-size: 16px; font-weight: 800; color: #0f172a; }
    .footer { border-top: 1px solid #e2e8f0; padding-top: 16px; font-size: 11px; color: #64748b; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="title">BHAGWATI PLASTICS</div>
      <div class="subtitle">Industrial Area, Phase 2 | Quality Molded Polymers</div>
      <div class="subtitle">GSTIN: 07AAAAA0000A1Z5 | Phone: +91 98765 43210</div>
    </div>
    <div style="text-align: right;">
      <span class="badge">OFFICIAL QUOTATION</span>
      <div style="font-weight: 800; font-size: 18px; margin-top: 8px;">${quotation.quote_number}</div>
      <div class="subtitle">Date: ${new Date(quotation.created_at).toLocaleDateString()}</div>
      <div class="subtitle">Order Ref: #${order.order_number}</div>
    </div>
  </div>

  <div class="grid">
    <div class="box">
      <h4>Billed To (Distributor)</h4>
      <div style="font-weight: 700;">${distributor.business_name || distributor.full_name}</div>
      <div>Contact: ${distributor.full_name}</div>
      <div>Phone: ${distributor.phone || "N/A"}</div>
      <div>Address: ${distributor.address || "On File"}</div>
      ${distributor.gst_number ? `<div>GSTIN: ${distributor.gst_number}</div>` : ""}
    </div>
    <div class="box">
      <h4>Logistics & Dispatch Allocation</h4>
      <div>Vehicle Assigned: <strong>${vehicleTier?.name || "Standard Freight"}</strong></div>
      <div>Total Packages: <strong>${order.total_packages} packages</strong> (${order.total_units} units)</div>
      <div>Status: <strong>${order.status.toUpperCase()}</strong></div>
      <div>Est. Dispatch: <strong>${order.estimated_dispatch_date ? new Date(order.estimated_dispatch_date).toLocaleDateString() : "2-4 Business Days"}</strong></div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th style="width: 40px; text-align: center;">#</th>
        <th>Product Description</th>
        <th style="text-align: center;">Packaging / Qty</th>
        <th style="text-align: right;">Unit Price</th>
        <th style="text-align: right;">Total (INR)</th>
      </tr>
    </thead>
    <tbody>
      ${itemsHtml}
    </tbody>
  </table>

  <table class="totals">
    <tr>
      <td>Items Subtotal:</td>
      <td style="text-align: right; font-weight: 600;">₹${Number(quotation.final_subtotal).toFixed(2)}</td>
    </tr>
    <tr>
      <td>Delivery Fare (${vehicleTier?.name || "Auto-tier"}):</td>
      <td style="text-align: right; font-weight: 600;">₹${Number(quotation.vehicle_fare).toFixed(2)}</td>
    </tr>
    <tr>
      <td>GST (18%):</td>
      <td style="text-align: right; font-weight: 600;">₹${Number(taxAmount).toFixed(2)}</td>
    </tr>
    <tr class="grand">
      <td style="padding-top: 8px;">Final Payable Total:</td>
      <td style="text-align: right; padding-top: 8px;">₹${Number(grandTotal).toFixed(2)}</td>
    </tr>
  </table>

  <div class="footer">
    <strong>Terms & Conditions:</strong><br/>
    1. Goods once manufactured against Made-to-Order specifications cannot be cancelled after production commencement.<br/>
    2. Delivery verification will take place via verbal driver OTP handshake on physical arrival.<br/>
    3. Payment terms as agreed per distributor account credit agreement.<br/>
    Computer-generated quotation by Bhagwati Plastic Manufacturing Platform.
  </div>
</body>
</html>`;
}
