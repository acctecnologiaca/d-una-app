-- Migración: Auto-Homologación Inteligente y Ascenso Automático de Marcas
-- Fecha: 2026-09-04
-- Descripción:
-- 1. Siembra y verificación de marcas principales de tecnología y seguridad electrónica.
-- 2. Actualización de sync_odoo_supplier_data con normalización de 3 capas, auto-creación y ascenso de marcas.

-- PARTE 1: Sembrado y aseguramiento de marcas fundamentales
INSERT INTO public.brands (name, normalized_name, is_verified, created_at)
VALUES
    ('Dahua', 'dahua', true, now()),
    ('Western Digital', 'westerndigital', true, now()),
    ('Seagate', 'seagate', true, now()),
    ('Ezviz', 'ezviz', true, now()),
    ('Ubiquiti', 'ubiquiti', true, now()),
    ('MikroTik', 'mikrotik', true, now()),
    ('Cisco', 'cisco', true, now()),
    ('Intelbras', 'intelbras', true, now()),
    ('Ajax', 'ajax', true, now()),
    ('Paradox', 'paradox', true, now()),
    ('DSC', 'dsc', true, now())
ON CONFLICT (normalized_name) DO UPDATE
SET is_verified = true,
    name = EXCLUDED.name;

-- PARTE 2: Actualización de la función RPC sync_odoo_supplier_data
CREATE OR REPLACE FUNCTION public.sync_odoo_supplier_data(
    p_api_key text DEFAULT NULL::text, 
    p_branches jsonb DEFAULT '[]'::jsonb, 
    p_products jsonb DEFAULT '[]'::jsonb, 
    p_stock_prices jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_api_key text;
    v_supplier_id uuid;
    v_supplier_name text;
    v_is_active boolean;
    v_branch jsonb;
    v_product jsonb;
    v_stock jsonb;
    v_product_id uuid;
    v_branch_id uuid;
    v_branch_count integer := 0;
    v_product_count integer := 0;
    v_stock_count integer := 0;

    v_brand_id uuid;
    v_brand_raw text;
    v_normalized_brand text;
    v_is_brand_verified boolean;
    v_brand_official_name text;

    v_category_id uuid;
    v_category_raw text;
    v_uom_id uuid;
    v_uom_raw text;
    v_warranty_time integer;
    v_warranty_unit text;
    v_image_urls text[];
    v_sin_marca_id uuid;
    v_default_uom_id uuid;
    v_raw_name text;
    v_clean_name text;
BEGIN
    v_api_key := NULLIF(TRIM(p_api_key), '');
    IF v_api_key IS NULL THEN
        BEGIN
            v_api_key := current_setting('request.headers', true)::jsonb->>'x-api-key';
        EXCEPTION WHEN OTHERS THEN
            v_api_key := NULL;
        END;
    END IF;

    IF v_api_key IS NULL OR TRIM(v_api_key) = '' THEN
        RAISE EXCEPTION 'DUNA_AUTH_ERROR: Header x-api-key requerido para autenticar el conector';
    END IF;

    SELECT id, name, is_active
    INTO v_supplier_id, v_supplier_name, v_is_active
    FROM public.suppliers
    WHERE api_key = v_api_key;

    IF v_supplier_id IS NULL THEN
        RAISE EXCEPTION 'DUNA_AUTH_ERROR: API Key inválida o no registrada en D-Una';
    END IF;

    IF v_is_active IS NOT TRUE THEN
        RAISE EXCEPTION 'DUNA_AUTH_ERROR: Proveedor inactivo o deshabilitado en D-Una';
    END IF;

    SELECT id INTO v_sin_marca_id 
    FROM public.brands 
    WHERE is_verified = true AND (normalized_name = 'sinmarca' OR unaccent(lower(name)) = 'sin marca') 
    LIMIT 1;

    SELECT id INTO v_default_uom_id 
    FROM public.uoms 
    WHERE is_verified = true AND (symbol = 'ud.' OR normalized_name = 'unidad') 
    LIMIT 1;

    -- PASO 1: Upsert de sucursales
    IF p_branches IS NOT NULL AND jsonb_array_length(p_branches) > 0 THEN
        FOR v_branch IN SELECT * FROM jsonb_array_elements(p_branches) LOOP
            IF v_branch->>'external_id' IS NOT NULL AND TRIM(v_branch->>'external_id') != '' THEN
                INSERT INTO public.supplier_branches (
                    supplier_id, external_id, name, city, email, phone
                )
                VALUES (
                    v_supplier_id,
                    TRIM(v_branch->>'external_id'),
                    COALESCE(v_branch->>'name', 'Sucursal'),
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

    -- PASO 2: Upsert de productos con Auto-Homologación, Limpieza de Nombre y Garantías
    IF p_products IS NOT NULL AND jsonb_array_length(p_products) > 0 THEN
        FOR v_product IN SELECT * FROM jsonb_array_elements(p_products) LOOP
            IF v_product->>'sku' IS NOT NULL AND TRIM(v_product->>'sku') != '' THEN
                
                -- 2.1 AUTO-HOMOLOGACIÓN INTELIGENTE Y ASCENSO DE MARCA
                v_brand_raw := TRIM(COALESCE(v_product->>'brand', ''));
                v_brand_id := NULL;
                v_brand_official_name := NULL;

                IF v_brand_raw != '' AND unaccent(lower(v_brand_raw)) NOT IN ('sin marca', 'generico', 'generica') THEN
                    v_normalized_brand := regexp_replace(unaccent(lower(v_brand_raw)), '[^a-z0-9]', '', 'g');

                    -- Buscar si existe por normalized_name o nombre exacto (verificada o no verificada)
                    SELECT id, is_verified, name
                    INTO v_brand_id, v_is_brand_verified, v_brand_official_name
                    FROM public.brands
                    WHERE normalized_name = v_normalized_brand
                       OR unaccent(lower(name)) = unaccent(lower(v_brand_raw))
                    ORDER BY is_verified DESC, created_at ASC
                    LIMIT 1;

                    -- Caso A: Existe pero no estaba verificada -> Ascenso automático por confirmación de distribuidor
                    IF v_brand_id IS NOT NULL AND v_is_brand_verified IS NOT TRUE THEN
                        UPDATE public.brands 
                        SET is_verified = true 
                        WHERE id = v_brand_id;
                        v_is_brand_verified := true;
                    END IF;

                    -- Caso B: No existe en D-Una -> Auto-creación directa como verificada
                    IF v_brand_id IS NULL AND length(v_normalized_brand) >= 2 THEN
                        INSERT INTO public.brands (name, normalized_name, is_verified, created_at)
                        VALUES (v_brand_raw, v_normalized_brand, true, now())
                        ON CONFLICT DO NOTHING
                        RETURNING id, name INTO v_brand_id, v_brand_official_name;

                        IF v_brand_id IS NULL THEN
                            SELECT id, name INTO v_brand_id, v_brand_official_name 
                            FROM public.brands 
                            WHERE normalized_name = v_normalized_brand 
                            LIMIT 1;
                        END IF;
                    END IF;
                END IF;

                -- Caso C: No vino campo brand o no se pudo resolver -> Inferencia segura en texto libre (solo marcas verificadas)
                IF v_brand_id IS NULL THEN
                    SELECT id, name
                    INTO v_brand_id, v_brand_official_name
                    FROM public.brands
                    WHERE is_verified = true
                      AND normalized_name NOT IN ('sinmarca', 'generico')
                      AND length(name) >= 3
                      AND (
                        unaccent(lower(COALESCE(v_product->>'name', ''))) ~* ('\y' || unaccent(lower(name)) || '\y')
                        OR unaccent(lower(COALESCE(v_product->>'sku', ''))) ~* ('\y' || unaccent(lower(name)) || '\y')
                      )
                    ORDER BY length(name) DESC
                    LIMIT 1;
                END IF;

                -- Fallback final a Sin Marca si nada coincidió
                IF v_brand_id IS NULL THEN
                    v_brand_id := v_sin_marca_id;
                    v_brand_official_name := 'Sin marca';
                END IF;

                -- Preservación del texto descriptivo (siempre conserva la marca original del proveedor)
                v_brand_raw := COALESCE(NULLIF(v_brand_raw, ''), v_brand_official_name);

                -- 2.2 AUTO-HOMOLOGACIÓN DE UNIDAD
                v_uom_raw := TRIM(COALESCE(v_product->>'uom', ''));
                v_uom_id := NULL;

                IF v_uom_raw != '' THEN
                    SELECT id INTO v_uom_id
                    FROM public.uoms
                    WHERE is_verified = true
                      AND (
                        normalized_name = regexp_replace(unaccent(lower(v_uom_raw)), '[^a-z0-9]', '', 'g')
                        OR unaccent(lower(symbol)) = unaccent(lower(v_uom_raw))
                        OR unaccent(lower(name)) = unaccent(lower(v_uom_raw))
                      )
                    LIMIT 1;

                    IF v_uom_id IS NULL THEN
                        CASE
                            WHEN unaccent(lower(v_uom_raw)) IN ('unidades', 'unidad', 'unid.', 'unid', 'ud', 'ud.', 'pza', 'pz', 'pzas', 'pcs', 'piece') THEN
                                v_uom_id := v_default_uom_id;
                            WHEN unaccent(lower(v_uom_raw)) IN ('metros', 'metro', 'mts', 'mt', 'm') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'm' OR normalized_name = 'metro') LIMIT 1;
                            WHEN unaccent(lower(v_uom_raw)) IN ('cajas', 'caja', 'caj.', 'caj') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'caj.' OR normalized_name = 'caja') LIMIT 1;
                            WHEN unaccent(lower(v_uom_raw)) IN ('rollos', 'rollo', 'rol') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'ROL' OR normalized_name = 'rollo') LIMIT 1;
                            WHEN unaccent(lower(v_uom_raw)) IN ('bobinas', 'bobina', 'bob.', 'bob') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'bob.' OR normalized_name = 'bobina') LIMIT 1;
                            WHEN unaccent(lower(v_uom_raw)) IN ('bulto', 'bultos', 'be') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'BE' OR normalized_name = 'bulto') LIMIT 1;
                            WHEN unaccent(lower(v_uom_raw)) IN ('paquete', 'paquetes', 'paq.', 'paq') THEN
                                SELECT id INTO v_uom_id FROM public.uoms WHERE is_verified = true AND (symbol = 'paq.' OR normalized_name = 'paquete') LIMIT 1;
                            ELSE
                                NULL;
                        END CASE;
                    END IF;
                END IF;

                IF v_uom_id IS NULL THEN
                    v_uom_id := v_default_uom_id;
                END IF;
                SELECT symbol INTO v_uom_raw FROM public.uoms WHERE id = v_uom_id;

                -- 2.3 AUTO-HOMOLOGACIÓN DE CATEGORÍA
                v_category_raw := TRIM(COALESCE(v_product->>'category', ''));
                v_category_id := NULL;

                IF v_category_raw != '' AND unaccent(lower(v_category_raw)) != 'general' THEN
                    SELECT id INTO v_category_id
                    FROM public.categories
                    WHERE is_verified = true
                      AND (
                        normalized_name = regexp_replace(unaccent(lower(v_category_raw)), '[^a-z0-9]', '', 'g')
                        OR unaccent(lower(name)) = unaccent(lower(v_category_raw))
                      )
                    LIMIT 1;

                    IF v_category_id IS NULL THEN
                        SELECT id INTO v_category_id
                        FROM public.categories
                        WHERE is_verified = true
                          AND (
                            (name = 'Control de Acceso y Asistencia' AND (
                                v_category_raw ~* 'ACCESO|BIOMETRICO|ASISTENCIA|LECTOR|CERRADURA|CHAPA|TORNIQUETE|BARRERA|INSPECCION|RAYOS|DETECTOR|METAL|TARJETA|VIDEOPORTERO|PORTERO'
                                OR v_product->>'name' ~* 'BIOMETRICO|LECTOR|CONTROL.*ACCESO|ASISTENCIA|TORNIQUETE|BARRERA|DETECTOR.*METAL|RAYOS.*X|TARJETA.*PROX|VIDEOPORTERO|CHAPA|CERRADURA|FACIAL'
                            ))
                            OR (name = 'Cámaras de Seguridad' AND (
                                v_category_raw ~* 'CAMARA|CCTV|DVR|NVR|VIDEO|DOMO|BALUN|PTZ'
                                OR v_product->>'name' ~* 'CAMARA|DVR|NVR|VIDEO SEGURIDAD|DOMO|BALUN|PTZ'
                            ))
                            OR (name = 'Alarma' AND (
                                v_category_raw ~* 'ALARMA|SIRENA|PIR|MAGNETICO|SENSOR'
                                OR v_product->>'name' ~* 'ALARMA|SIRENA|SENSOR.*MOVIMIENTO|PIR|MAGNETICO'
                            ))
                            OR (name = 'Redes y Conectividad' AND (
                                v_category_raw ~* 'RED|REDES|ROUTER|SWITCH|WIFI|ACCESS POINT|ANTENA|TRANSCEIVER|FIBRA'
                                OR v_product->>'name' ~* 'ROUTER|SWITCH|ACCESS POINT|TRANSCEIVER|ANTENA'
                            ))
                            OR (name = 'Respaldo de Energía' AND (
                                v_category_raw ~* 'ENERGIA|BATERIA|UPS|FUENTE|INVERSOR|TRANSFORMADOR'
                                OR v_product->>'name' ~* 'BATERIA|UPS|FUENTE.*PODER|INVERSOR'
                            ))
                            OR (name = 'Cables y Accesorios' AND (
                                v_category_raw ~* 'CABLE|UTP|CONECTOR|PATCH CORD'
                                OR v_product->>'name' ~* 'CABLE.*UTP|CONECTOR.*RJ45|PATCH CORD'
                            ))
                            OR (name = 'Computación' AND (
                                v_category_raw ~* 'COMPUTACION|DISCO|SSD|HDD|MEMORIA|MONITOR'
                                OR v_product->>'name' ~* 'DISCO DURO|SSD|MEMORIA RAM|MONITOR'
                            ))
                            OR (name = 'Herramientas' AND (
                                v_category_raw ~* 'HERRAMIENTA|PONCHADORA|TESTER|CRIMPEADORA'
                                OR v_product->>'name' ~* 'PONCHADORA|TESTER|CRIMPEADORA'
                            ))
                            OR (name = 'Materiales Eléctricos' AND (
                                v_category_raw ~* 'ELECTRICO|BREAKER|TABLERO|CAJETIN'
                                OR v_product->>'name' ~* 'BREAKER|TABLERO ELECTRICO'
                            ))
                          );
                    END IF;
                END IF;

                IF v_category_id IS NULL THEN
                    SELECT id INTO v_category_id
                    FROM public.categories
                    WHERE is_verified = true
                      AND (
                        (name = 'Control de Acceso y Asistencia' AND v_product->>'name' ~* 'BIOMETRICO|LECTOR|ACCESO|ASISTENCIA|TORNIQUETE|BARRERA|DETECTOR.*METAL|RAYOS.*X|TARJETA.*PROX|VIDEOPORTERO|FACIAL|HUELLA')
                        OR (name = 'Cámaras de Seguridad' AND v_product->>'name' ~* 'CAMARA|DVR|NVR|DOMO|BALUN|PTZ')
                        OR (name = 'Alarma' AND v_product->>'name' ~* 'ALARMA|SIRENA|SENSOR')
                        OR (name = 'Redes y Conectividad' AND v_product->>'name' ~* 'ROUTER|SWITCH|ACCESS POINT|FIBRA')
                        OR (name = 'Respaldo de Energía' AND v_product->>'name' ~* 'BATERIA|UPS|FUENTE')
                        OR (name = 'Cables y Accesorios' AND v_product->>'name' ~* 'CABLE|UTP|CONECTOR')
                        OR (name = 'Computación' AND v_product->>'name' ~* 'DISCO DURO|SSD|RAM')
                      )
                    LIMIT 1;
                END IF;

                IF v_category_id IS NOT NULL THEN
                    SELECT name INTO v_category_raw FROM public.categories WHERE id = v_category_id;
                ELSIF v_category_raw IS NULL OR v_category_raw = '' THEN
                    v_category_raw := 'General';
                END IF;

                -- 2.4 SOPORTE DE IMÁGENES
                v_image_urls := ARRAY[]::text[];
                IF v_product->'image_urls' IS NOT NULL AND jsonb_array_length(v_product->'image_urls') > 0 THEN
                    SELECT ARRAY_AGG(x) INTO v_image_urls 
                    FROM jsonb_array_elements_text(v_product->'image_urls') x 
                    WHERE x IS NOT NULL AND x != '';
                ELSIF v_product->>'image_url' IS NOT NULL AND TRIM(v_product->>'image_url') != '' THEN
                    v_image_urls := ARRAY[TRIM(v_product->>'image_url')];
                END IF;

                -- 2.5 LIMPIEZA INTELIGENTE DE NOMBRE
                v_raw_name := COALESCE(TRIM(v_product->>'name'), 'Sin Nombre');
                v_clean_name := v_raw_name;

                IF v_brand_raw IS NOT NULL AND v_brand_raw NOT IN ('Sin marca', 'Genérico', '') THEN
                    v_clean_name := regexp_replace(v_clean_name, '^\s*' || regexp_replace(v_brand_raw, '([()[\]{}*+?^$|.\\])', '\\\1', 'g') || '\s*[-–:/]?\s*', '', 'i');
                END IF;

                IF v_brand_official_name IS NOT NULL AND v_brand_official_name NOT IN ('Sin marca', 'Genérico', '', v_brand_raw) THEN
                    v_clean_name := regexp_replace(v_clean_name, '^\s*' || regexp_replace(v_brand_official_name, '([()[\]{}*+?^$|.\\])', '\\\1', 'g') || '\s*[-–:/]?\s*', '', 'i');
                END IF;

                IF v_product->>'sku' IS NOT NULL AND TRIM(v_product->>'sku') != '' THEN
                    v_clean_name := regexp_replace(v_clean_name, '^\s*' || regexp_replace(TRIM(v_product->>'sku'), '([()[\]{}*+?^$|.\\])', '\\\1', 'g') || '\s*[-–:/]?\s*', '', 'i');
                END IF;

                v_clean_name := regexp_replace(v_clean_name, '^[\s\-–:/]+', '');

                IF length(TRIM(v_clean_name)) < 3 THEN
                    v_clean_name := v_raw_name;
                ELSE
                    v_clean_name := TRIM(v_clean_name);
                END IF;

                -- 2.6 EXTRACCIÓN DE GARANTÍA
                v_warranty_time := NULLIF(TRIM(v_product->>'warranty_time'), '')::integer;
                v_warranty_unit := NULLIF(TRIM(v_product->>'warranty_unit'), '');

                -- INSERT / UPSERT DEL PRODUCTO
                INSERT INTO public.supplier_products (
                    supplier_id, model_raw, model, name, description,
                    category_id, category_raw,
                    brand_id, brand_raw,
                    uom_id, uom_raw,
                    warranty_time, warranty_unit,
                    is_active, attributes, image_urls, updated_at
                )
                VALUES (
                    v_supplier_id,
                    TRIM(v_product->>'sku'),
                    TRIM(v_product->>'sku'),
                    v_clean_name,
                    v_product->>'description',
                    v_category_id,
                    v_category_raw,
                    v_brand_id,
                    v_brand_raw,
                    v_uom_id,
                    v_uom_raw,
                    v_warranty_time,
                    v_warranty_unit,
                    COALESCE((v_product->>'is_active')::boolean, true),
                    jsonb_build_object('original_name', v_raw_name) || COALESCE(v_product->'attributes', '{}'::jsonb),
                    COALESCE(v_image_urls, ARRAY[]::text[]),
                    now()
                )
                ON CONFLICT (supplier_id, model_raw)
                DO UPDATE SET
                    name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    category_id = EXCLUDED.category_id,
                    category_raw = EXCLUDED.category_raw,
                    brand_id = EXCLUDED.brand_id,
                    brand_raw = EXCLUDED.brand_raw,
                    uom_id = EXCLUDED.uom_id,
                    uom_raw = EXCLUDED.uom_raw,
                    warranty_time = EXCLUDED.warranty_time,
                    warranty_unit = EXCLUDED.warranty_unit,
                    is_active = EXCLUDED.is_active,
                    attributes = EXCLUDED.attributes,
                    image_urls = CASE 
                        WHEN array_length(EXCLUDED.image_urls, 1) > 0 THEN EXCLUDED.image_urls 
                        ELSE supplier_products.image_urls 
                    END,
                    updated_at = now();
                
                v_product_count := v_product_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- PASO 3: Upsert de stock y precios por sucursal
    IF p_stock_prices IS NOT NULL AND jsonb_array_length(p_stock_prices) > 0 THEN
        FOR v_stock IN SELECT * FROM jsonb_array_elements(p_stock_prices) LOOP
            SELECT id INTO v_product_id
            FROM public.supplier_products
            WHERE supplier_id = v_supplier_id
              AND model_raw = TRIM(v_stock->>'sku');

            SELECT id INTO v_branch_id
            FROM public.supplier_branches
            WHERE supplier_id = v_supplier_id
              AND external_id = TRIM(v_stock->>'branch_external_id');

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

    RETURN jsonb_build_object(
        'success', true,
        'supplier_name', v_supplier_name,
        'branches_synced', v_branch_count,
        'products_synced', v_product_count,
        'stock_entries_synced', v_stock_count
    );
END;
$function$;
