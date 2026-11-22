-- Seed Data for Bhagwati Plastic Manufacturing B2B Distributor App
-- Contains 5 Vehicle Tiers, 46 Catalog Products, Sample Announcements

-- ============================================================================
-- 1. VEHICLE TIERS SEED DATA
-- ============================================================================
INSERT INTO public.vehicle_tiers (id, name, min_packages, max_packages, base_fare, per_km_rate, description)
VALUES
    ('auto', '3-Wheeler Auto / E-Loader', 1, 25, 350.00, 15.00, 'Best suited for small localized distributor sample orders (Up to 25 packages).'),
    ('tempo', 'Tata Ace / Small Tempo (Chota Hathi)', 26, 60, 850.00, 22.00, 'Standard municipal local route carrier (26 to 60 packages).'),
    ('mini_truck', 'Mahindra Bolero Maxi / 8-10ft Pickup', 61, 100, 1600.00, 30.00, 'Medium delivery vehicle for regional distributor dispatches (61 to 100 packages).'),
    ('truck', '14-17ft Full Body Truck', 101, 220, 3200.00, 45.00, 'Heavy commercial truck for bulk distributor orders (>100 packages up to 220 packages).'),
    ('heavy_truck', '20ft+ Multi-Axle Industrial Container', 221, NULL, 5800.00, 60.00, 'Interstate bulk shipping for maximum cargo loads (221+ packages).')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    min_packages = EXCLUDED.min_packages,
    max_packages = EXCLUDED.max_packages,
    base_fare = EXCLUDED.base_fare,
    per_km_rate = EXCLUDED.per_km_rate,
    description = EXCLUDED.description;

-- ============================================================================
-- 2. PLASTIC PRODUCTS SEED DATA (46 Realistic Products)
-- ============================================================================
INSERT INTO public.products (sku, name, category, description, unit_price, units_per_package, stock_quantity, low_stock_threshold, per_distributor_max_cap, global_queue_cap, production_lead_days_per_batch)
VALUES
    -- Buckets & Mugs (Household & Utility)
    ('BKT-005L-STD', '5 Litre Heavy Duty Virgin Bucket', 'Buckets & Mugs', 'Premium virgin polypropylene bucket with rust-free stainless steel handle.', 48.00, 24, 450, 60, 120, 1500, 2),
    ('BKT-010L-DLX', '10 Litre Deluxe Printed Bucket', 'Buckets & Mugs', 'Floral in-mold labeling bathroom bucket with ergonomic grip handle.', 85.00, 18, 320, 50, 100, 1200, 2),
    ('BKT-016L-SUP', '16 Litre Super Ribbed Bucket', 'Buckets & Mugs', 'Reinforced side-ribbed design for high impact resistance in daily household use.', 115.00, 12, 180, 40, 80, 1000, 2),
    ('BKT-020L-IND', '20 Litre Industrial Heavy Duty Bucket', 'Buckets & Mugs', 'Extra thick wall construction suited for paint, construction, and chemical handling.', 145.00, 12, 25, 50, 50, 1000, 3), -- Low stock: triggers cap & backorder logic
    ('BKT-025L-JMB', '25 Litre Jumbo Frost Finish Bucket', 'Buckets & Mugs', 'Jumbo capacity water storage bucket with durable plastic carrying handle.', 180.00, 10, 0, 30, 40, 800, 3), -- 0 Stock: Made to order

    ('MUG-001L-CLS', '1 Litre Classic Bath Mug (Pack of 12)', 'Buckets & Mugs', 'Smooth molded round bath mug with comfortable thumb rest.', 18.00, 24, 600, 80, 150, 2000, 1),
    ('MUG-015L-DLX', '1.5 Litre Transparent Frost Bath Mug (Pack of 12)', 'Buckets & Mugs', 'Frost gradient finish bath mug with measurement indicators.', 24.00, 24, 420, 70, 150, 1800, 1),

    -- Basins & Washing Tubs
    ('BSN-014R-STD', '14" Round Multipurpose Basin', 'Basins & Tubs', 'Flexible crack-resistant basin for kitchen and household washing.', 38.00, 30, 500, 60, 120, 1500, 2),
    ('BSN-018R-HVY', '18" Heavy Rim Construction Basin', 'Basins & Tubs', 'Thickened outer rim for mortar, cement, and high-load civil tasks.', 72.00, 20, 12, 50, 60, 1200, 2), -- Low stock
    ('BSN-022R-SUP', '22" Super Deluxe Deep Washing Basin', 'Basins & Tubs', 'Deep bowl basin for heavy laundry and domestic washing applications.', 110.00, 15, 210, 40, 80, 1000, 2),
    ('TUB-035L-FLX', '35 Litre Oval Washing Tub with Handles', 'Basins & Tubs', 'Dual ergonomic handles for effortless lifting of loaded clothes/water.', 175.00, 10, 95, 30, 50, 800, 3),
    ('TUB-050L-JMB', '50 Litre Jumbo Oval Laundry Tub', 'Basins & Tubs', 'Large volume tub with reinforced bottom ribbing for heavy-duty soaking.', 240.00, 8, 45, 25, 40, 600, 3),

    -- Industrial Storage Drums & Containers
    ('DRM-030L-IND', '30 Litre Blue Chemical Storage Drum', 'Industrial Storage', 'Blow-molded high molecular HDPE drum with tight closure bung caps.', 380.00, 4, 110, 20, 40, 500, 3),
    ('DRM-050L-IND', '50 Litre Blue Industrial Drum with Ring Lock', 'Industrial Storage', 'Full open top drum with galvanized steel clamping ring for chemical safety.', 520.00, 2, 8, 20, 30, 400, 4), -- Low stock
    ('DRM-080L-IND', '80 Litre Commercial Waste / Liquid Drum', 'Industrial Storage', 'Heavy capacity liquid reservoir drum with side handles.', 780.00, 2, 35, 15, 20, 300, 4),
    ('DRM-100L-IND', '100 Litre Open Top Industrial Tank Container', 'Industrial Storage', 'Industrial-grade UV stabilized polyethylene container with screw lid.', 990.00, 1, 0, 10, 15, 250, 5), -- Backorder

    -- Dustbins & Waste Management
    ('DST-010L-PDL', '10 Litre Hygienic Pedal Dustbin', 'Dustbins', 'Hands-free foot pedal mechanism dustbin with inner removable bucket.', 185.00, 12, 140, 30, 60, 800, 2),
    ('DST-030L-SWG', '30 Litre Dual-Action Swing Dustbin', 'Dustbins', 'Balanced counter-weighted swing lid for commercial offices and clinics.', 295.00, 6, 80, 20, 40, 600, 2),
    ('DST-060L-FLP', '60 Litre Heavy Push-Flap Municipal Dustbin', 'Dustbins', 'High traffic waste bin suitable for factories, hotels, and schools.', 540.00, 4, 3, 15, 25, 400, 3), -- Low stock
    ('DST-120L-WHL', '120 Litre Two-Wheel Heavy Outdoor Bin', 'Dustbins', 'UV resistant outdoor mobile bin with solid rubber wheels and steel axle.', 1450.00, 1, 18, 10, 15, 200, 4),

    -- Furniture & Seating (Chairs & Stools)
    ('CHR-001M-RYL', 'Royal Plastic Arm Chair (Set of 2)', 'Furniture', 'Molded monobloc stackable arm chair with high backrest and 150kg load rating.', 450.00, 2, 220, 30, 50, 600, 3),
    ('CHR-002A-PRM', 'Armless Modern Dining Plastic Chair (Set of 4)', 'Furniture', 'Contemporary sleek profile suitable for cafeteria and event seating.', 360.00, 4, 160, 25, 40, 500, 3),
    ('STL-008B-PAT', '8" Bathroom Bath Patla with Rubber Bush', 'Furniture', 'Non-skid rubber feet base stool with anti-slip patterned top surface.', 65.00, 20, 350, 40, 100, 1200, 2),
    ('STL-012D-DLX', '12" Deluxe Kitchen Stool', 'Furniture', 'Strong ribbed stool with center finger grip hole for effortless moving.', 110.00, 15, 190, 35, 75, 900, 2),
    ('STL-018H-STK', '18" High Stacking Counter Stool', 'Furniture', 'High clearance commercial stacking stool for workbenches and counters.', 195.00, 10, 0, 20, 30, 500, 3), -- Backorder

    -- Industrial Crates & Logistics
    ('CRT-001P-VEG', 'Perforated Fruit & Veggie Crate (540x360x280mm)', 'Industrial Crates', 'Optimized airflow design with inter-stacking rails for agro logistics.', 290.00, 6, 420, 50, 100, 1500, 3),
    ('CRT-002S-IND', 'Solid Industrial Stacking Crate (600x400x320mm)', 'Industrial Crates', 'Closed wall heavy duty tote box for auto parts and warehouse hardware.', 385.00, 5, 280, 40, 80, 1200, 3),
    ('CRT-003M-MLK', 'Milk Pouch Distribution Crate (12 Litre)', 'Industrial Crates', 'Standard dairy industry crate designed for 24 half-litre pouches.', 240.00, 8, 5, 40, 80, 1000, 2), -- Low stock
    ('CRT-004F-JMB', 'Fish & Poultry Transport Crate (800x560x380mm)', 'Industrial Crates', 'Ultra-high impact copolymer crate with drain holes.', 580.00, 4, 90, 20, 35, 600, 4),

    -- Kitchenware & Food Storage Containers
    ('JARS-0500-SPC', '500ml Airtight Spice Jar (Box of 12)', 'Kitchen Storage', 'Food-grade polypropylene airtight jar with textured twist cap.', 28.00, 12, 540, 60, 150, 2000, 1),
    ('JARS-1000-FOD', '1000ml Modular Food Saver Container (Box of 6)', 'Kitchen Storage', 'Stackable modular dry-pantry food storage container.', 45.00, 12, 380, 50, 120, 1800, 1),
    ('JARS-2000-KTC', '2000ml Transparent Kitchen Jar (Box of 4)', 'Kitchen Storage', 'High clarity food jar with airtight silicone gasket seal ring.', 75.00, 12, 210, 40, 100, 1200, 2),
    ('JARS-5000-RIC', '5 Litre Rice & Flour Keeper with Measuring Cup', 'Kitchen Storage', 'Wide mouth food hopper with sliding lid and portion cup included.', 160.00, 8, 120, 25, 60, 800, 2),
    ('TFN-003C-LNC', '3-Tier Thermal Insulated Lunch Carrier', 'Kitchen Storage', '3-container stackable lunch carrier with secure side lock buckles.', 210.00, 10, 15, 30, 50, 600, 3), -- Low stock

    -- Household Accessories & Hardware
    ('HNG-006P-STD', 'Heavy Duty Clothes Hanger (Pack of 12)', 'Household Accessories', 'Strong neck hanger with anti-slip strap notches and trouser bar.', 60.00, 20, 600, 50, 150, 2500, 1),
    ('HNG-012P-MET', 'Steel Hook Swivel Hanger (Pack of 6)', 'Household Accessories', '360 degree chrome plated swivel hook with reinforced plastic shoulders.', 95.00, 15, 310, 40, 100, 1500, 2),
    ('CLP-024P-PEG', 'Super Grip Cloth Pegs with Stainless Spring (Pack of 24)', 'Household Accessories', 'UV stabilized pegs that do not stain or rust fabrics.', 35.00, 25, 750, 80, 200, 3000, 1),
    ('DSP-001P-RUB', 'Dustpan with Flexible Beveled Rubber Edge', 'Household Accessories', 'Deep pan design with rubber lip that hugs uneven tile flooring.', 28.00, 24, 430, 50, 120, 1800, 1),
    ('WPR-018F-FLR', '18" Heavy Floor Wiper with Virgin Blade Frame', 'Household Accessories', 'Durable threaded socket wiper head fitting standard metal pipes.', 55.00, 20, 0, 40, 80, 1200, 2), -- Backorder
    ('RK-003T-CNR', '3-Tier Multipurpose Corner Storage Rack', 'Household Accessories', 'Tool-free snap assembly corner organizer for kitchens and bathrooms.', 260.00, 8, 110, 25, 50, 700, 3),

    -- Packaging Bottles & Dispenser Pumps
    ('BTL-0500-SPR', '500ml Heavy Trigger Spray Bottle (Box of 10)', 'Packaging & Caps', 'Adjustable mist-to-stream trigger sprayer for sanitizers and cleaners.', 32.00, 20, 380, 40, 100, 1500, 2),
    ('BTL-1000-HDPE', '1000ml HDPE Narrow Neck Chemical Bottle (Box of 10)', 'Packaging & Caps', 'Opaque bottle with tamper-evident induction seal cap.', 28.00, 25, 520, 50, 150, 2000, 2),
    ('CAP-0028-FLP', '28mm Flip-Top Shampoos/Oil Cap (Box of 500)', 'Packaging & Caps', 'Precision orifice snap-hinge closure cap with leak-proof plug.', 1.20, 10, 1200, 100, 300, 10000, 1),
    ('PMP-0038-LOT', '38mm Heavy Lotion / Soap Dispenser Pump (Box of 200)', 'Packaging & Caps', 'Smooth dispensing pump mechanism with lock-down feature.', 6.50, 10, 850, 80, 200, 5000, 1),
    ('JAR-0250-COS', '250ml Wide Cream Cosmetics Tub (Box of 50)', 'Packaging & Caps', 'Double-wall insulated cosmetic container with inner liner disc.', 14.00, 15, 340, 40, 120, 2000, 2),
    ('CAN-0005-HDPE', '5 Litre Heavy Jerrycan with Vent Cap', 'Packaging & Caps', 'Blow molded stackable jerrycan with integrated sturdy carry handle.', 62.00, 12, 180, 30, 80, 1200, 2)
ON CONFLICT (sku) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    unit_price = EXCLUDED.unit_price,
    units_per_package = EXCLUDED.units_per_package,
    stock_quantity = EXCLUDED.stock_quantity,
    low_stock_threshold = EXCLUDED.low_stock_threshold,
    per_distributor_max_cap = EXCLUDED.per_distributor_max_cap,
    global_queue_cap = EXCLUDED.global_queue_cap,
    production_lead_days_per_batch = EXCLUDED.production_lead_days_per_batch;

-- ============================================================================
-- 3. SAMPLE ANNOUNCEMENTS SEED DATA
-- ============================================================================
INSERT INTO public.announcements (title, message, category, is_published, pinned)
VALUES
    (
        'Exciting New Addition: 20L Industrial Heavy Duty Buckets Now Available!',
        'We have commissioned a new 350-ton injection molding line for our 20L Industrial Heavy Duty Buckets. Orders placed this week receive prioritized production dispatch.',
        'product_launch',
        true,
        true
    ),
    (
        'GST & Raw Material Price Stability Update',
        'Despite polymer granule fluctuations, Bhagwati Plastics is maintaining fixed distributor base pricing across all storage containers and crates for Q4.',
        'price_update',
        true,
        false
    ),
    (
        'Fast-Track Delivery Tiers Active: Truck & Mini-Truck Dispatches',
        'Direct vehicle assignment is now fully integrated into the distributor app. Real-time vehicle fare estimates are visible right in your cart prior to quote confirmation.',
        'general',
        true,
        false
    )
ON CONFLICT DO NOTHING;
