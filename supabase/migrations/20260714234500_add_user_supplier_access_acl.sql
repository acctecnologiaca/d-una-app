-- Migration: Add User-Supplier Access Control (ACL)
-- Date: 2026-07-14

-- 1. Add is_restricted column to suppliers
ALTER TABLE public.suppliers
ADD COLUMN IF NOT EXISTS is_restricted BOOLEAN NOT NULL DEFAULT false;

-- 2. Create user_supplier_access table
CREATE TABLE IF NOT EXISTS public.user_supplier_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
    access_type TEXT NOT NULL DEFAULT 'allow' CHECK (access_type IN ('allow', 'deny')),
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    UNIQUE(user_id, supplier_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_usa_user ON public.user_supplier_access(user_id);
CREATE INDEX IF NOT EXISTS idx_usa_supplier ON public.user_supplier_access(supplier_id);
CREATE INDEX IF NOT EXISTS idx_usa_type ON public.user_supplier_access(access_type);

-- Enable RLS on user_supplier_access
ALTER TABLE public.user_supplier_access ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view own access grants
DROP POLICY IF EXISTS "Users can view own access grants" ON public.user_supplier_access;
CREATE POLICY "Users can view own access grants"
    ON public.user_supplier_access
    FOR SELECT
    USING (user_id = auth.uid());

-- 3. Create or replace check_supplier_access helper function
CREATE OR REPLACE FUNCTION public.check_supplier_access(
    p_supplier_id UUID,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_is_restricted BOOLEAN;
    v_access_type TEXT;
BEGIN
    -- 1. Check if supplier is restricted
    SELECT is_restricted INTO v_is_restricted
    FROM public.suppliers
    WHERE id = p_supplier_id;

    -- If supplier not found, deny
    IF v_is_restricted IS NULL THEN
        RETURN false;
    END IF;

    -- 2. Check for explicit ACL entry
    SELECT access_type INTO v_access_type
    FROM public.user_supplier_access
    WHERE supplier_id = p_supplier_id
    AND user_id = p_user_id;

    -- 3. Apply rules
    -- DENY always wins
    IF v_access_type = 'deny' THEN
        RETURN false;
    END IF;

    -- If restricted, require explicit ALLOW
    IF v_is_restricted THEN
        RETURN v_access_type = 'allow';
    END IF;

    -- Public supplier with no deny entry -> allowed
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Drop function before recreate to allow changes in return types
DROP FUNCTION IF EXISTS public.get_relevant_suppliers_by_id(uuid[]);

-- 4. Update get_relevant_suppliers_by_id RPC
CREATE OR REPLACE FUNCTION public.get_relevant_suppliers_by_id(occupation_ids uuid[])
 RETURNS TABLE(id uuid, name text, api_key text, is_active boolean, contact_info jsonb, created_at timestamp with time zone, banner_url text, logo_url text, trade_type text, allowed_verification_types text[], user_id uuid, is_verified boolean, is_affiliated boolean, normalized_name text, phone text, email text, tax_id text, notes text, legal_name text, minimum_purchase_amount numeric, is_restricted boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
BEGIN
    -- Get current user context
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        SELECT 
            p.verification_status, 
            p.verification_type 
        INTO 
            v_verification_status, 
            v_verification_type 
        FROM profiles p
        WHERE p.id = v_user_id;
    END IF;

    v_verification_status := COALESCE(v_verification_status, 'unverified');

    RETURN QUERY
    SELECT s.id, s.name, s.api_key, s.is_active, s.contact_info, s.created_at, s.banner_url, s.logo_url, s.trade_type, s.allowed_verification_types, s.user_id, s.is_verified, s.is_affiliated, s.normalized_name, s.phone, s.email, s.tax_id, s.notes, s.legal_name, s.minimum_purchase_amount, s.is_restricted
    FROM suppliers s
    JOIN supplier_sectors ss ON s.id = ss.supplier_id
    JOIN sectors sec ON ss.sector_id = sec.id
    JOIN occupation_sectors os ON sec.id = os.sector_id
    WHERE 
        os.occupation_id = ANY(occupation_ids)
        AND s.is_active = true
        
        -- Access Control: Filter out DENIED suppliers
        AND (
            CASE
                -- Verified Business -> Full (Allow)
                WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
                
                -- Verified Individual -> Full/Partial (Allow All)
                WHEN v_verification_status = 'verified' AND v_verification_type = 'individual' THEN true
                
                -- Unverified
                ELSE 
                    -- Retail -> Full (Allow)
                    CASE
                         WHEN s.trade_type IS DISTINCT FROM 'WHOLESALE' THEN true
                         -- Wholesale Business -> Denied (Block)
                         WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN false
                         -- Wholesale Individual -> Restricted (Allow but Locked in UI)
                         ELSE true
                    END
            END
        )
        
        -- ACL Access control layer
        AND public.check_supplier_access(s.id, v_user_id)
        
    GROUP BY s.id
    ORDER BY 
        min(ss.display_order) ASC NULLS LAST,
        s.name ASC;
END;
$function$;

-- Drop function before recreate to be consistent
DROP FUNCTION IF EXISTS public.get_product_suppliers(text, text, text, text, uuid[], numeric, numeric);

-- 5. Update get_product_suppliers RPC
CREATE OR REPLACE FUNCTION public.get_product_suppliers(p_name text, p_brand text, p_model text, p_uom text, p_supplier_ids uuid[] DEFAULT NULL::uuid[], p_min_price numeric DEFAULT NULL::numeric, p_max_price numeric DEFAULT NULL::numeric)
 RETURNS TABLE(supplier_branch_stock_id uuid, supplier_id uuid, supplier_name text, supplier_trade_type text, supplier_allowed_verification_types text[], branch_id uuid, branch_name text, branch_city text, price numeric, stock_quantity integer, last_updated timestamp with time zone, uom text, uom_icon_name text, is_accessible boolean, minimum_purchase_amount numeric, product_id uuid)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        SELECT 
            p.verification_status, 
            p.verification_type 
        INTO 
            v_verification_status, 
            v_verification_type 
        FROM profiles p
        WHERE p.id = v_user_id;
    END IF;

    v_verification_status := LOWER(COALESCE(v_verification_status, 'unverified'));
    v_verification_type := LOWER(COALESCE(v_verification_type, 'individual'));

    RETURN QUERY
    SELECT
        sbs.id as supplier_branch_stock_id,
        s.id as supplier_id,
        s.name as supplier_name,
        s.trade_type as supplier_trade_type,
        s.allowed_verification_types as supplier_allowed_verification_types,
        sb.id as branch_id,
        sb.name as branch_name,
        sb.city as branch_city,
        sbs.price,
        sbs.quantity::integer as stock_quantity,
        sbs.updated_at as last_updated,
        COALESCE(u.symbol, sp.uom_raw, 'unid.') as uom,
        COALESCE(u.icon_name, 'package_2') as uom_icon_name,
        
        CASE
            WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
            WHEN v_verification_status != 'verified' THEN (UPPER(COALESCE(s.trade_type, '')) IS DISTINCT FROM 'WHOLESALE')
            ELSE
                NOT (
                   UPPER(COALESCE(s.trade_type, '')) = 'WHOLESALE' 
                   AND 
                   COALESCE(s.allowed_verification_types::text, '') NOT ILIKE '%individual%'
                )
        END as is_accessible,
        s.minimum_purchase_amount,
        sp.id as product_id

    FROM supplier_products sp
    JOIN supplier_branch_stock sbs ON sp.id = sbs.product_id
    JOIN supplier_branches sb ON sbs.branch_id = sb.id
    JOIN suppliers s ON sp.supplier_id = s.id
    LEFT JOIN brands b ON sp.brand_id = b.id
    LEFT JOIN uoms u ON sp.uom_id = u.id
    WHERE
        UPPER(TRIM(COALESCE(b.name, sp.brand_raw, 'Genérico'))) = UPPER(TRIM(p_brand))
        AND UPPER(TRIM(COALESCE(sp.model, ''))) = UPPER(TRIM(p_model))
        AND UPPER(TRIM(COALESCE(u.symbol, sp.uom_raw, 'unid.'))) = UPPER(TRIM(p_uom))
        AND (
            TRIM(COALESCE(sp.model, '')) != '' 
            OR UPPER(TRIM(sp.name)) = UPPER(TRIM(p_name))
        )
        
        AND sp.is_active = true
        AND s.is_active = true
        AND sbs.quantity > 0
        AND (p_supplier_ids IS NULL OR s.id = ANY(p_supplier_ids))
        AND (p_min_price IS NULL OR sbs.price >= p_min_price)
        AND (p_max_price IS NULL OR sbs.price <= p_max_price)
        
        -- ACL Access control layer
        AND public.check_supplier_access(s.id, v_user_id)
    ORDER BY sbs.price ASC, s.name ASC;
END;
$function$;

-- 6. Update Cascading RLS Policies

-- supplier_branches policy
DROP POLICY IF EXISTS "Public Read Access Branches" ON public.supplier_branches;
CREATE POLICY "Branches filtered by supplier access"
    ON public.supplier_branches
    FOR SELECT
    USING (
        public.check_supplier_access(supplier_id, auth.uid())
    );

-- supplier_products policy
DROP POLICY IF EXISTS "Everyone can view active supplier products" ON public.supplier_products;
CREATE POLICY "Products filtered by supplier access"
    ON public.supplier_products
    FOR SELECT
    USING (
        is_active = true
        AND public.check_supplier_access(supplier_id, auth.uid())
    );

-- supplier_branch_stock policy
DROP POLICY IF EXISTS "Public Read Access Stock" ON public.supplier_branch_stock;
CREATE POLICY "Stock filtered by supplier access"
    ON public.supplier_branch_stock
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.supplier_branches sb
            WHERE sb.id = supplier_branch_stock.branch_id
            AND public.check_supplier_access(sb.supplier_id, auth.uid())
        )
    );

-- 7. Update public.suppliers RLS Select Policies
DROP POLICY IF EXISTS "Everyone can view active suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "suppliers_select_policy" ON public.suppliers;

CREATE POLICY "Everyone can view active suppliers"
    ON public.suppliers
    FOR SELECT
    USING (
        is_active = true
        AND public.check_supplier_access(id, auth.uid())
    );

CREATE POLICY "suppliers_select_policy"
    ON public.suppliers
    FOR SELECT
    USING (
        (
            ((is_affiliated = true) AND (is_verified = true)) 
            OR 
            ((is_affiliated = false) AND ((is_verified = true) OR (user_id = auth.uid())))
        )
        AND public.check_supplier_access(id, auth.uid())
    );

