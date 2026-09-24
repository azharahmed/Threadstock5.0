-- Migration: 20260924150225_020_auth_membership_role_foundation.sql
-- Description: Phase 2 Auth / Membership / RBAC Foundation Hardened:
--   1. Member business discovery via businesses_select_own_or_member policy
--   2. Dedicated business_invitations table with closed direct mutations (RPC only)
--   3. Machine-stable permissions catalog & business system roles seeder
--   4. Business creation trigger ensuring owner membership + RBAC atomicity
--   5. Idempotent backfill of existing businesses (memberships, roles, team_members)
--   6. Secure invitation RPCs: create_team_invitation, accept_team_invitation, revoke_team_invitation
--   7. Fail-closed validation on invitation role & location references (role required)
--   8. Authoritative permission helper has_business_permission
--   9. Explicit BEGIN / COMMIT with comprehensive blocking assertions

BEGIN;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = on;

-- ---------------------------------------------------------------------------
-- 1. FIX BUSINESS DISCOVERY FOR AUTHENTICATED MEMBERS
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "businesses_select_own" ON "public"."businesses";
DROP POLICY IF EXISTS "businesses_select_own_or_member" ON "public"."businesses";

CREATE POLICY "businesses_select_own_or_member" ON "public"."businesses"
  FOR SELECT TO authenticated
  USING (
    (owner_user_id = auth.uid())
    OR public.is_business_member(id, auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 2. BUSINESS INVITATIONS TABLE (MUTATION CLOSED TO DIRECT CLIENTS)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    email text NOT NULL,
    role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
    location_id uuid REFERENCES public.locations(id) ON DELETE SET NULL,
    location_was_assigned boolean NOT NULL DEFAULT false,
    token_hash text NOT NULL,
    status text NOT NULL DEFAULT 'pending'
        CONSTRAINT business_invitations_status_check
        CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
    invited_by uuid NOT NULL REFERENCES auth.users(id),
    expires_at timestamptz NOT NULL,
    accepted_at timestamptz,
    accepted_by uuid REFERENCES auth.users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT business_invitations_email_check
        CHECK (length(trim(email)) >= 3 AND position('@' in email) > 1)
);

ALTER TABLE public.business_invitations OWNER TO postgres;

CREATE UNIQUE INDEX IF NOT EXISTS idx_business_invitations_token_hash
    ON public.business_invitations (token_hash);

CREATE UNIQUE INDEX IF NOT EXISTS idx_business_invitations_active_pending
    ON public.business_invitations (business_id, lower(trim(email)))
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_business_invitations_business_id
    ON public.business_invitations (business_id);

CREATE INDEX IF NOT EXISTS idx_business_invitations_email
    ON public.business_invitations (lower(trim(email)));

DROP TRIGGER IF EXISTS trg_business_invitations_set_updated_at ON public.business_invitations;

CREATE TRIGGER trg_business_invitations_set_updated_at
    BEFORE UPDATE ON public.business_invitations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.business_invitations ENABLE ROW LEVEL SECURITY;

-- Owner-scoped read access only; direct client INSERT/UPDATE/DELETE remains closed
DROP POLICY IF EXISTS "business_invitations_select_owner" ON public.business_invitations;
CREATE POLICY "business_invitations_select_owner" ON public.business_invitations
    FOR SELECT TO authenticated
    USING (public.is_business_owner(business_id));

-- Explicitly revoke all direct mutations from authenticated and anon
REVOKE ALL ON TABLE public.business_invitations FROM PUBLIC;
REVOKE ALL ON TABLE public.business_invitations FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.business_invitations FROM authenticated;
GRANT SELECT ON TABLE public.business_invitations TO authenticated;
GRANT ALL ON TABLE public.business_invitations TO service_role;

-- ---------------------------------------------------------------------------
-- 3. PERMISSIONS CATALOG & SYSTEM ROLES SEEDER
-- ---------------------------------------------------------------------------
INSERT INTO public.permissions (code, name, module) VALUES
    ('inventory.view', 'View Inventory', 'inventory'),
    ('inventory.manage', 'Manage Products & Catalog', 'inventory'),
    ('inventory.adjust', 'Adjust Stock & Reconciliation', 'inventory'),
    ('inventory.import', 'Import Inventory Data', 'inventory'),
    ('sales.view', 'View Sales & Orders', 'sales'),
    ('sales.create', 'Create Sales & POS Checkout', 'sales'),
    ('sales.hold', 'Hold & Resume Sales', 'sales'),
    ('sales.refund', 'Process Refunds & Returns', 'sales'),
    ('purchasing.view', 'View Purchasing & POs', 'purchasing'),
    ('purchasing.manage', 'Manage Purchasing & Suppliers', 'purchasing'),
    ('purchasing.receive', 'Receive PO Shipments', 'purchasing'),
    ('transfers.view', 'View Transfers', 'transfers'),
    ('transfers.manage', 'Manage Stock Transfers', 'transfers'),
    ('customers.view', 'View Customers', 'customers'),
    ('customers.manage', 'Manage Customer Accounts', 'customers'),
    ('team.view', 'View Team Members', 'team'),
    ('team.manage', 'Manage Team & Invitations', 'team'),
    ('insights.view', 'View Analytics & Reports', 'insights'),
    ('insights.export', 'Export Business Intelligence', 'insights'),
    ('settings.view', 'View Store Settings', 'settings'),
    ('settings.manage', 'Manage Store Configuration', 'settings')
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    module = EXCLUDED.module;

CREATE OR REPLACE FUNCTION public.seed_business_system_roles(
    p_business_id uuid,
    p_owner_user_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_owner_role_id uuid;
    v_manager_role_id uuid;
    v_cashier_role_id uuid;
    v_inventory_role_id uuid;
BEGIN
    -- 1. Owner role (system role with all permissions)
    INSERT INTO public.roles (business_id, name, description, is_system)
    VALUES (p_business_id, 'Owner', 'Full business administration authority', true)
    ON CONFLICT (business_id, name) DO UPDATE SET is_system = true
    RETURNING id INTO v_owner_role_id;

    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT v_owner_role_id, p.id
    FROM public.permissions p
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 2. Store Manager role
    INSERT INTO public.roles (business_id, name, description, is_system)
    VALUES (p_business_id, 'Store Manager', 'Store operations, staff and catalog management', true)
    ON CONFLICT (business_id, name) DO UPDATE SET is_system = true
    RETURNING id INTO v_manager_role_id;

    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT v_manager_role_id, p.id
    FROM public.permissions p
    WHERE p.code IN (
        'inventory.view', 'inventory.manage', 'inventory.adjust', 'inventory.import',
        'sales.view', 'sales.create', 'sales.hold', 'sales.refund',
        'purchasing.view', 'purchasing.manage', 'purchasing.receive',
        'transfers.view', 'transfers.manage',
        'customers.view', 'customers.manage',
        'team.view', 'team.manage',
        'insights.view', 'settings.view'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 3. Cashier role
    INSERT INTO public.roles (business_id, name, description, is_system)
    VALUES (p_business_id, 'Cashier', 'Front-of-house sales, POS checkout, customers', true)
    ON CONFLICT (business_id, name) DO UPDATE SET is_system = true
    RETURNING id INTO v_cashier_role_id;

    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT v_cashier_role_id, p.id
    FROM public.permissions p
    WHERE p.code IN (
        'sales.view', 'sales.create', 'sales.hold',
        'customers.view', 'customers.manage',
        'inventory.view'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 4. Inventory Staff role
    INSERT INTO public.roles (business_id, name, description, is_system)
    VALUES (p_business_id, 'Inventory Staff', 'Stock counts, receiving shipments, transfers', true)
    ON CONFLICT (business_id, name) DO UPDATE SET is_system = true
    RETURNING id INTO v_inventory_role_id;

    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT v_inventory_role_id, p.id
    FROM public.permissions p
    WHERE p.code IN (
        'inventory.view', 'inventory.manage', 'inventory.adjust', 'inventory.import',
        'transfers.view', 'transfers.manage',
        'purchasing.view', 'purchasing.receive'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- If owner_user_id is provided, link Owner role in team_members
    IF p_owner_user_id IS NOT NULL THEN
        INSERT INTO public.team_members (
            business_id,
            user_id,
            role_id,
            status
        ) VALUES (
            p_business_id,
            p_owner_user_id,
            v_owner_role_id,
            'active'
        )
        ON CONFLICT (business_id, user_id)
        DO UPDATE SET
            role_id = v_owner_role_id,
            status = 'active',
            updated_at = now();
    END IF;
END;
$$;

ALTER FUNCTION public.seed_business_system_roles(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.seed_business_system_roles(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.seed_business_system_roles(uuid, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.seed_business_system_roles(uuid, uuid) FROM authenticated;
GRANT ALL ON FUNCTION public.seed_business_system_roles(uuid, uuid) TO service_role;

-- ---------------------------------------------------------------------------
-- 4. BUSINESS CREATION TRIGGER (OWNER MEMBERSHIP + RBAC ATOMICITY)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_business_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
BEGIN
    -- 1. Ensure owner membership exists and is active
    INSERT INTO public.memberships (business_id, user_id, status)
    VALUES (NEW.id, NEW.owner_user_id, 'active')
    ON CONFLICT (business_id, user_id)
    DO UPDATE SET status = 'active', updated_at = now();

    -- 2. Seed system roles and assign owner in team_members
    PERFORM public.seed_business_system_roles(NEW.id, NEW.owner_user_id);

    RETURN NEW;
END;
$$;

ALTER FUNCTION public.handle_business_created() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.handle_business_created() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_business_created() FROM anon;
REVOKE ALL ON FUNCTION public.handle_business_created() FROM authenticated;
GRANT ALL ON FUNCTION public.handle_business_created() TO service_role;

DROP TRIGGER IF EXISTS trg_on_business_created ON public.businesses;

CREATE TRIGGER trg_on_business_created
AFTER INSERT ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION public.handle_business_created();

-- ---------------------------------------------------------------------------
-- 5. IDEMPOTENT BACKFILL FOR EXISTING BUSINESSES
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT b.id, b.owner_user_id
        FROM public.businesses b
        WHERE b.owner_user_id IS NOT NULL
    LOOP
        -- 1. Ensure owner active membership row exists
        INSERT INTO public.memberships (business_id, user_id, status)
        VALUES (r.id, r.owner_user_id, 'active')
        ON CONFLICT (business_id, user_id)
        DO UPDATE SET status = 'active', updated_at = now();

        -- 2. Seed system roles & link owner in team_members
        PERFORM public.seed_business_system_roles(r.id, r.owner_user_id);
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. INVITATION CREATION RPC (ROLE REQUIRED, CROSS-TENANT VALIDATED)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_team_invitation(
    p_business_id uuid,
    p_email text,
    p_role_id uuid,
    p_location_id uuid DEFAULT NULL,
    p_expires_in_days integer DEFAULT 7
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'extensions'
AS $$
DECLARE
    v_caller_id uuid;
    v_clean_email text;
    v_raw_token text;
    v_token_hash text;
    v_invitation_id uuid;
    v_expires_at timestamptz;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    -- Validate business ownership
    IF NOT public.is_business_owner(p_business_id) THEN
        RAISE EXCEPTION 'Unauthorized: only business owners can create invitations' USING ERRCODE = '42501';
    END IF;

    -- Role is strictly required for team invitations
    IF p_role_id IS NULL THEN
        RAISE EXCEPTION 'Role assignment is required for team invitations' USING ERRCODE = '22023';
    END IF;

    -- Validate role belongs to same business
    IF NOT EXISTS (
        SELECT 1 FROM public.roles
        WHERE id = p_role_id AND business_id = p_business_id
    ) THEN
        RAISE EXCEPTION 'Role does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Validate location belongs to same business if provided
    IF p_location_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.locations
            WHERE id = p_location_id AND business_id = p_business_id
        ) THEN
            RAISE EXCEPTION 'Location does not belong to this business' USING ERRCODE = '23503';
        END IF;
    END IF;

    -- Normalize email
    v_clean_email := lower(trim(p_email));
    IF v_clean_email IS NULL OR length(v_clean_email) < 3 OR position('@' in v_clean_email) < 2 THEN
        RAISE EXCEPTION 'Invalid email address' USING ERRCODE = '22023';
    END IF;

    -- Check if user is already an active member of this business
    IF EXISTS (
        SELECT 1
        FROM public.memberships m
        JOIN auth.users u ON u.id = m.user_id
        WHERE m.business_id = p_business_id
          AND lower(trim(u.email)) = v_clean_email
          AND m.status = 'active'
    ) THEN
        RAISE EXCEPTION 'User with this email is already an active member' USING ERRCODE = '23505';
    END IF;

    -- Auto-expire any past-due pending invitations for this business & email
    UPDATE public.business_invitations
    SET status = 'expired', updated_at = now()
    WHERE business_id = p_business_id
      AND lower(trim(email)) = v_clean_email
      AND status = 'pending'
      AND expires_at <= now();

    -- Check for existing active pending invitation for this email in this business
    IF EXISTS (
        SELECT 1
        FROM public.business_invitations
        WHERE business_id = p_business_id
          AND lower(trim(email)) = v_clean_email
          AND status = 'pending'
          AND expires_at > now()
    ) THEN
        RAISE EXCEPTION 'A pending invitation already exists for this email' USING ERRCODE = '23505';
    END IF;

    -- Calculate expiration
    IF p_expires_in_days IS NULL OR p_expires_in_days <= 0 THEN
        p_expires_in_days := 7;
    END IF;
    v_expires_at := now() + (p_expires_in_days || ' days')::interval;

    -- Generate secure random token (64 hex characters from 32 random bytes)
    v_raw_token := encode(extensions.gen_random_bytes(32), 'hex');
    v_token_hash := encode(sha256(v_raw_token::bytea), 'hex');

    -- Insert invitation
    INSERT INTO public.business_invitations (
        business_id,
        email,
        role_id,
        location_id,
        location_was_assigned,
        token_hash,
        status,
        invited_by,
        expires_at
    ) VALUES (
        p_business_id,
        v_clean_email,
        p_role_id,
        p_location_id,
        (p_location_id IS NOT NULL),
        v_token_hash,
        'pending',
        v_caller_id,
        v_expires_at
    )
    RETURNING id INTO v_invitation_id;

    RETURN jsonb_build_object(
        'invitation_id', v_invitation_id,
        'business_id', p_business_id,
        'email', v_clean_email,
        'role_id', p_role_id,
        'location_id', p_location_id,
        'token', v_raw_token,
        'expires_at', v_expires_at
    );
END;
$$;

ALTER FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) TO service_role;

-- ---------------------------------------------------------------------------
-- 7. INVITATION ACCEPTANCE RPC (FAIL-CLOSED VALIDATIONS)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_team_invitation(
    p_token text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'extensions'
AS $$
DECLARE
    v_caller_id uuid;
    v_user_email text;
    v_token_hash text;
    v_invitation record;
    v_membership_id uuid;
    v_team_member_id uuid;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_token IS NULL OR length(trim(p_token)) = 0 THEN
        RAISE EXCEPTION 'Invitation token is required' USING ERRCODE = '22023';
    END IF;

    -- Hash supplied token server-side
    v_token_hash := encode(sha256(trim(p_token)::bytea), 'hex');

    -- Locate and lock invitation row
    SELECT * INTO v_invitation
    FROM public.business_invitations
    WHERE token_hash = v_token_hash
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found' USING ERRCODE = 'P0002';
    END IF;

    -- Check status
    IF v_invitation.status = 'revoked' THEN
        RAISE EXCEPTION 'Invitation has been revoked' USING ERRCODE = '22023';
    END IF;

    IF v_invitation.status = 'accepted' THEN
        RAISE EXCEPTION 'Invitation has already been accepted' USING ERRCODE = '22023';
    END IF;

    IF v_invitation.status = 'expired' OR v_invitation.expires_at < now() THEN
        IF v_invitation.status <> 'expired' THEN
            UPDATE public.business_invitations
            SET status = 'expired', updated_at = now()
            WHERE id = v_invitation.id;
        END IF;
        RAISE EXCEPTION 'Invitation has expired' USING ERRCODE = '22023';
    END IF;

    IF v_invitation.status <> 'pending' THEN
        RAISE EXCEPTION 'Invitation is not in pending status' USING ERRCODE = '22023';
    END IF;

    -- Verify authenticated user's email matches invited email
    SELECT lower(trim(email)) INTO v_user_email
    FROM auth.users
    WHERE id = v_caller_id;

    IF v_user_email IS NULL OR v_user_email <> lower(trim(v_invitation.email)) THEN
        RAISE EXCEPTION 'Authenticated user email does not match invitation recipient' USING ERRCODE = '42501';
    END IF;

    -- Fail-closed: Validate business exists
    IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = v_invitation.business_id) THEN
        RAISE EXCEPTION 'Business associated with invitation no longer exists' USING ERRCODE = '23503';
    END IF;

    -- Fail-closed: Validate role is present and still belongs to business
    IF v_invitation.role_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.roles
        WHERE id = v_invitation.role_id AND business_id = v_invitation.business_id
    ) THEN
        RAISE EXCEPTION 'Assigned role is no longer valid for this business' USING ERRCODE = '23503';
    END IF;

    -- Fail-closed: Validate location assignment
    IF v_invitation.location_was_assigned IS TRUE AND v_invitation.location_id IS NULL THEN
        RAISE EXCEPTION 'Assigned location is no longer available' USING ERRCODE = '23503';
    END IF;

    -- Fail-closed: Validate location still belongs to business if set
    IF v_invitation.location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.locations
        WHERE id = v_invitation.location_id AND business_id = v_invitation.business_id
    ) THEN
        RAISE EXCEPTION 'Assigned location is no longer valid for this business' USING ERRCODE = '23503';
    END IF;

    -- Ensure profile exists for this user (memberships references profiles(id))
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caller_id) THEN
        INSERT INTO public.profiles (id, email, full_name)
        VALUES (
            v_caller_id,
            v_user_email,
            coalesce(
                (SELECT raw_user_meta_data->>'full_name' FROM auth.users WHERE id = v_caller_id),
                v_user_email
            )
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- 1. Create or update memberships row
    INSERT INTO public.memberships (
        business_id,
        user_id,
        status,
        invited_by
    ) VALUES (
        v_invitation.business_id,
        v_caller_id,
        'active',
        v_invitation.invited_by
    )
    ON CONFLICT (business_id, user_id)
    DO UPDATE SET
        status = 'active',
        invited_by = EXCLUDED.invited_by,
        updated_at = now()
    RETURNING id INTO v_membership_id;

    -- 2. Create or update team_members row
    INSERT INTO public.team_members (
        business_id,
        user_id,
        role_id,
        location_id,
        status,
        invited_by
    ) VALUES (
        v_invitation.business_id,
        v_caller_id,
        v_invitation.role_id,
        v_invitation.location_id,
        'active',
        v_invitation.invited_by
    )
    ON CONFLICT (business_id, user_id)
    DO UPDATE SET
        role_id = EXCLUDED.role_id,
        location_id = EXCLUDED.location_id,
        status = 'active',
        invited_by = EXCLUDED.invited_by,
        updated_at = now()
    RETURNING id INTO v_team_member_id;

    -- 3. Mark invitation accepted
    UPDATE public.business_invitations
    SET status = 'accepted',
        accepted_at = now(),
        accepted_by = v_caller_id,
        updated_at = now()
    WHERE id = v_invitation.id;

    RETURN jsonb_build_object(
        'success', true,
        'business_id', v_invitation.business_id,
        'membership_id', v_membership_id,
        'team_member_id', v_team_member_id,
        'role_id', v_invitation.role_id,
        'location_id', v_invitation.location_id
    );
END;
$$;

ALTER FUNCTION public.accept_team_invitation(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.accept_team_invitation(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accept_team_invitation(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_team_invitation(text) TO service_role;

-- ---------------------------------------------------------------------------
-- 8. INVITATION REVOCATION RPC (OWNER ONLY)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.revoke_team_invitation(
    p_invitation_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_caller_id uuid;
    v_invitation record;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_invitation_id IS NULL THEN
        RAISE EXCEPTION 'Invitation ID is required' USING ERRCODE = '22023';
    END IF;

    SELECT * INTO v_invitation
    FROM public.business_invitations
    WHERE id = p_invitation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found' USING ERRCODE = 'P0002';
    END IF;

    -- Owner authority check
    IF NOT public.is_business_owner(v_invitation.business_id) THEN
        RAISE EXCEPTION 'Unauthorized: only business owners can revoke invitations' USING ERRCODE = '42501';
    END IF;

    IF v_invitation.status <> 'pending' THEN
        RAISE EXCEPTION 'Only pending invitations can be revoked' USING ERRCODE = '22023';
    END IF;

    UPDATE public.business_invitations
    SET status = 'revoked',
        updated_at = now()
    WHERE id = p_invitation_id;

    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', p_invitation_id,
        'status', 'revoked'
    );
END;
$$;

ALTER FUNCTION public.revoke_team_invitation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.revoke_team_invitation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_team_invitation(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.revoke_team_invitation(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_team_invitation(uuid) TO service_role;

-- ---------------------------------------------------------------------------
-- 9. AUTHORIZATION HELPER: has_business_permission
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.has_business_permission(
    p_business_id uuid,
    p_permission_code text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_user_id uuid;
    v_is_owner boolean;
    v_is_member boolean;
    v_has_perm boolean;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL OR p_business_id IS NULL OR p_permission_code IS NULL OR length(trim(p_permission_code)) = 0 THEN
        RETURN false;
    END IF;

    -- 1. Verify business exists
    IF NOT EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = p_business_id) THEN
        RETURN false;
    END IF;

    -- 2. Verify permission code exists in public.permissions catalog (unknown permission -> false for everyone)
    IF NOT EXISTS (SELECT 1 FROM public.permissions p WHERE p.code = trim(p_permission_code)) THEN
        RETURN false;
    END IF;

    -- 3. Business owner has authoritative administrative clearance for known permissions
    SELECT (b.owner_user_id = v_user_id) INTO v_is_owner
    FROM public.businesses b
    WHERE b.id = p_business_id;

    IF v_is_owner IS TRUE THEN
        RETURN true;
    END IF;

    -- 4. Inactive/non-member -> false
    SELECT EXISTS (
        SELECT 1
        FROM public.memberships m
        WHERE m.business_id = p_business_id
          AND m.user_id = v_user_id
          AND m.status = 'active'
    ) INTO v_is_member;

    IF v_is_member IS NOT TRUE THEN
        RETURN false;
    END IF;

    -- 5. Active member with matching role permission
    SELECT EXISTS (
        SELECT 1
        FROM public.team_members tm
        JOIN public.roles r ON r.id = tm.role_id AND r.business_id = p_business_id
        JOIN public.role_permissions rp ON rp.role_id = r.id
        JOIN public.permissions p ON p.id = rp.permission_id
        WHERE tm.business_id = p_business_id
          AND tm.user_id = v_user_id
          AND tm.status = 'active'
          AND p.code = trim(p_permission_code)
    ) INTO v_has_perm;

    RETURN coalesce(v_has_perm, false);
END;
$$;

ALTER FUNCTION public.has_business_permission(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.has_business_permission(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_business_permission(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.has_business_permission(uuid, text) TO authenticated;
GRANT ALL ON FUNCTION public.has_business_permission(uuid, text) TO service_role;

-- ---------------------------------------------------------------------------
-- 10. MIGRATION PRE/POSTCONDITION INVARIANT VERIFICATION
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v_perm_count int;
    v_biz_count int;
    v_missing_mem_count int;
    v_missing_role_count int;
    v_missing_tm_count int;
    v_inv_rls boolean;
    v_anon_inv_rpc_count int;
    v_auth_inv_rpc_count int;
    v_direct_mutation_count int;
    v_businesses_policy_count int;
    v_phase1a_app_rpc_count int;
    v_sales_direct_mut_count int;
    v_rls_disabled_table_count int;
    v_internal_client_exec_count int;
BEGIN
    -- 1. Table business_invitations exists & RLS enabled & location_was_assigned exists
    SELECT rowsecurity INTO v_inv_rls
    FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'business_invitations';

    IF v_inv_rls IS NOT TRUE THEN
        RAISE EXCEPTION 'Assertion Failed: business_invitations table does not exist or has RLS disabled';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'business_invitations'
          AND column_name = 'location_was_assigned'
    ) THEN
        RAISE EXCEPTION 'Assertion Failed: location_was_assigned column missing on business_invitations';
    END IF;

    -- 2. Permissions catalog exactly 21 defined codes
    SELECT count(*) INTO v_perm_count FROM public.permissions;
    IF v_perm_count <> 21 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 21 permissions in catalog, found %', v_perm_count;
    END IF;

    -- 3. Every business has active owner membership, Owner role, and active team_member Owner assignment
    SELECT count(*) INTO v_biz_count FROM public.businesses WHERE owner_user_id IS NOT NULL;

    SELECT count(*) INTO v_missing_mem_count
    FROM public.businesses b
    WHERE b.owner_user_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM public.memberships m
          WHERE m.business_id = b.id AND m.user_id = b.owner_user_id AND m.status = 'active'
      );

    IF v_missing_mem_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: % businesses missing active owner membership', v_missing_mem_count;
    END IF;

    SELECT count(*) INTO v_missing_role_count
    FROM public.businesses b
    WHERE b.owner_user_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM public.roles r
          WHERE r.business_id = b.id AND r.name = 'Owner' AND r.is_system = true
      );

    IF v_missing_role_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: % businesses missing Owner system role', v_missing_role_count;
    END IF;

    SELECT count(*) INTO v_missing_tm_count
    FROM public.businesses b
    JOIN public.roles r ON r.business_id = b.id AND r.name = 'Owner'
    WHERE b.owner_user_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM public.team_members tm
          WHERE tm.business_id = b.id AND tm.user_id = b.owner_user_id AND tm.role_id = r.id AND tm.status = 'active'
      );

    IF v_missing_tm_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: % businesses missing active owner team_members assignment', v_missing_tm_count;
    END IF;

    -- 4. Invitation RPC permissions:
    -- create_team_invitation, accept_team_invitation, revoke_team_invitation
    -- authenticated EXECUTE = true (count = 3), anon EXECUTE = false (count = 0)
    SELECT count(*) INTO v_auth_inv_rpc_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee = 'authenticated'
      AND privilege_type = 'EXECUTE'
      AND routine_name IN ('create_team_invitation', 'accept_team_invitation', 'revoke_team_invitation');

    IF v_auth_inv_rpc_count <> 3 THEN
        RAISE EXCEPTION 'Assertion Failed: Authenticated missing EXECUTE on invitation RPCs (found % of 3)', v_auth_inv_rpc_count;
    END IF;

    SELECT count(*) INTO v_anon_inv_rpc_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee IN ('anon', 'PUBLIC')
      AND privilege_type = 'EXECUTE'
      AND routine_name IN ('create_team_invitation', 'accept_team_invitation', 'revoke_team_invitation');

    IF v_anon_inv_rpc_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Anon has EXECUTE on invitation RPCs (count: %)', v_anon_inv_rpc_count;
    END IF;

    -- 5. business_invitations direct mutation closed to authenticated
    SELECT count(*) INTO v_direct_mutation_count
    FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'business_invitations'
      AND grantee = 'authenticated'
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE');

    IF v_direct_mutation_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Authenticated has direct mutation grants on business_invitations (count: %)', v_direct_mutation_count;
    END IF;

    -- 6. businesses member SELECT policy exists
    SELECT count(*) INTO v_businesses_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'businesses'
      AND policyname = 'businesses_select_own_or_member';

    IF v_businesses_policy_count <> 1 THEN
        RAISE EXCEPTION 'Assertion Failed: Policy businesses_select_own_or_member does not exist on businesses';
    END IF;

    -- 7. Internal functions revoked from clients
    SELECT count(*) INTO v_internal_client_exec_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee IN ('anon', 'authenticated', 'PUBLIC')
      AND privilege_type = 'EXECUTE'
      AND routine_name IN ('seed_business_system_roles', 'handle_business_created');

    IF v_internal_client_exec_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Client execution not revoked from internal functions (count: %)', v_internal_client_exec_count;
    END IF;

    -- 8. Phase 1A application RPCs remain intact (6 RPCs)
    SELECT count(*) INTO v_phase1a_app_rpc_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee = 'authenticated'
      AND privilege_type = 'EXECUTE'
      AND routine_name IN ('complete_sale', 'hold_sale', 'list_held_sales', 'resume_held_sale', 'discard_held_sale', 'save_or_publish_product');

    IF v_phase1a_app_rpc_count <> 6 THEN
        RAISE EXCEPTION 'Assertion Failed: Phase 1A application RPC grants missing (found % of 6)', v_phase1a_app_rpc_count;
    END IF;

    -- 9. sales direct mutations remain blocked
    SELECT count(*) INTO v_sales_direct_mut_count
    FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name IN ('sales', 'sale_items', 'sale_payments')
      AND grantee = 'authenticated'
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE');

    IF v_sales_direct_mut_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Direct sales mutation privileges detected for authenticated';
    END IF;

    -- 10. All public tables still have RLS enabled
    SELECT count(*) INTO v_rls_disabled_table_count
    FROM pg_tables
    WHERE schemaname = 'public'
      AND rowsecurity = false;

    IF v_rls_disabled_table_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Public tables detected with RLS disabled (count: %)', v_rls_disabled_table_count;
    END IF;

    RAISE NOTICE 'Migration 020 postconditions verified successfully.';
END;
$$;

COMMIT;
