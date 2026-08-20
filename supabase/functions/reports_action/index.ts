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
  let body: any = null;

  if (req.method === 'POST') {
    try {
      body = await req.json();
      if (body?.token) token = body.token;
      if (body?.action) action = body.action;
    } catch (_e) {
      // Fallback
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
    // 1. Fetch service report by action_token
    const { data: report, error: reportError } = await supabaseAdmin
      .from('service_reports')
      .select(`
        *,
        clients (*),
        contacts (*),
        categories (*),
        collaborators!advisor_id (full_name, phone, email),
        service_report_items_products (*),
        service_report_items_services (*),
        service_report_conditions (*)
      `)
      .eq('action_token', token)
      .maybeSingle();

    if (reportError || !report) {
      return jsonResponse({
        status: 'invalid',
        message: 'Este enlace ya no es válido o el reporte de servicio no existe.',
      });
    }

    // 2. Fetch issuer profile data
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', report.user_id)
      .maybeSingle();

    const isExpired = report.action_token_expires_at
      ? new Date().getTime() > new Date(report.action_token_expires_at).getTime()
      : false;

    // Handle 'get_details' action
    if (action === 'get_details' || action === 'view' || action === 'get') {
      // Automatic telemetry: update to 'opened' and opened_at timestamp
      if (report.status === 'sent' || report.status === 'resent') {
        try {
          await supabaseAdmin
            .from('service_reports')
            .update({
              status: 'opened',
              opened_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq('id', report.id);
          report.status = 'opened';
        } catch (statusUpdateErr) {
          console.error('Error actualizando estatus a opened:', statusUpdateErr);
        }
      }

      return jsonResponse({
        status: 'success',
        is_expired: isExpired,
        report: {
          id: report.id,
          report_number: report.report_number || 'RS-PENDIENTE',
          status: report.status,
          intervention_type: report.intervention_type || 'corrective',
          category_name: report.categories?.name,
          advisor_name: report.collaborators?.full_name,
          request_description: report.request_description,
          work_description: report.work_description,
          recommendations: report.recommendations,
          service_date: report.service_date,
          start_time: report.start_time,
          end_time: report.end_time,
          duration_minutes: report.duration_minutes,
          subtotal: report.subtotal,
          tax_amount: report.tax_amount,
          total: report.total,
          notes: report.notes,
          pdf_url: report.pdf_url,
          client: report.clients ? {
            name: report.clients.name,
            tax_id: report.clients.tax_id,
            address: report.clients.address,
            phone: report.clients.phone,
            email: report.clients.email,
          } : null,
          contact: report.contacts ? {
            name: report.contacts.name,
            phone: report.contacts.phone,
            email: report.contacts.email,
          } : null,
          products: (report.service_report_items_products || []).map((p: any) => ({
            name: p.name,
            brand: p.brand,
            model: p.model,
            uom: p.uom,
            quantity: p.quantity,
            unit_price: p.unit_price,
            total_price: p.total_price,
            warranty_time: p.warranty_time,
            warranty_unit: p.warranty_unit,
          })),
          services: (report.service_report_items_services || []).map((s: any) => ({
            name: s.name,
            description: s.description,
            quantity: s.quantity,
            rate_symbol: s.rate_symbol,
            unit_price: s.unit_price,
            total_price: s.total_price,
            warranty_time: s.warranty_time,
            warranty_unit: s.warranty_unit,
          })),
          conditions: (report.service_report_conditions || [])
            .sort((a: any, b: any) => (a.order_index ?? 0) - (b.order_index ?? 0))
            .map((c: any) => ({
              description: c.description,
            })),
        },
        issuer: profile ? {
          company_name: profile.company_name,
          full_name: profile.full_name,
          logo_url: profile.logo_url,
          tax_id: profile.tax_id,
          address: profile.address,
          phone: profile.phone,
          email: profile.email,
          currency_code: profile.currency_code || 'USD',
        } : null,
      });
    }

    return jsonResponse({ status: 'invalid', message: `Acción '${action}' no reconocida.` }, 400);

  } catch (error: any) {
    console.error('Error en reports_action function:', error);
    return jsonResponse({
      status: 'error',
      message: 'Ocurrió un error inesperado al procesar el reporte de servicio.',
      details: error.message,
    }, 500);
  }
});

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
