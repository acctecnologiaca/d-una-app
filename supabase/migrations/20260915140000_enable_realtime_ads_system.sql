-- ==============================================================================
-- Migración: Habilitar Realtime para ad_placement_settings y ad_banners
-- ==============================================================================

-- 1. Actualizar RLS de ad_banners para que los clientes autenticados y anónimos
--    puedan recibir eventos de INSERT, UPDATE y DELETE vía Realtime
DROP POLICY IF EXISTS "read_active_banners" ON public.ad_banners;
DROP POLICY IF EXISTS "allow_read_ad_banners" ON public.ad_banners;

CREATE POLICY "allow_read_ad_banners" 
  ON public.ad_banners 
  FOR SELECT 
  TO authenticated, anon 
  USING (true);

-- 2. Asegurar REPLICA IDENTITY FULL para que los eventos de UPDATE y DELETE
--    incluyan el registro completo en los eventos de Supabase Realtime
ALTER TABLE public.ad_placement_settings REPLICA IDENTITY FULL;
ALTER TABLE public.ad_banners REPLICA IDENTITY FULL;

-- 3. Agregar las tablas a la publicación de supabase_realtime
--    (Ignorando si ya están presentes para evitar fallos de ejecución)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'ad_placement_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ad_placement_settings;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'ad_banners'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ad_banners;
  END IF;
END $$;
