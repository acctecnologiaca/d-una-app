-- ==============================================================================
-- FIX: Standardize Own Inventory Naming to "Inventario propio"
-- Description: The app expects "Inventario propio" as the standard string for
-- the user's own inventory. This updates both `get_quote_product_suggestions` 
-- and `get_product_sources` to use the correct terminology to prevent 
-- client-side filtering mismatches.
-- ==============================================================================

-- 1. Update get_quote_product_suggestions RPC
DROP FUNCTION IF EXISTS public.get_quote_product_suggestions(text);
DROP FUNCTION IF EXISTS public.get_quote_product_suggestions();

CREATE OR REPLACE FUNCTION public.get_quote_product_suggestions(p_verification_status text DEFAULT NULL::text)
 RETURNS TABLE(
  name text, 
  brand text, 
  model text, 
  uom text, 
  min_price numeric, 
  total_quantity numeric, 
  supplier_count integer, 
  has_own_inventory boolean, 
  frequency_score bigint, 
  last_added_at timestamp with time zone,
  category text,                     
  first_supplier_trade_type text,    
  is_locked boolean,                 
  supplier_names text[],              
  sources jsonb                      
 )
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'extensions'
AS $function$
DECLARE
  v_user_id uuid;
  v_verification_status text;
  v_verification_type text;
BEGIN
  BEGIN
    v_user_id := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    v_user_id := NULL;
  END;

  IF v_user_id IS NOT NULL THEN
    BEGIN
      SELECT verification_status, verification_type 
      INTO v_verification_status, v_verification_type
      FROM profiles
      WHERE id = v_user_id;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END IF;

  v_verification_status := COALESCE(v_verification_status, p_verification_status, 'unverified');
  v_verification_type := COALESCE(v_verification_type, 'individual');

  RETURN QUERY
  WITH all_products AS (
    -- Suppliers
    SELECT 
      sp.name,
      COALESCE(b.name, 'Genérico') as brand,
      COALESCE(sp.model, '') as model,
      COALESCE(u.symbol, 'ud.') as uom,
      c.name as category,
      ps.price,
      ps.quantity,
      sp.supplier_id as supplier_id,
      s.name as supplier_name,
      FALSE as is_own,
      s.trade_type as supplier_trade_type,
      sp.created_at,
      
      CASE
        WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
        WHEN v_verification_status != 'verified' THEN 
          (s.trade_type IS DISTINCT FROM 'WHOLESALE')
        ELSE
          NOT (
             s.trade_type = 'WHOLESALE' 
             AND 
             (s.allowed_verification_types IS NOT NULL AND array_length(s.allowed_verification_types, 1) > 0)
             AND 
             NOT ('individual' = ANY(s.allowed_verification_types))
          )
      END as is_accessible

    FROM supplier_products sp
    JOIN supplier_branch_stock ps ON ps.product_id = sp.id
    JOIN suppliers s ON sp.supplier_id = s.id
    LEFT JOIN brands b ON sp.brand_id = b.id
    LEFT JOIN categories c ON sp.category_id = c.id
    LEFT JOIN uoms u ON sp.uom_id = u.id
    WHERE sp.is_active = TRUE AND s.is_active = TRUE AND ps.quantity > 0

    UNION ALL

    -- Own Inventory
    SELECT
      p.name,
      COALESCE(b.name, 'Genérico') as brand,
      COALESCE(p.model, '') as model,
      COALESCE(u.symbol, 'ud.') as uom,
      c.name as category,
      0::numeric as price,
      0::numeric as quantity,
      NULL::uuid as supplier_id,
      'Inventario propio'::text as supplier_name, -- STANDARD STRING
      TRUE as is_own,
      NULL::text as supplier_trade_type,
      p.created_at,
      TRUE as is_accessible
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.id
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN uoms u ON p.uom_id = u.id
    WHERE p.user_id = v_user_id
  ),
  grouped AS (
    SELECT 
      (ARRAY_AGG(ap.name ORDER BY ap.price ASC))[1] as name,
      COALESCE((ARRAY_AGG(ap.brand ORDER BY ap.price ASC))[1], 'Genérico') as brand,
      COALESCE((ARRAY_AGG(ap.model ORDER BY ap.price ASC))[1], '') as model,
      (ARRAY_AGG(ap.uom ORDER BY ap.price ASC))[1] as uom,
      
      COALESCE(
        MIN(ap.price) FILTER (WHERE ap.is_accessible AND NOT ap.is_own), 
        MIN(ap.price) FILTER (WHERE ap.is_accessible),
        MIN(ap.price)
      ) as min_price,
      
      SUM(ap.quantity) as total_quantity,
      
      (COUNT(DISTINCT ap.supplier_id) + CASE WHEN BOOL_OR(ap.is_own) THEN 1 ELSE 0 END)::int as supplier_count,
      
      BOOL_OR(ap.is_own) as has_own_inventory,
      MAX(ap.created_at) as last_added_at,
      
      (ARRAY_AGG(ap.category ORDER BY ap.price ASC))[1] as category,
      (ARRAY_AGG(ap.supplier_trade_type ORDER BY ap.is_accessible DESC, ap.price ASC))[1] as first_supplier_trade_type,
      
      (COUNT(*) FILTER (WHERE ap.is_accessible) = 0) as is_locked,

      ARRAY_REMOVE(ARRAY_AGG(DISTINCT ap.supplier_name), NULL) as supplier_names,

      jsonb_agg(jsonb_build_object(
        'supplier_name', ap.supplier_name,
        'price', ap.price,
        'quantity', ap.quantity,
        'is_own', ap.is_own,
        'is_accessible', ap.is_accessible,
        'supplier_trade_type', ap.supplier_trade_type
      )) as sources

    FROM all_products ap
    GROUP BY 
      public.normalize_text(ap.brand),
      public.normalize_text(ap.model),
      public.normalize_text(ap.uom)
  ),
  frequency AS (
    SELECT 
      public.normalize_text(COALESCE(qip.brand, 'Genérico')) as f_brand,
      public.normalize_text(COALESCE(qip.model, '')) as f_model,
      public.normalize_text(COALESCE(qip.uom, 'ud.')) as f_uom,
      COUNT(*) as cnt
    FROM quote_items_products qip
    GROUP BY 
      public.normalize_text(COALESCE(qip.brand, 'Genérico')),
      public.normalize_text(COALESCE(qip.model, '')),
      public.normalize_text(COALESCE(qip.uom, 'ud.'))
  )
  SELECT 
    g.name,
    g.brand,
    g.model,
    g.uom,
    g.min_price,
    g.total_quantity,
    g.supplier_count,
    g.has_own_inventory,
    COALESCE(f.cnt, 0)::bigint as frequency_score,
    g.last_added_at,
    g.category,
    g.first_supplier_trade_type,
    g.is_locked,
    g.supplier_names,
    g.sources
  FROM grouped g
  LEFT JOIN frequency f ON 
    public.normalize_text(COALESCE(g.brand, 'Genérico')) = f.f_brand AND 
    public.normalize_text(COALESCE(g.model, '')) = f.f_model AND 
    public.normalize_text(COALESCE(g.uom, 'ud.')) = f.f_uom
    
  ORDER BY frequency_score DESC, last_added_at DESC;
END;
$function$;

-- 2. Update get_product_sources RPC
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
    'Inventario propio'::text AS source_name, -- STANDARD STRING
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
