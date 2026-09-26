-- Migración: Sistema Integral de Reservas (Reportes, Notas y Cotizaciones)
-- Archivo: supabase/migrations/20260926000000_inventory_reservations_and_validations.sql

-- 1. Actualizar recalculate_product_reservation para incluir Reportes de Servicio Activos
CREATE OR REPLACE FUNCTION public.recalculate_product_reservation(p_product_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quotes_reserved NUMERIC := 0;
    v_scratch_ne_reserved NUMERIC := 0;
    v_service_reports_reserved NUMERIC := 0;
    v_total_reserved NUMERIC := 0;
BEGIN
    IF p_product_id IS NULL THEN
        RETURN;
    END IF;

    -- A. Reserva de Cotizaciones Aprobadas
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

    -- B. Reserva de Notas de Entrega desde Cero en estado activo
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

    -- C. Reserva de Reportes de Servicio en estado activo (draft, sent, resent, opened)
    SELECT COALESCE(SUM(sri.quantity), 0)
    INTO v_service_reports_reserved
    FROM public.service_reports sr
    JOIN public.service_report_items_products sri ON sri.report_id = sr.id
    WHERE sri.product_id = p_product_id
      AND sr.status IN ('draft', 'sent', 'resent', 'opened')
      AND COALESCE(sr.is_archived, false) = false;

    v_total_reserved := v_quotes_reserved + v_scratch_ne_reserved + v_service_reports_reserved;

    -- D. Actualizar columna reserved_quantity en products
    UPDATE public.products 
    SET reserved_quantity = v_total_reserved
    WHERE id = p_product_id;
END;
$$;

-- 2. Triggers para Reportes de Servicio
CREATE OR REPLACE FUNCTION public.handle_service_report_item_reservation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        IF NEW.product_id IS NOT NULL THEN
            PERFORM public.recalculate_product_reservation(NEW.product_id);
        END IF;
        IF (TG_OP = 'UPDATE' AND OLD.product_id IS DISTINCT FROM NEW.product_id AND OLD.product_id IS NOT NULL) THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.product_id IS NOT NULL THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_service_report_item_reservation_change ON public.service_report_items_products;
CREATE TRIGGER trigger_service_report_item_reservation_change
AFTER INSERT OR UPDATE OR DELETE ON public.service_report_items_products
FOR EACH ROW
EXECUTE FUNCTION public.handle_service_report_item_reservation_change();

CREATE OR REPLACE FUNCTION public.handle_service_report_header_reservation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    item RECORD;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.status IS DISTINCT FROM NEW.status OR OLD.is_archived IS DISTINCT FROM NEW.is_archived) THEN
            FOR item IN 
                SELECT DISTINCT product_id 
                FROM public.service_report_items_products 
                WHERE report_id = NEW.id 
                  AND product_id IS NOT NULL 
            LOOP
                PERFORM public.recalculate_product_reservation(item.product_id);
            END LOOP;
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        FOR item IN 
            SELECT DISTINCT product_id 
            FROM public.service_report_items_products 
            WHERE report_id = OLD.id 
              AND product_id IS NOT NULL 
        LOOP
            PERFORM public.recalculate_product_reservation(item.product_id);
        END LOOP;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_service_report_header_reservation_change ON public.service_reports;
CREATE TRIGGER trigger_service_report_header_reservation_change
AFTER UPDATE OR DELETE ON public.service_reports
FOR EACH ROW
EXECUTE FUNCTION public.handle_service_report_header_reservation_change();

-- 3. Actualizar check_service_report_insufficient_stock con Anti-Autobloqueo
CREATE OR REPLACE FUNCTION public.check_service_report_insufficient_stock(p_report_id uuid)
RETURNS TABLE(product_id uuid, product_name text, requested_qty numeric, available_qty numeric)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH report_items_agg AS (
      SELECT 
          sri.product_id,
          sri.name,
          SUM(sri.quantity) as requested_qty
      FROM public.service_report_items_products sri
      WHERE sri.report_id = p_report_id 
        AND sri.product_id IS NOT NULL
      GROUP BY sri.product_id, sri.name
  )
  SELECT 
    ria.product_id,
    ria.name::text as product_name,
    ria.requested_qty,
    GREATEST(0, (public.inventory_quantity(p) - GREATEST(0, COALESCE(p.reserved_quantity, 0) - ria.requested_qty)))::numeric as available_qty
  FROM report_items_agg ria
  JOIN public.products p ON ria.product_id = p.id
  WHERE ria.requested_qty > (public.inventory_quantity(p) - GREATEST(0, COALESCE(p.reserved_quantity, 0) - ria.requested_qty));
END;
$$;

-- 4. Crear RPC check_delivery_note_insufficient_stock
CREATE OR REPLACE FUNCTION public.check_delivery_note_insufficient_stock(p_note_id uuid)
RETURNS TABLE(product_id uuid, product_name text, requested_qty numeric, available_qty numeric)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quote_id uuid;
BEGIN
    SELECT dn.quote_id INTO v_quote_id
    FROM public.delivery_notes dn
    WHERE dn.id = p_note_id;

    RETURN QUERY
    WITH note_items_agg AS (
        SELECT 
            dni.product_id,
            dni.name,
            SUM(dni.quantity) as requested_qty
        FROM public.delivery_note_items dni
        WHERE dni.delivery_note_id = p_note_id
          AND dni.product_id IS NOT NULL
          AND COALESCE(dni.source_type, 'own') = 'own'
          AND COALESCE(dni.is_dropshipping, false) = false
        GROUP BY dni.product_id, dni.name
    ),
    product_availability AS (
        SELECT 
            nia.product_id,
            nia.name as product_name,
            nia.requested_qty,
            public.inventory_quantity(p) as physical_stock,
            COALESCE(p.reserved_quantity, 0) as total_reserved,
            COALESCE((
                SELECT SUM(qi.quantity) - COALESCE((
                    SELECT SUM(dni_prev.quantity)
                    FROM public.delivery_notes dn_prev
                    JOIN public.delivery_note_items dni_prev ON dni_prev.delivery_note_id = dn_prev.id
                    WHERE dn_prev.quote_id = v_quote_id
                      AND dn_prev.id != p_note_id
                      AND dn_prev.status = 'finalized'
                      AND dni_prev.product_id = nia.product_id
                      AND COALESCE(dni_prev.source_type, 'own') = 'own'
                ), 0)
                FROM public.quote_items_products qi
                JOIN public.quotes q ON qi.quote_id = q.id
                WHERE q.id = v_quote_id
                  AND q.status = 'approved'
                  AND qi.product_id = nia.product_id
                  AND qi.source_type = 'own'
            ), 0) as quote_reserved_balance,
            CASE WHEN v_quote_id IS NULL THEN nia.requested_qty ELSE 0 END as note_own_reserved
        FROM note_items_agg nia
        JOIN public.products p ON nia.product_id = p.id
    )
    SELECT 
        pa.product_id,
        pa.product_name::text,
        pa.requested_qty::numeric,
        CASE 
            WHEN v_quote_id IS NOT NULL THEN
                LEAST(
                    pa.physical_stock,
                    GREATEST(0, pa.quote_reserved_balance) + GREATEST(0, pa.physical_stock - pa.total_reserved)
                )::numeric
            ELSE
                GREATEST(0, pa.physical_stock - (pa.total_reserved - pa.note_own_reserved))::numeric
        END as available_qty
    FROM product_availability pa
    WHERE 
        pa.requested_qty > pa.physical_stock
        OR 
        pa.requested_qty > (
            CASE 
                WHEN v_quote_id IS NOT NULL THEN
                    LEAST(
                        pa.physical_stock,
                        GREATEST(0, pa.quote_reserved_balance) + GREATEST(0, pa.physical_stock - pa.total_reserved)
                    )
                ELSE
                    GREATEST(0, pa.physical_stock - (pa.total_reserved - pa.note_own_reserved))
            END
        );
END;
$$;

-- 5. Sincronización Inicial de Reservas para Productos Existentes
DO $$
DECLARE
    p RECORD;
BEGIN
    FOR p IN SELECT id FROM public.products LOOP
        PERFORM public.recalculate_product_reservation(p.id);
    END LOOP;
END;
$$;
