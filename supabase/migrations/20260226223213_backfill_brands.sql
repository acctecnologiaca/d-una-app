-- =================================================================================
-- SCRIPT DE BACKFILL PARA brand_id
-- =================================================================================
-- Este script dispara el trigger 'assign_or_create_brand' para todas las filas
-- existentes en 'supplier_products'. Esto obliga a que el nivel 1 (Regex) y
-- el nivel 2 (Similitud) se ejecuten y vinculen (o creen) el 'brand_id' correcto
-- utilizando la tabla 'brands'.
-- =================================================================================

UPDATE supplier_products 
SET brand_raw = brand_raw
WHERE brand_id IS NULL;
