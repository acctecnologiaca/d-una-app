import { createTransport } from "npm:nodemailer";

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
          // No cerrar la conexión prematuramente
          rejectUnauthorized: false,
        },
        // Aumentar el tiempo de espera
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
                <td style="width: 80px; vertical-align: top; padding-right: 15px;">
                  <img src="${userContext.companyLogo}" width="70" height="70" style="border-radius: 12px; object-fit: contain;" alt="Logo">
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
        </div>
      `;

      const mailOptions = {
        from: `"${userContext.name}" <${smtpFrom}>`,
        to: recipientEmails.join(', '),
        replyTo: userContext.replyToEmail,
        subject: emailContent.subject,
        html: fullBodyHtml,
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

      // Logic for Resend API call
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
          html: emailContent.bodyHtml, // For Resend we'd need a similar HTML structure logic
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

    return new Response(JSON.stringify({ success: true, message: 'Email sent successfully' }), {
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
