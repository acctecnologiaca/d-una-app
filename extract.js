const fs = require('fs');
const txt = fs.readFileSync('C:/Users/aleja/.gemini/antigravity/brain/f83d8e5c-2119-4948-afdd-7cf300235439/.system_generated/steps/7340/output.txt', 'utf8');

const sIdx = txt.indexOf('[{"routine_name');
const eIdx = txt.lastIndexOf('}]');
const jsonStr = txt.substring(sIdx, eIdx + 2);

const arr = JSON.parse(jsonStr);

const sp = arr.find(r => r.routine_name === 'search_supplier_products').routine_definition;
const qp = arr.find(r => r.routine_name === 'get_quote_products').routine_definition;

let out = `
DROP FUNCTION IF EXISTS public.search_supplier_products(text,text[],text[],uuid[],numeric,numeric);
CREATE OR REPLACE FUNCTION public.search_supplier_products(
  query_text text DEFAULT NULL::text,
  brand_filter text[] DEFAULT NULL::text[],
  category_filter text[] DEFAULT NULL::text[],
  supplier_filter uuid[] DEFAULT NULL::uuid[],
  min_price_filter numeric DEFAULT NULL::numeric,
  max_price_filter numeric DEFAULT NULL::numeric
)
RETURNS TABLE (
  id uuid,
  name text,
  description text,
  brand text,
  model text,
  category text,
  sku text,
  uom text,
  uom_icon_name text,
  image_url text,
  total_quantity bigint,
  min_price numeric,
  supplier_count bigint,
  first_supplier_id uuid,
  first_supplier_name text,
  first_supplier_trade_type text,
  first_supplier_logo text,
  supplier_ids uuid[],
  is_locked boolean
)
LANGUAGE plpgsql
AS $function$
${sp}
$function$;

DROP FUNCTION IF EXISTS public.get_quote_products(text,text[],text[],uuid[],numeric,numeric);
CREATE OR REPLACE FUNCTION public.get_quote_products(
  query_text text DEFAULT NULL::text,
  brand_filter text[] DEFAULT NULL::text[],
  category_filter text[] DEFAULT NULL::text[],
  supplier_filter uuid[] DEFAULT NULL::uuid[],
  min_price_filter numeric DEFAULT NULL::numeric,
  max_price_filter numeric DEFAULT NULL::numeric
)
RETURNS TABLE (
  id uuid,
  name text,
  description text,
  brand text,
  model text,
  category text,
  sku text,
  uom text,
  uom_icon_name text,
  image_url text,
  total_quantity bigint,
  min_price numeric,
  supplier_count bigint,
  first_supplier_id uuid,
  first_supplier_name text,
  first_supplier_trade_type text,
  first_supplier_logo text,
  supplier_ids jsonb,
  is_locked boolean,
  has_own_inventory boolean
)
LANGUAGE plpgsql
AS $function$
${qp}
$function$;
`;

fs.writeFileSync('restore.sql', out);
console.log('restore.sql written.');
