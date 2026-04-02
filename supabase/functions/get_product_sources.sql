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
    uom_icon_name text,
    is_accessible boolean
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
    
    -- Pasamos los valores a minúsculas para un manejo más robusto
    IF v_user_id IS NOT NULL THEN
        SELECT 
            LOWER(COALESCE(verification_status::text, 'unverified')), 
            LOWER(COALESCE(verification_type::text, 'individual')) 
        INTO 
            v_verification_status, 
            v_verification_type 
        FROM profiles 
        WHERE id = v_user_id;
    ELSE
        v_verification_status := 'unverified';
        v_verification_type := 'individual';
    END IF;

    RETURN QUERY
    -- 1. FUENTES DE INVENTARIO PROPIO
    SELECT 
        'OWN'::text,
        p.id,
        'Mi Inventario'::text,
        NULL::text,
        public.average_cost(p),
        public.inventory_quantity(p),
        'RETAIL'::text,
        COALESCE(u.icon_name, 'package_2'),
        true -- El inventario propio siempre es accesible
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.id
    LEFT JOIN uoms u ON p.uom_id = u.id
    WHERE 
        p.user_id = v_user_id
        AND UPPER(TRIM(COALESCE(b.name, ''))) = UPPER(TRIM(p_brand))
        AND UPPER(TRIM(COALESCE(p.model, ''))) = UPPER(TRIM(p_model))
        AND UPPER(TRIM(COALESCE(u.symbol, 'unid.'))) = UPPER(TRIM(p_uom))

    UNION ALL

    -- 2. FUENTES DE PROVEEDORES EXTERNOS
    SELECT 
        'SUPPLIER'::text,
        sbs.id,
        s.name,
        sb.city,
        sbs.price,
        sbs.quantity,
        s.trade_type,
        COALESCE(u.icon_name, 'package_2'),
        -- Lógica de visibilidad unificada con get_quote_products
        CASE
            WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
            WHEN v_verification_status != 'verified' THEN (UPPER(COALESCE(s.trade_type, '')) IS DISTINCT FROM 'WHOLESALE')
            ELSE
                NOT (
                   UPPER(COALESCE(s.trade_type, '')) = 'WHOLESALE' 
                   AND 
                   COALESCE(s.allowed_verification_types::text, '') NOT ILIKE '%individual%'
                )
        END
    FROM supplier_products sp
    JOIN supplier_branch_stock sbs ON sp.id = sbs.product_id
    JOIN suppliers s ON sp.supplier_id = s.id
    JOIN supplier_branches sb ON sbs.branch_id = sb.id
    LEFT JOIN brands b ON sp.brand_id = b.id
    LEFT JOIN uoms u ON sp.uom_id = u.id
    WHERE sp.is_active = TRUE
        AND s.is_active = TRUE
        AND sbs.quantity > 0
        -- Coincidencia exacta de Marca, Modelo y UOM
        AND UPPER(TRIM(COALESCE(b.name, sp.brand_raw, 'Genérico'))) = UPPER(TRIM(p_brand))
        AND UPPER(TRIM(COALESCE(sp.model, ''))) = UPPER(TRIM(p_model))
        AND UPPER(TRIM(COALESCE(u.symbol, sp.uom_raw, 'unid.'))) = UPPER(TRIM(p_uom))
    
    ORDER BY 
        1 ASC, -- source_type (OWN primero)
        5 ASC; -- price ASC
END;
$$;
