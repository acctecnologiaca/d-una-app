-- Migración: Estandarización de Ciclo de Vida, Inmutabilidad de Estatus, Reactividad de Reservas y Dropshipping en Órdenes de Compra
-- Archivo: supabase/migrations/20260918000000_enforce_document_status_immutability.sql

-- 1. Campos de Entrega y Destinatario Dropshipping en Órdenes de Compra
ALTER TABLE public.supplier_orders
ADD COLUMN IF NOT EXISTS is_dropshipping BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS recipient_name TEXT,
ADD COLUMN IF NOT EXISTS recipient_address TEXT,
ADD COLUMN IF NOT EXISTS recipient_phone TEXT,
ADD COLUMN IF NOT EXISTS delivery_instructions TEXT;

-- 2. Inmutabilidad y Reversión de Notas de Entrega
CREATE OR REPLACE FUNCTION public.check_delivery_note_status_immutability()
RETURNS TRIGGER AS $$
BEGIN
  -- Si ya está finalizada, solo se permite pasar a cancelada (reversión de entrega / devolución)
  IF OLD.status = 'finalized' AND NEW.status != 'cancelled' THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_FINALIZED_DELIVERY_NOTE: Una nota finalizada solo puede pasar a cancelada.';
  END IF;
  
  -- Si ya está cancelada, es terminal e inmutable
  IF OLD.status = 'cancelled' AND NEW.status != 'cancelled' THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_CANCELLED_DELIVERY_NOTE: Una nota cancelada es inmutable.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_note_status_immutability ON public.delivery_notes;
CREATE TRIGGER trigger_delivery_note_status_immutability
BEFORE UPDATE OF status ON public.delivery_notes
FOR EACH ROW
EXECUTE FUNCTION public.check_delivery_note_status_immutability();

-- 3. Inmutabilidad de Cotizaciones
CREATE OR REPLACE FUNCTION public.check_quote_status_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IN ('finalized', 'cancelled') AND NEW.status != OLD.status THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_TERMINAL_QUOTE: Cotización finalizada o cancelada no puede modificarse.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_quote_status_immutability ON public.quotes;
CREATE TRIGGER trigger_quote_status_immutability
BEFORE UPDATE OF status ON public.quotes
FOR EACH ROW
EXECUTE FUNCTION public.check_quote_status_immutability();

-- 4. Inmutabilidad y Reversión de Reportes de Servicio
CREATE OR REPLACE FUNCTION public.check_service_report_status_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'finalized' AND NEW.status != 'cancelled' THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_FINALIZED_REPORT: Reporte finalizado solo puede cancelarse.';
  END IF;
  
  IF OLD.status = 'cancelled' AND NEW.status != 'cancelled' THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_CANCELLED_REPORT: Reporte cancelado es inmutable.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_service_report_status_immutability ON public.service_reports;
CREATE TRIGGER trigger_service_report_status_immutability
BEFORE UPDATE OF status ON public.service_reports
FOR EACH ROW
EXECUTE FUNCTION public.check_service_report_status_immutability();

-- 5. Inmutabilidad de Órdenes de Compra
CREATE OR REPLACE FUNCTION public.check_supplier_order_status_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IN ('finalized', 'cancelled') AND NEW.status != OLD.status THEN
    RAISE EXCEPTION 'CANNOT_MODIFY_TERMINAL_SUPPLIER_ORDER: Orden de compra finalizada o cancelada es inmutable.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_supplier_order_status_immutability ON public.supplier_orders;
CREATE TRIGGER trigger_supplier_order_status_immutability
BEFORE UPDATE OF status ON public.supplier_orders
FOR EACH ROW
EXECUTE FUNCTION public.check_supplier_order_status_immutability();

-- 6. Reactividad de Reservas en Cotizaciones (Cabecera e Ítems)
CREATE OR REPLACE FUNCTION public.handle_quote_header_reservation_change()
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
                FROM public.quote_items_products 
                WHERE quote_id = NEW.id 
                  AND product_id IS NOT NULL 
                  AND source_type = 'own'
            LOOP
                PERFORM public.recalculate_product_reservation(item.product_id);
            END LOOP;
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        FOR item IN 
            SELECT DISTINCT product_id 
            FROM public.quote_items_products 
            WHERE quote_id = OLD.id 
              AND product_id IS NOT NULL 
              AND source_type = 'own'
        LOOP
            PERFORM public.recalculate_product_reservation(item.product_id);
        END LOOP;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_quote_header_reservation_change ON public.quotes;
CREATE TRIGGER trigger_quote_header_reservation_change
AFTER UPDATE OR DELETE ON public.quotes
FOR EACH ROW
EXECUTE FUNCTION public.handle_quote_header_reservation_change();

CREATE OR REPLACE FUNCTION public.handle_quote_item_reservation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        IF NEW.product_id IS NOT NULL AND NEW.source_type = 'own' THEN
            PERFORM public.recalculate_product_reservation(NEW.product_id);
        END IF;
        IF (TG_OP = 'UPDATE' AND OLD.product_id IS DISTINCT FROM NEW.product_id AND OLD.product_id IS NOT NULL) THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.product_id IS NOT NULL AND OLD.source_type = 'own' THEN
            PERFORM public.recalculate_product_reservation(OLD.product_id);
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trigger_quote_item_reservation_change ON public.quote_items_products;
CREATE TRIGGER trigger_quote_item_reservation_change
AFTER INSERT OR UPDATE OR DELETE ON public.quote_items_products
FOR EACH ROW
EXECUTE FUNCTION public.handle_quote_item_reservation_change();
