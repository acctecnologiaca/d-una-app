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
  let token = url.searchParams.get('token');
  let action = url.searchParams.get('action') || 'get_details';

  // Handle JSON body if POST
  if (req.method === 'POST') {
    try {
      const body = await req.json();
      if (body.token) token = body.token;
      if (body.action) action = body.action;
    } catch (_e) {
      // Fallback to URL searchParams
    }
  }

  if (!token) {
    return jsonResponse({ status: 'invalid', message: 'Token de seguridad no proporcionado.' }, 400);
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  try {
    // 1. Fetch quote by action_token
    const { data: quote, error: quoteError } = await supabaseAdmin
      .from('quotes')
      .select(`
        *,
        clients (*),
        contacts (*),
        quote_items_products (*),
        quote_items_services (*),
        quote_conditions (*)
      `)
      .eq('action_token', token)
      .maybeSingle();

    if (quoteError || !quote) {
      return jsonResponse({
        status: 'invalid',
        message: 'Este enlace ya no es válido o la cotización no existe.',
      });
    }

    // 2. Fetch issuer profile data (technician / company)
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', quote.user_id)
      .maybeSingle();

    // Check expiration based on action_token_expires_at
    const isExpired = quote.action_token_expires_at
      ? new Date().getTime() > new Date(quote.action_token_expires_at).getTime()
      : false;

    // Handle 'get_details' action
    if (action === 'get_details' || action === 'view' || action === 'get') {
      return jsonResponse({
        status: 'success',
        is_expired: isExpired,
        quote: {
          id: quote.id,
          quote_number: quote.quote_number || 'S/N',
          status: quote.status,
          date_issued: quote.date_issued,
          validity_days: quote.validity_days || 15,
          subtotal: quote.subtotal,
          tax_amount: quote.tax_amount,
          total: quote.total,
          notes: quote.notes,
          pdf_url: quote.pdf_url,
          expires_at: quote.action_token_expires_at,
        },
        client: {
          name: quote.clients?.name || 'Cliente',
          tax_id: quote.clients?.tax_id || quote.clients?.identification_id || '-',
          phone: quote.contacts?.phone || quote.clients?.phone || '-',
          email: quote.contacts?.email || quote.clients?.email || '-',
          contact_name: quote.contacts?.name || quote.clients?.contact_name || '-',
          type: quote.clients?.type || 'person',
          address: quote.clients?.address || '-',
        },
        issuer: {
          company_name: profile?.company_name || null,
          user_name: `${profile?.first_name || ''} ${profile?.last_name || ''}`.trim() || 'Asesor Técnico',
          phone: profile?.phone || '-',
          email: profile?.email || '-',
          tax_id: profile?.company_id || profile?.tax_id || profile?.identification_id || null,
          address: profile?.company_address || profile?.address || null,
          city: profile?.company_city || profile?.city || null,
          state: profile?.company_state || profile?.state || null,
          country: profile?.company_country || profile?.country || null,
          logo_url: profile?.company_logo_url || null,
        },
        items: {
          products: (quote.quote_items_products || []).map((p: any) => ({
            name: p.name,
            brand: p.brand,
            model: p.model,
            quantity: p.quantity,
            unit_price: p.unit_price,
            tax_amount: p.tax_amount,
            total_price: p.total_price,
            uom: p.uom || 'Und',
          })),
          services: (quote.quote_items_services || []).map((s: any) => ({
            name: s.name,
            description: s.description,
            quantity: s.quantity,
            unit_price: s.unit_price,
            tax_amount: s.tax_amount,
            total_price: s.total_price,
          })),
        },
        conditions: (quote.quote_conditions || []).map((c: any) => c.description || c.condition_text || c),
      });
    }

    // Handle 'approve' or 'reject' actions
    if (action === 'approve' || action === 'confirm' || action === 'reject') {
      // A. Check if already processed
      if (quote.status === 'approved' || quote.status === 'rejected') {
        return jsonResponse({
          status: 'already_processed',
          quote_number: quote.quote_number,
          current_status: quote.status,
        });
      }

      // B. Check expiration
      if (isExpired) {
        return jsonResponse({
          status: 'expired',
          quote_number: quote.quote_number,
          expires_at: quote.action_token_expires_at,
        });
      }

      // C. Determine new status
      const newStatus = (action === 'approve' || action === 'confirm') ? 'approved' : 'rejected';

      // D. Update quote status in Supabase (Keep token for idempotency view)
      const { error: updateError } = await supabaseAdmin
        .from('quotes')
        .update({
          status: newStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', quote.id);

      if (updateError) {
        throw new Error(`Error al actualizar estado: ${updateError.message}`);
      }

      // E. Optional Push Notification to Technician/User
      try {
        console.log(`[PUSH NOTIFICATION] Cotización ${quote.quote_number} marcada como ${newStatus} por el cliente.`);
      } catch (pushErr) {
        console.error('Error enviando notificación push:', pushErr);
      }

      return jsonResponse({
        status: newStatus,
        quote_number: quote.quote_number,
      });
    }

    return jsonResponse({ status: 'invalid', message: 'Acción no reconocida.' }, 400);

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
