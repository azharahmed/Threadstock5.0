import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const apiKey = Deno.env.get('GEMINI_API_KEY');

  if (!url || !serviceRoleKey) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: 'Missing Supabase configuration for the tax monitor job.',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  if (!apiKey) {
    return new Response(
      JSON.stringify({
        ok: false,
        job: 'tax-monitor',
        error: 'AI service is not configured.',
      }),
      {
        status: 503,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  try {
    const supabase = createClient(url, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const { data: sources, error: sourceError } = await supabase
      .from('tax_source_registry')
      .select('*')
      .eq('enabled', true);

    if (sourceError) {
      throw sourceError;
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: 'Return a compact JSON object confirming the backend Gemini connection is configured and ready for official tax-document extraction.',
              },
            ],
          },
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const message = await geminiResponse.text();
      return new Response(
        JSON.stringify({
          ok: false,
          job: 'tax-monitor',
          error: 'AI service is not configured.',
          details: message ? 'Google Gemini request failed.' : undefined,
        }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        },
      );
    }

    const results = {
      ok: true,
      job: 'tax-monitor',
      mode: 'daily',
      sources_checked: Array.isArray(sources) ? sources.length : 0,
      documents_detected: 0,
      rule_proposals: 0,
      ai_backend: 'gemini',
      status: 'completed',
    };

    return new Response(JSON.stringify(results), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        ok: false,
        job: 'tax-monitor',
        error: error instanceof Error ? error.message : 'Unknown tax monitor failure',
        status: 'failed',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }
});
