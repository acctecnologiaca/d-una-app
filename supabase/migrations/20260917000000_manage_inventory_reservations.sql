-- Migración: Gestión Integral de Reservas de Inventario (Cotizaciones y Notas de Entrega)
-- Archivo: supabase/migrations/20260917000000_manage_inventory_reservations.sql

-- 1. Actualizar la función recalculate_product_reservation para unificar reservas de cotizaciones y NEs activas
CREATE OR REPLACE FUNCTION public.recalculate_product_reservation(p_product_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quotes_reserved NUMERIC := 0;
    v_scratch_ne_reserved NUMERIC := 0;
    v_total_reserved NUMERIC := 0;
BEGIN
    IF p_product_id IS NULL THEN
        RETURN;
    END IF;

    -- A. Reserva de Cotizaciones Aprobadas
    -- Incluye el saldo no entregado de la cotización, o las NEs activas vinculadas si superan el saldo
    WITH quote_summary AS (
        SELECT 
            q.id AS quote_id,
            COALESCE(SUM(qi.quantity), 0) AS quote_qty
        FROM public.quotes q
        JOIN public.quote_items_products qi ON qi.quote_id = q.id
        WHERE qi.product_id = p_product_id
          AND qi.source_type = 'own'
          AND q.status = 'approved'
          AND COALESCE(q.is_archived, false) = false
        GROUP BY q.id
    ),
    quote_ne_finalized AS (
        SELECT 
            dn.quote_id,
            COALESCE(SUM(dni.quantity), 0) AS finalized_qty
        FROM public.delivery_notes dn
        JOIN public.delivery_note_items dni ON dni.delivery_note_id = dn.id
        WHERE dn.quote_id IS NOT NULL
          AND dni.product_id = p_product_id
          AND dn.status = 'finalized'
          AND COALESCE(dni.source_type, 'own') = 'own'
          AND COALESCE(dni.is_dropshipping, false) = false
        GROUP BY dn.quote_id
    ),
    quote_ne_active AS (
        SELECT 
            dn.quote_id,
            COALESCE(SUM(dni.quantity), 0) AS active_qty
        FROM public.delivery_notes dn
        JOIN public.delivery_note_items dni ON dni.delivery_note_id = dn.id
        WHERE dn.quote_id IS NOT NULL
          AND dni.product_id = p_product_id
          AND dn.status IN ('draft', 'sent', 'resent', 'opened')
          AND COALESCE(dn.is_archived, false) = false
          AND COALESCE(dni.source_type, 'own') = 'own'
          AND COALESCE(dni.is_dropshipping, false) = false
        GROUP BY dn.quote_id
    )
    SELECT COALESCE(SUM(
        GREATEST(
            GREATEST(0, qs.quote_qty - COALESCE(qf.finalized_qty, 0)),
            COALESCE(qa.active_qty, 0)
        )
    ), 0)
    INTO v_quotes_reserved
    FROM quote_summary qs
    LEFT JOIN quote_ne_finalized qf ON qf.quote_id = qs.quote_id
    LEFT JOIN quote_ne_active qa ON qa.quote_id = qs.quote_id;

    -- B. Reserva de Notas de Entrega desde Cero (sin cotización) en estado activo
    SELECT COALESCE(SUM(dni.quantity), 0)
    INTO v_scratch_ne_reserved
    FROM public.delivery_notes dn
    JOIN public.delivery_note_items dni ON dni.delivery_note_id = dn.id
    WHERE dn.quote_id IS NULL
      AND dni.product_id = p_product_id
      AND dn.status IN ('draft', 'sent', 'resent', 'opened')
      AND COALESCE(dn.is_archived, false) = false
      AND COALESCE(dni.source_type, 'own') = 'own'
      AND COALESCE(dni.is_dropshipping, false) = false;

    v_total_reserved := v_quotes_reserved + v_scratch_ne_reserved;

    -- C. Actualizar columna reserved_quantity en products
    UPDATE public.products 
    SET reserved_quantity = v_total_reserved
    WHERE id = p_product_id;
END;
$$;

-- 2. Actualizar validate_quote_items con orden inmutable y protección contra NEs desde cero
CREATE OR REPLACE FUNCTION public.validate_quote_items(
  p_supplier_product_ids uuid[],
  p_product_ids uuid[],
  p_quote_id uuid DEFAULT NULL
)
RETURNS TABLE (
  item_id uuid,
  item_type text,
  current_stock numeric,
  current_cost numeric,
  reserved_stock numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  -- 1. Validación de stock de sucursales de proveedores
  SELECT 
    sbs.id as item_id,
    'SUPPLIER'::text as item_type,
    COALESCE(sbs.quantity, 0)::numeric as current_stock,
    COALESCE(sbs.price, 0)::numeric as current_cost,
    0::numeric as reserved_stock
  FROM public.supplier_branch_stock sbs
  WHERE sbs.id = ANY(p_supplier_product_ids)

  UNION ALL

  -- 2. Validación de productos propios
  SELECT 
    p.id as item_id,
    'OWN'::text as item_type,
    public.inventory_quantity(p)::numeric as current_stock,
    public.average_cost(p)::numeric as current_cost,
    CASE 
      WHEN p_quote_id IS NOT NULL AND (SELECT q.status FROM public.quotes q WHERE q.id = p_quote_id) = 'approved' THEN
        -- Para una cotización aprobada, el reserved_stock son:
        -- a) Las cotizaciones aprobadas ANTES de esta (ordenadas por created_at o client_feedback_at)
        -- b) Más las NEs activas creadas desde cero
        (
          COALESCE((
            SELECT SUM(qi.quantity)
            FROM public.quote_items_products qi
            JOIN public.quotes q ON qi.quote_id = q.id
            WHERE qi.product_id = p.id 
              AND qi.source_type = 'own'
              AND q.status = 'approved'
              AND q.id != p_quote_id
              AND COALESCE(q.is_archived, false) = false
              AND (
                COALESCE(q.client_feedback_at, q.created_at) < 
                COALESCE((SELECT COALESCE(q_curr.client_feedback_at, q_curr.created_at) FROM public.quotes q_curr WHERE q_curr.id = p_quote_id), now())
                OR (
                  COALESCE(q.client_feedback_at, q.created_at) = 
                  COALESCE((SELECT COALESCE(q_curr.client_feedback_at, q_curr.created_at) FROM public.quotes q_curr WHERE q_curr.id = p_quote_id), now())
                  AND q.id < p_quote_id
                )
              )
          ), 0)
          +
          COALESCE((
            SELECT SUM(dni.quantity)
            FROM public.delivery_notes dn
            JOIN public.delivery_note_items dni ON dni.delivery_note_id = dn.id
            WHERE dn.quote_id IS NULL
              AND dni.product_id = p.id
              AND dn.status IN ('draft', 'sent', 'resent', 'opened')
              AND COALESCE(dn.is_archived, false) = false
              AND COALESCE(dni.source_type, 'own') = 'own'
              AND COALESCE(dni.is_dropshipping, false) = false
          ), 0)
        )::numeric
      ELSE
        -- Para cotizaciones nuevas o borradores, reserved_stock es la reserva total del producto
        COALESCE(p.reserved_quantity, 0)::numeric
    END as reserved_stock
  FROM public.products p
  WHERE p.id = ANY(p_product_ids);
END;
$$;

-- 3. Actualizar get_product_sources para recibir p_quote_id opcional
DROP FUNCTION IF EXISTS public.get_product_sources(text, text, text, text);
DROP FUNCTION IF EXISTS public.get_product_sources(text, text, text, text, uuid);

CREATE OR REPLACE FUNCTION public.get_product_sources(
    p_name text,
    p_brand text,
    p_model text,
    p_uom text,
    p_quote_id uuid DEFAULT NULL
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
    is_accessible boolean,
    reserved_stock numeric,
    last_updated timestamp with time zone
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
        true,
        CASE 
            WHEN p_quote_id IS NOT NULL AND (SELECT q.status FROM public.quotes q WHERE q.id = p_quote_id) = 'approved' THEN
                GREATEST(0, COALESCE(p.reserved_quantity, 0.0) - COALESCE((
                    SELECT SUM(qi.quantity)
                    FROM public.quote_items_products qi
                    WHERE qi.quote_id = p_quote_id AND qi.product_id = p.id AND qi.source_type = 'own'
                ), 0.0))::numeric
            ELSE
                COALESCE(p.reserved_quantity, 0.0)::numeric
        END as reserved_stock,
        p.updated_at as last_updated
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
        CASE
            WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
            WHEN v_verification_status != 'verified' THEN (UPPER(COALESCE(s.trade_type, '')) IS DISTINCT FROM 'WHOLESALE')
            ELSE
                NOT (
                   UPPER(COALESCE(s.trade_type, '')) = 'WHOLESALE' 
                   AND 
                   COALESCE(s.allowed_verification_types::text, '') NOT ILIKE '%individual%'
                )
        END,
        0.0::numeric,
        sbs.updated_at as last_updated
    FROM supplier_products sp
    JOIN supplier_branch_stock sbs ON sp.id = sbs.product_id
    JOIN suppliers s ON sp.supplier_id = s.id
    JOIN supplier_branches sb ON sbs.branch_id = sb.id
    LEFT JOIN brands b ON sp.brand_id = b.id
    LEFT JOIN uoms u ON sp.uom_id = u.id
    WHERE sp.is_active = TRUE
        AND s.is_active = TRUE
        AND sbs.quantity > 0
        AND UPPER(TRIM(COALESCE(b.name, sp.brand_raw, 'Genérico'))) = UPPER(TRIM(p_brand))
        AND UPPER(TRIM(COALESCE(sp.model, ''))) = UPPER(TRIM(p_model))
        AND UPPER(TRIM(COALESCE(u.symbol, sp.uom_raw, 'unid.'))) = UPPER(TRIM(p_uom))
    
    ORDER BY 
        1 ASC,
        5 ASC;
END;
$$;

-- 4. Triggers en delivery_note_items para actualizar reservas
CREATE OR REPLACE FUNCTION public.handle_delivery_note_item_reservation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        IF NEW.product_id IS NOT NULL AND COALESCE(NEW.source_type, 'own') = 'own' THEN
            PERFORM public.recalculate_product_reservation(NEW.product_id);
        END IF;
        IF (TG_OP = 'UPDATE' AND OLD.product_id IS DISTINCT FROM NEW.product_id AND OLD.product_id IS NOT NULL) THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.product_id IS NOT NULL AND COALESCE(OLD.source_type, 'own') = 'own' THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_delivery_note_item_reservation_change ON public.delivery_note_items;
CREATE TRIGGER trigger_delivery_note_item_reservation_change
AFTER INSERT OR UPDATE OR DELETE ON public.delivery_note_items
FOR EACH ROW
EXECUTE FUNCTION public.handle_delivery_note_item_reservation_change();

-- 5. Triggers en delivery_notes para actualizar reservas ante cambios de estatus o quote_id
CREATE OR REPLACE FUNCTION public.handle_delivery_note_header_reservation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    item RECORD;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.status IS DISTINCT FROM NEW.status OR 
            OLD.quote_id IS DISTINCT FROM NEW.quote_id OR 
            OLD.is_archived IS DISTINCT FROM NEW.is_archived) THEN
            
            FOR item IN 
                SELECT DISTINCT product_id 
                FROM public.delivery_note_items 
                WHERE delivery_note_id = NEW.id 
                  AND product_id IS NOT NULL 
                  AND COALESCE(source_type, 'own') = 'own'
            LOOP
                PERFORM public.recalculate_product_reservation(item.product_id);
            END LOOP;
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        FOR item IN 
            SELECT DISTINCT product_id 
            FROM public.delivery_note_items 
            WHERE delivery_note_id = OLD.id 
              AND product_id IS NOT NULL 
              AND COALESCE(source_type, 'own') = 'own'
        LOOP
            PERFORM public.recalculate_product_reservation(item.product_id);
        END LOOP;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_delivery_note_header_reservation_change ON public.delivery_notes;
CREATE TRIGGER trigger_delivery_note_header_reservation_change
AFTER UPDATE OR DELETE ON public.delivery_notes
FOR EACH ROW
EXECUTE FUNCTION public.handle_delivery_note_header_reservation_change();

-- 6. Sincronización inicial de existencias reservadas
DO $$
DECLARE
    p RECORD;
BEGIN
    FOR p IN SELECT id FROM public.products LOOP
        PERFORM public.recalculate_product_reservation(p.id);
    END LOOP;
END;
$$;
