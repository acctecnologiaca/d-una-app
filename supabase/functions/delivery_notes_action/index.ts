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
    // 1. Fetch delivery note by action_token
    const { data: note, error: noteError } = await supabaseAdmin
      .from('delivery_notes')
      .select(`
        *,
        clients (*),
        contacts (*),
        shipping_companies (*),
        delivery_note_items (
          *,
          delivery_note_serials (*)
        ),
        delivery_note_observations (*)
      `)
      .eq('action_token', token)
      .maybeSingle();

    if (noteError || !note) {
      return jsonResponse({
        status: 'invalid',
        message: 'Este enlace ya no es válido o la nota de entrega no existe.',
      });
    }

    // 2. Fetch issuer profile data
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', note.user_id)
      .maybeSingle();

    const isExpired = note.action_token_expires_at
      ? new Date().getTime() > new Date(note.action_token_expires_at).getTime()
      : false;

    // Handle 'get_details' action
    if (action === 'get_details' || action === 'view' || action === 'get') {
      // Automatic telemetry: update to 'opened' and opened_at timestamp
      if (note.status === 'sent' || note.status === 'resent') {
        try {
          await supabaseAdmin
            .from('delivery_notes')
            .update({
              status: 'opened',
              opened_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq('id', note.id);
          note.status = 'opened';
        } catch (statusUpdateErr) {
          console.error('Error actualizando estatus a opened:', statusUpdateErr);
        }
      }

      return jsonResponse({
        status: 'success',
        is_expired: isExpired,
        delivery_note: {
          id: note.id,
          delivery_note_number: note.delivery_note_number || 'NE-PENDIENTE',
          status: note.status,
          date: note.date,
          delivery_date: note.delivery_date,
          delivery_type: note.delivery_type || 'direct_delivery',
          shipping_company_name: note.shipping_companies?.name,
          tracking_number: note.tracking_number,
          recipient_address: note.recipient_address,
          recipient_city: note.recipient_city,
          recipient_state: note.recipient_state,
          delivery_instructions: note.delivery_instructions,
          client_po_number: note.client_po_number,
          tag: note.tag,
          notes: note.notes,
          received_by_name: note.received_by_name,
          received_by_id: note.received_by_id,
          received_by_phone: note.received_by_phone,
          receiver_relationship: note.receiver_relationship,
          received_at: note.received_at,
          signature_data: note.signature_data,
          subtotal: note.subtotal,
          tax_rate: note.tax_rate,
          tax_amount: note.tax_amount,
          total: note.total,
          is_dropshipping: note.is_dropshipping,
          pdf_url: note.pdf_url,
          client: note.clients ? {
            name: note.clients.name || 'Cliente',
            tax_id: note.clients.tax_id || note.clients.identification_id || '-',
            phone: note.contacts?.phone || note.clients.phone || '-',
            email: note.contacts?.email || note.clients.email || '-',
            contact_name: note.contacts?.name || note.clients.contact_name || '-',
            type: note.clients.type || 'person',
            address: note.clients.address || '-',
            city: note.clients.city || '-',
            state: note.clients.state || '-',
            country: note.clients.country || '-',
          } : null,
          contact: note.contacts ? {
            name: note.contacts.name,
            phone: note.contacts.phone,
            email: note.contacts.email,
          } : null,
          items: (note.delivery_note_items || [])
            .sort((a: any, b: any) => (a.order_index ?? 0) - (b.order_index ?? 0))
            .map((item: any) => ({
              id: item.id,
              name: item.name,
              brand: item.brand,
              model: item.model,
              uom: item.uom,
              description: item.description,
              quantity: item.quantity,
              unit_price: item.unit_price,
              tax_rate: item.tax_rate,
              tax_amount: item.tax_amount,
              total_price: item.total_price,
              warranty_time: item.warranty_time,
              warranty_unit: item.warranty_unit,
              source_type: item.source_type,
              requires_serials: item.requires_serials,
              is_dropshipping: item.is_dropshipping,
              serials: (item.delivery_note_serials || []).map((s: any) => s.serial_number),
            })),
          observations: (note.delivery_note_observations || [])
            .sort((a: any, b: any) => (a.order_index ?? 0) - (b.order_index ?? 0))
            .map((o: any) => ({
              description: o.description,
            })),
        },
        issuer: profile ? {
          company_name: profile.company_name || null,
          user_name: `${profile.first_name || ''} ${profile.last_name || ''}`.trim() || profile.full_name || 'Despachador Responsable',
          phone: profile.phone || '-',
          email: profile.email || '-',
          tax_id: profile.company_rif || profile.company_id || profile.tax_id || profile.national_id || profile.identification_id || '-',
          address: profile.company_address || profile.address || '-',
          city: profile.company_city || profile.city || '-',
          state: profile.company_state || profile.state || '-',
          country: profile.company_country || profile.country || '-',
          logo_url: profile.company_logo_url || profile.logo_url || null,
          currency_code: profile.currency_code || 'USD',
        } : null,
      });
    }

    // Handle 'confirm_reception' action
    if (action === 'confirm_reception' || action === 'sign' || action === 'finalize') {
      if (note.status === 'finalized') {
        return jsonResponse({
          status: 'already_processed',
          delivery_note_number: note.delivery_note_number,
          current_status: note.status,
          received_by_name: note.received_by_name,
          received_at: note.received_at,
          message: 'Esta nota de entrega ya fue confirmada y firmada como recibida.',
        });
      }

      if (note.status === 'cancelled') {
        return jsonResponse({
          status: 'cancelled',
          delivery_note_number: note.delivery_note_number,
          message: 'Esta nota de entrega se encuentra cancelada.',
        }, 400);
      }

      const receivedByName: string | null = body?.received_by_name || url.searchParams.get('received_by_name');
      const receivedById: string | null = body?.received_by_id || url.searchParams.get('received_by_id');
      const receivedByPhone: string | null = body?.received_by_phone || url.searchParams.get('received_by_phone') || null;
      const receiverRelationship: string | null = body?.receiver_relationship || url.searchParams.get('receiver_relationship') || null;
      const signatureData: string | null = body?.signature_data || null;

      if (!receivedByName || receivedByName.trim().length === 0) {
        return jsonResponse({
          status: 'error',
          message: 'El nombre de la persona que recibe es obligatorio.',
        }, 400);
      }

      if (!receivedById || receivedById.trim().length === 0) {
        return jsonResponse({
          status: 'error',
          message: 'El documento de identidad o cédula es obligatorio.',
        }, 400);
      }

      const updateData: Record<string, any> = {
        status: 'finalized',
        received_by_name: receivedByName.trim(),
        received_by_id: receivedById.trim(),
        received_by_phone: receivedByPhone?.trim() || null,
        receiver_relationship: receiverRelationship?.trim() || null,
        received_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      if (signatureData && signatureData.trim().length > 0) {
        updateData.signature_data = signatureData.trim();
      }

      const { error: updateError } = await supabaseAdmin
        .from('delivery_notes')
        .update(updateData)
        .eq('id', note.id);

      if (updateError) {
        throw new Error(`Error al confirmar recepción: ${updateError.message}`);
      }

      return jsonResponse({
        status: 'success',
        delivery_note_number: note.delivery_note_number,
        message: 'Entrega confirmada y registrada exitosamente.',
        received_by_name: updateData.received_by_name,
        received_at: updateData.received_at,
      });
    }

    return jsonResponse({ status: 'invalid', message: `Acción '${action}' no reconocida.` }, 400);

  } catch (error: any) {
    console.error('Error en delivery_notes_action function:', error);
    return jsonResponse({
      status: 'error',
      message: 'Ocurrió un error inesperado al procesar la nota de entrega.',
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
