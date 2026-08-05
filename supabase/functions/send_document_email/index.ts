import { createTransport } from "npm:nodemailer";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json();
    console.log('--- Payload Recibido ---');
    console.log(JSON.stringify(body, null, 2));

    const { 
      documentBase64, 
      fileName, 
      recipientEmails, 
      userContext, 
      emailContent,
      documentType = 'quote',
      documentId = null,
    } = body;

    // Verify required fields
    if (!recipientEmails || !emailContent) {
      console.error('Error: Faltan campos obligatorios');
      throw new Error('Missing required fields in payload');
    }

    // ============================================================
    // AUTHENTICATION: Extract user from JWT
    // ============================================================
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing Authorization header');
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    
    if (userError || !user) {
      throw new Error('Invalid or expired authentication token');
    }

    const userId = user.id;

    // ============================================================
    // RATE LIMITING & CREDITS VALIDATION
    // ============================================================
    const COOLDOWN_SECONDS = 20;
    const isExemptFromCredits = documentType === 'supplier_order' || documentType === 'oc';
    let remainingCredits = 0;

    // 1. Check credits status for non-exempt documents
    if (!isExemptFromCredits) {
      const { data: creditStatus, error: rpcError } = await supabaseAdmin
        .rpc('get_user_credit_status', { p_user_id: userId });

      if (rpcError || !creditStatus) {
        console.error('Error checking credit status:', rpcError);
        throw new Error('Could not verify credit status');
      }

      remainingCredits = creditStatus.remainingCredits || 0;
      if (remainingCredits <= 0) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: `Has alcanzado el límite de créditos de tu ciclo.`,
          errorCode: 'INSUFFICIENT_CREDITS',
          remainingCredits: 0,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 429,
        });
      }
    }

    // 2. Check 20s cooldown specifically for the SAME document (documentId)
    if (documentId) {
      const { data: recentSends } = await supabaseAdmin
        .from('credit_transactions')
        .select('created_at')
        .eq('user_id', userId)
        .eq('reference_id', documentId)
        .order('created_at', { ascending: false })
        .limit(1);

      if (recentSends && recentSends.length > 0) {
        const lastSendTime = new Date(recentSends[0].created_at).getTime();
        const secondsSinceLastSend = (Date.now() - lastSendTime) / 1000;

        if (secondsSinceLastSend < COOLDOWN_SECONDS) {
          const waitSeconds = Math.ceil(COOLDOWN_SECONDS - secondsSinceLastSend);
          return new Response(JSON.stringify({ 
            success: false, 
            error: `Debes esperar ${waitSeconds} segundos antes de volver a enviar este documento.`,
            errorCode: 'COOLDOWN_ACTIVE',
            waitSeconds: waitSeconds,
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 429,
          });
        }
      }
    }
    // ============================================================
    // END RATE LIMITING & CREDITS VALIDATION
    // ============================================================

    const provider = Deno.env.get('MAIL_PROVIDER') || 'GOOGLE';
    console.log('Proveedor de correo:', provider);

    if (provider === 'GOOGLE') {
      const smtpHost = Deno.env.get('SMTP_HOST') || 'smtp.gmail.com';
      const smtpPort = parseInt(Deno.env.get('SMTP_PORT') || '465');
      const smtpUser = Deno.env.get('SMTP_USER');
      const smtpPass = Deno.env.get('SMTP_PASS');
      const smtpFrom = Deno.env.get('SMTP_FROM') || smtpUser;

      console.log('Configuración SMTP:', { 
        host: smtpHost, 
        port: smtpPort, 
        user: smtpUser ? 'Configurado' : 'FALTANTE',
        from: smtpFrom
      });

      if (!smtpUser || !smtpPass) {
        throw new Error('SMTP credentials not configured in environment variables (SMTP_USER or SMTP_PASS)');
      }

      const transporter = createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpPort === 465,
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
        tls: {
          rejectUnauthorized: false,
        },
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 10000,
      });

      // Construct HTML Body: para Órdenes de Compra (supplier_order / oc) se usa directamente bodyHtml sin firma duplicada
      const isSupplierOrder = documentType === 'supplier_order' || documentType === 'oc';
      const fullBodyHtml = isSupplierOrder 
        ? emailContent.bodyHtml
        : `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; line-height: 1.6;">
          <div style="margin-bottom: 30px;">
            ${emailContent.bodyHtml.replace(/\n/g, '<br>')}
          </div>
          
          <div style="margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
            <table cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
              <tr>
                ${userContext.companyLogo ? `
                <td style="width: 120px; vertical-align: top; padding-right: 15px;">
                  <img src="${userContext.companyLogo}" width="120" height="120" style="border-radius: 12px; object-fit: contain;" alt="Logo">
                </td>` : ''}
                <td style="vertical-align: middle;">
                  <div style="font-size: 16px; font-weight: bold; color: #1a1a1a;">${userContext.name}</div>
                  ${userContext.companyName ? `<div style="font-size: 14px; color: #666;">${userContext.companyName}</div>` : ''}
                  <div style="margin-top: 5px; font-size: 13px;">
                    ${userContext.phone ? `<span style="color: #666;">Tel: </span><span style="color: #333;">${userContext.phone}</span><br>` : ''}
                    <span style="color: #666;">Email: </span><a href="mailto:${userContext.replyToEmail}" style="color: #007bff; text-decoration: none;">${userContext.replyToEmail}</a>
                  </div>
                </td>
              </tr>
            </table>
          </div>

          <div style="margin-top: 40px; text-align: center;">
            <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/sign/app_images/creado_con_d_una.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yNjZhOWZkMS0xYWQyLTQ3OWEtOGNlYS1kYjQzMjA0OGNlMjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhcHBfaW1hZ2VzL2NyZWFkb19jb25fZF91bmEucG5nIiwiaWF0IjoxNzc4MjUwNzI0LCJleHAiOjQ5MzE4NTA3MjR9.sP-lgLmlurZ3oMZxk6IGFwaRQ6_OTKZgMmiZQ0CM4Mc" width="100" style="opacity: 0.7; display: inline-block;" alt="Creado con d'una">
          </div>
        </div>
      `;

      const mailOptions = {
        from: `"${userContext.name}" <${smtpFrom}>`,
        to: recipientEmails.join(', '),
        replyTo: userContext.replyToEmail,
        subject: emailContent.subject,
        html: fullBodyHtml,
        envelope: {
          from: smtpUser,
          to: recipientEmails,
        },
        attachments: documentBase64
          ? [
              {
                filename: fileName || 'documento.pdf',
                content: documentBase64,
                encoding: 'base64',
              },
            ]
          : [],
      };

      const info = await transporter.sendMail(mailOptions);
      console.log('Email sent successfully via GOOGLE:', info.messageId);

    } else if (provider === 'RESEND') {
      const resendApiKey = Deno.env.get('RESEND_API_KEY');
      if (!resendApiKey) {
        throw new Error('RESEND_API_KEY not configured');
      }

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${resendApiKey}`,
        },
        body: JSON.stringify({
          from: `"${userContext.name}" <notificaciones@tu-dominio-verificado.com>`, 
          to: recipientEmails,
          reply_to: userContext.replyToEmail,
          subject: emailContent.subject,
          html: emailContent.bodyHtml,
          attachments: documentBase64
            ? [
                {
                  filename: fileName || 'documento.pdf',
                  content: documentBase64,
                },
              ]
            : undefined,
        }),
      });

      if (!res.ok) {
        const errorData = await res.text();
        throw new Error(`Resend API error: ${errorData}`);
      }
      
      const data = await res.json();
      console.log('Email sent successfully via RESEND:', data.id);
    } else {
      throw new Error(`Unsupported MAIL_PROVIDER: ${provider}`);
    }

    // ============================================================
    // LOG & CONSUME CREDIT AFTER SUCCESSFUL SEND
    // ============================================================
    let newRemaining = remainingCredits;

    if (!isExemptFromCredits) {
      const { data: updatedStatus, error: consumeError } = await supabaseAdmin.rpc(
        'consume_user_credit',
        {
          p_user_id: userId,
          p_doc_type: documentType,
          p_channel: 'email',
          p_ref_id: documentId,
        }
      );

      if (consumeError) {
        console.error('Warning: Failed to consume credit:', consumeError);
      } else {
        newRemaining = updatedStatus?.remainingCredits ?? (remainingCredits - 1);
      }
    } else if (documentId) {
      // Para documentos exentos (OCs), se inserta un registro con monto 0 
      // para habilitar el control de cooldown de 20s por el mismo documentId.
      await supabaseAdmin.from('credit_transactions').insert({
        user_id: userId,
        transaction_type: 'email_sent',
        amount: 0,
        reference_type: documentType,
        reference_id: documentId,
        description: `Envío de ${documentType} vía email (Exento)`,
      });
    }
    // ============================================================

    return new Response(JSON.stringify({
      success: true,
      message: 'Email sent successfully',
      remainingCredits: isExemptFromCredits ? null : newRemaining,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('--- ERROR EN EDGE FUNCTION ---');
    console.error(errorMessage);
    if (error instanceof Error && error.stack) {
      console.error(error.stack);
    }
    return new Response(JSON.stringify({ success: false, error: errorMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})