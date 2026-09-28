-- ==============================================================================
-- Migración: Rango de Fecha de Ejecución en Reportes de Servicio
-- 1. Agregar columna service_end_date
-- 2. Check constraint preventivo
-- 3. Índice para optimización de filtros temporales
-- ==============================================================================

ALTER TABLE public.service_reports
ADD COLUMN IF NOT EXISTS service_end_date DATE NULL;

-- Constraint preventivo
ALTER TABLE public.service_reports
DROP CONSTRAINT IF EXISTS chk_service_report_date_range;

ALTER TABLE public.service_reports
ADD CONSTRAINT chk_service_report_date_range 
CHECK (service_end_date IS NULL OR service_end_date >= service_date);

-- Índice para consultas y solapamientos
CREATE INDEX IF NOT EXISTS idx_service_reports_dates 
ON public.service_reports(service_date, service_end_date);
