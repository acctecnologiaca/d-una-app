-- ==============================================================================
-- Migración: Gestión de Seriales en Reportes de Servicio y Triggers de Estado
-- 1. Agregar columna requires_serials a service_report_items_products
-- 2. Crear tabla service_report_serials
-- 3. Configurar RLS en service_report_serials
-- 4. Crear trigger para actualizar product_serials al finalizar o cancelar reportes
-- ==============================================================================

-- 1. Agregar columna requires_serials
ALTER TABLE public.service_report_items_products
ADD COLUMN IF NOT EXISTS requires_serials BOOLEAN DEFAULT FALSE;

-- 2. Crear tabla service_report_serials
CREATE TABLE IF NOT EXISTS public.service_report_serials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_item_id UUID NOT NULL REFERENCES public.service_report_items_products(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    product_serial_id UUID REFERENCES public.product_serials(id),
    serial_number TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para optimizar búsquedas y joins
CREATE INDEX IF NOT EXISTS idx_service_report_serials_item_id ON public.service_report_serials(report_item_id);
CREATE INDEX IF NOT EXISTS idx_service_report_serials_product_id ON public.service_report_serials(product_id);
CREATE INDEX IF NOT EXISTS idx_service_report_serials_serial_number ON public.service_report_serials(serial_number);

-- 3. Habilitar RLS
ALTER TABLE public.service_report_serials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own service report serials" ON public.service_report_serials;
CREATE POLICY "Users can manage their own service report serials"
ON public.service_report_serials
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.service_report_items_products sri
        JOIN public.service_reports sr ON sr.id = sri.report_id
        WHERE sri.id = report_item_id AND sr.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.service_report_items_products sri
        JOIN public.service_reports sr ON sr.id = sri.report_id
        WHERE sri.id = report_item_id AND sr.user_id = auth.uid()
    )
);

-- 4. Trigger Function para actualizar estatus en product_serials
CREATE OR REPLACE FUNCTION public.handle_service_report_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Cuando pasa a Finalizado ('finalized'): marcar seriales como despachados ('dispatched')
  IF NEW.status = 'finalized' AND (OLD.status IS NULL OR OLD.status != 'finalized') THEN
    UPDATE public.product_serials ps
    SET status = 'dispatched', updated_at = NOW()
    FROM public.service_report_serials srs
    JOIN public.service_report_items_products sri ON sri.id = srs.report_item_id
    WHERE sri.report_id = NEW.id
      AND (ps.id = srs.product_serial_id OR (ps.product_id = srs.product_id AND ps.serial_number = srs.serial_number));
  
  -- Si se cancela un reporte previamente finalizado: restaurar seriales a inventario ('in_stock')
  ELSIF NEW.status = 'cancelled' AND OLD.status = 'finalized' THEN
    UPDATE public.product_serials ps
    SET status = 'in_stock', updated_at = NOW()
    FROM public.service_report_serials srs
    JOIN public.service_report_items_products sri ON sri.id = srs.report_item_id
    WHERE sri.report_id = NEW.id
      AND (ps.id = srs.product_serial_id OR (ps.product_id = srs.product_id AND ps.serial_number = srs.serial_number));
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_service_report_status_change ON public.service_reports;
CREATE TRIGGER trigger_service_report_status_change
AFTER INSERT OR UPDATE OF status ON public.service_reports
FOR EACH ROW
EXECUTE FUNCTION public.handle_service_report_status_change();
