-- ==============================================================================
-- FIX: get_product_sources RPC (String match naming issue)
-- Description: The Dart UI filters the returned sources by ensuring their 
-- `source_name` exists in the `sources` array of the AggregatedProduct.
-- get_quote_product_suggestions used "Mi Inventario", but get_product_sources 
-- used "Inventario propio", causing the frontend to falsely filter it out.
-- ==============================================================================

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
  access_level text
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
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        SELECT verification_status, verification_type 
        INTO v_verification_status, v_verification_type 
        FROM profiles 
        WHERE id = v_user_id;
    END IF;

    v_verification_status := COALESCE(v_verification_status, 'unverified');

  RETURN QUERY
  SELECT 
    'OWN'::text AS source_type,
    p.id AS source_id,
    'Mi Inventario'::text AS source_name, -- FIXED: Was 'Inventario propio'
    NULL::text AS location,
    0::numeric AS price,
    0::numeric AS stock,
    NULL::text AS trade_type,
    'full'::text AS access_level
  FROM products p
  LEFT JOIN brands b ON p.brand_id = b.id
  LEFT JOIN uoms u ON p.uom_id = u.id
  WHERE p.user_id = v_user_id
    AND public.normalize_text(COALESCE(b.name, 'Genérico')) = public.normalize_text(COALESCE(p_brand, 'Genérico'))
    AND public.normalize_text(COALESCE(p.model, '')) = public.normalize_text(COALESCE(p_model, ''))
    AND public.normalize_text(COALESCE(u.symbol, 'ud.')) = public.normalize_text(COALESCE(p_uom, 'ud.'))

  UNION ALL

  SELECT * FROM (
      SELECT 
        'SUPPLIER'::text AS source_type,
        ps.id AS source_id,
        s.name AS source_name,
        sb.city AS location,
        ps.price AS price,
        ps.quantity AS stock,
        s.trade_type AS trade_type,
        
        CASE
            WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN 'full'
            WHEN v_verification_status = 'verified' AND v_verification_type = 'individual' THEN
                CASE 
                    WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN 'partial'
                    ELSE 'full'
                END
            ELSE 
                CASE
                     WHEN s.trade_type IS DISTINCT FROM 'WHOLESALE' THEN 'full'
                     WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN 'denied'
                     ELSE 'restricted'
                END
        END as access_level

      FROM supplier_products sp
      JOIN supplier_branch_stock ps ON sp.id = ps.product_id
      JOIN suppliers s ON sp.supplier_id = s.id
      JOIN supplier_branches sb ON ps.branch_id = sb.id
      LEFT JOIN brands b ON sp.brand_id = b.id
      LEFT JOIN uoms u ON sp.uom_id = u.id
      WHERE sp.is_active = TRUE
        AND s.is_active = TRUE
        AND ps.quantity > 0
        AND public.normalize_text(COALESCE(b.name, 'Genérico')) = public.normalize_text(COALESCE(p_brand, 'Genérico'))
        AND public.normalize_text(COALESCE(sp.model, '')) = public.normalize_text(COALESCE(p_model, ''))
        AND public.normalize_text(COALESCE(u.symbol, 'ud.')) = public.normalize_text(COALESCE(p_uom, 'ud.'))
  ) AS supplier_sources
  WHERE supplier_sources.access_level != 'denied'
  
  ORDER BY 
    source_type ASC,
    price ASC;
END;
$$;
