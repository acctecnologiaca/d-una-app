const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json();
    const { 
      phone, 
      templateName, 
      languageCode = 'es', 
      phoneId,
      documentUrl, 
      documentName, 
      headerVariables = [],
      bodyVariables = [],
      buttonUrlParam
    } = payload;

    // 1. Validation
    if (!phone || !templateName) {
      throw new Error('Missing required fields: phone or templateName');
    }

    // Clean phone number: remove all non-digits
    const cleanPhone = String(phone).replace(/\D/g, '');

    // 2. Auth Check
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');

    // 3. Environment Variables & Phone ID
    const ACCESS_TOKEN = Deno.env.get('WHATSAPP_ACCESS_TOKEN');
    const PHONE_ID = phoneId || '1151175861409459';

    if (!ACCESS_TOKEN) {
      throw new Error('WHATSAPP_ACCESS_TOKEN not configured in Supabase Secrets');
    }

    // Helper to format parameter (supports both named parameters and positional)
    const formatParam = (item: any) => {
      if (typeof item === 'object' && item !== null) {
        const textVal = String(item.text ?? item.value ?? '');
        const paramObj: any = { type: "text", text: textVal };
        if (item.name || item.parameter_name) {
          paramObj.parameter_name = String(item.name || item.parameter_name);
        }
        return paramObj;
      }
      return { type: "text", text: String(item) };
    };

    const formatHeaderParam = (item: any) => {
      let maxLen = 60;
      if (templateName === 'd_una_envio_cotizacion_formal') maxLen = 30;
      else if (templateName === 'd_una_envio_orden_compra') maxLen = 48;
      else if (templateName === 'd_una_envio_reporte_servicio') maxLen = 22;

      if (typeof item === 'object' && item !== null) {
        let textVal = String(item.text ?? item.value ?? '');
        if (textVal.length > maxLen) {
          textVal = textVal.substring(0, maxLen - 3) + '...';
        }
        const paramObj: any = { type: "text", text: textVal };
        if (item.name || item.parameter_name) {
          paramObj.parameter_name = String(item.name || item.parameter_name);
        }
        return paramObj;
      }
      let textVal = String(item);
      if (textVal.length > maxLen) {
        textVal = textVal.substring(0, maxLen - 3) + '...';
      }
      return { type: "text", text: textVal };
    };

    // 4. Construct Meta API Request Components
    const components: any[] = [];

    // Header component
    if (headerVariables && headerVariables.length > 0) {
      components.push({
        type: "header",
        parameters: headerVariables.map(formatHeaderParam)
      });
    } else if (documentUrl) {
      components.push({
        type: "header",
        parameters: [
          {
            type: "document",
            document: {
              link: documentUrl,
              filename: documentName || "documento.pdf"
            }
          }
        ]
      });
    }

    // Body component
    if (bodyVariables && bodyVariables.length > 0) {
      components.push({
        type: "body",
        parameters: bodyVariables.map(formatParam)
      });
    }

    // Dynamic Button component (URL Button)
    if (buttonUrlParam) {
      components.push({
        type: "button",
        sub_type: "url",
        index: "0",
        parameters: [
          {
            type: "text",
            text: String(buttonUrlParam)
          }
        ]
      });
    }

    // Try sending with the components
    const languagesToTry = Array.from(new Set([languageCode, 'es', 'es_LA', 'es_MX', 'es_ES']));
    let lastError: any = null;
    let successfulResult: any = null;

    for (const lang of languagesToTry) {
      const metaBody = {
        messaging_product: "whatsapp",
        to: cleanPhone,
        type: "template",
        template: {
          name: templateName,
          language: { code: lang },
          components: components
        }
      };

      console.log(`Sending WhatsApp to ${cleanPhone} (lang: ${lang}):`, JSON.stringify(metaBody, null, 2));

      const response = await fetch(
        `https://graph.facebook.com/v25.0/${PHONE_ID}/messages`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${ACCESS_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(metaBody),
        }
      );

      const result = await response.json();

      if (response.ok) {
        console.log(`WhatsApp send successful with language "${lang}":`, result);
        successfulResult = result;
        break;
      } else {
        console.error(`Meta API Error with lang "${lang}":`, JSON.stringify(result, null, 2));
        lastError = result;
        // If error is not a translation/language error (132001), stop trying other languages
        if (result.error?.code !== 132001 && !result.error?.message?.includes('translation')) {
          break;
        }
      }
    }

    if (!successfulResult) {
      const details = lastError?.error?.error_data?.details || lastError?.error?.message || 'Failed to send WhatsApp message via Meta API';
      const metaCode = lastError?.error?.code || 'unknown';
      const metaSubcode = lastError?.error?.error_subcode || '';
      throw new Error(`${details} (Meta Code: ${metaCode}${metaSubcode ? ', Subcode: ' + metaSubcode : ''})`);
    }

    return new Response(
      JSON.stringify({ success: true, data: successfulResult }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    console.error('Edge Function Error:', error.message);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }
})
