-- 1. Actualizar de manera retroactiva las cotizaciones existentes al nuevo formato CT-[USER_CODE]-[YY][SEQ]
WITH numbered_quotes AS (
    SELECT 
        q.id,
        row_number() OVER (
            PARTITION BY q.user_id, TO_CHAR(q.created_at, 'YY') 
            ORDER BY q.created_at ASC
        ) as seq,
        p.main_country,
        p.user_number,
        TO_CHAR(q.created_at, 'YY') as yr
    FROM public.quotes q
    JOIN public.profiles p ON q.user_id = p.id
)
UPDATE public.quotes q
SET quote_number = 'CT-' 
    || CASE COALESCE(nq.main_country, '')
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
    END
    || UPPER(LPAD(to_hex(COALESCE(nq.user_number, 0)), 4, '0'))
    || '-'
    || nq.yr
    || LPAD(nq.seq::TEXT, 3, '0')
FROM numbered_quotes nq
WHERE q.id = nq.id;

-- 2. Reemplazar la función de generación automática del Trigger para Cotizaciones futuras
CREATE OR REPLACE FUNCTION generate_quote_number()
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
    IF NEW.quote_number IS NULL THEN
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

        -- Obtener la última cotización en el formato correcto para secuenciación
        SELECT quote_number INTO last_num
        FROM public.quotes
        WHERE user_id = NEW.user_id
        ORDER BY created_at DESC
        LIMIT 1;

        next_seq := 1;
        IF last_num IS NOT NULL AND last_num LIKE 'CT-%' THEN
            DECLARE
                parts TEXT[];
                cot_part TEXT;
                year_in_last TEXT;
                seq_in_last TEXT;
            BEGIN
                parts := regexp_split_to_array(last_num, '-');
                IF array_length(parts, 1) >= 3 THEN
                    cot_part := parts[array_length(parts, 1)];
                    IF length(cot_part) = 5 THEN
                        year_in_last := substring(cot_part from 1 for 2);
                        seq_in_last := substring(cot_part from 3);
                        IF year_in_last = year_prefix THEN
                            next_seq := CAST(seq_in_last AS INTEGER) + 1;
                        END IF;
                    END IF;
                END IF;
            END;
        END IF;

        NEW.quote_number := 'CT-' || user_code || '-' || year_prefix || LPAD(next_seq::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
