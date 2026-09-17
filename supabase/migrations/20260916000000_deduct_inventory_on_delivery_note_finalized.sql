-- ==============================================================================
-- Migration: Deduct Own Inventory and Manage Serials on Delivery Note Finalization
-- 1. Updates computed column public.inventory_quantity(product products) to deduct
--    quantities from delivery notes with status = 'finalized' and source_type = 'own'
--    and is_dropshipping = false.
-- 2. Trigger on delivery_notes:
--    - When status transitions to 'finalized': update associated serials in product_serials to 'dispatched'.
--    - When status transitions to 'cancelled' from 'finalized': restore associated serials to 'in_stock'.
-- ==============================================================================

-- 1. Actualizar la función computed column de inventario en PostgreSQL
CREATE OR REPLACE FUNCTION public.inventory_quantity(product products)
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
    ), 0);
$$;

-- 2. Trigger para actualizar el estatus de los seriales en product_serials
CREATE OR REPLACE FUNCTION public.handle_delivery_note_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Cuando pasa a Finalizada: marcar seriales como despachados ('dispatched')
  IF NEW.status = 'finalized' AND (OLD.status IS NULL OR OLD.status != 'finalized') THEN
    UPDATE public.product_serials ps
    SET status = 'dispatched', updated_at = NOW()
    FROM public.delivery_note_serials dns
    JOIN public.delivery_note_items dni ON dni.id = dns.delivery_note_item_id
    WHERE dni.delivery_note_id = NEW.id
      AND (ps.id = dns.product_serial_id OR (ps.product_id = dns.product_id AND ps.serial_number = dns.serial_number));
  
  -- Si se cancela una nota previamente finalizada: devolver seriales a stock ('in_stock')
  ELSIF NEW.status = 'cancelled' AND OLD.status = 'finalized' THEN
    UPDATE public.product_serials ps
    SET status = 'in_stock', updated_at = NOW()
    FROM public.delivery_note_serials dns
    JOIN public.delivery_note_items dni ON dni.id = dns.delivery_note_item_id
    WHERE dni.delivery_note_id = NEW.id
      AND (ps.id = dns.product_serial_id OR (ps.product_id = dns.product_id AND ps.serial_number = dns.serial_number));
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_note_status_change ON public.delivery_notes;
CREATE TRIGGER trigger_delivery_note_status_change
AFTER INSERT OR UPDATE OF status ON public.delivery_notes
FOR EACH ROW
EXECUTE FUNCTION public.handle_delivery_note_status_change();
