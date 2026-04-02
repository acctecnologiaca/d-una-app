
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
        WHERE profiles.id = v_user_id;
    END IF;

    v_verification_status := LOWER(COALESCE(v_verification_status, 'unverified'));
    v_verification_type := LOWER(COALESCE(v_verification_type, 'individual'));

    RETURN QUERY
    WITH filtered_products AS (
        SELECT
            sp.id,
            sp.name,
            sp.description,
            COALESCE(b.name, sp.brand_raw, 'Genérico') as brand_label,
            sp.model as model_label,
            c.name as category_label,
            COALESCE(u.symbol, sp.uom_raw, 'unid.') as uom_label,
            COALESCE(u.icon_name, 'package_2') as icon_name,
            (sp.image_urls)[1] as image_url,
            sbs.quantity as stock_quantity,
            sbs.price,
            s.id as supplier_id,
            s.name as supplier_name,
            s.trade_type as supplier_trade_type,
            s.logo_url as supplier_logo,
            
            -- Accessibility: 3-tier business rules
            CASE
                WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
                WHEN v_verification_status != 'verified' THEN (UPPER(COALESCE(s.trade_type, '')) IS DISTINCT FROM 'WHOLESALE')
                ELSE
                    NOT (
                       UPPER(COALESCE(s.trade_type, '')) = 'WHOLESALE' 
                       AND 
                       COALESCE(s.allowed_verification_types::text, '') NOT ILIKE '%individual%'
                    )
            END as is_accessible

        FROM supplier_products sp
        JOIN supplier_branch_stock sbs ON sbs.product_id = sp.id
        JOIN suppliers s ON sp.supplier_id = s.id
        LEFT JOIN categories c ON sp.category_id = c.id
        LEFT JOIN brands b ON sp.brand_id = b.id
        LEFT JOIN uoms u ON sp.uom_id = u.id
        WHERE
            sp.is_active = true
            AND s.is_active = true
            AND sbs.quantity > 0
            
            -- Spanish full-text search + fallback ILIKE
            AND (
                query_text IS NULL 
                OR query_text = '' 
                OR (
                    to_tsvector('spanish', 
                        unaccent(COALESCE(sp.name, '')) || ' ' || 
                        unaccent(COALESCE(sp.description, '')) || ' ' || 
                        unaccent(COALESCE(b.name, sp.brand_raw, '')) || ' ' || 
                        unaccent(COALESCE(sp.model, ''))
                    ) @@ plainto_tsquery('spanish', unaccent(query_text))
                    OR unaccent(sp.name) ILIKE '%' || unaccent(query_text) || '%'
                )
            )

            AND (brand_filter IS NULL OR COALESCE(b.name, sp.brand_raw) = ANY(brand_filter))
            AND (category_filter IS NULL OR c.name = ANY(category_filter))
            AND (supplier_filter IS NULL OR s.id = ANY(supplier_filter))
            AND (min_price_filter IS NULL OR sbs.price >= min_price_filter)
            AND (max_price_filter IS NULL OR sbs.price <= max_price_filter)
    )
    SELECT
        (ARRAY_AGG(fp.id ORDER BY fp.price ASC))[1] as id,
        mode() WITHIN GROUP (ORDER BY fp.name) as name,
        MIN(fp.description) as description,
        fp.brand_label as brand,
        fp.model_label as model,
        mode() WITHIN GROUP (ORDER BY fp.category_label) as category,
        fp.model_label as sku,
        fp.uom_label as uom,
        fp.icon_name as uom_icon_name,
        MIN(fp.image_url) as image_url,
        SUM(fp.stock_quantity)::bigint as total_quantity,
        COALESCE(MIN(fp.price) FILTER (WHERE fp.is_accessible), MIN(fp.price)) as min_price,
        COUNT(DISTINCT fp.supplier_id) as supplier_count,
        COALESCE((ARRAY_AGG(fp.supplier_id ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible))[1], (ARRAY_AGG(fp.supplier_id ORDER BY fp.price ASC))[1]) as first_supplier_id,
        COALESCE((ARRAY_AGG(fp.supplier_name ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible))[1], (ARRAY_AGG(fp.supplier_name ORDER BY fp.price ASC))[1]) as first_supplier_name,
        COALESCE((ARRAY_AGG(fp.supplier_trade_type ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible))[1], (ARRAY_AGG(fp.supplier_trade_type ORDER BY fp.price ASC))[1]) as first_supplier_trade_type,
        COALESCE((ARRAY_AGG(fp.supplier_logo ORDER BY fp.price ASC) FILTER (WHERE fp.is_accessible))[1], (ARRAY_AGG(fp.supplier_logo ORDER BY fp.price ASC))[1]) as first_supplier_logo,
        ARRAY_AGG(DISTINCT fp.supplier_id) as supplier_ids,
        (COUNT(*) FILTER (WHERE fp.is_accessible) = 0) as is_locked
    FROM filtered_products fp
    GROUP BY 
        UPPER(TRIM(fp.brand_label)), 
        UPPER(TRIM(fp.model_label)), 
        UPPER(TRIM(fp.uom_label)),
        CASE WHEN TRIM(fp.model_label) = '' THEN UPPER(TRIM(fp.name)) ELSE '' END,
        fp.brand_label, 
        fp.model_label, 
        fp.uom_label, 
        fp.icon_name;
END;
