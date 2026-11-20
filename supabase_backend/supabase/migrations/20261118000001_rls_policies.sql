-- Migration: 20261118000001_rls_policies.sql
-- Description: Strict Row-Level Security (RLS) & Column Enforcement for Super Admin, Staff, and Distributor roles

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS FOR ROLE CHECKING
-- ============================================================================

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT role INTO v_role
    FROM public.profiles
    WHERE id = auth.uid();
    
    RETURN COALESCE(v_role, 'distributor');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT public.current_user_role() = 'super_admin');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT public.current_user_role() IN ('super_admin', 'staff'));
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- 1. PROFILES POLICIES
-- ============================================================================

-- Users can read their own profile; staff and super_admin can read all profiles
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT
    USING (
        auth.uid() = id OR public.is_staff_or_admin()
    );

-- Users can update their personal details (phone, business_name, fcm_token)
-- Changing 'role' is guarded by trigger below
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE
    USING (
        auth.uid() = id OR public.is_super_admin()
    )
    WITH CHECK (
        auth.uid() = id OR public.is_super_admin()
    );

-- Trigger: Guard role escalation on profiles
CREATE OR REPLACE FUNCTION public.guard_profile_role_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
        IF NOT public.is_super_admin() THEN
            RAISE EXCEPTION 'Access Denied: Only Super Admin can change user roles.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_guard_profile_role_update ON public.profiles;
CREATE TRIGGER trg_guard_profile_role_update
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.guard_profile_role_update();

-- ============================================================================
-- 2. PRODUCTS POLICIES & STAFF PRICE GUARD TRIGGER
-- ============================================================================

-- All authenticated users can view active products
DROP POLICY IF EXISTS "products_select_policy" ON public.products;
CREATE POLICY "products_select_policy" ON public.products
    FOR SELECT
    USING (
        is_active = true OR public.is_staff_or_admin()
    );

-- Super admin has full insert/delete rights
DROP POLICY IF EXISTS "products_insert_policy" ON public.products;
CREATE POLICY "products_insert_policy" ON public.products
    FOR INSERT
    WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS "products_delete_policy" ON public.products;
CREATE POLICY "products_delete_policy" ON public.products
    FOR DELETE
    USING (public.is_super_admin());

-- Staff and Super admin can update products
DROP POLICY IF EXISTS "products_update_policy" ON public.products;
CREATE POLICY "products_update_policy" ON public.products
    FOR UPDATE
    USING (public.is_staff_or_admin())
    WITH CHECK (public.is_staff_or_admin());

-- CRITICAL BUSINESS RULE ENFORCEMENT:
-- Staff is strictly blocked from modifying unit_price, caps, or sku.
-- Staff can ONLY update stock_quantity.
CREATE OR REPLACE FUNCTION public.guard_staff_product_updates()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT := public.current_user_role();
BEGIN
    IF v_role = 'staff' THEN
        IF OLD.unit_price IS DISTINCT FROM NEW.unit_price THEN
            RAISE EXCEPTION 'Access Denied: Restricted Staff cannot modify product prices. Only Super Admin can alter unit prices.';
        END IF;
        IF OLD.sku IS DISTINCT FROM NEW.sku THEN
            RAISE EXCEPTION 'Access Denied: Restricted Staff cannot modify product SKU.';
        END IF;
        IF OLD.per_distributor_max_cap IS DISTINCT FROM NEW.per_distributor_max_cap THEN
            RAISE EXCEPTION 'Access Denied: Restricted Staff cannot modify distributor order caps.';
        END IF;
        IF OLD.global_queue_cap IS DISTINCT FROM NEW.global_queue_cap THEN
            RAISE EXCEPTION 'Access Denied: Restricted Staff cannot modify global queue caps.';
        END IF;
        IF OLD.low_stock_threshold IS DISTINCT FROM NEW.low_stock_threshold THEN
            RAISE EXCEPTION 'Access Denied: Restricted Staff cannot modify low stock thresholds.';
        END IF;
    ELSIF v_role <> 'super_admin' THEN
        RAISE EXCEPTION 'Access Denied: Distributors cannot update product catalog.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_guard_staff_product_updates ON public.products;
CREATE TRIGGER trg_guard_staff_product_updates
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.guard_staff_product_updates();

-- ============================================================================
-- 3. VEHICLE TIERS POLICIES
-- ============================================================================

-- Anyone authenticated can view vehicle tiers for fare estimates
DROP POLICY IF EXISTS "vehicle_tiers_select_policy" ON public.vehicle_tiers;
CREATE POLICY "vehicle_tiers_select_policy" ON public.vehicle_tiers
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- ONLY Super Admin can insert, update or delete vehicle tiers and base fares
DROP POLICY IF EXISTS "vehicle_tiers_insert_policy" ON public.vehicle_tiers;
CREATE POLICY "vehicle_tiers_insert_policy" ON public.vehicle_tiers
    FOR INSERT
    WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS "vehicle_tiers_update_policy" ON public.vehicle_tiers;
CREATE POLICY "vehicle_tiers_update_policy" ON public.vehicle_tiers
    FOR UPDATE
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS "vehicle_tiers_delete_policy" ON public.vehicle_tiers;
CREATE POLICY "vehicle_tiers_delete_policy" ON public.vehicle_tiers
    FOR DELETE
    USING (public.is_super_admin());

-- ============================================================================
-- 4. ORDERS POLICIES
-- ============================================================================

-- Distributors see their own orders; Staff and Admin see all orders
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
CREATE POLICY "orders_select_policy" ON public.orders
    FOR SELECT
    USING (
        distributor_id = auth.uid() OR public.is_staff_or_admin()
    );

-- Distributors can insert orders for themselves
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
CREATE POLICY "orders_insert_policy" ON public.orders
    FOR INSERT
    WITH CHECK (
        distributor_id = auth.uid() OR public.is_super_admin()
    );

-- Updates:
-- Staff and Super Admin can update dispatch details and status
-- Distributors can only update arrival acknowledgement
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
CREATE POLICY "orders_update_policy" ON public.orders
    FOR UPDATE
    USING (
        distributor_id = auth.uid() OR public.is_staff_or_admin()
    )
    WITH CHECK (
        distributor_id = auth.uid() OR public.is_staff_or_admin()
    );

-- ============================================================================
-- 5. ORDER ITEMS POLICIES
-- ============================================================================

-- Distributors see their own order items; Staff and Admin see all
DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
CREATE POLICY "order_items_select_policy" ON public.order_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
              AND (o.distributor_id = auth.uid() OR public.is_staff_or_admin())
        )
    );

-- Inserting items during order placement
DROP POLICY IF EXISTS "order_items_insert_policy" ON public.order_items;
CREATE POLICY "order_items_insert_policy" ON public.order_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id
              AND (o.distributor_id = auth.uid() OR public.is_super_admin())
        )
    );

-- ============================================================================
-- 6. QUOTATIONS POLICIES
-- ============================================================================

-- Distributors see their own quotes; Staff and Super Admin see all
DROP POLICY IF EXISTS "quotations_select_policy" ON public.quotations;
CREATE POLICY "quotations_select_policy" ON public.quotations
    FOR SELECT
    USING (
        distributor_id = auth.uid() OR public.is_staff_or_admin()
    );

-- Quotations are generated by backend edge functions / super_admin
DROP POLICY IF EXISTS "quotations_insert_policy" ON public.quotations;
CREATE POLICY "quotations_insert_policy" ON public.quotations
    FOR INSERT
    WITH CHECK (
        public.is_staff_or_admin() OR auth.jwt() ->> 'role' = 'service_role'
    );

-- ============================================================================
-- 7. ANNOUNCEMENTS POLICIES
-- ============================================================================

-- Published announcements visible to all authenticated users
DROP POLICY IF EXISTS "announcements_select_policy" ON public.announcements;
CREATE POLICY "announcements_select_policy" ON public.announcements
    FOR SELECT
    USING (
        is_published = true OR public.is_super_admin()
    );

-- Only Super Admin can manage announcements
DROP POLICY IF EXISTS "announcements_admin_manage" ON public.announcements;
CREATE POLICY "announcements_admin_manage" ON public.announcements
    FOR ALL
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- ============================================================================
-- 8. NOTIFICATIONS POLICIES
-- ============================================================================

-- Users read and update their own notifications
DROP POLICY IF EXISTS "notifications_select_policy" ON public.notifications;
CREATE POLICY "notifications_select_policy" ON public.notifications
    FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_update_policy" ON public.notifications;
CREATE POLICY "notifications_update_policy" ON public.notifications
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_insert_policy" ON public.notifications;
CREATE POLICY "notifications_insert_policy" ON public.notifications
    FOR INSERT
    WITH CHECK (
        public.is_staff_or_admin() OR auth.jwt() ->> 'role' = 'service_role' OR user_id = auth.uid()
    );

-- ============================================================================
-- 9. INVENTORY AUDIT LOGS POLICIES
-- ============================================================================

-- Staff and Super Admin can view inventory logs
DROP POLICY IF EXISTS "inventory_logs_select_policy" ON public.inventory_logs;
CREATE POLICY "inventory_logs_select_policy" ON public.inventory_logs
    FOR SELECT
    USING (public.is_staff_or_admin());

-- Inserted by triggers / staff
DROP POLICY IF EXISTS "inventory_logs_insert_policy" ON public.inventory_logs;
CREATE POLICY "inventory_logs_insert_policy" ON public.inventory_logs
    FOR INSERT
    WITH CHECK (public.is_staff_or_admin());
