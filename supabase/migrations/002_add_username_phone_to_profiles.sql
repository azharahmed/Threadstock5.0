-- ============================================================
-- Migration: 002_add_username_phone_to_profiles.sql
-- Purpose  : Add username and phone fields to public.profiles
-- Status   : PREPARED — DO NOT DEPLOY without explicit review
--            and team sign-off.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Add columns
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS phone    TEXT;

-- ────────────────────────────────────────────────────────────
-- 2. Normalise existing usernames (lowercase + trim) on write.
--    Enforce via a check constraint and a unique index rather
--    than a trigger so the constraint is transparent in the
--    schema and queryable from the client.
-- ────────────────────────────────────────────────────────────

-- username must be lowercase, trimmed, 3-30 chars, alphanumeric + _
ALTER TABLE public.profiles
  ADD CONSTRAINT username_format CHECK (
    username IS NULL OR (
      username = lower(trim(username))
      AND length(username) BETWEEN 3 AND 30
      AND username ~ '^[a-z0-9_]+$'
    )
  );

-- Case-insensitive uniqueness (functional unique index)
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_ci_idx
  ON public.profiles (lower(username))
  WHERE username IS NOT NULL;

-- phone must be E.164 format when set
ALTER TABLE public.profiles
  ADD CONSTRAINT phone_e164_format CHECK (
    phone IS NULL OR phone ~ '^\+[1-9]\d{6,14}$'
  );

-- phone unique (when set) — one account per mobile
CREATE UNIQUE INDEX IF NOT EXISTS profiles_phone_idx
  ON public.profiles (phone)
  WHERE phone IS NOT NULL;

-- ────────────────────────────────────────────────────────────
-- 3. RLS: users may update their own username/phone.
--    The existing "Users can update own profile" policy covers
--    this via the existing UPDATE policy on public.profiles.
--    No additional policy is required.
-- ────────────────────────────────────────────────────────────

-- ────────────────────────────────────────────────────────────
-- 4. Optional: back-fill username from user metadata if you
--    want to seed existing users. Uncomment and review before
--    running in production.
-- ────────────────────────────────────────────────────────────
-- UPDATE public.profiles p
-- SET username = lower(trim(replace(
--       split_part(
--         coalesce(
--           (SELECT raw_user_meta_data->>'full_name'
--             FROM auth.users WHERE id = p.id),
--           ''
--         ), ' ', 1
--       ), ' ', '_'
-- )))
-- WHERE username IS NULL
--   AND (SELECT raw_user_meta_data->>'full_name' FROM auth.users WHERE id = p.id) IS NOT NULL;

-- ────────────────────────────────────────────────────────────
-- SECURITY NOTE
-- Username -> email resolution MUST NOT be done through a
-- public client query. Use a server-side Edge Function that:
--   1. Looks up username in profiles (service-role only).
--   2. Retrieves the associated auth.users email.
--   3. Calls supabase.auth.signInWithPassword internally.
-- Never expose service-role credentials in Flutter code.
-- ────────────────────────────────────────────────────────────
