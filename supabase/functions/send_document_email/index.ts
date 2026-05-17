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
      emailContent
    } = body;

    // Verify required fields
    if (!documentBase64 || !recipientEmails || !emailContent) {
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
    // RATE LIMITING: Validate before sending
    // ============================================================
    const MAX_RECIPIENTS_PER_SEND = 3;
    const COOLDOWN_SECONDS = 60;

    // Read system default from env var
    const systemDefault = parseInt(Deno.env.get('DEFAULT_DAILY_EMAIL_LIMIT') || '10');

    // Read user's extra credits from profiles
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('daily_extra_email_credits')
      .eq('id', userId)
      .single();

    if (profileError) {
      console.error('Error reading profile:', profileError);
    }

    const extraCredits = profile?.daily_extra_email_credits ?? 0;
    const MAX_CREDITS_PER_DAY = systemDefault + extraCredits;

    console.log(`Credits config: base=${systemDefault}, extra=${extraCredits}, total=${MAX_CREDITS_PER_DAY}`);

    // 1. Validate max recipients per send
    if (!Array.isArray(recipientEmails) || recipientEmails.length > MAX_RECIPIENTS_PER_SEND) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: `Máximo ${MAX_RECIPIENTS_PER_SEND} destinatarios por envío`,
        errorCode: 'MAX_RECIPIENTS_EXCEEDED'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 429,
      });
    }

    // 2. Check daily credit usage (last 24 hours)
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    
    const { data: usageLogs, error: usageError } = await supabaseAdmin
      .from('email_logs')
      .select('recipient_count, created_at')
      .eq('user_id', userId)
      .gte('created_at', twentyFourHoursAgo)
      .order('created_at', { ascending: false });

    if (usageError) {
      console.error('Error checking usage:', usageError);
      throw new Error('Could not verify sending limits');
    }

    const usedCredits = (usageLogs || []).reduce((sum: number, log: { recipient_count: number }) => sum + log.recipient_count, 0);
    const remainingCredits = MAX_CREDITS_PER_DAY - usedCredits;

    console.log(`Rate limit check: used=${usedCredits}, remaining=${remainingCredits}, requested=${recipientEmails.length}`);

    if (recipientEmails.length > remainingCredits) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: `Has alcanzado el límite de envíos diarios. Créditos restantes: ${remainingCredits}`,
        errorCode: 'DAILY_LIMIT_EXCEEDED',
        remainingCredits: remainingCredits,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 429,
      });
    }

    // 3. Check cooldown (last send must be > 60 seconds ago)
    if (usageLogs && usageLogs.length > 0) {
      const lastSendTime = new Date(usageLogs[0].created_at).getTime();
      const secondsSinceLastSend = (Date.now() - lastSendTime) / 1000;
      
      if (secondsSinceLastSend < COOLDOWN_SECONDS) {
        const waitSeconds = Math.ceil(COOLDOWN_SECONDS - secondsSinceLastSend);
        return new Response(JSON.stringify({ 
          success: false, 
          error: `Debes esperar ${waitSeconds} segundos antes de enviar otro correo`,
          errorCode: 'COOLDOWN_ACTIVE',
          waitSeconds: waitSeconds,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 429,
        });
      }
    }
    // ============================================================
    // END RATE LIMITING
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

      // Construct HTML Body with Automated Signature
      const fullBodyHtml = `
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
        attachments: [
          {
            filename: fileName || 'documento.pdf',
            content: documentBase64,
            encoding: 'base64',
          },
        ],
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
          attachments: [
            {
              filename: fileName || 'documento.pdf',
              content: documentBase64,
            },
          ],
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
    // LOG SUCCESSFUL SEND (after email is sent, before response)
    // ============================================================
    const { error: logError } = await supabaseAdmin
      .from('email_logs')
      .insert({
        user_id: userId,
        recipient_count: recipientEmails.length,
        document_type: body.documentType || null,
      });

    if (logError) {
      console.error('Warning: Failed to log email send:', logError);
      // Don't fail the request - the email was already sent successfully
    }
    // ============================================================

    // Calculate remaining credits after this send
    const updatedRemainingCredits = remainingCredits - recipientEmails.length;

    return new Response(JSON.stringify({
      success: true,
      message: 'Email sent successfully',
      remainingCredits: updatedRemainingCredits,
      totalCredits: MAX_CREDITS_PER_DAY,
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