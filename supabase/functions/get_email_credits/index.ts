import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Authenticate user from JWT
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

    // 2. Read system default from env var
    const systemDefault = parseInt(Deno.env.get('DEFAULT_DAILY_EMAIL_LIMIT') || '10');

    // 3. Read user's extra credits from profiles
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('daily_extra_email_credits')
      .eq('id', userId)
      .single();

    if (profileError) {
      console.error('Error reading profile:', profileError);
    }

    const extraCredits = profile?.daily_extra_email_credits ?? 0;
    const totalCredits = systemDefault + extraCredits;

    // 4. Count usage in last 24 hours
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    const { data: usageLogs, error: usageError } = await supabaseAdmin
      .from('email_logs')
      .select('recipient_count')
      .eq('user_id', userId)
      .gte('created_at', twentyFourHoursAgo);

    if (usageError) {
      console.error('Error checking usage:', usageError);
      throw new Error('Could not verify sending limits');
    }

    const usedCredits = (usageLogs || []).reduce(
      (sum: number, log: { recipient_count: number }) => sum + log.recipient_count, 0
    );
    const remainingCredits = totalCredits - usedCredits;

    // 5. Return credits info
    return new Response(JSON.stringify({
      success: true,
      totalCredits: totalCredits,
      usedCredits: usedCredits,
      remainingCredits: remainingCredits,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('Error in get_email_credits:', errorMessage);
    return new Response(JSON.stringify({ success: false, error: errorMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
