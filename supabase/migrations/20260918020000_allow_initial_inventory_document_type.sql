-- Migration: Allow 'initial_inventory' in purchases document_type check constraint
ALTER TABLE public.purchases 
DROP CONSTRAINT IF EXISTS purchases_document_type_check;

ALTER TABLE public.purchases 
ADD CONSTRAINT purchases_document_type_check 
CHECK (document_type = ANY (ARRAY['invoice'::text, 'delivery_note'::text, 'initial_inventory'::text]));
