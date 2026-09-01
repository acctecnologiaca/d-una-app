-- Migration: Create RPC generate_report_action_token for service_reports
-- Homologates token generation with quotes (generate_quote_action_token) and
-- supplier_orders (generate_oc_action_token).
-- Reports use a fixed 30-day validity window.

-- NOTE: service_reports.action_token is TEXT (not UUID) per the existing schema.
-- We generate a UUID and cast it to TEXT to match the column type.

CREATE OR REPLACE FUNCTION public.generate_report_action_token(p_report_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_token TEXT := gen_random_uuid()::TEXT;
BEGIN
  UPDATE public.service_reports
  SET action_token = v_new_token,
      action_token_expires_at = NOW() + INTERVAL '30 days',
      updated_at = NOW()
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reporte de servicio no encontrado: %', p_report_id;
  END IF;

  RETURN v_new_token;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_report_action_token(UUID) TO authenticated, service_role;
