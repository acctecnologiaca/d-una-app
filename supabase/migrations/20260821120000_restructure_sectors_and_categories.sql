-- Migration: Restructure Sectors, Occupations and Categories
-- Date: 2026-08-21
-- Description: Adds is_active to sectors and occupations, is_global to categories, creates category_sectors junction table, maps orphan occupations, maps categories to sectors, and creates get_relevant_categories RPC.

-- 1. Alter sectors table
ALTER TABLE public.sectors
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- 2. Alter occupations table
ALTER TABLE public.occupations
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- 3. Alter categories table
ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS is_global BOOLEAN NOT NULL DEFAULT false;

-- 4. Create category_sectors junction table
CREATE TABLE IF NOT EXISTS public.category_sectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    sector_id UUID NOT NULL REFERENCES public.sectors(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(category_id, sector_id)
);

-- Enable RLS on category_sectors
ALTER TABLE public.category_sectors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access category_sectors" ON public.category_sectors;
CREATE POLICY "Public Read Access category_sectors"
    ON public.category_sectors
    FOR SELECT
    USING (true);

-- 5. Data Seeding & Repair: Map orphan occupations to sectors in occupation_sectors
DO $$
DECLARE
    v_sector_auto UUID;
    v_sector_ferr UUID;
    v_sector_const UUID;
    v_sector_hogar UUID;
    v_sector_tec UUID;
    v_sector_comp UUID;
    v_sector_seg UUID;
    
    v_occ_mecanico UUID;
    v_occ_plomero UUID;
    v_occ_carpintero UUID;
    v_occ_pintor UUID;
    v_occ_redes UUID;
    v_occ_electricista UUID;
BEGIN
    -- Get Sector IDs
    SELECT id INTO v_sector_auto FROM public.sectors WHERE name ILIKE 'Automotriz' LIMIT 1;
    SELECT id INTO v_sector_ferr FROM public.sectors WHERE name ILIKE 'Ferretería' LIMIT 1;
    SELECT id INTO v_sector_const FROM public.sectors WHERE name ILIKE 'Construcción' LIMIT 1;
    SELECT id INTO v_sector_hogar FROM public.sectors WHERE name ILIKE 'Hogar' LIMIT 1;
    SELECT id INTO v_sector_tec FROM public.sectors WHERE name ILIKE 'Tecnología' LIMIT 1;
    SELECT id INTO v_sector_comp FROM public.sectors WHERE name ILIKE 'Computación' LIMIT 1;
    SELECT id INTO v_sector_seg FROM public.sectors WHERE name ILIKE 'Seguridad' LIMIT 1;

    -- Get Occupation IDs
    SELECT id INTO v_occ_mecanico FROM public.occupations WHERE name ILIKE 'Mecánico automotriz' LIMIT 1;
    SELECT id INTO v_occ_plomero FROM public.occupations WHERE name ILIKE 'Plomero' LIMIT 1;
    SELECT id INTO v_occ_carpintero FROM public.occupations WHERE name ILIKE 'Carpintero' LIMIT 1;
    SELECT id INTO v_occ_pintor FROM public.occupations WHERE name ILIKE 'Pintor' LIMIT 1;
    SELECT id INTO v_occ_redes FROM public.occupations WHERE name ILIKE 'Técnico en redes de datos' LIMIT 1;
    SELECT id INTO v_occ_electricista FROM public.occupations WHERE name ILIKE 'Técnico electricista' LIMIT 1;

    -- Insert mappings safely using ON CONFLICT DO NOTHING
    IF v_occ_mecanico IS NOT NULL THEN
        IF v_sector_auto IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_mecanico, v_sector_auto) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_ferr IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_mecanico, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_occ_plomero IS NOT NULL THEN
        IF v_sector_const IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_plomero, v_sector_const) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_ferr IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_plomero, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_hogar IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_plomero, v_sector_hogar) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_occ_carpintero IS NOT NULL THEN
        IF v_sector_const IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_carpintero, v_sector_const) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_ferr IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_carpintero, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_hogar IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_carpintero, v_sector_hogar) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_occ_pintor IS NOT NULL THEN
        IF v_sector_const IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_pintor, v_sector_const) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_hogar IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_pintor, v_sector_hogar) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_ferr IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_pintor, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_occ_redes IS NOT NULL THEN
        IF v_sector_tec IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_redes, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_comp IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_redes, v_sector_comp) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_seg IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_redes, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_occ_electricista IS NOT NULL THEN
        IF v_sector_ferr IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_electricista, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
        IF v_sector_tec IS NOT NULL THEN
            INSERT INTO public.occupation_sectors (occupation_id, sector_id) VALUES (v_occ_electricista, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;

-- 6. Data Seeding: Set is_global for general categories
UPDATE public.categories
SET is_global = true
WHERE name ILIKE 'Herramientas' OR name ILIKE 'Instalación';

-- 7. Data Seeding: Map official categories to sectors in category_sectors
DO $$
DECLARE
    v_sector_auto UUID;
    v_sector_ferr UUID;
    v_sector_const UUID;
    v_sector_hogar UUID;
    v_sector_tec UUID;
    v_sector_comp UUID;
    v_sector_seg UUID;
    
    v_cat_alarma UUID;
    v_cat_cables UUID;
    v_cat_camaras UUID;
    v_cat_comp UUID;
    v_cat_acceso UUID;
    v_cat_elec UUID;
    v_cat_redes UUID;
BEGIN
    -- Get Sector IDs
    SELECT id INTO v_sector_auto FROM public.sectors WHERE name ILIKE 'Automotriz' LIMIT 1;
    SELECT id INTO v_sector_ferr FROM public.sectors WHERE name ILIKE 'Ferretería' LIMIT 1;
    SELECT id INTO v_sector_const FROM public.sectors WHERE name ILIKE 'Construcción' LIMIT 1;
    SELECT id INTO v_sector_hogar FROM public.sectors WHERE name ILIKE 'Hogar' LIMIT 1;
    SELECT id INTO v_sector_tec FROM public.sectors WHERE name ILIKE 'Tecnología' LIMIT 1;
    SELECT id INTO v_sector_comp FROM public.sectors WHERE name ILIKE 'Computación' LIMIT 1;
    SELECT id INTO v_sector_seg FROM public.sectors WHERE name ILIKE 'Seguridad' LIMIT 1;

    -- Get Category IDs
    SELECT id INTO v_cat_alarma FROM public.categories WHERE name ILIKE 'Alarma' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_cables FROM public.categories WHERE name ILIKE 'Cables y Accesorios' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_camaras FROM public.categories WHERE name ILIKE 'Cámaras de Seguridad' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_comp FROM public.categories WHERE name ILIKE 'Computación' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_acceso FROM public.categories WHERE name ILIKE 'Control de Acceso y Asistencia' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_elec FROM public.categories WHERE name ILIKE 'Materiales Eléctricos' AND is_verified = true LIMIT 1;
    SELECT id INTO v_cat_redes FROM public.categories WHERE name ILIKE 'Redes y Conectividad' AND is_verified = true LIMIT 1;

    -- Seguridad
    IF v_sector_seg IS NOT NULL THEN
        IF v_cat_alarma IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_alarma, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_camaras IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_camaras, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_acceso IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_acceso, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_cables IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_cables, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_redes IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_redes, v_sector_seg) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- Computación & Tecnología
    IF v_sector_comp IS NOT NULL THEN
        IF v_cat_comp IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_comp, v_sector_comp) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_redes IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_redes, v_sector_comp) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_cables IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_cables, v_sector_comp) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_sector_tec IS NOT NULL THEN
        IF v_cat_comp IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_comp, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_redes IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_redes, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_cables IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_cables, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_elec IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_elec, v_sector_tec) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- Construcción & Ferretería
    IF v_sector_const IS NOT NULL THEN
        IF v_cat_elec IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_elec, v_sector_const) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_cables IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_cables, v_sector_const) ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF v_sector_ferr IS NOT NULL THEN
        IF v_cat_elec IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_elec, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
        IF v_cat_cables IS NOT NULL THEN
            INSERT INTO public.category_sectors (category_id, sector_id) VALUES (v_cat_cables, v_sector_ferr) ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;

-- 8. Create RPC get_relevant_categories
CREATE OR REPLACE FUNCTION public.get_relevant_categories(p_occupation_ids UUID[] DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    name TEXT,
    type TEXT,
    user_id UUID,
    is_verified BOOLEAN,
    is_global BOOLEAN,
    normalized_name TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    RETURN QUERY
    SELECT DISTINCT
        c.id,
        c.name,
        c.type,
        c.user_id,
        c.is_verified,
        c.is_global,
        c.normalized_name,
        c.created_at
    FROM public.categories c
    WHERE
        -- 1. Categorías propias del usuario autenticado
        (v_user_id IS NOT NULL AND c.user_id = v_user_id)
        
        -- 2. Categorías oficiales marcadas como globales (visibles para todos)
        OR (c.is_verified = true AND c.is_global = true)
        
        -- 3. Categorías asociadas a sectores activos vinculados a las ocupaciones del usuario
        OR (
            c.is_verified = true 
            AND p_occupation_ids IS NOT NULL 
            AND array_length(p_occupation_ids, 1) > 0
            AND EXISTS (
                SELECT 1 
                FROM public.category_sectors cs
                JOIN public.sectors s ON cs.sector_id = s.id
                JOIN public.occupation_sectors os ON s.id = os.sector_id
                WHERE cs.category_id = c.id
                  AND s.is_active = true
                  AND os.occupation_id = ANY(p_occupation_ids)
            )
        )
    ORDER BY c.name ASC;
END;
$$;

-- 9. Update get_relevant_suppliers_by_id to enforce sec.is_active = true
CREATE OR REPLACE FUNCTION public.get_relevant_suppliers_by_id(occupation_ids uuid[])
 RETURNS TABLE(id uuid, name text, api_key text, is_active boolean, contact_info jsonb, created_at timestamp with time zone, banner_url text, logo_url text, trade_type text, allowed_verification_types text[], user_id uuid, is_verified boolean, is_affiliated boolean, normalized_name text, phone text, email text, tax_id text, notes text, legal_name text, minimum_purchase_amount numeric, is_restricted boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id uuid;
    v_verification_status text;
    v_verification_type text;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NOT NULL THEN
        SELECT 
            p.verification_status, 
            p.verification_type 
        INTO 
            v_verification_status, 
            v_verification_type 
        FROM profiles p
        WHERE p.id = v_user_id;
    END IF;

    v_verification_status := COALESCE(v_verification_status, 'unverified');

    RETURN QUERY
    SELECT s.id, s.name, s.api_key, s.is_active, s.contact_info, s.created_at, s.banner_url, s.logo_url, s.trade_type, s.allowed_verification_types, s.user_id, s.is_verified, s.is_affiliated, s.normalized_name, s.phone, s.email, s.tax_id, s.notes, s.legal_name, s.minimum_purchase_amount, s.is_restricted
    FROM suppliers s
    JOIN supplier_sectors ss ON s.id = ss.supplier_id
    JOIN sectors sec ON ss.sector_id = sec.id
    JOIN occupation_sectors os ON sec.id = os.sector_id
    WHERE 
        os.occupation_id = ANY(occupation_ids)
        AND s.is_active = true
        AND sec.is_active = true
        
        -- Access Control: Filter out DENIED suppliers
        AND (
            CASE
                WHEN v_verification_status = 'verified' AND v_verification_type = 'business' THEN true
                WHEN v_verification_status = 'verified' AND v_verification_type = 'individual' THEN true
                ELSE 
                    CASE
                         WHEN s.trade_type IS DISTINCT FROM 'WHOLESALE' THEN true
                         WHEN s.trade_type = 'WHOLESALE' AND 'business' = ANY(s.allowed_verification_types) AND NOT ('individual' = ANY(s.allowed_verification_types)) THEN false
                         ELSE true
                    END
            END
        )
        
        -- ACL Access control layer
        AND public.check_supplier_access(s.id, v_user_id)
        
    GROUP BY s.id
    ORDER BY 
        min(ss.display_order) ASC NULLS LAST,
        s.name ASC;
END;
$function$;
