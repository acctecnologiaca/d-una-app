-- 1. Agregar columna de estatus de verificación en supplier_orders
ALTER TABLE public.supplier_orders 
ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'pending_review';

-- 2. Crear tabla de transacciones e historial de créditos
CREATE TABLE IF NOT EXISTS public.credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL, -- 'monthly_reset', 'oc_reward', 'oc_reversal', 'email_sent', 'whatsapp_sent'
    amount INTEGER NOT NULL, -- Positivo para ganados/base, negativo para consumidos/revertidos
    reference_type TEXT, -- 'supplier_order', 'quote', 'report', 'delivery_note', 'receipt'
    reference_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_date ON public.credit_transactions(user_id, created_at);

-- 3. Función RPC para obtener el estado de créditos del usuario
CREATE OR REPLACE FUNCTION public.get_user_credit_status(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_created_at TIMESTAMPTZ;
    v_now TIMESTAMPTZ := now();
    v_reg_day INT;
    v_cycle_start TIMESTAMPTZ;
    v_cycle_end TIMESTAMPTZ;
    v_months_old INT;
    v_base_credits INT;
    v_earned_credits INT := 0;
    v_reversed_credits INT := 0;
    v_spent_credits INT := 0;
    v_remaining_credits INT := 0;
BEGIN
    -- Obtener fecha de registro del usuario
    SELECT created_at INTO v_created_at FROM public.profiles WHERE id = p_user_id;
    IF v_created_at IS NULL THEN
        v_created_at := v_now;
    END IF;

    -- Calcular antigüedad en meses
    v_months_old := (EXTRACT(YEAR FROM age(v_now, v_created_at)) * 12) + EXTRACT(MONTH FROM age(v_now, v_created_at));
    
    -- Determinar créditos base del mes
    IF v_months_old < 3 THEN
        v_base_credits := 30;
    ELSE
        v_base_credits := 15;
    END IF;

    -- Calcular inicio y fin del ciclo mensual actual
    v_reg_day := LEAST(EXTRACT(DAY FROM v_created_at)::INT, 28);
    IF EXTRACT(DAY FROM v_now) >= v_reg_day THEN
        v_cycle_start := date_trunc('month', v_now) + (v_reg_day - 1 || ' days')::INTERVAL;
    ELSE
        v_cycle_start := (date_trunc('month', v_now) - INTERVAL '1 month') + (v_reg_day - 1 || ' days')::INTERVAL;
    END IF;
    v_cycle_end := v_cycle_start + INTERVAL '1 month';

    -- Sumar créditos ganados por OCs en el ciclo actual
    SELECT COALESCE(SUM(amount), 0) INTO v_earned_credits
    FROM public.credit_transactions
    WHERE user_id = p_user_id 
      AND transaction_type = 'oc_reward'
      AND created_at >= v_cycle_start AND created_at < v_cycle_end;

    -- Sumar reversiones de OCs rechazadas en el ciclo actual
    SELECT COALESCE(SUM(ABS(amount)), 0) INTO v_reversed_credits
    FROM public.credit_transactions
    WHERE user_id = p_user_id 
      AND transaction_type = 'oc_reversal'
      AND created_at >= v_cycle_start AND created_at < v_cycle_end;

    -- Sumar créditos consumidos en el ciclo actual
    SELECT COALESCE(SUM(ABS(amount)), 0) INTO v_spent_credits
    FROM public.credit_transactions
    WHERE user_id = p_user_id 
      AND transaction_type IN ('email_sent', 'whatsapp_sent')
      AND created_at >= v_cycle_start AND created_at < v_cycle_end;

    -- Calcular créditos restantes
    v_remaining_credits := GREATEST(0, (v_base_credits + v_earned_credits - v_reversed_credits) - v_spent_credits);

    RETURN jsonb_build_object(
        'baseCredits', v_base_credits,
        'earnedCredits', v_earned_credits,
        'reversedCredits', v_reversed_credits,
        'spentCredits', v_spent_credits,
        'remainingCredits', v_remaining_credits,
        'cycleStart', v_cycle_start,
        'cycleEnd', v_cycle_end,
        'isInitialThreeMonths', (v_months_old < 3)
    );
END;
$$;

-- 4. Trigger al finalizar una Orden de Compra (Asigna pending_review y recompensa)
CREATE OR REPLACE FUNCTION public.trg_on_supplier_order_finalized()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reward INT;
BEGIN
    IF NEW.status = 'finalized' AND (OLD.status IS NULL OR OLD.status != 'finalized') THEN
        -- Asignar estatus de verificación en revisión si no está seteado
        IF NEW.verification_status IS NULL OR NEW.verification_status = '' THEN
            NEW.verification_status := 'pending_review';
        END IF;
        
        -- Calcular recompensa: 1 crédito por cada $10 USD
        v_reward := FLOOR(NEW.total / 10);
        
        IF v_reward > 0 THEN
            INSERT INTO public.credit_transactions (
                user_id, transaction_type, amount, reference_type, reference_id, description
            ) VALUES (
                NEW.user_id, 'oc_reward', v_reward, 'supplier_order', NEW.id,
                'Créditos otorgados por finalizar Orden de Compra #' || NEW.order_number
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_supplier_order_finalized ON public.supplier_orders;
CREATE TRIGGER trigger_supplier_order_finalized
BEFORE UPDATE ON public.supplier_orders
FOR EACH ROW
EXECUTE FUNCTION public.trg_on_supplier_order_finalized();

-- 5. Trigger al rechazar el soporte de una Orden de Compra (Reversión automática)
CREATE OR REPLACE FUNCTION public.trg_on_supplier_order_verification_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_previous_reward INT;
BEGIN
    IF NEW.verification_status = 'rejected' AND OLD.verification_status != 'rejected' THEN
        -- Buscar los créditos otorgados previamente a esta OC
        SELECT COALESCE(SUM(amount), 0) INTO v_previous_reward
        FROM public.credit_transactions
        WHERE reference_id = NEW.id AND transaction_type = 'oc_reward';

        IF v_previous_reward > 0 THEN
            INSERT INTO public.credit_transactions (
                user_id, transaction_type, amount, reference_type, reference_id, description
            ) VALUES (
                NEW.user_id, 'oc_reversal', -v_previous_reward, 'supplier_order', NEW.id,
                'Reversión de créditos por Rechazo de soporte en Orden de Compra #' || NEW.order_number
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_supplier_order_verification ON public.supplier_orders;
CREATE TRIGGER trigger_supplier_order_verification
AFTER UPDATE ON public.supplier_orders
FOR EACH ROW
EXECUTE FUNCTION public.trg_on_supplier_order_verification_change();

-- 6. RPC para consumir crédito al enviar documento
CREATE OR REPLACE FUNCTION public.consume_user_credit(
    p_user_id UUID,
    p_doc_type TEXT,
    p_channel TEXT,
    p_ref_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status JSONB;
    v_remaining INT;
BEGIN
    v_status := public.get_user_credit_status(p_user_id);
    v_remaining := (v_status->>'remainingCredits')::INT;

    IF v_remaining <= 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_CREDITS';
    END IF;

    INSERT INTO public.credit_transactions (
        user_id, transaction_type, amount, reference_type, reference_id, description
    ) VALUES (
        p_user_id, 
        CASE WHEN p_channel = 'whatsapp' THEN 'whatsapp_sent' ELSE 'email_sent' END,
        -1, 
        p_doc_type, 
        p_ref_id,
        'Envío de ' || p_doc_type || ' vía ' || p_channel
    );

    RETURN public.get_user_credit_status(p_user_id);
END;
$$;
