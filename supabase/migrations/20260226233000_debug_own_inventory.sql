-- =================================================================================
-- SCRIPT DE DEPURACIÓN PARA INVENTARIO PROPIO
-- =================================================================================
-- Este script extrae exactamente cómo la base de datos está leyendo los atributos
-- de tus productos en inventario propio (tabla 'products'), para descubrir por qué
-- la validación estricta (modelo, marca, uom) los está rechazando.
-- =================================================================================

-- 1. Ver qué atributos tienen realmente tus productos
SELECT 
  p.id,
  p.name,
  p.model AS raw_model,
  public.normalize_text(COALESCE(p.model, '')) AS model_limpio,
  b.name AS raw_brand,
  public.normalize_text(COALESCE(b.name, 'Genérico')) AS brand_limpia,
  u.symbol AS raw_uom,
  public.normalize_text(COALESCE(u.symbol, 'ud.')) AS uom_limpia
FROM products p
LEFT JOIN brands b ON p.brand_id = b.id
LEFT JOIN uoms u ON p.uom_id = u.id
LIMIT 10;
