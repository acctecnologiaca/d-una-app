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

  // Handle JSON body if POST
  if (req.method === 'POST') {
    try {
      body = await req.json();
      if (body?.token) token = body.token;
      if (body?.action) action = body.action;
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
    // 1. Fetch supplier order by action_token with joined relations
    const { data: order, error: orderError } = await supabaseAdmin
      .from('supplier_orders')
      .select(`
        *,
        suppliers (*),
        supplier_branches (*),
        shipping_methods (
          *,
          shipping_companies (*)
        ),
        collaborators (*),
        supplier_order_items (
          *,
          supplier_branch_stock (
            supplier_branches (name)
          )
        )
      `)
      .eq('action_token', token)
      .maybeSingle();

    if (orderError || !order) {
      return jsonResponse({
        status: 'invalid',
        message: 'Este enlace ya no es válido o la orden de compra no existe.',
      });
    }

    // 2. Fetch buyer profile data
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', order.user_id)
      .maybeSingle();

    // Check expiration based on action_token_expires_at
    const isExpired = order.action_token_expires_at
      ? new Date().getTime() > new Date(order.action_token_expires_at).getTime()
      : false;

    // Handle 'get_details' action
    if (action === 'get_details' || action === 'view' || action === 'get') {
      if (isExpired) {
        // Si ha expirado y aún está en estado previo a resolución, marcar como expired
        if (
          order.status === 'sent' ||
          order.status === 'resent' ||
          order.status === 'opened'
        ) {
          const { error: updateExpiredErr } = await supabaseAdmin
            .from('supplier_orders')
            .update({
              status: 'expired',
              updated_at: new Date().toISOString(),
            })
            .eq('id', order.id);

          if (!updateExpiredErr) {
            order.status = 'expired';
          }
        }
      } else {
        // Telemetry: Transition to 'opened' if viewing within validity window
        if (order.status === 'sent' || order.status === 'resent') {
          const { error: updateOpenedErr } = await supabaseAdmin
            .from('supplier_orders')
            .update({
              status: 'opened',
              updated_at: new Date().toISOString(),
            })
            .eq('id', order.id);

          if (!updateOpenedErr) {
            order.status = 'opened';
          } else {
            console.error('Error actualizando estatus a opened:', updateOpenedErr);
          }
        }
      }

      // Format shipping method address details
      const sm = order.shipping_methods;
      let shippingAddress = '-';
      const addressParts: string[] = [];

      if (sm) {
        if (sm.use_main_address) {
          const mainAddr = profile?.company_address || profile?.main_address || profile?.address;
          if (mainAddr && mainAddr.trim().length > 0) {
            addressParts.push(mainAddr.trim());
          }
        } else {
          if (sm.address && sm.address.trim().length > 0) addressParts.push(sm.address.trim());
          if (sm.city && sm.city.trim().length > 0) addressParts.push(sm.city.trim());
          if (sm.state && sm.state.trim().length > 0) addressParts.push(sm.state.trim());
          if (sm.country && sm.country.trim().length > 0) addressParts.push(sm.country.trim());
        }
      }
      if (addressParts.length > 0) {
        shippingAddress = addressParts.join(', ');
      }

      const shippingCompanyName =
        sm?.shipping_companies?.name ||
        sm?.shipping_companies?.legal_name ||
        sm?.company?.name ||
        sm?.company?.legal_name ||
        '-';

      const deliveryOption = sm?.delivery_option || 'Por definir';
      const isPersonalPickup =
        deliveryOption.toLowerCase().includes('retiro en persona') ||
        deliveryOption.toLowerCase().includes('retiro personal');

      const isBranchDelivery = deliveryOption.toLowerCase().includes('sucursal');

      const hasCompany = Boolean(profile?.company_name && profile.company_name.trim().length > 0);
      const buyerDisplayName = hasCompany
        ? profile.company_name.trim()
        : `${profile?.first_name || ''} ${profile?.last_name || ''}`.trim() || 'Comprador';
      const buyerContactName = `${profile?.first_name || ''} ${profile?.last_name || ''}`.trim() || '-';
      const buyerTaxId = hasCompany
        ? (profile?.company_rif || profile?.company_id || profile?.tax_id || '-')
        : (profile?.national_id || profile?.identification_id || '-');
      const buyerAddress = hasCompany
        ? (profile?.company_address || '-')
        : ([profile?.main_address, profile?.main_city].filter(Boolean).join(', ') || '-');

      return jsonResponse({
        status: 'success',
        is_expired: isExpired,
        order: {
          id: order.id,
          order_number: order.order_number || 'S/N',
          status: order.status,
          date: order.date,
          payment_method: order.payment_method || 'Por definir',
          subtotal: Number(order.subtotal || 0),
          tax: Number(order.tax || 0),
          total: Number(order.total || 0),
          invoice_photo_url: order.invoice_photo_url,
          expires_at: order.action_token_expires_at,
          supplier_feedback: order.supplier_feedback || null,
          supplier_feedback_at: order.supplier_feedback_at || null,
        },
        buyer: {
          display_name: buyerDisplayName,
          has_company: hasCompany,
          tax_id: buyerTaxId,
          contact_name: buyerContactName,
          phone: profile?.phone || '-',
          email: profile?.email || '-',
          address: buyerAddress,
          city: profile?.main_city || profile?.company_city || '-',
          logo_url: profile?.company_logo_url || null,
        },
        supplier: {
          name: order.suppliers?.name || 'Proveedor',
          legal_name: order.suppliers?.legal_name || order.suppliers?.name || 'Proveedor',
          tax_id: order.suppliers?.tax_id || order.suppliers?.rif || '-',
          phone: order.suppliers?.phone || '-',
          email: order.suppliers?.email || '-',
        },
        shipping: {
          branch_name: order.supplier_branches?.name || 'Sucursal Principal',
          company_name: shippingCompanyName,
          delivery_option: deliveryOption,
          is_branch_delivery: isBranchDelivery,
          branch_code: sm?.branch_code || null,
          address: shippingAddress,
          is_personal_pickup: isPersonalPickup,
          receiver_name: order.collaborators?.full_name || order.receiver_name || '-',
          receiver_id: order.collaborators?.identification_id || null,
          receiver_phone: order.collaborators?.phone || null,
        },
        items: (order.supplier_order_items || []).map((item: any) => {
          const itemBranchName = item.supplier_branch_stock?.supplier_branches?.name || order.supplier_branches?.name || 'Sucursal Principal';
          return {
            name: item.name,
            brand: item.brand,
            model: item.model,
            uom: item.uom || 'Ud',
            quantity: Number(item.quantity || 0),
            unit_price: Number(item.unit_price || 0),
            total_price: Number((item.quantity || 0) * (item.unit_price || 0)),
            branch_name: itemBranchName,
          };
        }),
      });
    }

    // Handle 'approve' or 'confirm' or 'reject' actions
    if (action === 'approve' || action === 'confirm' || action === 'reject') {
      if (order.status === 'approved' || order.status === 'rejected') {
        return jsonResponse({
          status: 'already_processed',
          order_number: order.order_number,
          current_status: order.status,
        });
      }

      if (isExpired) {
        return jsonResponse({
          status: 'expired',
          order_number: order.order_number,
          expires_at: order.action_token_expires_at,
        });
      }

      const isApprove = action === 'approve' || action === 'confirm';
      const newStatus = isApprove ? 'approved' : 'rejected';

      const rawFeedback: string | null =
        body?.feedback ||
        body?.reason ||
        body?.notes ||
        url.searchParams.get('feedback') ||
        url.searchParams.get('reason') ||
        null;

      const trimmedFeedback = rawFeedback ? rawFeedback.trim().substring(0, 500) : null;

      const updateData: Record<string, any> = {
        status: newStatus,
        updated_at: new Date().toISOString(),
      };

      if (trimmedFeedback && trimmedFeedback.length > 0) {
        updateData.supplier_feedback = trimmedFeedback;
        updateData.supplier_feedback_at = new Date().toISOString();
      }

      const { error: updateError } = await supabaseAdmin
        .from('supplier_orders')
        .update(updateData)
        .eq('id', order.id);

      if (updateError) {
        throw new Error(`Error al actualizar estado: ${updateError.message}`);
      }

      return jsonResponse({
        status: newStatus,
        order_number: order.order_number,
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
