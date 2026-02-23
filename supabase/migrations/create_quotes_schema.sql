-- Quotes Module Schema

-- 1. Delivery Times (Auxiliary)
CREATE TABLE IF NOT EXISTS public.delivery_times (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    value_days INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Commercial Conditions (Auxiliary)
CREATE TABLE IF NOT EXISTS public.commercial_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Collaborators (Sales Agents)
CREATE TABLE IF NOT EXISTS public.collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    identification_id TEXT, -- CI, RIF, Passport
    phone TEXT,
    email TEXT,
    charge TEXT, -- Job Title
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Financial Parameters (Global Config - Singleton/Versioned)
CREATE TABLE IF NOT EXISTS public.financial_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profit_margin NUMERIC DEFAULT 25.00,
    tax_rate NUMERIC DEFAULT 16.00,
    currency_code TEXT DEFAULT 'USD',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default financial parameters if empty
INSERT INTO public.financial_parameters (profit_margin, tax_rate, currency_code)
SELECT 25.00, 16.00, 'USD'
WHERE NOT EXISTS (SELECT 1 FROM public.financial_parameters);


-- 5. Quotes Header
CREATE TABLE IF NOT EXISTS public.quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_number TEXT UNIQUE, -- Auto-generated via trigger (pending)
    client_id UUID NOT NULL REFERENCES public.clients(id),
    contact_id UUID REFERENCES public.contacts(id),
    advisor_id UUID REFERENCES public.collaborators(id), -- Or profiles, decided on collaborators
    category_id UUID REFERENCES public.categories(id),
    
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'resent', 'review', 'approved', 'rejected', 'expired', 'cancelled', 'finalized', 'archived')),
    date_issued DATE DEFAULT CURRENT_DATE,
    validity_days INTEGER DEFAULT 15,
    
    subtotal NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sequence for Quote Number
CREATE SEQUENCE IF NOT EXISTS quotes_number_seq START 1;

-- Function to generate Quote Number (C-0000000001)
CREATE OR REPLACE FUNCTION generate_quote_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quote_number IS NULL THEN
        NEW.quote_number := 'C-' || LPAD(nextval('quotes_number_seq')::TEXT, 10, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Quote Number
CREATE TRIGGER set_quote_number
BEFORE INSERT ON public.quotes
FOR EACH ROW
EXECUTE FUNCTION generate_quote_number();


-- 6. Quote Items - Products
CREATE TABLE IF NOT EXISTS public.quote_items_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES public.quotes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id), -- Own Inventory
    supplier_product_id UUID REFERENCES public.supplier_products(id), -- Supplier Inventory
    delivery_time_id UUID REFERENCES public.delivery_times(id),
    
    -- Snapshot Fields
    name TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    uom TEXT,
    description TEXT,
    
    -- Economic Fields
    quantity NUMERIC NOT NULL DEFAULT 1,
    cost_price NUMERIC DEFAULT 0,
    profit_margin NUMERIC DEFAULT 0,
    unit_price NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0, -- Calculated
    total_price NUMERIC DEFAULT 0, -- Calculated
    
    warranty_time TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 7. Quote Items - Services
CREATE TABLE IF NOT EXISTS public.quote_items_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES public.quotes(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id), -- Own Service
    service_rate_id UUID REFERENCES public.service_rates(id),
    execution_time_id UUID REFERENCES public.delivery_times(id),
    
    -- Snapshot Fields
    name TEXT NOT NULL,
    description TEXT,
    
    -- Economic Fields
    quantity NUMERIC NOT NULL DEFAULT 1,
    cost_price NUMERIC DEFAULT 0, -- If outsourced
    profit_margin NUMERIC DEFAULT 0,
    unit_price NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    total_price NUMERIC DEFAULT 0,
    
    warranty_time TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 8. Quote Conditions Relation
CREATE TABLE IF NOT EXISTS public.quote_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES public.quotes(id) ON DELETE CASCADE,
    condition_id UUID REFERENCES public.commercial_conditions(id),
    description TEXT NOT NULL, -- Snapshot of copy
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS (Policies to be defined later, enabling for now)
ALTER TABLE public.delivery_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercial_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_parameters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_items_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_items_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_conditions ENABLE ROW LEVEL SECURITY;

-- Basic Policy: Authenticated users can view/edit everything (MVP)
-- To be refined in "Security" phase
CREATE POLICY "Enable all for authenticated users" ON public.delivery_times FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.commercial_conditions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.collaborators FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.financial_parameters FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.quotes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.quote_items_products FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.quote_items_services FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for authenticated users" ON public.quote_conditions FOR ALL USING (auth.role() = 'authenticated');
