-- ============================================================================
-- Migración: Homologación Inteligente de Catálogo Odoo -> Supabase
-- - Auto-resolución de brands verificadas (con fallback a 'Sin marca')
-- - Auto-resolución de uoms verificadas (con fallback a 'ud.')
-- - Auto-resolución de categories verificadas
-- - Triggers de retro-homologación automática al verificar marcas/categorías/uoms
-- - Soporte preventivo de URLs de imágenes
-- ============================================================================

-- Drop de versiones previas para evitar colisión de firmas
DROP FUNCTION IF EXISTS public.sync_odoo_supplier_data(text, jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.sync_odoo_supplier_data(jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.sync_odoo_supplier_data(jsonb, jsonb, jsonb, text);

-- 1. Actualizar RPC sync_odoo_supplier_data con Auto-Homologación
CREATE OR REPLACE FUNCTION public.sync_odoo_supplier_data(
    p_api_key text DEFAULT NULL::text,
    p_branches jsonb DEFAULT '[]'::jsonb,
    p_products jsonb DEFAULT '[]'::jsonb,
    p_stock_prices jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

    -- Variables para auto-homologación
    v_brand_id uuid;
    v_brand_raw text;
    v_category_id uuid;
    v_category_raw text;
    v_uom_id uuid;
    v_uom_raw text;
    v_image_urls text[];
    v_sin_marca_id uuid;
    v_default_uom_id uuid;
    v_raw_name text;
    v_clean_name text;
BEGIN
    -- Obtener API Key de parámetro o de headers HTTP
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

    -- Validar proveedor
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

    -- Obtener IDs predeterminados verificados
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

    -- PASO 2: Upsert de productos con Auto-Homologación
    IF p_products IS NOT NULL AND jsonb_array_length(p_products) > 0 THEN
        FOR v_product IN SELECT * FROM jsonb_array_elements(p_products) LOOP
            IF v_product->>'sku' IS NOT NULL AND TRIM(v_product->>'sku') != '' THEN
                
                -- ====================================================
                -- 2.1 AUTO-HOMOLOGACIÓN DE MARCA (brand_id)
                -- ====================================================
                v_brand_raw := TRIM(COALESCE(v_product->>'brand', ''));
                v_brand_id := NULL;

                -- Intentar match con la marca enviada por Odoo
                IF v_brand_raw != '' AND unaccent(lower(v_brand_raw)) != 'sin marca' THEN
                    SELECT id INTO v_brand_id
                    FROM public.brands
                    WHERE is_verified = true
                      AND (
                        normalized_name = regexp_replace(unaccent(lower(v_brand_raw)), '[^a-z0-9]', '', 'g')
                        OR unaccent(lower(name)) = unaccent(lower(v_brand_raw))
                      )
                    LIMIT 1;
                END IF;

                -- Si no hay match o venía vacía, inferir del nombre comercial o SKU
                IF v_brand_id IS NULL THEN
                    SELECT id INTO v_brand_id
                    FROM public.brands
                    WHERE is_verified = true
                      AND normalized_name NOT IN ('sinmarca', 'generico')
                      AND (
                        unaccent(lower(COALESCE(v_product->>'name', ''))) ~* ('\y' || unaccent(lower(name)) || '\y')
                        OR unaccent(lower(COALESCE(v_product->>'sku', ''))) ~* ('\y' || unaccent(lower(name)) || '\y')
                      )
                    ORDER BY length(name) DESC
                    LIMIT 1;
                END IF;

                -- Si aún no tiene marca, asignar 'Sin marca'
                IF v_brand_id IS NULL THEN
                    v_brand_id := v_sin_marca_id;
                END IF;
                SELECT name INTO v_brand_raw FROM public.brands WHERE id = v_brand_id;

                -- ====================================================
                -- 2.2 AUTO-HOMOLOGACIÓN DE UNIDAD (uom_id)
                -- ====================================================
                v_uom_raw := TRIM(COALESCE(v_product->>'uom', ''));
                v_uom_id := NULL;

                IF v_uom_raw != '' THEN
                    -- Búsqueda directa en uoms verificadas
                    SELECT id INTO v_uom_id
                    FROM public.uoms
                    WHERE is_verified = true
                      AND (
                        normalized_name = regexp_replace(unaccent(lower(v_uom_raw)), '[^a-z0-9]', '', 'g')
                        OR unaccent(lower(symbol)) = unaccent(lower(v_uom_raw))
                        OR unaccent(lower(name)) = unaccent(lower(v_uom_raw))
                      )
                    LIMIT 1;

                    -- Mapeo de variantes de texto comunes
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

                -- Fallback a 'ud.'
                IF v_uom_id IS NULL THEN
                    v_uom_id := v_default_uom_id;
                END IF;
                SELECT symbol INTO v_uom_raw FROM public.uoms WHERE id = v_uom_id;

                -- ====================================================
                -- 2.3 AUTO-HOMOLOGACIÓN DE CATEGORÍA (category_id)
                -- ====================================================
                v_category_raw := TRIM(COALESCE(v_product->>'category', ''));
                v_category_id := NULL;

                IF v_category_raw != '' AND unaccent(lower(v_category_raw)) != 'general' THEN
                    -- Búsqueda directa en categorías verificadas
                    SELECT id INTO v_category_id
                    FROM public.categories
                    WHERE is_verified = true
                      AND (
                        normalized_name = regexp_replace(unaccent(lower(v_category_raw)), '[^a-z0-9]', '', 'g')
                        OR unaccent(lower(name)) = unaccent(lower(v_category_raw))
                      )
                    LIMIT 1;

                    -- Clasificación por palabras clave en la categoría de Odoo y en el nombre del producto
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
                          )
                        LIMIT 1;
                    END IF;
                END IF;

                -- Si la categoría de Odoo era 'General' o vino vacía, intentar inferir directamente del nombre del producto
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

                -- Si se homologó con una categoría oficial verificada, asignar su nombre oficial; si no, preservar texto original
                IF v_category_id IS NOT NULL THEN
                    SELECT name INTO v_category_raw FROM public.categories WHERE id = v_category_id;
                ELSIF v_category_raw IS NULL OR v_category_raw = '' THEN
                    v_category_raw := 'General';
                END IF;

                -- ====================================================
                -- 2.4 SOPORTE DE IMÁGENES (image_urls)
                -- ====================================================
                v_image_urls := ARRAY[]::text[];
                IF v_product->'image_urls' IS NOT NULL AND jsonb_array_length(v_product->'image_urls') > 0 THEN
                    SELECT ARRAY_AGG(x) INTO v_image_urls 
                    FROM jsonb_array_elements_text(v_product->'image_urls') x 
                    WHERE x IS NOT NULL AND x != '';
                ELSIF v_product->>'image_url' IS NOT NULL AND TRIM(v_product->>'image_url') != '' THEN
                    v_image_urls := ARRAY[TRIM(v_product->>'image_url')];
                END IF;

                -- ====================================================
                -- 2.5 LIMPIEZA INTELIGENTE DE NOMBRE (Remover redundancias de marca/modelo)
                -- ====================================================
                v_raw_name := COALESCE(TRIM(v_product->>'name'), 'Sin Nombre');
                v_clean_name := v_raw_name;

                -- Remover prefijo de marca si está al inicio
                IF v_brand_raw IS NOT NULL AND v_brand_raw NOT IN ('Sin marca', 'Genérico', '') THEN
                    v_clean_name := regexp_replace(v_clean_name, '^\s*' || regexp_replace(v_brand_raw, '([()[\]{}*+?^$|.\\])', '\\\1', 'g') || '\s*[-–:/]?\s*', '', 'i');
                END IF;

                -- Remover prefijo de modelo/SKU si está al inicio
                IF v_product->>'sku' IS NOT NULL AND TRIM(v_product->>'sku') != '' THEN
                    v_clean_name := regexp_replace(v_clean_name, '^\s*' || regexp_replace(TRIM(v_product->>'sku'), '([()[\]{}*+?^$|.\\])', '\\\1', 'g') || '\s*[-–:/]?\s*', '', 'i');
                END IF;

                -- Limpiar posibles separadores o espacios sobrantes al inicio
                v_clean_name := regexp_replace(v_clean_name, '^[\s\-–:/]+', '');

                -- Salvaguarda: si quedó vacío o menor a 3 caracteres, conservar v_raw_name
                IF length(TRIM(v_clean_name)) < 3 THEN
                    v_clean_name := v_raw_name;
                ELSE
                    v_clean_name := TRIM(v_clean_name);
                END IF;

                -- ====================================================
                -- 2.6 INSERT / UPDATE EN supplier_products
                -- ====================================================
                INSERT INTO public.supplier_products (
                    supplier_id, model_raw, model, name, description,
                    category_id, category_raw,
                    brand_id, brand_raw,
                    uom_id, uom_raw,
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
                    COALESCE((v_product->>'is_active')::boolean, true),
                    jsonb_build_object('original_name', v_raw_name) || COALESCE(v_product->'attributes', '{}'::jsonb),
                    COALESCE(v_image_urls, ARRAY[]::text[]),
                    now()
                )
                ON CONFLICT (supplier_id, model_raw)
                DO UPDATE SET
                    name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    category_id = COALESCE(EXCLUDED.category_id, supplier_products.category_id),
                    category_raw = EXCLUDED.category_raw,
                    brand_id = COALESCE(EXCLUDED.brand_id, supplier_products.brand_id),
                    brand_raw = EXCLUDED.brand_raw,
                    uom_id = COALESCE(EXCLUDED.uom_id, supplier_products.uom_id),
                    uom_raw = EXCLUDED.uom_raw,
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
            -- Resolver product_id
            SELECT id INTO v_product_id
            FROM public.supplier_products
            WHERE supplier_id = v_supplier_id
              AND model_raw = TRIM(v_stock->>'sku');

            -- Resolver branch_id
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
$$;


-- 2. Triggers de Retro-Homologación Automática en Supabase

-- Trigger para Marcas
CREATE OR REPLACE FUNCTION public.trg_fn_auto_link_brand_on_verify()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_verified = true AND (OLD.is_verified IS DISTINCT FROM true) THEN
        UPDATE public.supplier_products
        SET brand_id = NEW.id,
            brand_raw = NEW.name
        WHERE (brand_id IS NULL OR brand_id = (SELECT id FROM public.brands WHERE normalized_name = 'sinmarca' LIMIT 1))
          AND (
            regexp_replace(unaccent(lower(brand_raw)), '[^a-z0-9]', '', 'g') = NEW.normalized_name
            OR unaccent(lower(name)) ~* ('\y' || unaccent(lower(NEW.name)) || '\y')
            OR unaccent(lower(model)) ~* ('\y' || unaccent(lower(NEW.name)) || '\y')
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_link_brand_on_verify ON public.brands;
CREATE TRIGGER trg_auto_link_brand_on_verify
AFTER UPDATE OF is_verified ON public.brands
FOR EACH ROW
EXECUTE FUNCTION public.trg_fn_auto_link_brand_on_verify();


-- Trigger para Categorías
CREATE OR REPLACE FUNCTION public.trg_fn_auto_link_category_on_verify()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_verified = true AND (OLD.is_verified IS DISTINCT FROM true) THEN
        UPDATE public.supplier_products
        SET category_id = NEW.id,
            category_raw = NEW.name
        WHERE category_id IS NULL
          AND (
            regexp_replace(unaccent(lower(category_raw)), '[^a-z0-9]', '', 'g') = NEW.normalized_name
            OR unaccent(lower(category_raw)) = unaccent(lower(NEW.name))
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_link_category_on_verify ON public.categories;
CREATE TRIGGER trg_auto_link_category_on_verify
AFTER UPDATE OF is_verified ON public.categories
FOR EACH ROW
EXECUTE FUNCTION public.trg_fn_auto_link_category_on_verify();


-- Trigger para Unidades de Medida (UOMs)
CREATE OR REPLACE FUNCTION public.trg_fn_auto_link_uom_on_verify()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_verified = true AND (OLD.is_verified IS DISTINCT FROM true) THEN
        UPDATE public.supplier_products
        SET uom_id = NEW.id,
            uom_raw = NEW.symbol
        WHERE (uom_id IS NULL OR uom_id = (SELECT id FROM public.uoms WHERE symbol = 'ud.' LIMIT 1))
          AND (
            regexp_replace(unaccent(lower(uom_raw)), '[^a-z0-9]', '', 'g') = NEW.normalized_name
            OR unaccent(lower(uom_raw)) = unaccent(lower(NEW.symbol))
            OR unaccent(lower(uom_raw)) = unaccent(lower(NEW.name))
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_link_uom_on_verify ON public.uoms;
CREATE TRIGGER trg_auto_link_uom_on_verify
AFTER UPDATE OF is_verified ON public.uoms
FOR EACH ROW
EXECUTE FUNCTION public.trg_fn_auto_link_uom_on_verify();


-- 3. Salvaguarda en search_supplier_products para asegurar category_label con COALESCE
-- Se actualiza para garantizar que c.name nunca quede NULL si existe category_raw
CREATE OR REPLACE FUNCTION public.search_supplier_products(
  query_text text DEFAULT NULL::text,
  brand_filter text[] DEFAULT NULL::text[],
  category_filter text[] DEFAULT NULL::text[],
  supplier_filter uuid[] DEFAULT NULL::uuid[],
  min_price_filter numeric DEFAULT NULL::numeric,
  max_price_filter numeric DEFAULT NULL::numeric
)
RETURNS TABLE (
  id uuid,
  name text,
  description text,
  brand text,
  model text,
  category text,
  sku text,
  uom text,
  uom_icon_name text,
  image_url text,
  total_quantity bigint,
  min_price numeric,
  supplier_count bigint,
  first_supplier_id uuid,
  first_supplier_name text,
  first_supplier_trade_type text,
  first_supplier_logo text,
  supplier_ids uuid[],
  is_locked boolean
)
LANGUAGE plpgsql
AS $function$
declare 
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
begin 
    v_user_id := auth.uid ();

    IF v_user_id is not null then
        select
          verification_status,
          verification_type into v_verification_status,
          v_verification_type
        from
          profiles
        where
          profiles.id = v_user_id;
    end IF;

    v_verification_status := LOWER(COALESCE(v_verification_status, 'unverified'));
    v_verification_type := LOWER(COALESCE(v_verification_type, 'individual'));

    RETURN QUERY
    with
      base_products as (
        select
          sp.id,
          sp.name,
          sp.description,
          COALESCE(b.name, sp.brand_raw, 'Sin marca') as brand_label,
          sp.model as model_label,
          COALESCE(c.name, sp.category_raw, 'General') as category_label,
          COALESCE(u.symbol, sp.uom_raw, 'ud.') as uom_label,
          COALESCE(u.icon_name, 'package_2') as icon_name,
          (sp.image_urls) [1] as image_url,
          sbs.quantity as stock_quantity,
          sbs.price,
          sbs.branch_id,
          s.id as supplier_id,
          s.name as supplier_name,
          s.trade_type as supplier_trade_type,
          s.logo_url as supplier_logo,
          case
            when v_verification_status = 'verified'
            and v_verification_type = 'business' then true
            when v_verification_status != 'verified' then (
              UPPER(COALESCE(s.trade_type, '')) is distinct from 'WHOLESALE'
            )
            else not (
              UPPER(COALESCE(s.trade_type, '')) = 'WHOLESALE'
              and COALESCE(s.allowed_verification_types::text, '') not ilike '%individual%'
            )
          end as is_accessible,
          regexp_replace(unaccent(lower(COALESCE(b.name, sp.brand_raw, 'Sin marca'))), '[^a-z0-9]', '', 'g') as norm_brand,
          regexp_replace(unaccent(lower(COALESCE(sp.model, ''))), '[^a-z0-9]', '', 'g') as norm_model,
          regexp_replace(unaccent(lower(COALESCE(u.symbol, sp.uom_raw, 'ud.'))), '[^a-z0-9]', '', 'g') as norm_uom,
          CASE WHEN TRIM(COALESCE(sp.model, '')) = '' THEN regexp_replace(unaccent(lower(sp.name)), '[^a-z0-9]', '', 'g') ELSE '' END as norm_fallback_name,
          (
            query_text is null
            or query_text = ''
            or (
              to_tsvector(
                'spanish',
                unaccent (COALESCE(sp.name, '')) || ' ' || unaccent (COALESCE(sp.description, '')) || ' ' || unaccent (COALESCE(b.name, sp.brand_raw, '')) || ' ' || unaccent (COALESCE(sp.model, ''))
              ) @@ plainto_tsquery('spanish', unaccent (query_text))
              or unaccent (COALESCE(sp.name, '')) ilike '%' || unaccent (query_text) || '%'
              or regexp_replace(unaccent (lower(COALESCE(sp.model, ''))), '[^a-z0-9]', '', 'g') ilike '%' || regexp_replace(unaccent (lower(query_text)), '[^a-z0-9]', '', 'g') || '%'
              or regexp_replace(unaccent (lower(COALESCE(sp.name, ''))), '[^a-z0-9]', '', 'g') ilike '%' || regexp_replace(unaccent (lower(query_text)), '[^a-z0-9]', '', 'g') || '%'
            )
          ) as is_match
        from
          supplier_products sp
          join supplier_branch_stock sbs on sbs.product_id = sp.id
          join suppliers s on sp.supplier_id = s.id
          left join categories c on sp.category_id = c.id
          left join brands b on sp.brand_id = b.id
          left join uoms u on sp.uom_id = u.id
        where
          sp.is_active = true
          and s.is_active = true
          and sbs.quantity > 0
      ),
      matching_groups AS (
        SELECT DISTINCT norm_brand, norm_model, norm_uom, norm_fallback_name
        FROM base_products
        WHERE is_match = true
      ),
      filtered_products AS (
        SELECT bp.*
        FROM base_products bp
        JOIN matching_groups mg ON 
            bp.norm_brand = mg.norm_brand AND 
            bp.norm_model = mg.norm_model AND 
            bp.norm_uom = mg.norm_uom AND
            bp.norm_fallback_name = mg.norm_fallback_name
        WHERE
          (brand_filter is null or bp.brand_label = any (brand_filter))
          and (category_filter is null or bp.category_label = any (category_filter))
          and (supplier_filter is null or bp.supplier_id = any (supplier_filter))
          and (min_price_filter is null or bp.price >= min_price_filter)
          and (max_price_filter is null or bp.price <= max_price_filter)
      )
    select
      (ARRAY_AGG(fp.id order by fp.price asc)) [1] as id,
      mode() within group (order by fp.name) as name,
      MIN(fp.description) as description,
      fp.brand_label as brand,
      fp.model_label as model,
      mode() within group (order by fp.category_label) as category,
      fp.model_label as sku,
      fp.uom_label as uom,
      fp.icon_name as uom_icon_name,
      MIN(fp.image_url) as image_url,
      SUM(fp.stock_quantity)::bigint as total_quantity,
      COALESCE(MIN(fp.price) filter (where fp.is_accessible), MIN(fp.price)) as min_price,
      COUNT(distinct fp.branch_id) as supplier_count,
      COALESCE((ARRAY_AGG(fp.supplier_id order by fp.price asc) filter (where fp.is_accessible)) [1], (ARRAY_AGG(fp.supplier_id order by fp.price asc)) [1]) as first_supplier_id,
      COALESCE((ARRAY_AGG(fp.supplier_name order by fp.price asc) filter (where fp.is_accessible)) [1], (ARRAY_AGG(fp.supplier_name order by fp.price asc)) [1]) as first_supplier_name,
      COALESCE((ARRAY_AGG(fp.supplier_trade_type order by fp.price asc) filter (where fp.is_accessible)) [1], (ARRAY_AGG(fp.supplier_trade_type order by fp.price asc)) [1]) as first_supplier_trade_type,
      COALESCE((ARRAY_AGG(fp.supplier_logo order by fp.price asc) filter (where fp.is_accessible)) [1], (ARRAY_AGG(fp.supplier_logo order by fp.price asc)) [1]) as first_supplier_logo,
      ARRAY_AGG(distinct fp.supplier_id) as supplier_ids,
      (COUNT(*) filter (where fp.is_accessible) = 0) as is_locked
    from
      filtered_products fp
    GROUP BY 
        fp.norm_brand, 
        fp.norm_model, 
        fp.norm_uom,
        fp.norm_fallback_name,
        fp.brand_label, 
        fp.model_label, 
        fp.uom_label, 
        fp.icon_name;
end;
$function$;
