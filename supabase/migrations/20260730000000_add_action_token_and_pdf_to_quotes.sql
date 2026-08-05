-- Migration: Add action_token, action_token_expires_at, and pdf_url to quotes table

-- 1. Add columns to quotes
ALTER TABLE public.quotes 
ADD COLUMN IF NOT EXISTS pdf_url TEXT NULL,
ADD COLUMN IF NOT EXISTS action_token UUID NULL,
ADD COLUMN IF NOT EXISTS action_token_expires_at TIMESTAMPTZ NULL;

-- 2. Create index for fast token lookup
CREATE INDEX IF NOT EXISTS idx_quotes_action_token 
ON public.quotes(action_token) 
WHERE action_token IS NOT NULL;

-- 3. Ensure status constraint supports all required states
ALTER TABLE public.quotes 
DROP CONSTRAINT IF EXISTS quotes_status_check;

ALTER TABLE public.quotes 
ADD CONSTRAINT quotes_status_check 
CHECK (status IN (
  'draft', 
  'sent', 
  'resent', 
  'review', 
  'approved', 
  'rejected', 
  'expired', 
  'cancelled', 
  'finalized', 
  'archived'
));

-- 4. RPC function to generate or renew quote action token based on validity_days
CREATE OR REPLACE FUNCTION public.generate_quote_action_token(p_quote_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_token UUID := gen_random_uuid();
  v_validity_days INT;
BEGIN
  SELECT COALESCE(validity_days, 15) INTO v_validity_days
  FROM public.quotes
  WHERE id = p_quote_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cotización no encontrada: %', p_quote_id;
  END IF;

  UPDATE public.quotes
  SET action_token = v_new_token,
      action_token_expires_at = NOW() + (v_validity_days || ' days')::INTERVAL,
      updated_at = NOW()
  WHERE id = p_quote_id;

  RETURN v_new_token::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_quote_action_token(UUID) TO authenticated, service_role;
