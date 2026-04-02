-- 1. Primero borramos la version previa
DROP FUNCTION IF EXISTS public.get_quote_products(text, text[], text[], uuid[], numeric, numeric);

-- 2. Ahora creamos la version con nombres de salida unicos (product_id, product_name, etc.)
CREATE OR REPLACE FUNCTION public.get_quote_products(
    query_text text DEFAULT NULL,
    brand_filter text[] DEFAULT NULL,
    category_filter text[] DEFAULT NULL,
    supplier_filter uuid[] DEFAULT NULL,
    min_price_filter numeric DEFAULT NULL,
    max_price_filter numeric DEFAULT NULL
)
RETURNS TABLE (
    product_id uuid,
    product_name text,
    product_description text,
    product_brand text,
    product_model text,
    product_category text,
    product_sku text,
    product_uom text,
    uom_icon_name text,
    product_image_url text,
    total_quantity bigint,
    min_price numeric,
    supplier_count bigint,
    first_supplier_id uuid,
    first_supplier_name text,
    first_supplier_trade_type text,
    first_supplier_logo text,
    suppliers_info jsonb,
    is_locked boolean,
    has_own_inventory boolean
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'extensions'
AS $$
DECLARE
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
BEGIN
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

    v_verification_status := LOWER(COALESCE(v_verification_status, 'unverified'));
    v_verification_type := LOWER(COALESCE(v_verification_type, 'individual'));

    RETURN QUERY
    WITH raw_sources AS (
        SELECT
            sp.id,
            sp.name,
            sp.description,
            COALESCE(b.name, sp.brand_raw, 'Genérico') as brand_label,
            sp.model as model_label,
            COALESCE(c.name, 'Sin Categoría') as category_label,
            COALESCE(u.symbol, sp.uom_raw, 'unid.') as uom_label,
            COALESCE(u.icon_name, 'package_2') as uom_icon,
            (sp.image_urls)[1] as img_url,
            sbs.quantity as stock_quantity,
            sbs.price,
            s.id as supplier_id,
            s.name as supplier_name,
            s.trade_type as supplier_trade_type,
            s.logo_url as supplier_logo,
            false as is_own_inv,
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
            (
                query_text IS NULL OR query_text = '' 
                OR to_tsvector('spanish', unaccent(COALESCE(sp.name, '')) || ' ' || unaccent(COALESCE(sp.brand_raw, '')) || ' ' || unaccent(COALESCE(sp.model, '')))
                @@ plainto_tsquery('spanish', unaccent(query_text))
                OR unaccent(sp.name) ILIKE '%' || unaccent(query_text) || '%'
            ) as match_query
        FROM supplier_products sp
        JOIN supplier_branch_stock sbs ON sbs.product_id = sp.id
        JOIN suppliers s ON sp.supplier_id = s.id
        LEFT JOIN categories c ON sp.category_id = c.id
        LEFT JOIN brands b ON sp.brand_id = b.id
        LEFT JOIN uoms u ON sp.uom_id = u.id
        WHERE sp.is_active = true AND s.is_active = true AND sbs.quantity > 0

        UNION ALL

        SELECT
            p.id,
            p.name,
            p.specifications as description,
            COALESCE(b.name, 'Mi Marca') as brand_label,
            p.model as model_label,
            COALESCE(c.name, 'Sin Categoría') as category_label,
            COALESCE(u.symbol, 'unid.') as uom_label,
            COALESCE(u.icon_name, 'package_2') as uom_icon,
            NULL::text as img_url,
            public.inventory_quantity(p) as stock_quantity,
            public.average_cost(p) as price,
            v_user_id as supplier_id,
            'Mi Inventario' as supplier_name,
            'RETAIL' as supplier_trade_type,
            NULL::text as supplier_logo,
            true as is_own_inv,
            true as is_accessible,
            (
                query_text IS NULL OR query_text = '' 
                OR to_tsvector('spanish', unaccent(COALESCE(p.name, '')) || ' ' || unaccent(COALESCE(b.name, '')) || ' ' || unaccent(COALESCE(p.model, '')))
                @@ plainto_tsquery('spanish', unaccent(query_text))
                OR unaccent(p.name) ILIKE '%' || unaccent(query_text) || '%'
            ) as match_query
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN brands b ON p.brand_id = b.id
        LEFT JOIN uoms u ON p.uom_id = u.id
        WHERE p.user_id = v_user_id
    ),
    filtered_sources AS (
        SELECT * FROM raw_sources
        WHERE match_query = true
          AND (brand_filter IS NULL OR brand_label = ANY(brand_filter))
          AND (category_filter IS NULL OR category_label = ANY(category_filter))
          AND (supplier_filter IS NULL OR supplier_id = ANY(supplier_filter))
          AND (min_price_filter IS NULL OR price >= min_price_filter)
          AND (max_price_filter IS NULL OR price <= max_price_filter)
    )
    SELECT
        (ARRAY_AGG(fs.id ORDER BY fs.price ASC))[1],
        mode() WITHIN GROUP (ORDER BY fs.name),
        MIN(fs.description),
        fs.brand_label,
        fs.model_label,
        mode() WITHIN GROUP (ORDER BY fs.category_label),
        fs.model_label,
        fs.uom_label,
        fs.uom_icon,
        MIN(fs.img_url),
        SUM(fs.stock_quantity)::bigint,
        COALESCE(MIN(fs.price) FILTER (WHERE fs.is_accessible), MIN(fs.price)),
        COUNT(DISTINCT fs.supplier_id)::bigint,
        COALESCE((ARRAY_AGG(fs.supplier_id ORDER BY fs.price ASC) FILTER (WHERE fs.is_accessible))[1], (ARRAY_AGG(fs.supplier_id ORDER BY fs.price ASC))[1]),
        COALESCE((ARRAY_AGG(fs.supplier_name ORDER BY fs.price ASC) FILTER (WHERE fs.is_accessible))[1], (ARRAY_AGG(fs.supplier_name ORDER BY fs.price ASC))[1]),
        COALESCE((ARRAY_AGG(fs.supplier_trade_type ORDER BY fs.price ASC) FILTER (WHERE fs.is_accessible))[1], (ARRAY_AGG(fs.supplier_trade_type ORDER BY fs.price ASC))[1]),
        COALESCE((ARRAY_AGG(fs.supplier_logo ORDER BY fs.price ASC) FILTER (WHERE fs.is_accessible))[1], (ARRAY_AGG(fs.supplier_logo ORDER BY fs.price ASC))[1]),
        jsonb_agg(DISTINCT jsonb_build_object('id', fs.supplier_id, 'name', fs.supplier_name)),
        (COUNT(*) FILTER (WHERE fs.is_accessible) = 0),
        BOOL_OR(fs.is_own_inv)
    FROM filtered_sources fs
    GROUP BY 
        UPPER(TRIM(fs.brand_label)), 
        UPPER(TRIM(fs.model_label)), 
        UPPER(TRIM(fs.uom_label)),
        CASE WHEN TRIM(fs.model_label) = '' THEN UPPER(TRIM(fs.name)) ELSE '' END,
        fs.brand_label, 
        fs.model_label, 
        fs.uom_label, 
        fs.uom_icon;
END;
$$;