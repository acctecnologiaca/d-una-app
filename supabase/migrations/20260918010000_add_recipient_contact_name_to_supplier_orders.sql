-- Migration: Add recipient_contact_name to supplier_orders
ALTER TABLE public.supplier_orders 
ADD COLUMN IF NOT EXISTS recipient_contact_name TEXT;
