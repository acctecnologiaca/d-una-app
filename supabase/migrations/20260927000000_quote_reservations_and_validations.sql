-- Migración: Actualización de check_quote_insufficient_stock y validate_quote_items
-- Archivo: supabase/migrations/20260927000000_quote_reservations_and_validations.sql

-- 1. Actualizar check_quote_insufficient_stock con salvaguarda anti-autobloqueo
CREATE OR REPLACE FUNCTION public.check_quote_insufficient_stock(p_quote_id uuid)
RETURNS TABLE(product_id uuid, product_name text, requested_qty numeric, available_qty numeric)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quote_status text;
BEGIN
    SELECT q.status INTO v_quote_status FROM public.quotes q WHERE q.id = p_quote_id;

    RETURN QUERY
    WITH quote_items_agg AS (
        SELECT 
            qi.product_id,
            qi.name,
            SUM(qi.quantity) as requested_qty
        FROM public.quote_items_products qi
        WHERE qi.quote_id = p_quote_id 
          AND qi.source_type = 'own'
          AND qi.product_id IS NOT NULL
        GROUP BY qi.product_id, qi.name
    )
    SELECT 
        qia.product_id,
        qia.name::text as product_name,
        qia.requested_qty,
        CASE 
            WHEN v_quote_status = 'approved' THEN
                GREATEST(0, (public.inventory_quantity(p) - GREATEST(0, COALESCE(p.reserved_quantity, 0) - qia.requested_qty)))::numeric
            ELSE
                GREATEST(0, (public.inventory_quantity(p) - COALESCE(p.reserved_quantity, 0)))::numeric
        END as available_qty
    FROM quote_items_agg qia
    JOIN public.products p ON qia.product_id = p.id
    WHERE 
        qia.requested_qty > (
            CASE 
                WHEN v_quote_status = 'approved' THEN
                    GREATEST(0, (public.inventory_quantity(p) - GREATEST(0, COALESCE(p.reserved_quantity, 0) - qia.requested_qty)))
                ELSE
                    GREATEST(0, (public.inventory_quantity(p) - COALESCE(p.reserved_quantity, 0)))
            END
        );
END;
$$;

-- 2. Actualizar validate_quote_items para incluir reportes de servicio activos en cotizaciones aprobadas
CREATE OR REPLACE FUNCTION public.validate_quote_items(
    p_supplier_product_ids uuid[],
    p_product_ids uuid[],
    p_quote_id uuid DEFAULT NULL
)
RETURNS TABLE(
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
        -- a) Las cotizaciones aprobadas ANTES de esta
        -- b) Más las NEs activas creadas desde cero
        -- c) Más los Reportes de Servicio activos
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
          +
          COALESCE((
            SELECT SUM(sri.quantity)
            FROM public.service_reports sr
            JOIN public.service_report_items_products sri ON sri.report_id = sr.id
            WHERE sri.product_id = p.id
              AND sr.status IN ('draft', 'sent', 'resent', 'opened')
              AND COALESCE(sr.is_archived, false) = false
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
