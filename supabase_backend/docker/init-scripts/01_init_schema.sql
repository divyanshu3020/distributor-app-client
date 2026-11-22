-- Migration: 20261118000000_init_schema.sql
-- Description: Core schema for Bhagwati Plastic Manufacturing B2B Distributor App

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. PROFILES TABLE (Extends Supabase auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'distributor' CHECK (role IN ('super_admin', 'staff', 'distributor')),
    business_name TEXT,
    gst_number TEXT,
    address TEXT,
    fcm_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ============================================================================
-- 2. PRODUCTS TABLE (42-50 Plastic Manufacturing Items)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    units_per_package INTEGER NOT NULL DEFAULT 1 CHECK (units_per_package > 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 50 CHECK (low_stock_threshold >= 0),
    per_distributor_max_cap INTEGER NOT NULL DEFAULT 100 CHECK (per_distributor_max_cap > 0),
    global_queue_cap INTEGER NOT NULL DEFAULT 1000 CHECK (global_queue_cap > 0),
    production_lead_days_per_batch INTEGER NOT NULL DEFAULT 2 CHECK (production_lead_days_per_batch > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);

-- ============================================================================
-- 3. VEHICLE TIERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.vehicle_tiers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    min_packages INTEGER NOT NULL CHECK (min_packages >= 0),
    max_packages INTEGER CHECK (max_packages IS NULL OR max_packages >= min_packages),
    base_fare NUMERIC(10, 2) NOT NULL CHECK (base_fare >= 0),
    per_km_rate NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (per_km_rate >= 0),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 4. ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    distributor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (
        status IN (
            'pending_quote',
            'confirmed',
            'in_production',
            'packing',
            'dispatched',
            'out_for_delivery',
            'delivered',
            'cancelled'
        )
    ),
    subtotal_approx NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal_approx >= 0),
    vehicle_tier_id TEXT REFERENCES public.vehicle_tiers(id),
    vehicle_fare_approx NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (vehicle_fare_approx >= 0),
    total_approx NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_approx >= 0),
    total_packages INTEGER NOT NULL DEFAULT 0 CHECK (total_packages >= 0),
    total_units INTEGER NOT NULL DEFAULT 0 CHECK (total_units >= 0),
    has_made_to_order BOOLEAN NOT NULL DEFAULT false,
    estimated_dispatch_date TIMESTAMPTZ,
    dispatch_notes TEXT,
    driver_name TEXT,
    driver_phone TEXT,
    vehicle_number TEXT,
    expected_arrival TIMESTAMPTZ,
    delivery_otp_hash TEXT,
    delivery_otp_expires_at TIMESTAMPTZ,
    arrival_acknowledged_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    quote_pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_orders_distributor ON public.orders(distributor_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

-- ============================================================================
-- 5. ORDER ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    product_name TEXT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    units_per_package INTEGER NOT NULL DEFAULT 1 CHECK (units_per_package > 0),
    quantity_packages INTEGER NOT NULL DEFAULT 1 CHECK (quantity_packages > 0),
    quantity_units INTEGER NOT NULL DEFAULT 1 CHECK (quantity_units > 0),
    total_price NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0),
    is_made_to_order BOOLEAN NOT NULL DEFAULT false,
    estimated_lead_days INTEGER NOT NULL DEFAULT 0 CHECK (estimated_lead_days >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON public.order_items(product_id);

-- ============================================================================
-- 6. QUOTATIONS TABLE (Locked official quote)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_number TEXT UNIQUE NOT NULL,
    order_id UUID UNIQUE NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    distributor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    final_subtotal NUMERIC(12, 2) NOT NULL CHECK (final_subtotal >= 0),
    vehicle_fare NUMERIC(10, 2) NOT NULL CHECK (vehicle_fare >= 0),
    tax_amount NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    grand_total NUMERIC(12, 2) NOT NULL CHECK (grand_total >= 0),
    status TEXT NOT NULL DEFAULT 'locked' CHECK (status IN ('draft', 'locked', 'invoiced')),
    pdf_storage_path TEXT,
    pdf_public_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_quotations_order ON public.quotations(order_id);
CREATE INDEX IF NOT EXISTS idx_quotations_distributor ON public.quotations(distributor_id);

-- ============================================================================
-- 7. ANNOUNCEMENTS TABLE (News Feed)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'product_launch', 'price_update', 'holiday_closure', 'urgent')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_published BOOLEAN NOT NULL DEFAULT true,
    pinned BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_announcements_published ON public.announcements(is_published, pinned DESC, created_at DESC);

-- ============================================================================
-- 8. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'order_update' CHECK (type IN ('order_update', 'reorder_reminder', 'dispatch_alert', 'arrival_alert', 'announcement', 'general')),
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read, created_at DESC);

-- ============================================================================
-- 9. INVENTORY AUDIT LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.inventory_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    previous_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    change_amount INTEGER NOT NULL,
    reason TEXT NOT NULL,
    adjusted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_inventory_logs_product ON public.inventory_logs(product_id, created_at DESC);

-- ============================================================================
-- 10. HELPER FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: update timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_products_updated_at ON public.products;
CREATE TRIGGER set_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_vehicle_tiers_updated_at ON public.vehicle_tiers;
CREATE TRIGGER set_vehicle_tiers_updated_at BEFORE UPDATE ON public.vehicle_tiers FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_orders_updated_at ON public.orders;
CREATE TRIGGER set_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_announcements_updated_at ON public.announcements;
CREATE TRIGGER set_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Function: Auto-create profile on Supabase auth user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role TEXT := 'distributor';
BEGIN
    -- Allow metadata override for initial seed/admin setup if specified
    IF NEW.raw_user_meta_data->>'role' IS NOT NULL THEN
        default_role := NEW.raw_user_meta_data->>'role';
    END IF;

    INSERT INTO public.profiles (id, email, full_name, phone, role, business_name, address)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'phone',
        default_role,
        NEW.raw_user_meta_data->>'business_name',
        NEW.raw_user_meta_data->>'address'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function: Log product stock changes automatically
CREATE OR REPLACE FUNCTION public.handle_product_stock_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.stock_quantity IS DISTINCT FROM NEW.stock_quantity THEN
        INSERT INTO public.inventory_logs (
            product_id,
            previous_stock,
            new_stock,
            change_amount,
            reason,
            adjusted_by
        ) VALUES (
            NEW.id,
            OLD.stock_quantity,
            NEW.stock_quantity,
            (NEW.stock_quantity - OLD.stock_quantity),
            COALESCE(current_setting('app.inventory_change_reason', true), 'Manual stock update / reconciliation'),
            auth.uid()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS audit_product_stock ON public.products;
CREATE TRIGGER audit_product_stock
    AFTER UPDATE OF stock_quantity ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.handle_product_stock_audit();

-- Function: Calculate dynamic lead time based on current factory queue load
CREATE OR REPLACE FUNCTION public.calculate_dynamic_dispatch_lead_days(p_requested_units INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_active_queue_units INTEGER;
    v_base_lead_days INTEGER := 2; -- Standard tooling & setup lead time
    v_additional_days INTEGER := 0;
BEGIN
    -- Sum all pending units currently queued for production across active orders
    SELECT COALESCE(SUM(oi.quantity_units), 0)
    INTO v_active_queue_units
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE oi.is_made_to_order = true
      AND o.status IN ('confirmed', 'in_production');

    -- Every 200 queued units add ~1 additional factory production day
    v_additional_days := ((v_active_queue_units + p_requested_units) / 200);

    RETURN v_base_lead_days + v_additional_days;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: Determine vehicle tier and fare from package count
CREATE OR REPLACE FUNCTION public.predict_vehicle_for_packages(p_packages INTEGER)
RETURNS TABLE (
    tier_id TEXT,
    tier_name TEXT,
    base_fare NUMERIC(10, 2),
    min_packages INTEGER,
    max_packages INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        vt.id,
        vt.name,
        vt.base_fare,
        vt.min_packages,
        vt.max_packages
    FROM public.vehicle_tiers vt
    WHERE p_packages >= vt.min_packages
      AND (vt.max_packages IS NULL OR p_packages <= vt.max_packages)
    ORDER BY vt.min_packages DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;
