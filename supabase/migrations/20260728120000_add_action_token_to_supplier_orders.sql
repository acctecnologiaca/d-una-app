-- 1. Agregar columnas a supplier_orders
ALTER TABLE public.supplier_orders 
ADD COLUMN IF NOT EXISTS action_token UUID NULL,
ADD COLUMN IF NOT EXISTS action_token_expires_at TIMESTAMPTZ NULL;

-- Crear índice para búsqueda rápida del token
CREATE INDEX IF NOT EXISTS idx_supplier_orders_action_token 
ON public.supplier_orders(action_token) 
WHERE action_token IS NOT NULL;

-- 2. Agregar columnas a purchases (para compatibilidad de esquema)
ALTER TABLE public.purchases 
ADD COLUMN IF NOT EXISTS action_token UUID NULL,
ADD COLUMN IF NOT EXISTS action_token_expires_at TIMESTAMPTZ NULL;

-- 3. Actualizar la restricción CHECK de status en supplier_orders
ALTER TABLE public.supplier_orders 
DROP CONSTRAINT IF EXISTS supplier_orders_status_check;

ALTER TABLE public.supplier_orders 
ADD CONSTRAINT supplier_orders_status_check 
CHECK (status IN (
  'draft', 
  'sent', 
  'resent', 
  'approved', 
  'rejected', 
  'finalized', 
  'cancelled'
));

-- 4. Crear RPC con SECURITY DEFINER para generar/renovar el token de 72h
CREATE OR REPLACE FUNCTION public.generate_oc_action_token(p_order_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_token UUID := gen_random_uuid();
BEGIN
  UPDATE public.supplier_orders
  SET action_token = v_new_token,
      action_token_expires_at = NOW() + INTERVAL '72 hours',
      updated_at = NOW()
  WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Orden de compra no encontrada: %', p_order_id;
  END IF;

  RETURN v_new_token::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_oc_action_token(UUID) TO authenticated, service_role;
