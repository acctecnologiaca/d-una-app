-- Create sequence and tables for Supplier Orders

CREATE SEQUENCE IF NOT EXISTS public.supplier_orders_seq START 1;

CREATE TABLE IF NOT EXISTS public.supplier_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE RESTRICT,
  supplier_branch_id UUID REFERENCES public.supplier_branches(id) ON DELETE SET NULL,
  shipping_method_id UUID REFERENCES public.shipping_methods(id) ON DELETE SET NULL,
  receiver_collaborator_id UUID REFERENCES public.collaborators(id) ON DELETE SET NULL,
  order_number TEXT UNIQUE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'resent', 'finalized', 'cancelled')),
  subtotal NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  tax NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  total NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  invoice_photo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.supplier_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_order_id UUID NOT NULL REFERENCES public.supplier_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  uom TEXT NOT NULL DEFAULT 'Ud',
  quantity NUMERIC(15, 2) NOT NULL DEFAULT 1.00,
  unit_price NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger Function for Order Number OC-XXXXXX
CREATE OR REPLACE FUNCTION public.set_supplier_order_number()
RETURNS TRIGGER AS $$
DECLARE
  next_num INTEGER;
BEGIN
  IF NEW.order_number IS NULL THEN
    SELECT COALESCE(MAX(CAST(NULLIF(regexp_replace(order_number, '\D', '', 'g'), '') AS INTEGER)), 0) + 1
    INTO next_num
    FROM public.supplier_orders
    WHERE user_id = NEW.user_id;

    NEW.order_number := 'OC-' || LPAD(next_num::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger safely
DROP TRIGGER IF EXISTS trigger_set_supplier_order_number ON public.supplier_orders;
CREATE TRIGGER trigger_set_supplier_order_number
BEFORE INSERT ON public.supplier_orders
FOR EACH ROW
EXECUTE FUNCTION public.set_supplier_order_number();

-- Enable Row Level Security (RLS)
ALTER TABLE public.supplier_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_order_items ENABLE ROW LEVEL SECURITY;

-- Drop old policies if any
DROP POLICY IF EXISTS "Users can manage their own supplier orders" ON public.supplier_orders;
DROP POLICY IF EXISTS "Users can manage their own supplier order items" ON public.supplier_order_items;

-- Create RLS Policies
CREATE POLICY "Users can manage their own supplier orders" ON public.supplier_orders
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own supplier order items" ON public.supplier_order_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.supplier_orders
      WHERE id = supplier_order_items.supplier_order_id AND user_id = auth.uid()
    )
  );
