-- Actualización del trigger handle_new_user para capturar avatar_url de Google OAuth y sincronizar nombres
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (
    id,
    first_name,
    last_name,
    avatar_url,
    occupation_id,
    secondary_occupation_ids,
    national_id,
    gender,
    birth_date
  )
  VALUES (
    new.id,
    -- Prioridad: first_name (registro manual) > full_name primera palabra (Google)
    COALESCE(
      NULLIF(TRIM(new.raw_user_meta_data->>'first_name'), ''),
      NULLIF(TRIM(split_part(COALESCE(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name'
      ), ' ', 1)), '')
    ),
    -- Prioridad: last_name (registro manual) > full_name resto (Google)
    COALESCE(
      NULLIF(TRIM(new.raw_user_meta_data->>'last_name'), ''),
      NULLIF(TRIM(substring(COALESCE(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name'
      ) FROM '^\S+\s+(.*)')), '')
    ),
    -- Avatar URL de Google OAuth o registro
    COALESCE(
      NULLIF(TRIM(new.raw_user_meta_data->>'avatar_url'), ''),
      NULLIF(TRIM(new.raw_user_meta_data->>'picture'), '')
    ),
    -- occupation_id: solo presente en registro manual, NULL en Google OAuth
    CASE
      WHEN new.raw_user_meta_data->>'occupation_id' IS NOT NULL
        AND new.raw_user_meta_data->>'occupation_id' != ''
      THEN (new.raw_user_meta_data->>'occupation_id')::uuid
      ELSE NULL
    END,
    -- secondary_occupation_ids: solo presente en registro manual
    CASE 
      WHEN new.raw_user_meta_data->'secondary_occupation_ids' IS NOT NULL 
      THEN (
        SELECT array_agg(x::uuid) 
        FROM jsonb_array_elements_text(new.raw_user_meta_data->'secondary_occupation_ids') t(x)
      )
      ELSE NULL
    END,
    new.raw_user_meta_data->>'national_id',
    new.raw_user_meta_data->>'gender',
    CASE 
      WHEN new.raw_user_meta_data->>'birth_date' IS NOT NULL 
      THEN (new.raw_user_meta_data->>'birth_date')::date
      ELSE NULL
    END
  )
  ON CONFLICT (id) DO UPDATE SET
    avatar_url = COALESCE(
      public.profiles.avatar_url,
      EXCLUDED.avatar_url
    ),
    first_name = COALESCE(
      public.profiles.first_name,
      EXCLUDED.first_name
    ),
    last_name = COALESCE(
      public.profiles.last_name,
      EXCLUDED.last_name
    );
  RETURN new;
END;
$function$;
