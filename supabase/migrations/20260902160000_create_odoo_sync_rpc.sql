-- Migration: Create Odoo Supplier Sync RPC
-- Purpose: Atomic transactional synchronization of branches, products, and branch stock from Odoo instances

DROP FUNCTION IF EXISTS public.sync_odoo_supplier_data(text, jsonb, jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.sync_odoo_supplier_data(
    p_api_key text,
    p_branches jsonb DEFAULT '[]'::jsonb,
    p_products jsonb DEFAULT '[]'::jsonb,
    p_stock_prices jsonb DEFAULT '[]'::jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_supplier_id uuid;
    v_supplier_name text;
    v_branch_count int := 0;
    v_product_count int := 0;
    v_stock_count int := 0;
    v_branch jsonb;
    v_product jsonb;
    v_stock jsonb;
    v_product_id uuid;
    v_branch_id uuid;
BEGIN
    -- PASO 1: Autenticar proveedor por API Key
    SELECT id, name INTO v_supplier_id, v_supplier_name
    FROM public.suppliers
    WHERE api_key = p_api_key AND is_active = true;

    IF v_supplier_id IS NULL THEN
        RAISE EXCEPTION 'DUNA_AUTH_ERROR: API Key inválida o proveedor inactivo';
    END IF;

    -- PASO 2: Upsert de sucursales/almacenes
    IF p_branches IS NOT NULL AND jsonb_array_length(p_branches) > 0 THEN
        FOR v_branch IN SELECT * FROM jsonb_array_elements(p_branches) LOOP
            IF v_branch->>'external_id' IS NOT NULL AND TRIM(v_branch->>'external_id') != '' THEN
                INSERT INTO public.supplier_branches (supplier_id, external_id, name, city, email, phone)
                VALUES (
                    v_supplier_id,
                    TRIM(v_branch->>'external_id'),
                    COALESCE(v_branch->>'name', 'Sucursal Principal'),
                    v_branch->>'city',
                    v_branch->>'email',
                    v_branch->>'phone'
                )
                ON CONFLICT (supplier_id, external_id)
                DO UPDATE SET
                    name = EXCLUDED.name,
                    city = EXCLUDED.city,
                    email = EXCLUDED.email,
                    phone = EXCLUDED.phone;
                v_branch_count := v_branch_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- PASO 3: Upsert de productos
    IF p_products IS NOT NULL AND jsonb_array_length(p_products) > 0 THEN
        FOR v_product IN SELECT * FROM jsonb_array_elements(p_products) LOOP
            -- Solo insertar si tiene sku (model_raw)
            IF v_product->>'sku' IS NOT NULL AND TRIM(v_product->>'sku') != '' THEN
                INSERT INTO public.supplier_products (
                    supplier_id, model_raw, model, name, description,
                    category_raw, uom_raw, brand_raw, is_active, attributes, updated_at
                )
                VALUES (
                    v_supplier_id,
                    TRIM(v_product->>'sku'),
                    TRIM(v_product->>'sku'),
                    COALESCE(v_product->>'name', 'Sin Nombre'),
                    v_product->>'description',
                    v_product->>'category',
                    v_product->>'uom',
                    v_product->>'brand',
                    COALESCE((v_product->>'is_active')::boolean, true),
                    COALESCE(v_product->'attributes', '{}'::jsonb),
                    now()
                )
                ON CONFLICT (supplier_id, model_raw)
                DO UPDATE SET
                    name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    category_raw = EXCLUDED.category_raw,
                    uom_raw = EXCLUDED.uom_raw,
                    brand_raw = EXCLUDED.brand_raw,
                    is_active = EXCLUDED.is_active,
                    attributes = EXCLUDED.attributes,
                    updated_at = now();
                v_product_count := v_product_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- PASO 4: Upsert de stock y precios por sucursal
    IF p_stock_prices IS NOT NULL AND jsonb_array_length(p_stock_prices) > 0 THEN
        FOR v_stock IN SELECT * FROM jsonb_array_elements(p_stock_prices) LOOP
            -- Resolver product_id desde (supplier_id, sku)
            SELECT id INTO v_product_id
            FROM public.supplier_products
            WHERE supplier_id = v_supplier_id
              AND model_raw = TRIM(v_stock->>'sku');

            -- Resolver branch_id desde (supplier_id, external_id)
            SELECT id INTO v_branch_id
            FROM public.supplier_branches
            WHERE supplier_id = v_supplier_id
              AND external_id = TRIM(v_stock->>'branch_external_id');

            -- Solo insertar si ambas resoluciones fueron exitosas
            IF v_product_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                INSERT INTO public.supplier_branch_stock (product_id, branch_id, quantity, price, currency, updated_at)
                VALUES (
                    v_product_id,
                    v_branch_id,
                    COALESCE((v_stock->>'quantity')::numeric, 0),
                    COALESCE((v_stock->>'price_usd')::numeric, 0),
                    'USD',
                    now()
                )
                ON CONFLICT (product_id, branch_id)
                DO UPDATE SET
                    quantity = EXCLUDED.quantity,
                    price = EXCLUDED.price,
                    currency = 'USD',
                    updated_at = now();
                v_stock_count := v_stock_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- PASO 5: Retornar resumen
    RETURN jsonb_build_object(
        'success', true,
        'supplier_name', v_supplier_name,
        'branches_synced', v_branch_count,
        'products_synced', v_product_count,
        'stock_entries_synced', v_stock_count
    );
END;
$$;
