-- Add is_archived column to supplier_orders table
ALTER TABLE public.supplier_orders ADD COLUMN is_archived BOOLEAN NOT NULL DEFAULT FALSE;
