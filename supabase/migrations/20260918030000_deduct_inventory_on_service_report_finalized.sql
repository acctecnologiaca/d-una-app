-- Migración: Descuento de Inventario y Validación de Stock en Reportes de Servicio Finalizados
-- Archivo: supabase/migrations/20260918030000_deduct_inventory_on_service_report_finalized.sql

-- 1. Actualizar inventory_quantity para restar los ítems de reportes de servicio finalizados
CREATE OR REPLACE FUNCTION public.inventory_quantity(product public.products)
RETURNS numeric
LANGUAGE sql
STABLE
AS $$
  SELECT 
    COALESCE((
      SELECT SUM(pi.quantity)
      FROM public.purchase_items pi
      WHERE pi.product_id = product.id
    ), 0)
    -
    COALESCE((
      SELECT SUM(dni.quantity)
      FROM public.delivery_note_items dni
      JOIN public.delivery_notes dn ON dn.id = dni.delivery_note_id
      WHERE dni.product_id = product.id
        AND dn.status = 'finalized'
        AND COALESCE(dni.source_type, 'own') = 'own'
        AND COALESCE(dni.is_dropshipping, false) = false
    ), 0)
    -
    COALESCE((
      SELECT SUM(sri.quantity)
      FROM public.service_report_items_products sri
      JOIN public.service_reports sr ON sr.id = sri.report_id
      WHERE sri.product_id = product.id
        AND sr.status = 'finalized'
    ), 0);
$$;

-- 2. Crear RPC check_service_report_insufficient_stock para validar disponibilidad antes de finalizar
CREATE OR REPLACE FUNCTION public.check_service_report_insufficient_stock(p_report_id uuid)
RETURNS TABLE(product_id uuid, product_name text, requested_qty numeric, available_qty numeric)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sri.product_id,
    sri.name::text as product_name,
    sri.quantity as requested_qty,
    (public.inventory_quantity(p) - COALESCE(p.reserved_quantity, 0))::numeric as available_qty
  FROM public.service_report_items_products sri
  JOIN public.products p ON sri.product_id = p.id
  WHERE sri.report_id = p_report_id 
    AND sri.product_id IS NOT NULL
    AND sri.quantity > (public.inventory_quantity(p) - COALESCE(p.reserved_quantity, 0));
END;
$$;
