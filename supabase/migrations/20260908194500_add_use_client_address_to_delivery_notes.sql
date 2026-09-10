-- ==============================================================================
-- Migration: Add use_client_address to delivery_notes
-- ==============================================================================

ALTER TABLE public.delivery_notes 
ADD COLUMN IF NOT EXISTS use_client_address BOOLEAN DEFAULT false;
