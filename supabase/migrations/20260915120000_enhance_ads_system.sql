-- 1. Default auth.uid() en ad_clicks
ALTER TABLE public.ad_clicks 
  ALTER COLUMN user_id SET DEFAULT auth.uid();

-- 2. Actualización de la función RPC get_banners_for_user
CREATE OR REPLACE FUNCTION public.get_banners_for_user(
  p_occupation_ids UUID[] DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  subtitle TEXT,
  image_url TEXT,
  supplier_id UUID,
  advertiser_name TEXT,
  sector_ids UUID[],
  keywords TEXT[],
  category_tags TEXT[],
  action_type TEXT,
  action_payload TEXT,
  priority INT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_sector_ids UUID[];
  v_clean_query TEXT;
BEGIN
  v_clean_query := NULLIF(TRIM(p_search_query), '');

  -- 1. Si se proporcionan occupation_ids, obtener los sector_ids relacionados
  IF p_occupation_ids IS NOT NULL AND array_length(p_occupation_ids, 1) > 0 THEN
    SELECT ARRAY_AGG(DISTINCT os.sector_id)
    INTO v_user_sector_ids
    FROM public.occupation_sectors os
    WHERE os.occupation_id = ANY(p_occupation_ids);
  END IF;

  -- 2. Seleccionar banners activos respetando sector, filtros y orden de prioridad comercial
  RETURN QUERY
  SELECT 
    b.id,
    b.title,
    b.subtitle,
    COALESCE(b.image_url, s.logo_url) AS image_url,
    b.supplier_id,
    COALESCE(b.advertiser_name, s.name, 'Anunciante') AS advertiser_name,
    b.sector_ids,
    b.keywords,
    b.category_tags,
    b.action_type,
    b.action_payload,
    b.priority,
    b.start_date,
    b.end_date,
    b.created_at,
    b.updated_at
  FROM public.ad_banners b
  LEFT JOIN public.suppliers s ON b.supplier_id = s.id
  WHERE b.is_active = true
    AND (b.start_date IS NULL OR b.start_date <= NOW())
    AND (b.end_date IS NULL OR b.end_date >= NOW())
    AND (
      v_user_sector_ids IS NULL 
      OR b.sector_ids IS NULL 
      OR array_length(b.sector_ids, 1) = 0
      OR b.sector_ids && v_user_sector_ids
    )
    AND (
      v_clean_query IS NULL
      OR b.title ILIKE '%' || v_clean_query || '%'
      OR b.subtitle ILIKE '%' || v_clean_query || '%'
      OR b.advertiser_name ILIKE '%' || v_clean_query || '%'
      OR s.name ILIKE '%' || v_clean_query || '%'
      OR b.keywords && ARRAY[LOWER(v_clean_query)]
      OR EXISTS (
        SELECT 1 FROM unnest(b.keywords) kw WHERE kw ILIKE '%' || v_clean_query || '%'
      )
    )
  ORDER BY b.priority DESC, RANDOM()
  LIMIT p_limit;
END;
$$;

-- 3. Placements faltantes en ad_placement_settings
INSERT INTO public.ad_placement_settings (placement_key, parent_module, name, is_enabled)
VALUES
  ('delivery_notes', NULL, 'Módulo Notas de Entrega', true),
  ('delivery_notes_list', 'delivery_notes', 'Lista de Notas de Entrega', true),
  ('delivery_notes_search', 'delivery_notes', 'Búsqueda de Notas de Entrega', true),
  ('clients', NULL, 'Módulo Clientes', true),
  ('clients_list', 'clients', 'Lista de Clientes', true),
  ('clients_search', 'clients', 'Búsqueda de Clientes', true)
ON CONFLICT (placement_key) DO NOTHING;
