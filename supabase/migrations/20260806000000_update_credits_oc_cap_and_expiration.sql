-- 1. Agregar columnas para control de vencimiento y lotes FIFO
ALTER TABLE public.credit_transactions 
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ NULL,
ADD COLUMN IF NOT EXISTS remaining_amount INT NOT NULL DEFAULT 0;

-- Crear índice para optimizar consultas de saldos activos por fecha de expiración
CREATE INDEX IF NOT EXISTS idx_credit_transactions_expires ON public.credit_transactions(user_id, expires_at) WHERE remaining_amount > 0;

-- 2. Poblar remaining_amount para transacciones activas previas
UPDATE public.credit_transactions
SET remaining_amount = amount
WHERE amount > 0 AND remaining_amount = 0;

-- 3. Actualizar Trigger de finalización de Órdenes de Compra (Tope de 15 créditos + Vencimiento a 30 días)
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
        
        -- Calcular recompensa: 1 crédito por cada $10 USD con un tope MÁXIMO de 15 créditos
        v_reward := LEAST(15, FLOOR(NEW.total / 10));
        
        IF v_reward > 0 THEN
            INSERT INTO public.credit_transactions (
                user_id, transaction_type, amount, remaining_amount, reference_type, reference_id, description, expires_at
            ) VALUES (
                NEW.user_id, 'oc_reward', v_reward, v_reward, 'supplier_order', NEW.id,
                'Créditos otorgados por finalizar Orden de Compra #' || NEW.order_number,
                now() + INTERVAL '30 days'
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- 4. Actualizar RPC get_user_credit_status para considerar créditos de OC no vencidos
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

    -- Sumar créditos ganados por OCs que no hayan vencido (o vencen en el futuro)
    SELECT COALESCE(SUM(remaining_amount), 0) INTO v_earned_credits
    FROM public.credit_transactions
    WHERE user_id = p_user_id 
      AND transaction_type = 'oc_reward'
      AND remaining_amount > 0
      AND (expires_at IS NULL OR expires_at > v_now);

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

-- 5. Actualizar RPC consume_user_credit con regla FIFO (ORDER BY expires_at ASC NULLS LAST)
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
    v_batch RECORD;
BEGIN
    v_status := public.get_user_credit_status(p_user_id);
    v_remaining := (v_status->>'remainingCredits')::INT;

    IF v_remaining <= 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_CREDITS';
    END IF;

    -- Intentar reducir remaining_amount de un lote de recompensa activo por orden FIFO (el que vence primero)
    SELECT id, remaining_amount INTO v_batch
    FROM public.credit_transactions
    WHERE user_id = p_user_id
      AND transaction_type = 'oc_reward'
      AND remaining_amount > 0
      AND (expires_at IS NULL OR expires_at > now())
    ORDER BY expires_at ASC NULLS LAST, created_at ASC
    LIMIT 1;

    IF FOUND THEN
        UPDATE public.credit_transactions
        SET remaining_amount = remaining_amount - 1
        WHERE id = v_batch.id;
    END IF;

    -- Registrar la transacción de consumo
    INSERT INTO public.credit_transactions (
        user_id, transaction_type, amount, remaining_amount, reference_type, reference_id, description
    ) VALUES (
        p_user_id, 
        CASE WHEN p_channel = 'whatsapp' THEN 'whatsapp_sent' ELSE 'email_sent' END,
        -1,
        0,
        p_doc_type, 
        p_ref_id,
        'Envío de ' || p_doc_type || ' vía ' || p_channel
    );

    RETURN public.get_user_credit_status(p_user_id);
END;
$$;
