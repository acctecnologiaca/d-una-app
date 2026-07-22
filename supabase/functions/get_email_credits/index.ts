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

    // 2. Call get_user_credit_status RPC
    const { data: creditStatus, error: rpcError } = await supabaseAdmin
      .rpc('get_user_credit_status', { p_user_id: userId });

    if (rpcError || !creditStatus) {
      console.error('Error invoking get_user_credit_status:', rpcError);
      throw new Error('Could not verify credit status');
    }

    const totalCredits = (creditStatus.baseCredits || 0) + (creditStatus.earnedCredits || 0);
    const usedCredits = creditStatus.spentCredits || 0;
    const remainingCredits = creditStatus.remainingCredits || 0;

    // 3. Return credits info
    return new Response(JSON.stringify({
      success: true,
      totalCredits: totalCredits,
      usedCredits: usedCredits,
      remainingCredits: remainingCredits,
      baseCredits: creditStatus.baseCredits,
      earnedCredits: creditStatus.earnedCredits,
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
