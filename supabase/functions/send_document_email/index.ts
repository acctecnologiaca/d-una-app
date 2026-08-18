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
      documentNumber = null,
      actionToken = null,
      validityDays = 15,
    } = body;

    const rawRecipients = Array.isArray(recipientEmails) 
      ? recipientEmails 
      : String(recipientEmails || '').split(/[,;]/);

    const cleanRecipients = Array.from(
      new Set(
        rawRecipients
          .map((e: string) => String(e).trim().toLowerCase())
          .filter((e: string) => e.length > 0)
      )
    );

    if (cleanRecipients.length === 0) {
      throw new Error('Debe especificar al menos un destinatario válido');
    }

    if (cleanRecipients.length > 3) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Máximo 3 destinatarios permitidos por envío',
        errorCode: 'MAX_RECIPIENTS_EXCEEDED',
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
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
      if (remainingCredits < cleanRecipients.length) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: `No dispones de suficientes créditos (${remainingCredits}) para enviar a ${cleanRecipients.length} destinatarios.`,
          errorCode: 'INSUFFICIENT_CREDITS',
          remainingCredits: remainingCredits,
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
      let fullBodyHtml = '';

      if (isSupplierOrder) {
        fullBodyHtml = emailContent.bodyHtml;
      } else {
        const viewerUrl = actionToken 
          ? `https://d-una.app/quote.html?token=${actionToken}` 
          : 'https://d-una.app';
        
        const formattedUserBody = (emailContent.bodyHtml || '')
          .split('\n')
          .filter((line: string) => line.trim().length > 0)
          .map((line: string) => `<p style="margin: 0 0 12px 0;">${line}</p>`)
          .join('');

        const logoHtml = userContext?.companyLogo ? `
          <td style="width: 120px; vertical-align: middle; padding-right: 20px;">
            <img src="${userContext.companyLogo}" style="max-width: 110px; max-height: 110px; border-radius: 8px; object-fit: contain; display: block;" alt="Logo">
          </td>
        ` : '';

        const contactParts = [];
        if (userContext?.phone) contactParts.push(`📞 ${userContext.phone}`);
        if (userContext?.replyToEmail) contactParts.push(`✉️ <a href="mailto:${userContext.replyToEmail}" style="color: #36618E; text-decoration: none;">${userContext.replyToEmail}</a>`);
        const contactInfoLine = contactParts.join('&nbsp;&bull;&nbsp;');

        fullBodyHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cotización D-UNA</title>
</head>
<body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px 16px; color: #1E293B; line-height: 1.6;">
  <div style="max-width: 640px; margin: 0 auto; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);">
    
    <div style="padding: 28px 24px;">
      <!-- CUERPO DEFINIDO POR EL USUARIO -->
      <div style="font-size: 14px; color: #334155; margin-bottom: 20px;">
        ${formattedUserBody}
      </div>

      <!-- NOTA DE VIGENCIA -->
      <p style="font-size: 13px; color: #64748B; margin: 0 0 24px 0; background-color: #F8FAFC; padding: 10px 14px; border-radius: 8px; border-left: 3px solid #0F172A;">
        📝 <strong>Validez:</strong> Esta cotización es válida durante <strong>${validityDays} días</strong> desde su emisión.
      </p>

      <!-- BOTÓN PRINCIPAL DE ACCIÓN -->
      <div style="text-align: center; margin: 28px 0 14px 0;">
        <a href="${viewerUrl}" style="background-color: #0F172A; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 10px; font-weight: 700; font-size: 14px; display: inline-block; box-shadow: 0 4px 12px rgba(15, 23, 42, 0.25);">
          Ver cotización
        </a>
      </div>

      <!-- RESPALDO CON ENLACE DIRECTO -->
      <p style="font-size: 12px; color: #64748B; text-align: center; margin: 0 0 20px 0; line-height: 1.5;">
        Si el botón no funciona en su gestor de correo, copie y pegue este enlace en su navegador:<br>
        <a href="${viewerUrl}" style="color: #0284C7; word-break: break-all; text-decoration: underline;">${viewerUrl}</a>
      </p>

      <!-- FIRMA COMERCIAL DEL EMISOR -->
      <div style="margin-top: 28px; border-top: 1px solid #E2E8F0; padding-top: 20px;">
        <table cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
          <tr>
            ${logoHtml}
            <td style="vertical-align: middle;">
              <div style="font-size: 15px; font-weight: 700; color: #0F172A;">${userContext?.name || 'Asesor Comercial'}</div>
              ${userContext?.companyName ? `<div style="font-size: 13px; color: #64748B; margin-top: 2px;">${userContext.companyName}</div>` : ''}
              <div style="margin-top: 6px; font-size: 12px; color: #64748B; line-height: 1.6;">
                ${userContext?.phone ? `<div>📞 ${userContext.phone}</div>` : ''}
                ${userContext?.replyToEmail ? `<div style="margin-top: 2px;">✉️ <a href="mailto:${userContext.replyToEmail}" style="color: #0284C7; text-decoration: none;">${userContext.replyToEmail}</a></div>` : ''}
              </div>
            </td>
          </tr>
        </table>
      </div>
    </div>

    <!-- FOOTER INSTITUCIONAL -->
    <div style="background-color: #F1F5F9; padding: 18px 20px; border-top: 1px solid #E2E8F0; text-align: center;">
      <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/sign/app_images/creado_con_d_una.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yNjZhOWZkMS0xYWQyLTQ3OWEtOGNlYS1kYjQzMjA0OGNlMjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhcHBfaW1hZ2VzL2NyZWFkb19jb25fZF91bmEucG5nIiwiaWF0IjoxNzc4MjUwNzI0LCJleHAiOjQ5MzE4NTA3MjR9.sP-lgLmlurZ3oMZxk6IGFwaRQ6_OTKZgMmiZQ0CM4Mc" width="110" style="display: inline-block; opacity: 0.85;" alt="Creado con D-UNA">
    </div>

  </div>
</body>
</html>
        `;
      }

      const mailOptions = {
        from: `"${userContext.name}" <${smtpFrom}>`,
        to: cleanRecipients.join(', '),
        replyTo: userContext.replyToEmail,
        subject: emailContent.subject,
        html: fullBodyHtml,
        envelope: {
          from: smtpUser,
          to: cleanRecipients,
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

      const isSupplierOrder = documentType === 'supplier_order' || documentType === 'oc';
      let fullBodyHtml = '';

      if (isSupplierOrder) {
        fullBodyHtml = emailContent.bodyHtml;
      } else {
        const viewerUrl = actionToken 
          ? `https://d-una.app/quote.html?token=${actionToken}` 
          : 'https://d-una.app';
        
        const formattedUserBody = (emailContent.bodyHtml || '')
          .split('\n')
          .filter((line: string) => line.trim().length > 0)
          .map((line: string) => `<p style="margin: 0 0 12px 0;">${line}</p>`)
          .join('');

        const logoHtml = userContext?.companyLogo ? `
          <td style="width: 120px; vertical-align: middle; padding-right: 20px;">
            <img src="${userContext.companyLogo}" style="max-width: 110px; max-height: 110px; border-radius: 8px; object-fit: contain; display: block;" alt="Logo">
          </td>
        ` : '';

        fullBodyHtml = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cotización D-UNA</title>
</head>
<body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px 16px; color: #1E293B; line-height: 1.6;">
  <div style="max-width: 640px; margin: 0 auto; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);">
    
    <div style="padding: 28px 24px;">
      <!-- CUERPO DEFINIDO POR EL USUARIO -->
      <div style="font-size: 14px; color: #334155; margin-bottom: 20px;">
        ${formattedUserBody}
      </div>

      <!-- NOTA DE VIGENCIA -->
      <p style="font-size: 13px; color: #64748B; margin: 0 0 24px 0; background-color: #F8FAFC; padding: 10px 14px; border-radius: 8px; border-left: 3px solid #0F172A;">
        📝 <strong>Validez:</strong> Esta cotización es válida durante <strong>${validityDays} días</strong> desde su emisión.
      </p>

      <!-- BOTÓN PRINCIPAL DE ACCIÓN -->
      <div style="text-align: center; margin: 28px 0 14px 0;">
        <a href="${viewerUrl}" style="background-color: #0F172A; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 10px; font-weight: 700; font-size: 14px; display: inline-block; box-shadow: 0 4px 12px rgba(15, 23, 42, 0.25);">
          Ver cotización
        </a>
      </div>

      <!-- RESPALDO CON ENLACE DIRECTO -->
      <p style="font-size: 12px; color: #64748B; text-align: center; margin: 0 0 20px 0; line-height: 1.5;">
        Si el botón no funciona en su gestor de correo, copie y pegue este enlace en su navegador:<br>
        <a href="${viewerUrl}" style="color: #0284C7; word-break: break-all; text-decoration: underline;">${viewerUrl}</a>
      </p>

      <!-- FIRMA COMERCIAL DEL EMISOR -->
      <div style="margin-top: 28px; border-top: 1px solid #E2E8F0; padding-top: 20px;">
        <table cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
          <tr>
            ${logoHtml}
            <td style="vertical-align: middle;">
              <div style="font-size: 15px; font-weight: 700; color: #0F172A;">${userContext?.name || 'Asesor Comercial'}</div>
              ${userContext?.companyName ? `<div style="font-size: 13px; color: #64748B; margin-top: 2px;">${userContext.companyName}</div>` : ''}
              <div style="margin-top: 6px; font-size: 12px; color: #64748B; line-height: 1.6;">
                ${userContext?.phone ? `<div>📞 ${userContext.phone}</div>` : ''}
                ${userContext?.replyToEmail ? `<div style="margin-top: 2px;">✉️ <a href="mailto:${userContext.replyToEmail}" style="color: #0284C7; text-decoration: none;">${userContext.replyToEmail}</a></div>` : ''}
              </div>
            </td>
          </tr>
        </table>
      </div>
    </div>

    <!-- FOOTER INSTITUCIONAL -->
    <div style="background-color: #F1F5F9; padding: 18px 20px; border-top: 1px solid #E2E8F0; text-align: center;">
      <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/sign/app_images/creado_con_d_una.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yNjZhOWZkMS0xYWQyLTQ3OWEtOGNlYS1kYjQzMjA0OGNlMjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhcHBfaW1hZ2VzL2NyZWFkb19jb25fZF91bmEucG5nIiwiaWF0IjoxNzc4MjUwNzI0LCJleHAiOjQ5MzE4NTA3MjR9.sP-lgLmlurZ3oMZxk6IGFwaRQ6_OTKZgMmiZQ0CM4Mc" width="110" style="display: inline-block; opacity: 0.85;" alt="Creado con D-UNA">
    </div>

  </div>
</body>
</html>
        `;
      }

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${resendApiKey}`,
        },
        body: JSON.stringify({
          from: `"${userContext.name}" <notificaciones@tu-dominio-verificado.com>`, 
          to: cleanRecipients,
          reply_to: userContext.replyToEmail,
          subject: emailContent.subject,
          html: fullBodyHtml,
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
      for (const _recipient of cleanRecipients) {
        const { data: updatedStatus, error: consumeError } = await supabaseAdmin.rpc(
          'consume_user_credit',
          {
            p_user_id: userId,
            p_doc_type: documentType,
            p_channel: 'email',
            p_ref_id: documentId,
            p_doc_number: documentNumber,
          }
        );

        if (consumeError) {
          console.error('Warning: Failed to consume credit:', consumeError);
        } else if (updatedStatus) {
          newRemaining = updatedStatus.remainingCredits;
        }
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