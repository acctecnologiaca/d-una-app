-- ==========================================
-- DROP and RECREATE get_product_sources
-- ==========================================

DROP FUNCTION IF EXISTS public.get_product_sources(text, text, text, text);

CREATE OR REPLACE FUNCTION public.get_product_sources(
  p_name text,
  p_brand text,
  p_model text,
  p_uom text
)
RETURNS TABLE (
  source_type text,
  source_id uuid,
  source_name text,
  location text,
  price numeric,
  stock numeric,
  trade_type text,
  access_level text -- 'full', 'partial', 'restricted', 'denied'
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
BEGIN
    -- Get current user context
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        SELECT 
            verification_status, 
            verification_type 
        INTO 
            v_verification_status, 
            v_verification_type 
        FROM profiles 
        WHERE id = v_user_id;
    END IF;

    v_verification_status := COALESCE(v_verification_status, 'unverified');

  RETURN QUERY
  -- 1. Own Inventory
  SELECT 
    'OWN'::text AS source_type,
    p.id AS source_id,
    'Inventario propio'::text AS source_name,
    NULL::text AS location,
    0::numeric AS price,
    0::numeric AS stock,
    NULL::text AS trade_type,
    'full'::text AS access_level
  FROM products p
  LEFT JOIN brands b ON p.brand_id = b.id
  WHERE UPPER(TRIM(unaccent(COALESCE(b.name, 'Genérico')))) = UPPER(TRIM(unaccent(COALESCE(p_brand, 'Genérico'))))
    AND UPPER(TRIM(unaccent(COALESCE(p.model, '')))) = UPPER(TRIM(unaccent(COALESCE(p_model, ''))))
    AND UPPER(TRIM(unaccent('ud.'))) = UPPER(TRIM(unaccent(COALESCE(p_uom, 'ud.'))))

  UNION ALL

  -- 2. Suppliers
  SELECT * FROM (
      SELECT 
        'SUPPLIER'::text AS source_type,
        ps.id AS source_id,
        s.name AS source_name,
        sb.city AS location,
        ps.price AS price,
        ps.quantity AS stock,
        s.trade_type AS trade_type,
        
        -- Accessibility Level Logic
        CASE
            -- Verified Business -> Full Access
            WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN 'full'
            
            -- Verified Individual
            WHEN v_verification_status = 'verified' AND v_verification_type = 'individual' THEN
                CASE 
                     -- Wholesale Business -> Partial (Stock visible, Price hidden)
                    WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN 'partial'
                    ELSE 'full'
                END
            
            -- Unverified
            ELSE 
                CASE
                    -- Retail -> Full
                     WHEN s.trade_type IS DISTINCT FROM 'WHOLESALE' THEN 'full'
                     -- Wholesale Business -> Denied (Hidden - filtered out below)
                     WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN 'denied'
                     -- Wholesale Individual (or generic Wholesale) -> Restricted (Visible, Locked)
                     ELSE 'restricted'
                END
        END as access_level

      FROM supplier_products sp
      JOIN product_stock ps ON sp.id = ps.product_id
      JOIN suppliers s ON sp.supplier_id = s.id
      JOIN supplier_branches sb ON ps.branch_id = sb.id
      WHERE sp.is_active = TRUE
        AND s.is_active = TRUE
        AND ps.quantity > 0
        AND UPPER(TRIM(unaccent(COALESCE(sp.brand_raw, 'Genérico')))) = UPPER(TRIM(unaccent(COALESCE(p_brand, 'Genérico'))))
        AND UPPER(TRIM(unaccent(COALESCE(sp.sku, '')))) = UPPER(TRIM(unaccent(COALESCE(p_model, ''))))
        AND UPPER(TRIM(unaccent(COALESCE(sp.uom, 'ud.')))) = UPPER(TRIM(unaccent(COALESCE(p_uom, 'ud.'))))
  ) AS supplier_sources
  WHERE supplier_sources.access_level != 'denied'
  
  ORDER BY 
    source_type ASC, -- 'OWN' comes before 'SUPPLIER' 
    price ASC;
END;
$$;
