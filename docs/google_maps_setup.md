# Google Maps Platform & Places API Cost-Safe Setup Guide

This document outlines the mandatory Google Cloud setup procedures for ThreadStock's Google Maps and Places Platform integration. Follow these configuration guidelines to ensure production stability, prevent accidental runaway billing, and protect API keys.

---

## 1. Enable Billing

1. Navigate to the [Google Cloud Console Billing Page](https://console.cloud.google.com/billing).
2. Ensure an active billing account is linked to your project.
3. Google Cloud provides a complimentary recurring monthly credit (typically \$200 for Maps Platform SKUs), but a linked billing account is strictly required to enable APIs and provision production credentials.

---

## 2. Enable Required APIs Only

Enable **only** the APIs ThreadStock actively uses. Do not enable unused Maps SDKs.

1. Navigate to **APIs & Services > Library**.
2. Search and enable:
   - **Places API** (or **Places API (New)**) — used by the backend Edge Function for Autocomplete and Place Details.
   - *(Optional for native mobile view)* **Maps SDK for Android** and **Maps SDK for iOS** — used strictly for interactive map rendering on mobile clients.
3. Ensure all other Maps APIs (e.g., Directions, Distance Matrix, Geocoding, Elevation, Static Maps) remain **disabled**.

---

## 3. Create and Restrict Server-Side API Key

ThreadStock enforces an architectural separation: client Flutter applications **never** query Google Places directly and **never** hold server Places API keys. All calls route through the authenticated Supabase Edge Function (`places-search`).

### A. API Restrictions (Critical)
1. Go to **APIs & Services > Credentials**.
2. Locate or create the API key used by the backend.
3. Under **API restrictions**, select **Restrict key**.
4. Check **only**:
   - `Places API`
5. Save the configuration. Do **NOT** leave the key with "Don't restrict key".

### B. Application Restrictions
1. Since the key is invoked from Supabase serverless Edge Functions (Deno runtime), leave Application restrictions as **None** (or restrict by server IP addresses/CIDR blocks if dedicated static egress IPs are provisioned).
2. Never bundle this key inside the Flutter codebase, Git commits, `.env` files, or client-side assets.
3. Store the key exclusively in Supabase Secrets:
   ```bash
   npx supabase secrets set GOOGLE_MAPS_API_KEY="YOUR_API_KEY"
   ```

---

## 4. Set Daily API Quotas

To prevent cost spikes from loops, bugs, or abusive requests:

1. Navigate to **APIs & Services > Enabled APIs & services > Places API > Quotas & System Limits**.
2. Configure **Requests per day**:
   - **Development / Staging:** Cap at `1,000` to `2,500` requests/day.
   - **Production:** Set according to your expected peak daily active merchants (e.g., `10,000` requests/day).
3. Configure **Requests per minute**:
   - Cap at `60` to `120` requests/minute.

---

## 5. Set Budget Alerts (Cost Guardrail)

Budget alerts notify developers before costs accumulate.

1. Navigate to **Billing > Budgets & alerts**.
2. Click **Create Budget**.
3. Name: `ThreadStock Google Maps Budget Alert`.
4. Target amount:
   - **Recommended initial threshold for development:** **\$10.00 / month**.
5. Alert thresholds:
   - **50%** (\$5.00)
   - **90%** (\$9.00)
   - **100%** (\$10.00)
6. Notification settings: Check **Email alerts to billing admins and users** and connect to your Slack/Teams webhook if desired.

---

## 6. ThreadStock Built-in Architectural Cost Controls

ThreadStock includes the following client-side and Edge Function protections automatically:

1. **Debounce & Min Characters:**
   - 300 ms debounce on typing before dispatching autocomplete requests.
   - Minimum 2 characters required before any request is initiated.
   - Stale in-flight queries are dropped automatically when typing continues.
2. **Session Token Lifecycle:**
   - One session token is generated per user search session.
   - Reused across all autocomplete keystrokes for that location entry.
   - Passed to Place Details upon selection and discarded immediately.
   - Google bills the entire sequence as a single bundled Autocomplete Session SKU instead of individual per-keystroke requests.
3. **Selective Place Details:**
   - Place Details is invoked **only** when the user explicitly clicks a suggestion.
   - Minimal field mask requested: `place_id,name,formatted_address,address_components,geometry/location,utc_offset_minutes`.
   - Contact and Atmosphere data (reviews, photos, opening hours, phone numbers, ratings) are **never** requested, ensuring the lowest Basic Data tier.
4. **Session In-Memory Cache:**
   - Autocomplete results are cached in-memory per `query + countryCode`.
   - Re-typing or clearing and re-entering the same place within the session incurs 0 additional Google API calls.
5. **Edge Function Rate Limiting:**
   - The Supabase Edge Function requires an active authenticated Supabase user JWT.
   - Per-user rate limiting enforces a maximum of 60 requests/minute.
   - Results are capped at 5 suggestions maximum.
6. **Graceful Manual Fallback:**
   - If Google APIs are unavailable, disabled, or rate-limited, the UI displays:
     > *"Location search is temporarily unavailable. You can enter the address manually."*
   - Merchants can save their address manually and continue onboarding without obstruction.

---

## 7. Monitor API Usage

Check usage and billing regularly:
1. **Google Cloud Console:** Navigate to **APIs & Services > Metrics** to inspect request volume, error rates (e.g., 429, 403), and latencies.
2. **ThreadStock Debug Logs:** In debug mode, inspect `[PlacesUsage]` counters:
   ```
   [PlacesUsage] autocomplete=3 details=1 cacheHits=1 failures=0
   ```
