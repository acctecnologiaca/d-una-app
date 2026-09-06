import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-api-key',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

Deno.serve(async (req) => {
  // Manejo de preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Validación de método
  if (req.method !== 'POST') {
    return jsonResponse({ success: false, error: 'Método no permitido. Use POST.' }, 405);
  }

  // Extracción del API Key desde la cabecera
  const apiKey = req.headers.get('x-api-key')?.trim();
  if (!apiKey) {
    return jsonResponse({ success: false, error: 'Header x-api-key requerido' }, 401);
  }

  // Parseo del cuerpo JSON
  let body: any;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonResponse({ success: false, error: 'Cuerpo de la petición JSON malformado' }, 400);
  }

  // Inicialización del cliente Supabase con privilegios Service Role (bypasa RLS)
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  const action = body?.action || 'sync';

  try {
    // 1. Acción Ping (Prueba de Conexión y Autenticación)
    if (action === 'ping') {
      const { data, error } = await supabaseAdmin
        .from('suppliers')
        .select('id, name')
        .eq('api_key', apiKey)
        .eq('is_active', true)
        .maybeSingle();

      if (error || !data) {
        return jsonResponse({ success: false, error: 'API Key inválida o proveedor inactivo' }, 401);
      }

      return jsonResponse({
        success: true,
        supplier_name: data.name,
        message: 'Conexión exitosa con D-Una',
      });
    }

    // 2. Acción Sync (Sincronización completa o incremental de catálogo, existencias y precios)
    if (action === 'sync') {
      const branches = Array.isArray(body?.branches) ? body.branches : [];
      const products = Array.isArray(body?.products) ? body.products : [];
      const stockPrices = Array.isArray(body?.stock_prices) ? body.stock_prices : [];

      const { data, error } = await supabaseAdmin.rpc('sync_odoo_supplier_data', {
        p_api_key: apiKey,
        p_branches: branches,
        p_products: products,
        p_stock_prices: stockPrices,
      });

      if (error) {
        const isAuthError = error.message?.includes('DUNA_AUTH_ERROR');
        return jsonResponse(
          { success: false, error: error.message || 'Error al ejecutar sincronización' },
          isAuthError ? 401 : 500,
        );
      }

      return jsonResponse(data ?? { success: true });
    }

    // Acción no reconocida
    return jsonResponse({ success: false, error: `Acción desconocida: ${action}` }, 400);

  } catch (err: any) {
    return jsonResponse(
      { success: false, error: err?.message || 'Error interno del servidor' },
      500,
    );
  }
});
