-- Fix set_supplier_order_number trigger function to use structured nomenclature: OC-[USER_CODE]-[YY][SEQ]

CREATE OR REPLACE FUNCTION public.set_supplier_order_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_code TEXT;
    country_code TEXT;
    u_number INTEGER;
    country_name TEXT;
    year_prefix TEXT;
    next_seq INTEGER;
    last_num TEXT;
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' OR NEW.order_number LIKE 'OC-UNKNOWN%' THEN
        -- Fetch profile data for user code
        SELECT main_country, user_number INTO country_name, u_number
        FROM public.profiles
        WHERE id = NEW.user_id;

        -- Resolve country code
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

        -- Get last valid order number for sequencing
        SELECT order_number INTO last_num
        FROM public.supplier_orders
        WHERE user_id = NEW.user_id
          AND order_number LIKE 'OC-%'
          AND order_number NOT LIKE 'OC-UNKNOWN%'
        ORDER BY created_at DESC
        LIMIT 1;

        next_seq := 1;
        IF last_num IS NOT NULL THEN
            DECLARE
                parts TEXT[];
                oc_part TEXT;
                year_in_last TEXT;
                seq_in_last TEXT;
            BEGIN
                parts := regexp_split_to_array(last_num, '-');
                IF array_length(parts, 1) >= 3 THEN
                    oc_part := parts[array_length(parts, 1)];
                    IF length(oc_part) = 5 THEN
                        year_in_last := substring(oc_part from 1 for 2);
                        seq_in_last := substring(oc_part from 3);
                        IF year_in_last = year_prefix THEN
                            next_seq := CAST(seq_in_last AS INTEGER) + 1;
                        END IF;
                    END IF;
                END IF;
            END;
        END IF;

        NEW.order_number := 'OC-' || user_code || '-' || year_prefix || LPAD(next_seq::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$function$;
