-- ==============================================================================
-- MILESTONE: Intelligent Brand Refactoring (pg_trgm + Regex)
-- Description: Replaces brand_raw with a relational brand_id. Uses a trigger to 
-- automatically deduplicate and map brands based on exact regex match and > 80% 
-- pg_trgm similarity against neighbors sharing the same model.
-- ==============================================================================

-- 1. Enable pg_trgm extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Create the normalization function
CREATE OR REPLACE FUNCTION public.normalize_text(t text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $function$
  SELECT LOWER(regexp_replace(unaccent(COALESCE(t, '')), '[^a-zA-Z0-9]', '', 'g'));
$function$;

-- 3. Modify supplier_products table
ALTER TABLE supplier_products ADD COLUMN IF NOT EXISTS brand_id uuid REFERENCES brands(id);
-- Note: We keep brand_raw for now so as not to break existing data before we backfill

-- 4. Create the Intelligent Mapping Trigger Function
CREATE OR REPLACE FUNCTION public.assign_or_create_brand()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_normalized_brand text;
    v_normalized_model text;
    v_matched_brand_id uuid;
    v_best_similarity real;
    v_candidate record;
BEGIN
    -- Only act if brand_raw is provided
    IF NEW.brand_raw IS NULL OR TRIM(NEW.brand_raw) = '' THEN
        RETURN NEW;
    END IF;

    -- Level 1: Clean text and Exact Match
    v_normalized_brand := public.normalize_text(NEW.brand_raw);
    v_normalized_model := public.normalize_text(NEW.model);
    
    -- Try to find an exact match in the brands table
    SELECT id INTO v_matched_brand_id
    FROM brands
    WHERE public.normalize_text(name) = v_normalized_brand
    LIMIT 1;
    
    IF v_matched_brand_id IS NOT NULL THEN
        NEW.brand_id := v_matched_brand_id;
        RETURN NEW;
    END IF;

    -- Level 2: Similarity search using pg_trgm among peers sharing the same model
    -- We look for other products with the exact same normalized model to see what brands they use.
    v_best_similarity := 0;
    
    FOR v_candidate IN (
        SELECT DISTINCT b.id, b.name
        FROM supplier_products sp
        JOIN brands b ON sp.brand_id = b.id
        WHERE public.normalize_text(sp.model) = v_normalized_model
          AND sp.id != NEW.id -- exclude self if updating
    ) LOOP
        -- Calculate similarity between the incoming raw brand and the candidate brand
        IF similarity(v_normalized_brand, public.normalize_text(v_candidate.name)) > v_best_similarity THEN
            v_best_similarity := similarity(v_normalized_brand, public.normalize_text(v_candidate.name));
            v_matched_brand_id := v_candidate.id;
        END IF;
    END LOOP;

    -- If similarity is greater than 80% (0.8), we assume it's a typo and use that brand
    IF v_best_similarity > 0.8 AND v_matched_brand_id IS NOT NULL THEN
        NEW.brand_id := v_matched_brand_id;
        RETURN NEW;
    END IF;

    -- Level 3: Fallback - Create new brand
    INSERT INTO brands (name) 
    VALUES (TRIM(NEW.brand_raw))
    RETURNING id INTO NEW.brand_id;

    RETURN NEW;
END;
$function$;

-- 5. Attach trigger to supplier_products
DROP TRIGGER IF EXISTS ensure_brand_id ON supplier_products;
CREATE TRIGGER ensure_brand_id
    BEFORE INSERT OR UPDATE OF brand_raw, model ON supplier_products
    FOR EACH ROW
    EXECUTE FUNCTION assign_or_create_brand();

/* 
  ==============================================================================
  RPC UPDATES
  Now that we have a relational brand_id, we update the 4 main RPCs to rely on 
  `b.name` from the joined brands table, ensuring perfect standardization.
  ==============================================================================
*/

-- 6. Update search_supplier_products RPC
DROP FUNCTION IF EXISTS public.search_supplier_products(text, text[], text[], uuid[], numeric, numeric);

CREATE OR REPLACE FUNCTION public.search_supplier_products(
    query_text text,
    brand_filter text[] DEFAULT NULL::text[],
    category_filter text[] DEFAULT NULL::text[],
    supplier_filter uuid[] DEFAULT NULL::uuid[],
    min_price_filter numeric DEFAULT NULL::numeric,
    max_price_filter numeric DEFAULT NULL::numeric
)
RETURNS TABLE(
    id uuid,
    name text,
    description text,
    brand text,
    model text,
    category text,
    uom text, 
    image_url text,
    total_quantity bigint,
    min_price numeric,
    supplier_count bigint,
    first_supplier_id uuid,
    first_supplier_name text,
    first_supplier_trade_type text,
    first_supplier_logo text,
    is_locked boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $function$
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
        WHERE profiles.id = v_user_id;
    END IF;

    v_verification_status := COALESCE(v_verification_status, 'unverified');

    RETURN QUERY
    WITH matched_identities AS (
        SELECT DISTINCT
            public.normalize_text(COALESCE(b.name, 'Genérico')) as brand_key,
            public.normalize_text(COALESCE(sp.model, '')) as model_key,
            public.normalize_text(COALESCE(u.symbol, 'ud.')) as uom_key
        FROM supplier_products sp
        JOIN supplier_branch_stock ps ON ps.product_id = sp.id
        LEFT JOIN brands b ON sp.brand_id = b.id
        LEFT JOIN uoms u ON sp.uom_id = u.id
        WHERE
            sp.is_active = true
            AND ps.quantity > 0 
            
            AND (
                query_text IS NULL 
                OR query_text = '' 
                OR (
                    to_tsvector('spanish', 
                        unaccent(COALESCE(sp.name, '')) || ' ' || 
                        unaccent(COALESCE(sp.description, '')) || ' ' || 
                        unaccent(COALESCE(b.name, '')) || ' ' || 
                        unaccent(COALESCE(sp.model, '')) || ' ' || 
                        unaccent(COALESCE(sp.category_raw, ''))
                    ) @@ plainto_tsquery('spanish', unaccent(query_text))
                    OR unaccent(sp.name) ILIKE '%' || unaccent(query_text) || '%'
                )
            )
            AND (brand_filter IS NULL OR b.name = ANY(brand_filter))
            AND (category_filter IS NULL OR sp.category_raw = ANY(category_filter))
    ),
    filtered_products AS (
        SELECT
            sp.id,
            sp.name,
            sp.description,
            b.name as brand,
            sp.model,
            sp.category_raw as category,
            COALESCE(u.symbol, 'ud.') as uom,
            (sp.image_urls)[1] as image_url,
            ps.quantity as stock_quantity,
            ps.price,
            s.id as supplier_id,
            s.name as supplier_name,
            s.trade_type as supplier_trade_type,
            s.logo_url as supplier_logo,
            
            CASE
                WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
                WHEN v_verification_status != 'verified' THEN (s.trade_type IS DISTINCT FROM 'WHOLESALE')
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
        LEFT JOIN uoms u ON sp.uom_id = u.id
        JOIN matched_identities mi ON 
            public.normalize_text(COALESCE(b.name, 'Genérico')) = mi.brand_key
            AND public.normalize_text(COALESCE(sp.model, '')) = mi.model_key
            AND public.normalize_text(COALESCE(u.symbol, 'ud.')) = mi.uom_key
        WHERE
            sp.is_active = true
            AND s.is_active = true
            AND ps.quantity > 0 
            
            AND (supplier_filter IS NULL OR s.id = ANY(supplier_filter))
            AND (min_price_filter IS NULL OR ps.price >= min_price_filter)
            AND (max_price_filter IS NULL OR ps.price <= max_price_filter)
    )
    SELECT
        MIN(fp.id::text)::uuid as id,
        MIN(fp.name) as name, 
        MIN(fp.description) as description,
        
        mode() WITHIN GROUP (ORDER BY fp.brand) as brand,
        mode() WITHIN GROUP (ORDER BY fp.model) as model,
        MIN(fp.category) as category,
        mode() WITHIN GROUP (ORDER BY fp.uom) as uom,
        
        MIN(fp.image_url) as image_url,
        SUM(fp.stock_quantity)::bigint as total_quantity,
        
        COALESCE(
            MIN(fp.price) FILTER (WHERE fp.is_accessible = true), 
            0 
        ) as min_price,

        COUNT(DISTINCT fp.supplier_id) as supplier_count,
        
        COALESCE(
            (ARRAY_AGG(fp.supplier_id ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible = true))[1],
            (ARRAY_AGG(fp.supplier_id ORDER BY fp.price ASC))[1]
        ) as first_supplier_id,
        
        COALESCE(
            (ARRAY_AGG(fp.supplier_name ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible = true))[1],
            (ARRAY_AGG(fp.supplier_name ORDER BY fp.price ASC))[1]
        ) as first_supplier_name,
        
        COALESCE(
            (ARRAY_AGG(fp.supplier_trade_type ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible = true))[1],
            (ARRAY_AGG(fp.supplier_trade_type ORDER BY fp.price ASC))[1]
        ) as first_supplier_trade_type,
        
        COALESCE(
            (ARRAY_AGG(fp.supplier_logo ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible = true))[1],
            (ARRAY_AGG(fp.supplier_logo ORDER BY fp.price ASC))[1]
        ) as first_supplier_logo,

        (COUNT(*) FILTER (WHERE fp.is_accessible = true) = 0) as is_locked

    FROM filtered_products fp
    
    GROUP BY 
        public.normalize_text(fp.brand),
        public.normalize_text(fp.model),
        public.normalize_text(fp.uom); 
END;
$function$;

-- 7. Update get_quote_product_suggestions RPC
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
      'Mi Inventario'::text as supplier_name,
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

-- 8. Update get_product_suppliers RPC
DROP FUNCTION IF EXISTS public.get_product_suppliers(text, text, text, text, uuid[], numeric, numeric);

CREATE OR REPLACE FUNCTION public.get_product_suppliers(
    p_name text,
    p_brand text,
    p_model text,
    p_uom text, 
    p_supplier_ids uuid[] DEFAULT NULL::uuid[],
    p_min_price numeric DEFAULT NULL::numeric,
    p_max_price numeric DEFAULT NULL::numeric
)
RETURNS TABLE(
    supplier_id uuid,
    supplier_name text,
    supplier_trade_type text,
    supplier_allowed_verification_types text[],
    branch_id uuid,
    branch_name text,
    branch_city text,
    price numeric,
    stock_quantity integer,
    last_updated timestamp with time zone,
    uom text,
    access_level text 
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $function$
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
        s.id as supplier_id,
        s.name as supplier_name,
        s.trade_type as supplier_trade_type,
        s.allowed_verification_types as supplier_allowed_verification_types,
        sb.id as branch_id,
        sb.name as branch_name,
        sb.city as branch_city,
        ps.price,
        ps.quantity::integer as stock_quantity,
        ps.updated_at as last_updated,
        COALESCE(u.symbol, 'ud.') as uom,
        
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
    JOIN supplier_branches sb ON ps.branch_id = sb.id
    JOIN suppliers s ON sp.supplier_id = s.id
    LEFT JOIN brands b ON sp.brand_id = b.id
    LEFT JOIN uoms u ON sp.uom_id = u.id
    WHERE
        public.normalize_text(COALESCE(b.name, 'Genérico')) = public.normalize_text(COALESCE(p_brand, 'Genérico'))
        AND public.normalize_text(COALESCE(sp.model, '')) = public.normalize_text(COALESCE(p_model, ''))
        AND public.normalize_text(COALESCE(u.symbol, 'ud.')) = public.normalize_text(COALESCE(p_uom, 'ud.'))
        
        AND sp.is_active = true
        AND s.is_active = true
        AND ps.quantity > 0
        AND (p_supplier_ids IS NULL OR s.id = ANY(p_supplier_ids))
        AND (p_min_price IS NULL OR ps.price >= p_min_price)
        AND (p_max_price IS NULL OR ps.price <= p_max_price)
        
    AND (
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
        END
    ) NOT IN ('denied', 'restricted')

    ORDER BY ps.price ASC, s.name ASC;
END;
$function$;

-- 9. Update get_product_sources RPC
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
    'Inventario propio'::text AS source_name,
    NULL::text AS location,
    0::numeric AS price,
    0::numeric AS stock,
    NULL::text AS trade_type,
    'full'::text AS access_level
  FROM products p
  LEFT JOIN brands b ON p.brand_id = b.id
  WHERE public.normalize_text(COALESCE(b.name, 'Genérico')) = public.normalize_text(COALESCE(p_brand, 'Genérico'))
    AND public.normalize_text(COALESCE(p.model, 'ud.')) = public.normalize_text(COALESCE(p_model, 'ud.'))
    AND public.normalize_text('ud.') = public.normalize_text(COALESCE(p_uom, 'ud.'))

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
