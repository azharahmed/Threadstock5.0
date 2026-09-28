import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// In-memory rate limiting per user (max 60 requests per minute)
interface RateLimitEntry {
  count: number;
  resetAt: number;
}
const rateLimits = new Map<string, RateLimitEntry>();
const MAX_REQUESTS_PER_MINUTE = 60;

// Periodic cleanup of expired rate limit entries
setInterval(() => {
  const now = Date.now();
  for (const [userId, entry] of rateLimits.entries()) {
    if (now > entry.resetAt) {
      rateLimits.delete(userId);
    }
  }
}, 60_000);

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Require Authentication: Validate Supabase user session
    const authHeader = req.headers.get('Authorization') || req.headers.get('authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ ok: false, error: 'Unauthorized: Missing Authorization header.' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        },
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ ok: false, error: 'Unauthorized: Invalid or expired session.' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        },
      );
    }

    // 2. Enforce Rate Limiting per authenticated user
    const now = Date.now();
    const entry = rateLimits.get(user.id);
    if (entry && now < entry.resetAt) {
      if (entry.count >= MAX_REQUESTS_PER_MINUTE) {
        return new Response(
          JSON.stringify({
            ok: false,
            error: 'Rate limit exceeded. Please wait a moment before searching again.',
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 429,
          },
        );
      }
      entry.count++;
    } else {
      rateLimits.set(user.id, { count: 1, resetAt: now + 60_000 });
    }

    // 3. Verify Server-side Google API Key Secret
    const apiKey =
      Deno.env.get('GOOGLE_MAPS_API_KEY') ||
      Deno.env.get('GOOGLE_PLACES_API_KEY');

    const googleKeyConfigured = Boolean(apiKey && apiKey.trim().length > 0);

    if (!googleKeyConfigured) {
      console.error('[PlacesSearch] GOOGLE_MAPS_API_KEY missing from Supabase Edge Function secrets');
      return new Response(
        JSON.stringify({
          ok: false,
          googleKeyConfigured: false,
          status: 'MISSING_SECRET',
          error: 'GOOGLE_MAPS_API_KEY missing from Supabase Edge Function secrets',
          predictions: [],
          message: 'Location search is temporarily unavailable. You can enter the address manually.',
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      );
    }

    const cleanApiKey = apiKey!.trim();
    const body = await req.json();
    const action = body.action || 'autocomplete';

    if (action === 'autocomplete') {
      const rawInput = body.query || body.input || '';
      const input = rawInput.trim();
      const countryCode = body.countryCode;
      const sessionToken = body.sessionToken;
      const types = body.types; // e.g. 'address'

      // Minimum 2 characters required
      if (input.length < 2) {
        return new Response(
          JSON.stringify({
            ok: true,
            status: 'ZERO_RESULTS',
            predictions: [],
            googleKeyConfigured: true,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        );
      }

      // Maximum 100 characters to prevent payload spam
      if (input.length > 100) {
        return new Response(
          JSON.stringify({
            ok: false,
            error: 'Query exceeds maximum allowed length of 100 characters.',
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          },
        );
      }

      // 4A. Preferred: Places API (New) Autocomplete
      // POST https://places.googleapis.com/v1/places:autocomplete
      try {
        const newApiBody: Record<string, any> = {
          input: input,
        };
        if (countryCode && countryCode.trim().length > 0) {
          newApiBody.includedRegionCodes = [countryCode.trim().toLowerCase()];
        }
        if (sessionToken && sessionToken.trim().length > 0) {
          newApiBody.sessionToken = sessionToken.trim();
        }
        if (types === 'address') {
          newApiBody.includedPrimaryTypes = ['street_address', 'premise', 'route', 'subpremise'];
        }

        const newRes = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': cleanApiKey,
          },
          body: JSON.stringify(newApiBody),
        });

        const newJson = await newRes.json();

        if (newRes.ok) {
          const suggestions: any[] = newJson.suggestions || [];
          const predictions = suggestions.slice(0, 5).map((s: any) => {
            const p = s.placePrediction || {};
            const placeId = p.placeId || (p.place ? p.place.replace('places/', '') : '');
            const mainText = p.structuredFormat?.mainText?.text || p.text?.text || '';
            const secondaryText = p.structuredFormat?.secondaryText?.text || '';
            const description = p.text?.text || mainText;
            return {
              placeId: placeId,
              place_id: placeId,
              primaryText: mainText,
              mainText: mainText,
              main_text: mainText,
              secondaryText: secondaryText,
              secondary_text: secondaryText,
              description: description,
            };
          });

          return new Response(
            JSON.stringify({
              ok: true,
              status: predictions.length > 0 ? 'OK' : 'ZERO_RESULTS',
              predictions: predictions,
              googleKeyConfigured: true,
              apiType: 'places_new',
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            },
          );
        }

        // If Places API (New) fails, log diagnostic and attempt Legacy Places API fallback
        const newErrorStatus = newJson.error?.status || `HTTP_${newRes.status}`;
        const newErrorMessage = newJson.error?.message || 'Places API (New) returned non-200';
        console.warn(
          `[PlacesSearch] Places API (New) failed (status=${newErrorStatus}, error=${newErrorMessage}). Attempting Legacy Places fallback...`,
        );

        let legacyUrl = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
          input,
        )}&key=${cleanApiKey}`;
        if (countryCode) {
          legacyUrl += `&components=country:${encodeURIComponent(countryCode.toLowerCase())}`;
        }
        if (sessionToken) {
          legacyUrl += `&sessiontoken=${encodeURIComponent(sessionToken)}`;
        }
        if (types) {
          legacyUrl += `&types=${encodeURIComponent(types)}`;
        }

        const legacyRes = await fetch(legacyUrl);
        const legacyData = await legacyRes.json();

        if (legacyData.status === 'OK' || legacyData.status === 'ZERO_RESULTS') {
          const limitedPredictions = (legacyData.predictions || []).slice(0, 5);
          return new Response(
            JSON.stringify({
              ok: true,
              status: legacyData.status,
              predictions: limitedPredictions.map((p: any) => ({
                placeId: p.place_id,
                place_id: p.place_id,
                primaryText: p.structured_formatting?.main_text || p.description,
                mainText: p.structured_formatting?.main_text || p.description,
                main_text: p.structured_formatting?.main_text || p.description,
                secondaryText: p.structured_formatting?.secondary_text || '',
                secondary_text: p.structured_formatting?.secondary_text || '',
                description: p.description,
              })),
              googleKeyConfigured: true,
              apiType: 'places_legacy',
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            },
          );
        }

        // Both New and Legacy failed: Expose exact Google error
        const finalGoogleStatus = legacyData.status || newErrorStatus;
        const finalGoogleError = legacyData.error_message || newErrorMessage;
        console.error(
          `[PlacesSearch] action=autocomplete googleStatus=${finalGoogleStatus} googleError=${finalGoogleError}`,
        );

        return new Response(
          JSON.stringify({
            ok: false,
            status: finalGoogleStatus,
            error: finalGoogleError,
            predictions: [],
            googleKeyConfigured: true,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        );
      } catch (err: any) {
        console.error(`[PlacesSearch] action=autocomplete exception: ${err.message}`);
        return new Response(
          JSON.stringify({
            ok: false,
            status: 'NETWORK_ERROR',
            error: err.message || 'Error communicating with Google Places API',
            predictions: [],
            googleKeyConfigured: true,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        );
      }
    } else if (action === 'details') {
      const rawPlaceId = body.placeId || body.place_id;
      const placeId = rawPlaceId ? String(rawPlaceId).trim() : '';
      const sessionToken = body.sessionToken;

      if (!placeId) {
        return new Response(
          JSON.stringify({ ok: false, error: 'Missing placeId parameter.' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          },
        );
      }

      // 4B. Preferred: Places API (New) Place Details
      // GET https://places.googleapis.com/v1/places/{placeId}
      try {
        let newDetailsUrl = `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`;
        if (sessionToken && String(sessionToken).trim().length > 0) {
          newDetailsUrl += `?sessionToken=${encodeURIComponent(String(sessionToken).trim())}`;
        }

        const newRes = await fetch(newDetailsUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': cleanApiKey,
            // Request strictly required fields to avoid expensive SKUs
            'X-Goog-FieldMask':
              'id,displayName,formattedAddress,addressComponents,location,utcOffsetMinutes',
          },
        });

        const newJson = await newRes.json();

        if (newRes.ok && newJson.id) {
          const components: any[] = newJson.addressComponents || [];
          const getComponent = (type: string, useShort = false) => {
            const item = components.find((c: any) => c.types?.includes(type));
            return item ? (useShort ? item.shortText : item.longText) : '';
          };

          const streetNumber = getComponent('street_number');
          const route = getComponent('route');
          const streetAddress = [streetNumber, route].filter(Boolean).join(' ');
          const city =
            getComponent('locality') ||
            getComponent('sublocality') ||
            getComponent('postal_town') ||
            getComponent('administrative_area_level_2');
          const state = getComponent('administrative_area_level_1');
          const postalCode = getComponent('postal_code');
          const countryCode = getComponent('country', true);
          const countryName = getComponent('country', false);

          const lat = newJson.location?.latitude;
          const lng = newJson.location?.longitude;

          let timezone: string | null = null;
          if (newJson.utcOffsetMinutes != null) {
            const hours = newJson.utcOffsetMinutes / 60;
            const sign = hours >= 0 ? '+' : '';
            timezone = `UTC${sign}${hours}`;
          }

          return new Response(
            JSON.stringify({
              ok: true,
              placeId: newJson.id,
              place_id: newJson.id,
              displayName: newJson.displayName?.text || newJson.formattedAddress || '',
              name: newJson.displayName?.text || newJson.formattedAddress || '',
              formattedAddress: newJson.formattedAddress || '',
              formatted_address: newJson.formattedAddress || '',
              streetAddress: streetAddress,
              street_address: streetAddress,
              city: city,
              state: state,
              postalCode: postalCode,
              postal_code: postalCode,
              countryCode: countryCode,
              country_code: countryCode,
              countryName: countryName,
              country_name: countryName,
              latitude: lat,
              longitude: lng,
              timezone: timezone,
              apiType: 'places_new',
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            },
          );
        }

        // Fallback to Legacy Place Details
        const newErrorStatus = newJson.error?.status || `HTTP_${newRes.status}`;
        const newErrorMessage = newJson.error?.message || 'Places API (New) details non-200';
        console.warn(
          `[PlacesSearch] Places API (New) details failed (status=${newErrorStatus}, error=${newErrorMessage}). Attempting Legacy Place Details fallback...`,
        );

        let legacyUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(
          placeId,
        )}&fields=place_id,name,formatted_address,address_components,geometry/location,utc_offset_minutes&key=${cleanApiKey}`;
        if (sessionToken) {
          legacyUrl += `&sessiontoken=${encodeURIComponent(sessionToken)}`;
        }

        const legacyRes = await fetch(legacyUrl);
        const legacyData = await legacyRes.json();

        if (legacyData.status === 'OK' && legacyData.result) {
          const res = legacyData.result;
          const components: any[] = res.address_components || [];
          const getComponent = (type: string, useShort = false) => {
            const item = components.find((c: any) => c.types?.includes(type));
            return item ? (useShort ? item.short_name : item.long_name) : '';
          };

          const streetNumber = getComponent('street_number');
          const route = getComponent('route');
          const streetAddress = [streetNumber, route].filter(Boolean).join(' ');
          const city =
            getComponent('locality') ||
            getComponent('sublocality') ||
            getComponent('postal_town') ||
            getComponent('administrative_area_level_2');
          const state = getComponent('administrative_area_level_1');
          const postalCode = getComponent('postal_code');
          const countryCode = getComponent('country', true);
          const countryName = getComponent('country', false);

          const lat = res.geometry?.location?.lat;
          const lng = res.geometry?.location?.lng;

          let timezone: string | null = null;
          if (res.utc_offset_minutes != null) {
            const hours = res.utc_offset_minutes / 60;
            const sign = hours >= 0 ? '+' : '';
            timezone = `UTC${sign}${hours}`;
          }

          return new Response(
            JSON.stringify({
              ok: true,
              placeId: res.place_id,
              place_id: res.place_id,
              displayName: res.name || '',
              name: res.name || '',
              formattedAddress: res.formatted_address || '',
              formatted_address: res.formatted_address || '',
              streetAddress: streetAddress,
              street_address: streetAddress,
              city: city,
              state: state,
              postalCode: postalCode,
              postal_code: postalCode,
              countryCode: countryCode,
              country_code: countryCode,
              countryName: countryName,
              country_name: countryName,
              latitude: lat,
              longitude: lng,
              timezone: timezone,
              apiType: 'places_legacy',
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            },
          );
        }

        const finalStatus = legacyData.status || newErrorStatus;
        const finalError = legacyData.error_message || newErrorMessage;
        console.error(
          `[PlacesSearch] action=details googleStatus=${finalStatus} googleError=${finalError}`,
        );

        return new Response(
          JSON.stringify({
            ok: false,
            status: finalStatus,
            error: finalError,
            googleKeyConfigured: true,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        );
      } catch (err: any) {
        console.error(`[PlacesSearch] action=details exception: ${err.message}`);
        return new Response(
          JSON.stringify({
            ok: false,
            status: 'NETWORK_ERROR',
            error: err.message || 'Error communicating with Google Place Details API',
            googleKeyConfigured: true,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        );
      }
    } else {
      return new Response(
        JSON.stringify({ ok: false, error: `Unsupported action: ${action}` }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      );
    }
  } catch (err: any) {
    return new Response(
      JSON.stringify({ ok: false, error: err.message || 'Server error' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    );
  }
});
