-- ==============================================================================
-- Migration: Create Delivery Notes (NE) Schema & Dropshipping Discretionary Flags
-- Tables: delivery_notes, delivery_note_items, delivery_note_serials, delivery_note_observations
-- Trigger: generate_delivery_note_number() -> NE-[USER_CODE]-[YY][SEQ]
-- RPC: generate_delivery_note_action_token(p_note_id)
-- ==============================================================================

-- 0. Dropshipping Discretionary Flags for Suppliers and Branches
ALTER TABLE public.suppliers 
ADD COLUMN IF NOT EXISTS allows_dropshipping BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.supplier_branches 
ADD COLUMN IF NOT EXISTS allows_dropshipping BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.supplier_orders 
ADD COLUMN IF NOT EXISTS is_dropshipping BOOLEAN DEFAULT FALSE;

-- 1. Delivery Notes Header Table
CREATE TABLE IF NOT EXISTS public.delivery_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) DEFAULT auth.uid(),
    delivery_note_number TEXT UNIQUE,
    client_id UUID NOT NULL REFERENCES public.clients(id),
    contact_id UUID REFERENCES public.contacts(id),
    quote_id UUID REFERENCES public.quotes(id),
    supplier_order_id UUID REFERENCES public.supplier_orders(id),
    client_po_number TEXT,
    tag TEXT,
    notes TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'resent', 'opened', 'finalized', 'cancelled')),
    date DATE DEFAULT CURRENT_DATE,
    delivery_date DATE,
    delivery_type TEXT DEFAULT 'direct_delivery' CHECK (delivery_type IN ('pickup', 'direct_delivery', 'courier')),
    shipping_company_id UUID REFERENCES public.shipping_companies(id),
    tracking_number TEXT,
    recipient_address TEXT,
    recipient_city TEXT,
    recipient_state TEXT,
    delivery_instructions TEXT,
    received_by_name TEXT,
    received_by_id TEXT,
    received_by_phone TEXT,
    receiver_relationship TEXT,
    received_at TIMESTAMPTZ,
    signature_data TEXT, -- Base64 encoded PNG of physical signature
    subtotal NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    is_dropshipping BOOLEAN DEFAULT FALSE,
    has_missing_serials BOOLEAN DEFAULT FALSE,
    action_token TEXT UNIQUE,
    action_token_expires_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    pdf_url TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Delivery Note Items Table
CREATE TABLE IF NOT EXISTS public.delivery_note_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_note_id UUID NOT NULL REFERENCES public.delivery_notes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    name TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    uom TEXT DEFAULT 'Ud',
    description TEXT,
    quantity NUMERIC DEFAULT 1,
    unit_price NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total_price NUMERIC DEFAULT 0,
    order_index INTEGER DEFAULT 0,
    warranty_time INTEGER,
    warranty_unit TEXT DEFAULT 'months',
    source_type TEXT DEFAULT 'own' CHECK (source_type IN ('own', 'affiliated', 'external', 'temporal')),
    requires_serials BOOLEAN DEFAULT FALSE,
    is_dropshipping BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Delivery Note Serials Table
CREATE TABLE IF NOT EXISTS public.delivery_note_serials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_note_item_id UUID NOT NULL REFERENCES public.delivery_note_items(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    product_serial_id UUID REFERENCES public.product_serials(id),
    serial_number TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Delivery Note Observations Table
CREATE TABLE IF NOT EXISTS public.delivery_note_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_note_id UUID NOT NULL REFERENCES public.delivery_notes(id) ON DELETE CASCADE,
    observation_id UUID REFERENCES public.observations(id),
    description TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Trigger Function for Delivery Note Number (NE-[USER_CODE]-[YY][SEQ])
CREATE OR REPLACE FUNCTION generate_delivery_note_number()
RETURNS TRIGGER AS $$
DECLARE
    user_code TEXT;
    country_code TEXT;
    u_number INTEGER;
    country_name TEXT;
    year_prefix TEXT;
    next_seq INTEGER;
    last_num TEXT;
BEGIN
    IF NEW.delivery_note_number IS NULL THEN
        -- Obtener datos de perfil
        SELECT main_country, user_number INTO country_name, u_number
        FROM public.profiles
        WHERE id = NEW.user_id;

        -- Resolver código de país
        country_code := CASE COALESCE(country_name, '')
            WHEN 'Venezuela' THEN 'VE'
            WHEN 'Colombia' THEN 'CO'
            WHEN 'México' THEN 'MX'
            WHEN 'Ecuador' THEN 'EC'
            WHEN 'Perú' THEN 'PE'
            WHEN 'Chile' THEN 'CL'
            WHEN 'Argentina' THEN 'AR'
            WHEN 'Brasil' THEN 'BR'
            WHEN 'Panamá' THEN 'PA'
            WHEN 'Estados Unidos' THEN 'US'
            WHEN 'España' THEN 'ES'
            WHEN 'República Dominicana' THEN 'DO'
            WHEN 'Bolivia' THEN 'BO'
            WHEN 'Paraguay' THEN 'PY'
            WHEN 'Uruguay' THEN 'UY'
            WHEN 'Costa Rica' THEN 'CR'
            WHEN 'Guatemala' THEN 'GT'
            WHEN 'Honduras' THEN 'HN'
            WHEN 'El Salvador' THEN 'SV'
            WHEN 'Nicaragua' THEN 'NI'
            WHEN 'Cuba' THEN 'CU'
            WHEN 'Puerto Rico' THEN 'PR'
            WHEN 'Trinidad y Tobago' THEN 'TT'
            ELSE 'XX'
        END;

        user_code := country_code || UPPER(LPAD(to_hex(COALESCE(u_number, 0)), 4, '0'));
        year_prefix := TO_CHAR(CURRENT_DATE, 'YY');

        -- Obtener la última nota de entrega para secuenciación
        SELECT delivery_note_number INTO last_num
        FROM public.delivery_notes
        WHERE user_id = NEW.user_id
        ORDER BY created_at DESC
        LIMIT 1;

        next_seq := 1;
        IF last_num IS NOT NULL AND last_num LIKE 'NE-%' THEN
            DECLARE
                parts TEXT[];
                rep_part TEXT;
                year_in_last TEXT;
                seq_in_last TEXT;
            BEGIN
                parts := regexp_split_to_array(last_num, '-');
                IF array_length(parts, 1) >= 3 THEN
                    rep_part := parts[array_length(parts, 1)];
                    IF length(rep_part) = 5 THEN
                        year_in_last := substring(rep_part from 1 for 2);
                        seq_in_last := substring(rep_part from 3);
                        IF year_in_last = year_prefix THEN
                            next_seq := CAST(seq_in_last AS INTEGER) + 1;
                        END IF;
                    END IF;
                END IF;
            END;
        END IF;

        NEW.delivery_note_number := 'NE-' || user_code || '-' || year_prefix || LPAD(next_seq::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger assignment
DROP TRIGGER IF EXISTS trigger_generate_delivery_note_number ON public.delivery_notes;
CREATE TRIGGER trigger_generate_delivery_note_number
BEFORE INSERT ON public.delivery_notes
FOR EACH ROW
EXECUTE FUNCTION generate_delivery_note_number();

-- 6. Function RPC generate_delivery_note_action_token
CREATE OR REPLACE FUNCTION public.generate_delivery_note_action_token(p_note_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_token TEXT := gen_random_uuid()::TEXT;
BEGIN
  UPDATE public.delivery_notes
  SET action_token = v_new_token,
      action_token_expires_at = NOW() + INTERVAL '30 days',
      updated_at = NOW()
  WHERE id = p_note_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Nota de entrega no encontrada: %', p_note_id;
  END IF;

  RETURN v_new_token;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_delivery_note_action_token(UUID) TO authenticated, service_role;

-- 7. Row Level Security (RLS)
ALTER TABLE public.delivery_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_note_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_note_serials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_note_observations ENABLE ROW LEVEL SECURITY;

-- Policies for delivery_notes
DROP POLICY IF EXISTS "Users can manage their own delivery notes" ON public.delivery_notes;
CREATE POLICY "Users can manage their own delivery notes"
ON public.delivery_notes
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policies for delivery_note_items
DROP POLICY IF EXISTS "Users can manage their own delivery note items" ON public.delivery_note_items;
CREATE POLICY "Users can manage their own delivery note items"
ON public.delivery_note_items
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.delivery_notes n
        WHERE n.id = delivery_note_id AND n.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.delivery_notes n
        WHERE n.id = delivery_note_id AND n.user_id = auth.uid()
    )
);

-- Policies for delivery_note_serials
DROP POLICY IF EXISTS "Users can manage their own delivery note serials" ON public.delivery_note_serials;
CREATE POLICY "Users can manage their own delivery note serials"
ON public.delivery_note_serials
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.delivery_note_items i
        JOIN public.delivery_notes n ON n.id = i.delivery_note_id
        WHERE i.id = delivery_note_item_id AND n.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.delivery_note_items i
        JOIN public.delivery_notes n ON n.id = i.delivery_note_id
        WHERE i.id = delivery_note_item_id AND n.user_id = auth.uid()
    )
);

-- Policies for delivery_note_observations
DROP POLICY IF EXISTS "Users can manage their own delivery note observations" ON public.delivery_note_observations;
CREATE POLICY "Users can manage their own delivery note observations"
ON public.delivery_note_observations
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.delivery_notes n
        WHERE n.id = delivery_note_id AND n.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.delivery_notes n
        WHERE n.id = delivery_note_id AND n.user_id = auth.uid()
    )
);
