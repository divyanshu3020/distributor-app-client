// Supabase Edge Function: calculate-vehicle-fare
// Description: Predicts vehicle tier based on total package count, calculates approximate delivery fare,
// and evaluates Made-to-Order status and dynamic lead times based on current factory queue load.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CartItemInput {
  productId: string;
  packages: number;
}

interface CalculateFareRequest {
  items: CartItemInput[];
  distanceKm?: number;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const { items, distanceKm = 15 } = (await req.json()) as CalculateFareRequest;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return new Response(JSON.stringify({ error: "Cart items array is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch products
    const productIds = items.map((i) => i.productId);
    const { data: products, error: prodError } = await supabase
      .from("products")
      .select("*")
      .in("id", productIds);

    if (prodError || !products) {
      return new Response(JSON.stringify({ error: "Error fetching products" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const productMap = new Map(products.map((p) => [p.id, p]));

    let totalPackages = 0;
    let totalUnits = 0;
    let subtotalApprox = 0;
    let hasMadeToOrder = false;
    let maxItemLeadDays = 0;

    // Check current queue load across active manufacturing orders
    const { data: queueItems } = await supabase
      .from("order_items")
      .select("quantity_units, orders!inner(status)")
      .eq("is_made_to_order", true)
      .in("orders.status", ["confirmed", "in_production"]);

    const currentActiveQueueUnits = (queueItems || []).reduce((sum, item) => sum + (item.quantity_units || 0), 0);

    const evaluatedItems = items.map((input) => {
      const product = productMap.get(input.productId);
      if (!product) {
        throw new Error(`Product not found: ${input.productId}`);
      }

      const packages = Math.max(1, input.packages);
      const units = packages * product.units_per_package;
      const itemSubtotal = units * Number(product.unit_price);

      // Check threshold and cap logic
      const isBelowThreshold = product.stock_quantity < product.low_stock_threshold;
      const isCapExceeded = packages > product.per_distributor_max_cap;
      
      // Made to order evaluation: if ready stock is less than requested units
      const isMadeToOrder = units > product.stock_quantity;
      if (isMadeToOrder) {
        hasMadeToOrder = true;
      }

      // Dynamic lead days: base setup days + additional days based on queue load
      let itemLeadDays = 0;
      if (isMadeToOrder) {
        const queueImpact = Math.floor((currentActiveQueueUnits + units) / 200);
        itemLeadDays = product.production_lead_days_per_batch + queueImpact;
        if (itemLeadDays > maxItemLeadDays) {
          maxItemLeadDays = itemLeadDays;
        }
      }

      totalPackages += packages;
      totalUnits += units;
      subtotalApprox += itemSubtotal;

      return {
        productId: product.id,
        sku: product.sku,
        name: product.name,
        unitPrice: Number(product.unit_price),
        unitsPerPackage: product.units_per_package,
        packages: packages,
        units: units,
        itemSubtotal: itemSubtotal,
        isBelowThreshold: isBelowThreshold,
        perDistributorMaxCap: product.per_distributor_max_cap,
        isCapExceeded: isCapExceeded,
        isMadeToOrder: isMadeToOrder,
        estimatedLeadDays: itemLeadDays,
        currentReadyStock: product.stock_quantity,
      };
    });

    // Fetch vehicle tiers to match package count
    const { data: vehicleTiers, error: tierError } = await supabase
      .from("vehicle_tiers")
      .select("*")
      .order("min_packages", { ascending: true });

    if (tierError || !vehicleTiers || vehicleTiers.length === 0) {
      return new Response(JSON.stringify({ error: "Vehicle tiers not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Vehicle tier matching based purely on total package count
    let assignedTier = vehicleTiers[vehicleTiers.length - 1]; // Default to highest
    for (const tier of vehicleTiers) {
      if (totalPackages >= tier.min_packages && (tier.max_packages === null || totalPackages <= tier.max_packages)) {
        assignedTier = tier;
        break;
      }
    }

    // Approximate delivery fare: base_fare + (distance * per_km_rate)
    const baseFare = Number(assignedTier.base_fare);
    const perKmRate = Number(assignedTier.per_km_rate);
    const approxDeliveryFare = baseFare + (distanceKm > 10 ? (distanceKm - 10) * perKmRate : 0);

    // Approximate total
    const grandTotalApprox = subtotalApprox + approxDeliveryFare;

    // Dynamic estimated dispatch date
    const estimatedDispatchDate = new Date();
    const leadDays = hasMadeToOrder ? Math.max(2, maxItemLeadDays) : 1; // 1 day for ready stock packing
    estimatedDispatchDate.setDate(estimatedDispatchDate.getDate() + leadDays);

    return new Response(
      JSON.stringify({
        success: true,
        summary: {
          totalPackages,
          totalUnits,
          subtotalApprox,
          approxDeliveryFare,
          grandTotalApprox,
          hasMadeToOrder,
          leadDays,
          estimatedDispatchDate: estimatedDispatchDate.toISOString(),
        },
        vehicleTier: {
          id: assignedTier.id,
          name: assignedTier.name,
          baseFare: baseFare,
          minPackages: assignedTier.min_packages,
          maxPackages: assignedTier.max_packages,
          description: assignedTier.description,
        },
        items: evaluatedItems,
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
