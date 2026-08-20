-- ==============================================================================
-- Migration: Create Service Reports Schema
-- Tables: service_reports, service_report_items_services, service_report_items_products, service_report_conditions
-- Trigger: generate_service_report_number() -> RS-[USER_CODE]-[YY][SEQ]
-- ==============================================================================

-- 1. Service Reports Header Table
CREATE TABLE IF NOT EXISTS public.service_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) DEFAULT auth.uid(),
    report_number TEXT UNIQUE,
    client_id UUID NOT NULL REFERENCES public.clients(id),
    contact_id UUID REFERENCES public.contacts(id),
    advisor_id UUID REFERENCES public.collaborators(id),
    category_id UUID REFERENCES public.categories(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'resent', 'opened', 'finalized', 'cancelled')),
    intervention_type TEXT DEFAULT 'corrective' CHECK (intervention_type IN ('preventive', 'corrective', 'installation', 'diagnosis', 'warranty', 'support')),
    request_description TEXT,
    work_description TEXT,
    recommendations TEXT,
    service_date DATE DEFAULT CURRENT_DATE,
    start_time TEXT,
    end_time TEXT,
    duration_minutes INTEGER,
    subtotal NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    notes TEXT,
    report_tag TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    action_token TEXT UNIQUE,
    action_token_expires_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Service Report Items Services Table
CREATE TABLE IF NOT EXISTS public.service_report_items_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.service_reports(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id),
    name TEXT NOT NULL,
    description TEXT,
    quantity NUMERIC DEFAULT 1,
    cost_price NUMERIC DEFAULT 0,
    profit_margin NUMERIC DEFAULT 0,
    unit_price NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total_price NUMERIC DEFAULT 0,
    rate_symbol TEXT,
    rate_icon_name TEXT,
    order_index INTEGER DEFAULT 0,
    warranty_time INTEGER,
    warranty_unit TEXT DEFAULT 'days',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Service Report Items Products Table
CREATE TABLE IF NOT EXISTS public.service_report_items_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.service_reports(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    name TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    uom TEXT,
    uom_icon_name TEXT,
    description TEXT,
    quantity NUMERIC DEFAULT 1,
    cost_price NUMERIC DEFAULT 0,
    profit_margin NUMERIC DEFAULT 0,
    unit_price NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total_price NUMERIC DEFAULT 0,
    group_index INTEGER DEFAULT 0,
    warranty_time INTEGER,
    warranty_unit TEXT DEFAULT 'months',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Service Report Conditions Table
CREATE TABLE IF NOT EXISTS public.service_report_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.service_reports(id) ON DELETE CASCADE,
    condition_id UUID REFERENCES public.commercial_conditions(id),
    description TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Trigger Function for Service Report Number (RS-[USER_CODE]-[YY][SEQ])
CREATE OR REPLACE FUNCTION generate_service_report_number()
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
    IF NEW.report_number IS NULL THEN
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

        -- Obtener el último reporte en el formato correcto para secuenciación
        SELECT report_number INTO last_num
        FROM public.service_reports
        WHERE user_id = NEW.user_id
        ORDER BY created_at DESC
        LIMIT 1;

        next_seq := 1;
        IF last_num IS NOT NULL AND last_num LIKE 'RS-%' THEN
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

        NEW.report_number := 'RS-' || user_code || '-' || year_prefix || LPAD(next_seq::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger assignment
DROP TRIGGER IF EXISTS trigger_generate_service_report_number ON public.service_reports;
CREATE TRIGGER trigger_generate_service_report_number
BEFORE INSERT ON public.service_reports
FOR EACH ROW
EXECUTE FUNCTION generate_service_report_number();

-- 6. Row Level Security (RLS)
ALTER TABLE public.service_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_report_items_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_report_items_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_report_conditions ENABLE ROW LEVEL SECURITY;

-- Policies for service_reports
DROP POLICY IF EXISTS "Users can manage their own service reports" ON public.service_reports;
CREATE POLICY "Users can manage their own service reports"
ON public.service_reports
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policies for service_report_items_services
DROP POLICY IF EXISTS "Users can manage their own service report items services" ON public.service_report_items_services;
CREATE POLICY "Users can manage their own service report items services"
ON public.service_report_items_services
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
);

-- Policies for service_report_items_products
DROP POLICY IF EXISTS "Users can manage their own service report items products" ON public.service_report_items_products;
CREATE POLICY "Users can manage their own service report items products"
ON public.service_report_items_products
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
);

-- Policies for service_report_conditions
DROP POLICY IF EXISTS "Users can manage their own service report conditions" ON public.service_report_conditions;
CREATE POLICY "Users can manage their own service report conditions"
ON public.service_report_conditions
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.service_reports r
        WHERE r.id = report_id AND r.user_id = auth.uid()
    )
);
