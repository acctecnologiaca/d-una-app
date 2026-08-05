-- Add quote_id column to supplier_orders table with FK to quotes
ALTER TABLE public.supplier_orders 
ADD COLUMN IF NOT EXISTS quote_id UUID REFERENCES public.quotes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_supplier_orders_quote_id 
ON public.supplier_orders(quote_id);
