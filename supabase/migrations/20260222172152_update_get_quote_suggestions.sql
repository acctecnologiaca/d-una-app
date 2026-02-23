-- ==========================================
-- DROP and RECREATE get_quote_product_suggestions
-- ==========================================

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
  category text,                     -- NEW
  first_supplier_trade_type text,    -- NEW
  is_locked boolean                  -- NEW
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
  -- Safe user fetch
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
      COALESCE(sp.brand_raw, 'Genérico') as brand,
      COALESCE(sp.sku, '') as model,
      COALESCE(sp.uom, 'ud.') as uom,
      c.name as category,
      ps.price,
      ps.quantity,
      sp.supplier_id as supplier_id,
      FALSE as is_own,
      s.trade_type as supplier_trade_type,
      sp.created_at,
      
      -- Accessibility Logic (from search_supplier_products)
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
    JOIN product_stock ps ON ps.product_id = sp.id
    JOIN suppliers s ON sp.supplier_id = s.id
    LEFT JOIN categories c ON sp.category_id = c.id
    WHERE sp.is_active = TRUE AND s.is_active = TRUE AND ps.quantity > 0

    UNION ALL

    -- Own Inventory
    SELECT
      p.name,
      COALESCE(b.name, 'Genérico') as brand,
      COALESCE(p.model, '') as model,
      'ud.'::text as uom,
      c.name as category,
      0::numeric as price,
      0::numeric as quantity,
      NULL::uuid as supplier_id,
      TRUE as is_own,
      NULL::text as supplier_trade_type,
      p.created_at,
      TRUE as is_accessible -- Own inventory always accessible
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.id
    LEFT JOIN categories c ON p.category_id = c.id
  ),
  grouped AS (
    SELECT 
      (ARRAY_AGG(ap.name ORDER BY ap.price ASC))[1] as name,
      COALESCE((ARRAY_AGG(ap.brand ORDER BY ap.price ASC))[1], 'Genérico') as brand,
      COALESCE((ARRAY_AGG(ap.model ORDER BY ap.price ASC))[1], '') as model,
      (ARRAY_AGG(ap.uom ORDER BY ap.price ASC))[1] as uom,
      
      -- Price Logic: Take min from ACCESSIBLE objects first, fallback to overall min
      COALESCE(
        MIN(ap.price) FILTER (WHERE ap.is_accessible), 
        MIN(ap.price)
      ) as min_price,
      
      SUM(ap.quantity) as total_quantity,
      
      -- Supplier Count
      (COUNT(DISTINCT ap.supplier_id) + CASE WHEN BOOL_OR(ap.is_own) THEN 1 ELSE 0 END)::int as supplier_count,
      
      BOOL_OR(ap.is_own) as has_own_inventory,
      MAX(ap.created_at) as last_added_at,
      
      -- NEW FIELDS
      (ARRAY_AGG(ap.category ORDER BY ap.price ASC))[1] as category,
      (ARRAY_AGG(ap.supplier_trade_type ORDER BY ap.is_accessible DESC, ap.price ASC))[1] as first_supplier_trade_type,
      
      -- Is Locked Logic: Locked if NO source has 'true' for is_accessible
      (COUNT(*) FILTER (WHERE ap.is_accessible) = 0) as is_locked

    FROM all_products ap
    GROUP BY 
      LOWER(COALESCE(ap.brand, 'Genérico')), 
      LOWER(COALESCE(ap.model, '')), 
      LOWER(COALESCE(ap.uom, 'ud.'))
  ),
  frequency AS (
    SELECT 
      LOWER(COALESCE(qip.brand, 'Genérico')) as f_brand,
      LOWER(COALESCE(qip.model, '')) as f_model,
      LOWER(COALESCE(qip.uom, 'ud.')) as f_uom,
      COUNT(*) as cnt
    FROM quote_items_products qip
    GROUP BY 
      LOWER(COALESCE(qip.brand, 'Genérico')), 
      LOWER(COALESCE(qip.model, '')), 
      LOWER(COALESCE(qip.uom, 'ud.'))
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
    g.is_locked
  FROM grouped g
  LEFT JOIN frequency f ON 
    LOWER(COALESCE(g.brand, 'Genérico')) = f.f_brand AND 
    LOWER(COALESCE(g.model, '')) = f.f_model AND 
    LOWER(COALESCE(g.uom, 'ud.')) = f.f_uom
    
  -- HIDDEN FILTER: Hide if ONLY wholesale suppliers and user is unverified
  -- Actually, in search_supplier_products it's done dynamically in Dart.
  -- But we CAN pass everything and do it in Dart.
    
  ORDER BY frequency_score DESC, last_added_at DESC;
END;
$function$
