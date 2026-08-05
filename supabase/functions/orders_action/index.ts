import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const token = url.searchParams.get('token');
  const action = url.searchParams.get('action');

  if (!token || !action) {
    return jsonResponse({ status: 'invalid', message: 'Parámetros faltantes.' });
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  try {
    // 1. Buscar la orden por action_token
    const { data: order, error: fetchError } = await supabaseAdmin
      .from('supplier_orders')
      .select('id, order_number, status, action_token_expires_at')
      .eq('action_token', token)
      .maybeSingle();

    if (fetchError || !order) {
      return jsonResponse({
        status: 'invalid',
        message: 'Este enlace ya no es válido o ha sido utilizado previamente.',
      });
    }

    // 2. Verificar expiración (72h)
    if (order.action_token_expires_at) {
      const expiresAt = new Date(order.action_token_expires_at).getTime();
      if (Date.now() > expiresAt) {
        return jsonResponse({
          status: 'expired',
          order_number: order.order_number,
        });
      }
    }

    // 3. Verificar si fue consolidada o cancelada
    if (order.status === 'merged' || order.status === 'cancelled') {
      return jsonResponse({
        status: 'invalid',
        message: 'Esta orden de compra ha sido consolidada o cancelada y ya no está activa.',
      });
    }

    // 4. Verificar si ya fue procesada
    if (order.status === 'approved' || order.status === 'rejected') {
      return jsonResponse({
        status: 'already_processed',
        order_number: order.order_number,
        current_status: order.status,
      });
    }

    // 4. Determinar nuevo estado e invalidar token (un solo uso)
    const isApprove = action === 'confirm' || action === 'approve';
    const newStatus = isApprove ? 'approved' : 'rejected';

    const { error: updateError } = await supabaseAdmin
      .from('supplier_orders')
      .update({
        status: newStatus,
        action_token: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', order.id);

    if (updateError) {
      throw new Error(`Error al actualizar: ${updateError.message}`);
    }

    // 5. Retornar resultado exitoso
    return jsonResponse({
      status: newStatus,
      order_number: order.order_number,
    });

  } catch (err: any) {
    return jsonResponse({
      status: 'error',
      message: err.message || 'Error interno del servidor.',
    }, 500);
  }
});

function jsonResponse(data: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}
