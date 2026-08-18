-- Migration: Add 'opened' status and client feedback columns to quotes table
-- Date: 2026-08-15

-- 1. Actualizar check constraint de estatus de cotizaciones para incluir 'opened'
ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_status_check;
ALTER TABLE public.quotes ADD CONSTRAINT quotes_status_check 
CHECK (status IN (
  'draft', 
  'sent', 
  'resent', 
  'opened', 
  'review', 
  'approved', 
  'rejected', 
  'expired', 
  'cancelled', 
  'finalized', 
  'archived'
));

-- 2. Agregar columnas para comentarios y fecha de feedback del cliente si no existen
ALTER TABLE public.quotes 
ADD COLUMN IF NOT EXISTS client_feedback TEXT,
ADD COLUMN IF NOT EXISTS client_feedback_at TIMESTAMPTZ;
