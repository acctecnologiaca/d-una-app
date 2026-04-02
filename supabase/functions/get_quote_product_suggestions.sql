DECLARE
    v_user_id uuid;
    v_verification text;
    v_verification_type text;
BEGIN
    v_user_id := auth.uid();
    
    -- Manejo seguro si no hay usuario (caso extremo)
    IF v_user_id IS NOT NULL THEN
        SELECT LOWER(COALESCE(verification_status, 'unverified')), 
               LOWER(COALESCE(verification_type, 'individual')) 
        INTO v_verification, v_verification_type 
        FROM profiles 
        WHERE id = v_user_id;
    ELSE
        v_verification := 'unverified';
        v_verification_type := 'individual';
    END IF;

    RETURN QUERY
    WITH own_inventory AS (
         SELECT 
            p.name AS p_name,
            COALESCE(b.name, 'Genérico') AS p_brand,
            COALESCE(p.category, 'Sin Categoría') AS p_category,
            COALESCE(p.model, '') AS p_model,
            COALESCE(u.symbol, 'unid.') AS p_uom,
            COALESCE(u.icon_name, 'package_2') AS p_uom_icon_name,
            p.id AS product_id,
            0 AS frequency_score, 
            p.updated_at AS last_added_at,
            public.average_cost(p) AS unit_price,
            public.inventory_quantity(p) AS stock_qty,
            v_user_id AS supplier_id,
            'Mi Inventario' AS supplier_name,
            'RETAIL' AS trade_type, 
            true AS is_own_inv
        FROM products p
        LEFT JOIN brands b ON p.brand_id = b.id
        LEFT JOIN uoms u ON p.uom_id = u.id
        WHERE p.user_id = v_user_id
    ),
    supplier_market AS (
        SELECT 
            sp.name AS p_name,
            COALESCE(b.name, sp.brand_raw, 'Genérico') AS p_brand,
            COALESCE(sp.category, 'Sin Categoría') AS p_category,
            COALESCE(sp.model, '') AS p_model,
            COALESCE(u.symbol, sp.uom_raw, 'unid.') AS p_uom,
            COALESCE(u.icon_name, 'package_2') AS p_uom_icon_name,
            sp.id AS product_id,
            sp.frequency_score,
            sp.last_added_at,
            sbs.price AS unit_price,
            sbs.quantity AS stock_qty,
            s.id AS supplier_id,
            s.name AS supplier_name,
            s.trade_type AS trade_type,
            false AS is_own_inv
        FROM supplier_products sp
        JOIN supplier_branch_stock sbs ON sp.id = sbs.product_id
        JOIN suppliers s ON sp.supplier_id = s.id
        LEFT JOIN brands b ON sp.brand_id = b.id
        LEFT JOIN uoms u ON sp.uom_id = u.id
        WHERE 
            sp.is_active = true 
            AND s.is_active = true
            AND sbs.quantity > 0
            AND (
                s.trade_type IN ('RETAIL', 'BOTH') OR
                (s.trade_type = 'WHOLESALE' AND v_verification = 'verified' AND v_verification_type = 'business')
            )
    ),
    raw_sources AS (
        SELECT sm.*, 
            (
                query_text IS NULL OR query_text = '' OR
                to_tsvector('spanish', unaccent(COALESCE(sm.p_name, ''))) ||
                to_tsvector('spanish', unaccent(COALESCE(sm.p_brand, ''))) ||
                to_tsvector('spanish', unaccent(COALESCE(sm.p_model, '')))
                @@ plainto_tsquery('spanish', unaccent(query_text))
            ) AS match_query
        FROM supplier_market sm
        UNION ALL
        SELECT oi.*, 
            (
                query_text IS NULL OR query_text = '' OR
                to_tsvector('spanish', unaccent(COALESCE(oi.p_name, ''))) ||
                to_tsvector('spanish', unaccent(COALESCE(oi.p_brand, ''))) ||
                to_tsvector('spanish', unaccent(COALESCE(oi.p_model, '')))
                @@ plainto_tsquery('spanish', unaccent(query_text))
            ) AS match_query
        FROM own_inventory oi
    ),
    filtered_sources AS (
        SELECT * FROM raw_sources
        WHERE 
            match_query = true
            AND (brand_filters IS NULL OR array_length(brand_filters, 1) IS NULL OR p_brand = ANY(brand_filters))
            AND (category_filters IS NULL OR array_length(category_filters, 1) IS NULL OR p_category = ANY(category_filters))
            AND (supplier_filters IS NULL OR array_length(supplier_filters, 1) IS NULL OR supplier_id = ANY(supplier_filters))
    )
    SELECT 
        fs.p_name AS name,
        fs.p_brand AS brand,
        fs.p_category AS category,
        fs.p_model AS model,
        fs.p_uom AS uom,
        fs.p_uom_icon_name AS uom_icon_name,
        MIN(fs.unit_price) AS min_price,
        SUM(fs.stock_qty) AS total_quantity,
        COUNT(DISTINCT fs.supplier_id)::integer AS supplier_count,
        BOOL_OR(fs.is_own_inv) AS has_own_inventory,
        MAX(fs.frequency_score)::integer AS frequency_score,
        MAX(fs.last_added_at) AS last_added_at,
        (array_agg(fs.trade_type ORDER BY fs.unit_price ASC))[1] AS first_supplier_trade_type,
        false AS is_locked, 
        array_agg(DISTINCT fs.supplier_name) AS supplier_names,
        array_agg(DISTINCT fs.supplier_id) AS supplier_ids
    FROM filtered_sources fs
    GROUP BY 
        fs.p_name,
        fs.p_brand,
        fs.p_category,
        fs.p_model,
        fs.p_uom,
        fs.p_uom_icon_name
    HAVING 
        (p_min_price IS NULL OR MIN(fs.unit_price) >= p_min_price) AND
        (p_max_price IS NULL OR MIN(fs.unit_price) <= p_max_price)
    ORDER BY 
        MAX(fs.frequency_score)::integer DESC NULLS LAST, 
        COUNT(DISTINCT fs.supplier_id)::integer DESC,     
        MIN(fs.unit_price) ASC;                   
END;
