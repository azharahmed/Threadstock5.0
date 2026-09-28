-- ============================================================================
-- Migration: 022_inventory_operations_foundation
-- Description: Inventory Operations Architecture Foundation
--   1. inventory_ledger schema enhancements:
--      - Explicit bucket deltas: available_delta, committed_delta, damaged_delta
--      - Actor foreign key: actor_id referencing public.profiles(id) ON DELETE SET NULL
--      - Extended event_type check constraint: 'damage', 'damage_restore', 'damage_writeoff'
--      - Prevent cascade-deleting audit history: location_id & variant_id ON DELETE RESTRICT
--      - Deterministic backfill of historical rows
--   2. adjust_stock RPC correction:
--      - Remove semantically incorrect last_counted_at = now()
--      - Populate explicit bucket deltas (available_delta = delta, others = 0)
--      - Populate actor_id = auth.uid()
--      - Optional concurrency guard (expected_current_qty)
--   3. record_damaged_stock RPC:
--      - Atomic bucket transitions: mark_damaged, restore_sellable, write_off
--      - Atomic balance update + append-only ledger transaction
--      - Prevents negative available_qty or negative damaged_qty
--   4. stock_counts & stock_count_lines tables:
--      - Tenant-isolated physical count & cycle count headers and lines
--      - Unique count_number generated server-side per business
--      - Protected references: location & variant ON DELETE RESTRICT
--      - Full RLS enabled: SELECT requires inventory.view; direct client mutations revoked
--   5. Physical count lifecycle RPCs:
--      - start_stock_count(payload jsonb): Snapshot active stock-tracked SKUs (including zero-balance)
--      - submit_stock_count(payload jsonb): Submit counted SKUs (supports unexpected scanned SKUs)
--      - complete_stock_count(payload jsonb): Movement-safe atomic reconciliation, applies variance,
--        updates last_counted_at, appends ledger, prevents double completion
--      - cancel_stock_count(payload jsonb): Safe cancellation
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. INVENTORY LEDGER SCHEMA ENHANCEMENTS
-- ---------------------------------------------------------------------------

-- 1A. Add explicit bucket deltas
ALTER TABLE public.inventory_ledger
    ADD COLUMN IF NOT EXISTS available_delta integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS committed_delta integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS damaged_delta integer NOT NULL DEFAULT 0;

-- 1B. Add explicit actor_id referencing public.profiles(id)
ALTER TABLE public.inventory_ledger
    ADD COLUMN IF NOT EXISTS actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 1C. Deterministic backfill of pre-022 historical ledger rows
-- All prior ledger events (stock_in, stock_out, adjustment, sale, count_reconciliation)
-- operated directly on available_qty.
UPDATE public.inventory_ledger
SET available_delta = quantity_delta,
    committed_delta = 0,
    damaged_delta = 0
WHERE available_delta = 0 AND quantity_delta != 0;

-- Backfill actor_id from metadata if present and valid
UPDATE public.inventory_ledger
SET actor_id = CASE
    WHEN metadata->>'adjusted_by' ~* '^[0-9a-f-]{36}$'
         AND EXISTS (SELECT 1 FROM public.profiles WHERE id = (metadata->>'adjusted_by')::uuid)
        THEN (metadata->>'adjusted_by')::uuid
    WHEN metadata->>'created_by' ~* '^[0-9a-f-]{36}$'
         AND EXISTS (SELECT 1 FROM public.profiles WHERE id = (metadata->>'created_by')::uuid)
        THEN (metadata->>'created_by')::uuid
    ELSE NULL
END
WHERE actor_id IS NULL;

-- 1D. Extend event_type constraint to include damage lifecycle events
ALTER TABLE public.inventory_ledger DROP CONSTRAINT IF EXISTS inventory_ledger_event_type_check;
ALTER TABLE public.inventory_ledger ADD CONSTRAINT inventory_ledger_event_type_check
CHECK (event_type = ANY (ARRAY[
    'stock_in'::text,
    'stock_out'::text,
    'adjustment'::text,
    'sale'::text,
    'return'::text,
    'transfer_in'::text,
    'transfer_out'::text,
    'count_reconciliation'::text,
    'damage'::text,
    'damage_restore'::text,
    'damage_writeoff'::text
]));

-- 1E. Protect audit integrity: Prevent cascade delete of historical ledger records
-- Retiring/deleting an operational location or variant must NOT erase ledger history.
ALTER TABLE public.inventory_ledger DROP CONSTRAINT IF EXISTS inventory_ledger_location_id_fkey;
ALTER TABLE public.inventory_ledger ADD CONSTRAINT inventory_ledger_location_id_fkey
    FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE RESTRICT;

ALTER TABLE public.inventory_ledger DROP CONSTRAINT IF EXISTS inventory_ledger_variant_id_fkey;
ALTER TABLE public.inventory_ledger ADD CONSTRAINT inventory_ledger_variant_id_fkey
    FOREIGN KEY (variant_id) REFERENCES public.product_variants(id) ON DELETE RESTRICT;

-- 1F. Performance indexes for inventory history
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_actor_id ON public.inventory_ledger(actor_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_occurred_at ON public.inventory_ledger(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_biz_loc_var ON public.inventory_ledger(business_id, location_id, variant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_event_type ON public.inventory_ledger(event_type);

-- 1G. Add authoritative balance revision/version mechanism
ALTER TABLE public.inventory_balances
    ADD COLUMN IF NOT EXISTS version bigint NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.trg_inventory_balances_version_increment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.version := coalesce(OLD.version, 0) + 1;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inventory_balances_version ON public.inventory_balances;
CREATE TRIGGER trg_inventory_balances_version
BEFORE UPDATE ON public.inventory_balances
FOR EACH ROW
EXECUTE FUNCTION public.trg_inventory_balances_version_increment();

-- 1H. Central backward compatibility trigger for legacy stock writers on inventory_ledger
CREATE OR REPLACE FUNCTION public.trg_inventory_ledger_bucket_compat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
BEGIN
    -- Backward compatibility for legacy RPCs (complete_sale, save_or_publish_product, etc.)
    -- When quantity_delta != 0 and all three bucket deltas are 0:
    IF NEW.quantity_delta != 0
       AND coalesce(NEW.available_delta, 0) = 0
       AND coalesce(NEW.committed_delta, 0) = 0
       AND coalesce(NEW.damaged_delta, 0) = 0
    THEN
        IF NEW.event_type NOT IN ('damage', 'damage_restore', 'damage_writeoff') THEN
            NEW.available_delta := NEW.quantity_delta;
        END IF;
    END IF;

    -- Actor attribution compatibility when caller did not pass actor_id explicitly
    IF NEW.actor_id IS NULL AND auth.uid() IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid()) THEN
            NEW.actor_id := auth.uid();
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inventory_ledger_compat ON public.inventory_ledger;
CREATE TRIGGER trg_inventory_ledger_compat
BEFORE INSERT ON public.inventory_ledger
FOR EACH ROW
EXECUTE FUNCTION public.trg_inventory_ledger_bucket_compat();

-- ---------------------------------------------------------------------------
-- 2. CORRECT adjust_stock RPC (DO NOT UPDATE last_counted_at)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.adjust_stock(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := (payload->>'location_id')::uuid;
    v_variant_id uuid := (payload->>'variant_id')::uuid;
    v_quantity_delta integer := (payload->>'quantity_delta')::integer;
    v_reason text := nullif(trim(payload->>'reason'), '');
    v_reference_type text := coalesce(nullif(trim(payload->>'reference_type'), ''), 'adjustment');
    v_reference_id uuid := nullif(payload->>'reference_id', '')::uuid;
    v_expected_current_qty integer := CASE
        WHEN payload ? 'expected_current_qty' AND nullif(trim(payload->>'expected_current_qty'), '') IS NOT NULL
        THEN (payload->>'expected_current_qty')::integer
        ELSE NULL
    END;

    v_valid_variant_id uuid;
    v_balance record;
    v_previous_available integer;
    v_new_available integer;
    v_ledger_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'business_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_location_id IS NULL THEN
        RAISE EXCEPTION 'location_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_variant_id IS NULL THEN
        RAISE EXCEPTION 'variant_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_quantity_delta IS NULL OR v_quantity_delta = 0 THEN
        RAISE EXCEPTION 'quantity_delta must be non-zero' USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    -- Validate location belongs to business
    IF NOT EXISTS (
        SELECT 1 FROM public.locations
        WHERE id = v_location_id AND business_id = v_business_id
    ) THEN
        RAISE EXCEPTION 'Location not found or does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Validate variant belongs to business via its parent product
    SELECT pv.id INTO v_valid_variant_id
    FROM public.product_variants pv
    JOIN public.products p ON p.id = pv.product_id
    WHERE pv.id = v_variant_id AND p.business_id = v_business_id;

    IF v_valid_variant_id IS NULL THEN
        RAISE EXCEPTION 'Variant not found or does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Lock the balance row to prevent race conditions
    SELECT * INTO v_balance
    FROM public.inventory_balances
    WHERE business_id = v_business_id
      AND location_id = v_location_id
      AND variant_id = v_variant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        v_previous_available := 0;
        v_new_available := v_quantity_delta;
        IF v_new_available < 0 THEN
            RAISE EXCEPTION 'Insufficient stock: available quantity cannot be negative (current: 0, requested delta: %)', v_quantity_delta USING ERRCODE = '22003';
        END IF;

        IF v_expected_current_qty IS NOT NULL AND v_expected_current_qty != 0 THEN
            RAISE EXCEPTION 'Concurrency conflict: current available quantity (0) does not match expected (%)', v_expected_current_qty USING ERRCODE = '40001';
        END IF;

        INSERT INTO public.inventory_balances (
            business_id,
            location_id,
            variant_id,
            available_qty,
            committed_qty,
            damaged_qty,
            last_counted_at,
            created_at,
            updated_at
        ) VALUES (
            v_business_id,
            v_location_id,
            v_variant_id,
            v_new_available,
            0,
            0,
            NULL, -- DO NOT set last_counted_at on ordinary adjustment
            now(),
            now()
        ) RETURNING * INTO v_balance;
    ELSE
        v_previous_available := v_balance.available_qty;
        v_new_available := v_previous_available + v_quantity_delta;
        IF v_new_available < 0 THEN
            RAISE EXCEPTION 'Insufficient stock: available quantity cannot be negative (current: %, requested delta: %)', v_previous_available, v_quantity_delta USING ERRCODE = '22003';
        END IF;

        IF v_expected_current_qty IS NOT NULL AND v_expected_current_qty != v_previous_available THEN
            RAISE EXCEPTION 'Concurrency conflict: current available quantity (%) does not match expected (%)', v_previous_available, v_expected_current_qty USING ERRCODE = '40001';
        END IF;

        -- PRESERVE existing last_counted_at; only touch updated_at and available_qty
        UPDATE public.inventory_balances
        SET available_qty = v_new_available,
            updated_at = now()
        WHERE id = v_balance.id
        RETURNING * INTO v_balance;
    END IF;

    -- Strictly append-only ledger write with explicit bucket deltas and actor_id
    INSERT INTO public.inventory_ledger (
        business_id,
        location_id,
        variant_id,
        event_type,
        quantity_delta,
        available_delta,
        committed_delta,
        damaged_delta,
        reference_type,
        reference_id,
        source,
        occurred_at,
        metadata,
        actor_id,
        created_at
    ) VALUES (
        v_business_id,
        v_location_id,
        v_variant_id,
        'adjustment',
        v_quantity_delta,
        v_quantity_delta,
        0,
        0,
        v_reference_type,
        v_reference_id,
        'manual',
        now(),
        jsonb_build_object(
            'adjusted_by', auth.uid(),
            'reason', coalesce(v_reason, ''),
            'previous_qty', v_previous_available,
            'new_qty', v_new_available
        ),
        auth.uid(),
        now()
    ) RETURNING id INTO v_ledger_id;

    RETURN jsonb_build_object(
        'success', true,
        'balance_id', v_balance.id,
        'location_id', v_location_id,
        'variant_id', v_variant_id,
        'previous_qty', v_previous_available,
        'new_qty', v_new_available,
        'quantity_delta', v_quantity_delta,
        'ledger_id', v_ledger_id
    );
END;
$$;

ALTER FUNCTION public.adjust_stock(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.adjust_stock(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.adjust_stock(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.adjust_stock(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.adjust_stock(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 3. RECORD DAMAGED STOCK RPC
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.record_damaged_stock(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := (payload->>'location_id')::uuid;
    v_variant_id uuid := (payload->>'variant_id')::uuid;
    v_action text := nullif(trim(payload->>'action'), '');
    v_quantity integer := (payload->>'quantity')::integer;
    v_reason text := nullif(trim(payload->>'reason'), '');
    v_reference_type text := coalesce(nullif(trim(payload->>'reference_type'), ''), 'damaged_stock');
    v_reference_id uuid := nullif(payload->>'reference_id', '')::uuid;

    v_valid_variant_id uuid;
    v_balance record;
    v_previous_available integer;
    v_previous_damaged integer;
    v_new_available integer;
    v_new_damaged integer;
    v_avail_delta integer := 0;
    v_dam_delta integer := 0;
    v_on_hand_delta integer := 0;
    v_event_type text;
    v_ledger_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'business_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_location_id IS NULL THEN
        RAISE EXCEPTION 'location_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_variant_id IS NULL THEN
        RAISE EXCEPTION 'variant_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_action IS NULL OR v_action NOT IN ('mark_damaged', 'restore_sellable', 'write_off') THEN
        RAISE EXCEPTION 'action must be mark_damaged, restore_sellable, or write_off' USING ERRCODE = '22023';
    END IF;
    IF v_quantity IS NULL OR v_quantity <= 0 THEN
        RAISE EXCEPTION 'quantity must be positive' USING ERRCODE = '22023';
    END IF;
    IF v_reason IS NULL THEN
        RAISE EXCEPTION 'reason is required for damaged stock operations' USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    -- Validate location
    IF NOT EXISTS (
        SELECT 1 FROM public.locations
        WHERE id = v_location_id AND business_id = v_business_id
    ) THEN
        RAISE EXCEPTION 'Location not found or does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Validate variant belongs to business via its parent product
    SELECT pv.id INTO v_valid_variant_id
    FROM public.product_variants pv
    JOIN public.products p ON p.id = pv.product_id
    WHERE pv.id = v_variant_id AND p.business_id = v_business_id;

    IF v_valid_variant_id IS NULL THEN
        RAISE EXCEPTION 'Variant not found or does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Lock balance row FOR UPDATE
    SELECT * INTO v_balance
    FROM public.inventory_balances
    WHERE business_id = v_business_id
      AND location_id = v_location_id
      AND variant_id = v_variant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        v_previous_available := 0;
        v_previous_damaged := 0;
    ELSE
        v_previous_available := v_balance.available_qty;
        v_previous_damaged := v_balance.damaged_qty;
    END IF;

    -- Compute bucket transitions atomically
    IF v_action = 'mark_damaged' THEN
        -- Sellable -> Quarantined Damaged
        IF v_previous_available < v_quantity THEN
            RAISE EXCEPTION 'Insufficient available stock to mark damaged (available: %, requested: %)',
                v_previous_available, v_quantity USING ERRCODE = '22003';
        END IF;
        v_new_available := v_previous_available - v_quantity;
        v_new_damaged   := v_previous_damaged + v_quantity;
        v_avail_delta   := -v_quantity;
        v_dam_delta     := +v_quantity;
        v_on_hand_delta := 0; -- Physical items on premises did not change
        v_event_type    := 'damage';

    ELSIF v_action = 'restore_sellable' THEN
        -- Quarantined Damaged -> Sellable
        IF v_previous_damaged < v_quantity THEN
            RAISE EXCEPTION 'Insufficient damaged stock to restore (damaged: %, requested: %)',
                v_previous_damaged, v_quantity USING ERRCODE = '22003';
        END IF;
        v_new_available := v_previous_available + v_quantity;
        v_new_damaged   := v_previous_damaged - v_quantity;
        v_avail_delta   := +v_quantity;
        v_dam_delta     := -v_quantity;
        v_on_hand_delta := 0; -- Physical items on premises did not change
        v_event_type    := 'damage_restore';

    ELSIF v_action = 'write_off' THEN
        -- Discard / Destroy damaged stock -> leaves facility
        IF v_previous_damaged < v_quantity THEN
            RAISE EXCEPTION 'Insufficient damaged stock to write off (damaged: %, requested: %)',
                v_previous_damaged, v_quantity USING ERRCODE = '22003';
        END IF;
        v_new_available := v_previous_available;
        v_new_damaged   := v_previous_damaged - v_quantity;
        v_avail_delta   := 0;
        v_dam_delta     := -v_quantity;
        v_on_hand_delta := -v_quantity; -- Physical items left facility
        v_event_type    := 'damage_writeoff';
    END IF;

    -- Update or insert balance
    IF v_balance.id IS NULL THEN
        INSERT INTO public.inventory_balances (
            business_id, location_id, variant_id,
            available_qty, committed_qty, damaged_qty,
            last_counted_at, created_at, updated_at
        ) VALUES (
            v_business_id, v_location_id, v_variant_id,
            v_new_available, 0, v_new_damaged,
            NULL, now(), now()
        ) RETURNING * INTO v_balance;
    ELSE
        UPDATE public.inventory_balances
        SET available_qty = v_new_available,
            damaged_qty   = v_new_damaged,
            updated_at    = now()
        WHERE id = v_balance.id
        RETURNING * INTO v_balance;
    END IF;

    -- Append-only audit ledger entry
    INSERT INTO public.inventory_ledger (
        business_id,
        location_id,
        variant_id,
        event_type,
        quantity_delta,
        available_delta,
        committed_delta,
        damaged_delta,
        reference_type,
        reference_id,
        source,
        occurred_at,
        metadata,
        actor_id,
        created_at
    ) VALUES (
        v_business_id,
        v_location_id,
        v_variant_id,
        v_event_type,
        v_on_hand_delta,
        v_avail_delta,
        0,
        v_dam_delta,
        v_reference_type,
        v_reference_id,
        'manual',
        now(),
        jsonb_build_object(
            'action', v_action,
            'reason', v_reason,
            'adjusted_by', auth.uid(),
            'previous_available', v_previous_available,
            'new_available', v_new_available,
            'previous_damaged', v_previous_damaged,
            'new_damaged', v_new_damaged
        ),
        auth.uid(),
        now()
    ) RETURNING id INTO v_ledger_id;

    RETURN jsonb_build_object(
        'success', true,
        'balance_id', v_balance.id,
        'location_id', v_location_id,
        'variant_id', v_variant_id,
        'action', v_action,
        'previous_available', v_previous_available,
        'new_available', v_new_available,
        'previous_damaged', v_previous_damaged,
        'new_damaged', v_new_damaged,
        'available_delta', v_avail_delta,
        'damaged_delta', v_dam_delta,
        'quantity_delta', v_on_hand_delta,
        'ledger_id', v_ledger_id
    );
END;
$$;

ALTER FUNCTION public.record_damaged_stock(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_damaged_stock(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_damaged_stock(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.record_damaged_stock(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.record_damaged_stock(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 4. STOCK COUNT & RECONCILIATION TABLES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.stock_counts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    location_id uuid NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
    count_number text NOT NULL,
    count_type text NOT NULL CHECK (count_type IN ('full', 'cycle', 'zone')),
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'submitted', 'in_reconciliation', 'completed', 'cancelled')),
    notes text,
    started_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    started_at timestamp with time zone,
    submitted_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    submitted_at timestamp with time zone,
    completed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    completed_at timestamp with time zone,
    cancelled_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT stock_counts_business_count_number_key UNIQUE (business_id, count_number),
    CONSTRAINT stock_counts_id_business_id_key UNIQUE (id, business_id)
);

-- Ensure composite uniqueness constraint exists if table already existed
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'stock_counts_id_business_id_key'
    ) THEN
        ALTER TABLE public.stock_counts
            ADD CONSTRAINT stock_counts_id_business_id_key UNIQUE (id, business_id);
    END IF;
END;
$$;

-- Partial unique index preventing overlapping active counts for same business/location (Item H)
CREATE UNIQUE INDEX IF NOT EXISTS stock_counts_active_location_idx
    ON public.stock_counts (business_id, location_id)
    WHERE status IN ('draft', 'in_progress', 'submitted', 'in_reconciliation');

CREATE TABLE IF NOT EXISTS public.stock_count_lines (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    count_id uuid NOT NULL,
    variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE RESTRICT,
    expected_qty integer NOT NULL DEFAULT 0 CHECK (expected_qty >= 0),
    snapshot_balance_version bigint NOT NULL DEFAULT 0,
    snapshot_balance_updated_at timestamp with time zone,
    counted_qty integer CHECK (counted_qty >= 0),
    counted_balance_version bigint,
    reconciled_qty integer CHECK (reconciled_qty >= 0),
    discrepancy integer,
    reason text,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'counted', 'verified', 'discrepancy', 'approved', 'rejected', 'requires_recount')),
    counted_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    counted_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT stock_count_lines_count_variant_key UNIQUE (count_id, variant_id),
    CONSTRAINT stock_count_lines_count_business_fkey
        FOREIGN KEY (count_id, business_id) REFERENCES public.stock_counts(id, business_id) ON DELETE CASCADE
);

-- Ensure columns and composite FK exist if table already existed
ALTER TABLE public.stock_count_lines
    ADD COLUMN IF NOT EXISTS snapshot_balance_version bigint NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS counted_balance_version bigint;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'stock_count_lines_count_business_fkey'
    ) THEN
        ALTER TABLE public.stock_count_lines
            DROP CONSTRAINT IF EXISTS stock_count_lines_count_id_fkey;
        ALTER TABLE public.stock_count_lines
            ADD CONSTRAINT stock_count_lines_count_business_fkey
            FOREIGN KEY (count_id, business_id) REFERENCES public.stock_counts(id, business_id) ON DELETE CASCADE;
    END IF;
END;
$$;

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_stock_counts_business_id ON public.stock_counts(business_id);
CREATE INDEX IF NOT EXISTS idx_stock_counts_location_id ON public.stock_counts(location_id);
CREATE INDEX IF NOT EXISTS idx_stock_counts_status ON public.stock_counts(status);
CREATE INDEX IF NOT EXISTS idx_stock_count_lines_count_id ON public.stock_count_lines(count_id);
CREATE INDEX IF NOT EXISTS idx_stock_count_lines_variant_id ON public.stock_count_lines(variant_id);
CREATE INDEX IF NOT EXISTS idx_stock_count_lines_status ON public.stock_count_lines(status);

-- Enable RLS
ALTER TABLE public.stock_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_count_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "stock_counts_select_inventory_view" ON public.stock_counts;
CREATE POLICY "stock_counts_select_inventory_view" ON public.stock_counts
    FOR SELECT TO authenticated
    USING (public.has_business_permission(business_id, 'inventory.view'));

DROP POLICY IF EXISTS "stock_count_lines_select_inventory_view" ON public.stock_count_lines;
CREATE POLICY "stock_count_lines_select_inventory_view" ON public.stock_count_lines
    FOR SELECT TO authenticated
    USING (public.has_business_permission(business_id, 'inventory.view'));

-- Revoke all direct client mutations; all operations must route through SECURITY DEFINER RPCs
REVOKE ALL ON TABLE public.stock_counts FROM anon;
REVOKE ALL ON TABLE public.stock_count_lines FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.stock_counts FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.stock_count_lines FROM authenticated;

GRANT SELECT ON TABLE public.stock_counts TO authenticated;
GRANT SELECT ON TABLE public.stock_count_lines TO authenticated;
GRANT ALL ON TABLE public.stock_counts TO service_role;
GRANT ALL ON TABLE public.stock_count_lines TO service_role;

-- ---------------------------------------------------------------------------
-- 5. START STOCK COUNT RPC
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.start_stock_count(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := (payload->>'location_id')::uuid;
    v_count_type text := coalesce(nullif(trim(payload->>'count_type'), ''), 'full');
    v_notes text := nullif(trim(payload->>'notes'), '');

    v_count_id uuid;
    v_count_number text;
    v_seq integer;
    v_lines_count integer := 0;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'business_id is required' USING ERRCODE = '22023';
    END IF;
    IF v_location_id IS NULL THEN
        RAISE EXCEPTION 'location_id is required' USING ERRCODE = '22023';
    END IF;

    -- Phase 3 Operational Restriction (Item E): Support full counts only
    IF v_count_type != 'full' THEN
        RAISE EXCEPTION 'Count type "%" is not supported in Phase 3 operations foundation. Only "full" counts are supported.', v_count_type USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    -- Validate location
    IF NOT EXISTS (
        SELECT 1 FROM public.locations
        WHERE id = v_location_id AND business_id = v_business_id
    ) THEN
        RAISE EXCEPTION 'Location not found or does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Prevent overlapping active counts for same location (Item H)
    IF EXISTS (
        SELECT 1 FROM public.stock_counts
        WHERE business_id = v_business_id
          AND location_id = v_location_id
          AND status IN ('draft', 'in_progress', 'submitted', 'in_reconciliation')
    ) THEN
        RAISE EXCEPTION 'An active stock count already exists for this location' USING ERRCODE = '23505';
    END IF;

    -- Generate unique sequential count number under advisory lock per business
    PERFORM pg_advisory_xact_lock(hashtext('threadstock-stock-count-' || v_business_id::text));

    SELECT count(*) + 1 INTO v_seq
    FROM public.stock_counts
    WHERE business_id = v_business_id
      AND extract(year from created_at) = extract(year from now());

    v_count_number := 'SC-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 5, '0');
    WHILE EXISTS (
        SELECT 1 FROM public.stock_counts
        WHERE business_id = v_business_id AND count_number = v_count_number
    ) LOOP
        v_seq := v_seq + 1;
        v_count_number := 'SC-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 5, '0');
    END LOOP;

    -- Create header session in in_progress state
    INSERT INTO public.stock_counts (
        business_id,
        location_id,
        count_number,
        count_type,
        status,
        notes,
        started_by,
        started_at,
        created_at,
        updated_at
    ) VALUES (
        v_business_id,
        v_location_id,
        v_count_number,
        v_count_type,
        'in_progress',
        v_notes,
        auth.uid(),
        now(),
        now(),
        now()
    ) RETURNING id INTO v_count_id;

    -- For a full count, snapshot all active stock-tracked variants for this business
    -- If no balance row exists yet, expected_qty = 0, version = 0, and snapshot_balance_updated_at = NULL
    INSERT INTO public.stock_count_lines (
        business_id,
        count_id,
        variant_id,
        expected_qty,
        snapshot_balance_version,
        snapshot_balance_updated_at,
        status,
        created_at,
        updated_at
    )
    SELECT
        v_business_id,
        v_count_id,
        pv.id,
        coalesce(ib.available_qty, 0),
        coalesce(ib.version, 0),
        ib.updated_at,
        'pending',
        now(),
        now()
    FROM public.product_variants pv
    JOIN public.products p ON p.id = pv.product_id
    LEFT JOIN public.inventory_balances ib
        ON ib.variant_id = pv.id
       AND ib.location_id = v_location_id
       AND ib.business_id = v_business_id
    WHERE p.business_id = v_business_id
      AND p.status = 'active'
      AND p.track_stock_levels = true
      AND pv.status = 'active';

    GET DIAGNOSTICS v_lines_count = ROW_COUNT;

    RETURN jsonb_build_object(
        'success', true,
        'count_id', v_count_id,
        'count_number', v_count_number,
        'location_id', v_location_id,
        'count_type', v_count_type,
        'status', 'in_progress',
        'lines_count', v_lines_count,
        'started_at', now()
    );
END;
$$;

ALTER FUNCTION public.start_stock_count(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.start_stock_count(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.start_stock_count(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.start_stock_count(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.start_stock_count(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 6. SUBMIT STOCK COUNT RPC (SUPPORTS UNEXPECTED SCANNED SKUs)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_stock_count(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_count_id uuid := (payload->>'count_id')::uuid;
    v_lines jsonb := payload->'lines';
    v_line jsonb;
    v_count record;
    v_variant_id uuid;
    v_counted_qty integer;
    v_reason text;
    v_existing_line record;
    v_live_version bigint;
    v_unexpected_sku record;
    v_live_bal_rec record;
    v_remaining_conflicts_count integer := 0;
    v_remaining_conflicts jsonb;
    v_updated_lines_count integer := 0;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_count_id IS NULL THEN
        RAISE EXCEPTION 'count_id is required' USING ERRCODE = '22023';
    END IF;

    -- Lock count header FOR UPDATE
    SELECT * INTO v_count
    FROM public.stock_counts
    WHERE id = v_count_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock count not found' USING ERRCODE = '23503';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_count.business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    -- Allow submission from in_progress, draft, or recount recovery from in_reconciliation
    IF v_count.status NOT IN ('in_progress', 'draft', 'in_reconciliation') THEN
        RAISE EXCEPTION 'Cannot submit stock count in status: %', v_count.status USING ERRCODE = '22023';
    END IF;

    -- Ensure count is not empty
    IF NOT EXISTS (
        SELECT 1 FROM public.stock_count_lines
        WHERE count_id = v_count.id
    ) THEN
        RAISE EXCEPTION 'Cannot submit an empty stock count' USING ERRCODE = '22023';
    END IF;

    IF v_count.status = 'in_reconciliation' AND (v_lines IS NULL OR jsonb_array_length(v_lines) = 0) THEN
        RAISE EXCEPTION 'Recount submission must include lines to recount' USING ERRCODE = '22023';
    END IF;

    -- Process submitted line counts
    IF v_lines IS NOT NULL AND jsonb_typeof(v_lines) = 'array' THEN
        FOR v_line IN SELECT * FROM jsonb_array_elements(v_lines) LOOP
            v_variant_id := (v_line->>'variant_id')::uuid;
            v_counted_qty := (v_line->>'counted_qty')::integer;
            v_reason := nullif(trim(v_line->>'reason'), '');

            IF v_variant_id IS NULL THEN
                RAISE EXCEPTION 'variant_id is required in line' USING ERRCODE = '22023';
            END IF;
            IF v_counted_qty IS NULL OR v_counted_qty < 0 THEN
                RAISE EXCEPTION 'counted_qty cannot be negative' USING ERRCODE = '22023';
            END IF;

            SELECT * INTO v_existing_line
            FROM public.stock_count_lines
            WHERE count_id = v_count.id AND variant_id = v_variant_id;

            -- -----------------------------------------------------------------
            -- RECOUNT RECOVERY WORKFLOW (Count header is in_reconciliation)
            -- -----------------------------------------------------------------
            IF v_count.status = 'in_reconciliation' THEN
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'Variant % is not part of this stock count', v_variant_id USING ERRCODE = '22023';
                END IF;

                -- Only permit updates to lines currently requiring recount/review
                IF v_existing_line.status != 'requires_recount' THEN
                    RAISE EXCEPTION 'Line for variant % does not require recount (current status: %)', v_variant_id, v_existing_line.status USING ERRCODE = '22023';
                END IF;

                -- Lock the corresponding live inventory_balances row
                SELECT available_qty, version, updated_at
                INTO v_live_bal_rec
                FROM public.inventory_balances
                WHERE business_id = v_count.business_id
                  AND location_id = v_count.location_id
                  AND variant_id = v_variant_id
                FOR UPDATE;

                -- Treat this operation as a NEW physical-count baseline for that line
                UPDATE public.stock_count_lines
                SET expected_qty = coalesce(v_live_bal_rec.available_qty, 0),
                    snapshot_balance_version = coalesce(v_live_bal_rec.version, 0),
                    snapshot_balance_updated_at = v_live_bal_rec.updated_at,
                    counted_qty = v_counted_qty,
                    counted_balance_version = coalesce(v_live_bal_rec.version, 0),
                    reconciled_qty = NULL,
                    discrepancy = (v_counted_qty - coalesce(v_live_bal_rec.available_qty, 0)),
                    reason = coalesce(v_reason, 'Recount completed'),
                    status = 'counted',
                    counted_by = auth.uid(),
                    counted_at = now(),
                    updated_at = now()
                WHERE id = v_existing_line.id;

                v_updated_lines_count := v_updated_lines_count + 1;

            -- -----------------------------------------------------------------
            -- INITIAL COUNT SUBMISSION (Count header is draft or in_progress)
            -- -----------------------------------------------------------------
            ELSIF FOUND THEN
                -- Fetch live balance version at moment of submission
                SELECT coalesce(version, 0) INTO v_live_version
                FROM public.inventory_balances
                WHERE business_id = v_count.business_id
                  AND location_id = v_count.location_id
                  AND variant_id = v_variant_id;

                v_live_version := coalesce(v_live_version, 0);

                -- If inventory moved between snapshot and submission, flag as requires_recount
                IF v_live_version != v_existing_line.snapshot_balance_version THEN
                    UPDATE public.stock_count_lines
                    SET counted_qty = v_counted_qty,
                        counted_balance_version = v_live_version,
                        discrepancy = (v_counted_qty - expected_qty),
                        reason      = coalesce(v_reason, 'Stale count: inventory moved before count submission'),
                        status      = 'requires_recount',
                        counted_by  = auth.uid(),
                        counted_at  = now(),
                        updated_at  = now()
                    WHERE id = v_existing_line.id;
                ELSE
                    UPDATE public.stock_count_lines
                    SET counted_qty = v_counted_qty,
                        counted_balance_version = v_live_version,
                        discrepancy = (v_counted_qty - expected_qty),
                        reason      = coalesce(v_reason, reason),
                        status      = 'counted',
                        counted_by  = auth.uid(),
                        counted_at  = now(),
                        updated_at  = now()
                    WHERE id = v_existing_line.id;
                END IF;
                v_updated_lines_count := v_updated_lines_count + 1;
            ELSE
                -- Unexpected SKU scanned during count! (Item F validation)
                -- Must belong to business, active product, active variant, and track_stock_levels = true
                SELECT pv.id, coalesce(ib.available_qty, 0) as avail, coalesce(ib.version, 0) as ver, ib.updated_at
                INTO v_unexpected_sku
                FROM public.product_variants pv
                JOIN public.products p ON p.id = pv.product_id
                LEFT JOIN public.inventory_balances ib
                    ON ib.variant_id = pv.id
                   AND ib.location_id = v_count.location_id
                   AND ib.business_id = v_count.business_id
                WHERE pv.id = v_variant_id
                  AND p.business_id = v_count.business_id
                  AND p.status = 'active'
                  AND p.track_stock_levels = true
                  AND pv.status = 'active';

                IF v_unexpected_sku.id IS NULL THEN
                    RAISE EXCEPTION 'Variant % is not eligible for stock count (must be an active, stock-tracked variant of this business)', v_variant_id USING ERRCODE = '23503';
                END IF;

                INSERT INTO public.stock_count_lines (
                    business_id,
                    count_id,
                    variant_id,
                    expected_qty,
                    snapshot_balance_version,
                    snapshot_balance_updated_at,
                    counted_qty,
                    counted_balance_version,
                    discrepancy,
                    reason,
                    status,
                    counted_by,
                    counted_at,
                    created_at,
                    updated_at
                ) VALUES (
                    v_count.business_id,
                    v_count.id,
                    v_variant_id,
                    v_unexpected_sku.avail,
                    v_unexpected_sku.ver,
                    v_unexpected_sku.updated_at,
                    v_counted_qty,
                    v_unexpected_sku.ver,
                    v_counted_qty - v_unexpected_sku.avail,
                    coalesce(v_reason, 'Unexpected SKU scanned during active count'),
                    'counted',
                    auth.uid(),
                    now(),
                    now(),
                    now()
                );
                v_updated_lines_count := v_updated_lines_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- -------------------------------------------------------------------------
    -- STATUS TRANSITION & RESPONSE
    -- -------------------------------------------------------------------------
    IF v_count.status = 'in_reconciliation' THEN
        -- Check if any lines still require recount
        SELECT count(*), jsonb_agg(jsonb_build_object(
            'line_id', id,
            'variant_id', variant_id,
            'status', status,
            'reason', reason
        ))
        INTO v_remaining_conflicts_count, v_remaining_conflicts
        FROM public.stock_count_lines
        WHERE count_id = v_count.id AND status = 'requires_recount';

        IF v_remaining_conflicts_count > 0 THEN
            -- Other requires_recount lines remain, keep header in_reconciliation
            UPDATE public.stock_counts
            SET updated_at = now()
            WHERE id = v_count.id;

            RETURN jsonb_build_object(
                'success', true,
                'count_id', v_count.id,
                'count_number', v_count.count_number,
                'status', 'in_reconciliation',
                'lines_processed', v_updated_lines_count,
                'remaining_recount_lines_count', v_remaining_conflicts_count,
                'unresolved_lines', coalesce(v_remaining_conflicts, '[]'::jsonb),
                'updated_at', now()
            );
        ELSE
            -- Every required line has a valid physical count again, transition header back to submitted
            UPDATE public.stock_counts
            SET status = 'submitted',
                submitted_by = auth.uid(),
                submitted_at = now(),
                updated_at = now()
            WHERE id = v_count.id;

            RETURN jsonb_build_object(
                'success', true,
                'count_id', v_count.id,
                'count_number', v_count.count_number,
                'status', 'submitted',
                'lines_processed', v_updated_lines_count,
                'remaining_recount_lines_count', 0,
                'submitted_at', now()
            );
        END IF;
    END IF;

    -- For full count, verify that all lines have been physically counted
    IF v_count.count_type = 'full' THEN
        IF EXISTS (
            SELECT 1 FROM public.stock_count_lines
            WHERE count_id = v_count.id AND counted_qty IS NULL
        ) THEN
            RAISE EXCEPTION 'Full stock count cannot be submitted with uncounted lines. All lines must be physically counted.' USING ERRCODE = '22023';
        END IF;
    END IF;

    -- Update count status to submitted
    UPDATE public.stock_counts
    SET status = 'submitted',
        submitted_by = auth.uid(),
        submitted_at = now(),
        updated_at = now()
    WHERE id = v_count.id;

    RETURN jsonb_build_object(
        'success', true,
        'count_id', v_count.id,
        'count_number', v_count.count_number,
        'status', 'submitted',
        'lines_processed', v_updated_lines_count,
        'submitted_at', now()
    );
END;
$$;

ALTER FUNCTION public.submit_stock_count(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.submit_stock_count(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_stock_count(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.submit_stock_count(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.submit_stock_count(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 7. COMPLETE STOCK COUNT RPC (MOVEMENT-SAFE ATOMIC RECONCILIATION)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.complete_stock_count(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_count_id uuid := (payload->>'count_id')::uuid;
    v_reconciled_lines jsonb := payload->'reconciled_lines';
    v_reconciled_entry jsonb;
    v_count record;
    v_line record;
    v_balance record;
    v_approved_qty integer;
    v_audit_variance integer;
    v_live_available integer;
    v_new_available integer;
    v_ledger_id uuid;
    v_reconciled_lines_count integer := 0;
    v_total_adjustments integer := 0;
    v_conflict_count integer := 0;
    v_conflicts jsonb := '[]'::jsonb;
    v_line_conflict text;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_count_id IS NULL THEN
        RAISE EXCEPTION 'count_id is required' USING ERRCODE = '22023';
    END IF;

    -- Lock count header FOR UPDATE
    SELECT * INTO v_count
    FROM public.stock_counts
    WHERE id = v_count_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock count not found' USING ERRCODE = '23503';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_count.business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    -- Concurrency & Idempotency: Reject double completion or cancelled counts
    IF v_count.status = 'completed' THEN
        RAISE EXCEPTION 'Stock count % is already completed', v_count.count_number USING ERRCODE = '22023';
    END IF;
    IF v_count.status = 'cancelled' THEN
        RAISE EXCEPTION 'Cannot complete a cancelled stock count' USING ERRCODE = '22023';
    END IF;
    IF v_count.status NOT IN ('submitted', 'in_reconciliation') THEN
        RAISE EXCEPTION 'Stock count must be submitted before completion (current: %)', v_count.status USING ERRCODE = '22023';
    END IF;

    -- Apply explicit manager overrides provided in payload
    IF v_reconciled_lines IS NOT NULL AND jsonb_typeof(v_reconciled_lines) = 'array' THEN
        FOR v_reconciled_entry IN SELECT * FROM jsonb_array_elements(v_reconciled_lines) LOOP
            UPDATE public.stock_count_lines
            SET reconciled_qty = (v_reconciled_entry->>'reconciled_qty')::integer,
                reason = coalesce(nullif(trim(v_reconciled_entry->>'reason'), ''), reason),
                status = 'counted',
                updated_at = now()
            WHERE count_id = v_count.id
              AND variant_id = (v_reconciled_entry->>'variant_id')::uuid;
        END LOOP;
    END IF;

    -- =========================================================================
    -- STAGE 1: PREFLIGHT PASS (Fail-Closed Conflict Detection, Item G)
    -- =========================================================================
    FOR v_line IN
        SELECT scl.*, p.name as product_name, pv.sku as variant_sku
        FROM public.stock_count_lines scl
        JOIN public.product_variants pv ON pv.id = scl.variant_id
        JOIN public.products p ON p.id = pv.product_id
        WHERE scl.count_id = v_count.id
        ORDER BY scl.id
        FOR UPDATE OF scl
    LOOP
        v_line_conflict := NULL;

        -- 1. Uncounted line check (Item B): Never substitute expected_qty for uncounted line
        IF v_line.counted_qty IS NULL AND v_line.reconciled_qty IS NULL THEN
            v_line_conflict := 'Uncounted line in stock count';
        END IF;

        -- 2. Stale count check (Item A): Did balance version change before physical count submission?
        IF v_line_conflict IS NULL THEN
            IF v_line.status = 'requires_recount' THEN
                v_line_conflict := coalesce(v_line.reason, 'Line flagged as requiring recount');
            ELSIF v_line.counted_balance_version IS NOT NULL
                  AND v_line.counted_balance_version != v_line.snapshot_balance_version
            THEN
                v_line_conflict := 'Stale count: inventory moved before count submission (snapshot v' ||
                    v_line.snapshot_balance_version || ' != counted v' || v_line.counted_balance_version || ')';
            END IF;
        END IF;

        -- 3. Live Balance absorption check: Can live available balance absorb the audit variance?
        IF v_line_conflict IS NULL THEN
            SELECT * INTO v_balance
            FROM public.inventory_balances
            WHERE business_id = v_count.business_id
              AND location_id = v_count.location_id
              AND variant_id = v_line.variant_id;

            v_live_available := coalesce(v_balance.available_qty, 0);
            v_approved_qty := coalesce(v_line.reconciled_qty, v_line.counted_qty);
            v_audit_variance := v_approved_qty - v_line.expected_qty;
            v_new_available := v_live_available + v_audit_variance;

            IF v_new_available < 0 THEN
                v_line_conflict := 'Negative stock conflict: live available (' || v_live_available ||
                    ') cannot absorb audit variance (' || v_audit_variance || ')';
            END IF;
        END IF;

        -- If conflict discovered, mark line as requires_recount
        IF v_line_conflict IS NOT NULL THEN
            UPDATE public.stock_count_lines
            SET status = 'requires_recount',
                reason = v_line_conflict,
                updated_at = now()
            WHERE id = v_line.id;

            v_conflict_count := v_conflict_count + 1;
            v_conflicts := v_conflicts || jsonb_build_object(
                'line_id', v_line.id,
                'variant_id', v_line.variant_id,
                'variant_sku', v_line.variant_sku,
                'product_name', v_line.product_name,
                'conflict', v_line_conflict
            );
        END IF;
    END LOOP;

    -- If any conflicts detected in preflight, abort mutations cleanly and return conflict summary
    IF v_conflict_count > 0 THEN
        UPDATE public.stock_counts
        SET status = 'in_reconciliation',
            updated_at = now()
        WHERE id = v_count.id;

        RETURN jsonb_build_object(
            'success', false,
            'count_id', v_count.id,
            'count_number', v_count.count_number,
            'status', 'in_reconciliation',
            'conflict_count', v_conflict_count,
            'conflicts', v_conflicts,
            'message', 'Stock count has lines requiring recount or review. No inventory balances were modified.'
        );
    END IF;

    -- =========================================================================
    -- STAGE 2: EXECUTION PASS (Only executes when ALL lines pass preflight)
    -- =========================================================================
    FOR v_line IN
        SELECT scl.*, p.name as product_name
        FROM public.stock_count_lines scl
        JOIN public.product_variants pv ON pv.id = scl.variant_id
        JOIN public.products p ON p.id = pv.product_id
        WHERE scl.count_id = v_count.id
        ORDER BY scl.id
    LOOP
        v_approved_qty := coalesce(v_line.reconciled_qty, v_line.counted_qty);
        v_audit_variance := v_approved_qty - v_line.expected_qty;

        -- Lock live balance row FOR UPDATE
        SELECT * INTO v_balance
        FROM public.inventory_balances
        WHERE business_id = v_count.business_id
          AND location_id = v_count.location_id
          AND variant_id = v_line.variant_id
        FOR UPDATE;

        IF NOT FOUND THEN
            v_live_available := 0;
        ELSE
            v_live_available := v_balance.available_qty;
        END IF;

        v_new_available := v_live_available + v_audit_variance;

        -- Update or insert inventory balance
        IF v_balance.id IS NULL THEN
            INSERT INTO public.inventory_balances (
                business_id, location_id, variant_id,
                available_qty, committed_qty, damaged_qty,
                last_counted_at, created_at, updated_at
            ) VALUES (
                v_count.business_id, v_count.location_id, v_line.variant_id,
                v_new_available, 0, 0,
                now(), -- Authoritative physical count completed!
                now(), now()
            ) RETURNING * INTO v_balance;
        ELSE
            UPDATE public.inventory_balances
            SET available_qty   = v_new_available,
                last_counted_at = now(), -- Authoritative physical count completed!
                updated_at      = now()
            WHERE id = v_balance.id
            RETURNING * INTO v_balance;
        END IF;

        -- Append ledger entry if variance != 0
        IF v_audit_variance != 0 THEN
            INSERT INTO public.inventory_ledger (
                business_id,
                location_id,
                variant_id,
                event_type,
                quantity_delta,
                available_delta,
                committed_delta,
                damaged_delta,
                reference_type,
                reference_id,
                source,
                occurred_at,
                metadata,
                actor_id,
                created_at
            ) VALUES (
                v_count.business_id,
                v_count.location_id,
                v_line.variant_id,
                'count_reconciliation',
                v_audit_variance,
                v_audit_variance,
                0,
                0,
                'stock_count',
                v_count.id,
                'manual',
                now(),
                jsonb_build_object(
                    'count_id', v_count.id,
                    'count_number', v_count.count_number,
                    'expected_qty', v_line.expected_qty,
                    'reconciled_qty', v_approved_qty,
                    'variance', v_audit_variance,
                    'live_available_before', v_live_available,
                    'live_available_after', v_new_available,
                    'reason', coalesce(v_line.reason, 'Stock count reconciliation')
                ),
                auth.uid(),
                now()
            ) RETURNING id INTO v_ledger_id;

            v_total_adjustments := v_total_adjustments + 1;
        END IF;

        -- Mark line approved and reconciled
        UPDATE public.stock_count_lines
        SET reconciled_qty = v_approved_qty,
            discrepancy    = v_audit_variance,
            status         = 'approved',
            updated_at     = now()
        WHERE id = v_line.id;

        v_reconciled_lines_count := v_reconciled_lines_count + 1;
    END LOOP;

    -- Mark count header completed
    UPDATE public.stock_counts
    SET status = 'completed',
        completed_by = auth.uid(),
        completed_at = now(),
        updated_at = now()
    WHERE id = v_count.id;

    RETURN jsonb_build_object(
        'success', true,
        'count_id', v_count.id,
        'count_number', v_count.count_number,
        'status', 'completed',
        'lines_reconciled', v_reconciled_lines_count,
        'ledger_adjustments_posted', v_total_adjustments,
        'completed_at', now()
    );
END;
$$;

ALTER FUNCTION public.complete_stock_count(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_stock_count(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_stock_count(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_stock_count(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.complete_stock_count(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 8. CANCEL STOCK COUNT RPC
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cancel_stock_count(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_count_id uuid := (payload->>'count_id')::uuid;
    v_reason text := nullif(trim(payload->>'reason'), '');
    v_count record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_count_id IS NULL THEN
        RAISE EXCEPTION 'count_id is required' USING ERRCODE = '22023';
    END IF;

    -- Lock count header FOR UPDATE
    SELECT * INTO v_count
    FROM public.stock_counts
    WHERE id = v_count_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock count not found' USING ERRCODE = '23503';
    END IF;

    -- Granular RBAC Check: inventory.adjust
    IF NOT public.has_business_permission(v_count.business_id, 'inventory.adjust') THEN
        RAISE EXCEPTION 'Permission denied: inventory.adjust required' USING ERRCODE = '42501';
    END IF;

    IF v_count.status = 'completed' THEN
        RAISE EXCEPTION 'Cannot cancel an already completed stock count' USING ERRCODE = '22023';
    END IF;
    IF v_count.status = 'cancelled' THEN
        RAISE EXCEPTION 'Stock count is already cancelled' USING ERRCODE = '22023';
    END IF;

    UPDATE public.stock_counts
    SET status = 'cancelled',
        cancelled_by = auth.uid(),
        cancelled_at = now(),
        notes = case
            when v_reason is not null then coalesce(notes || ' | Cancellation reason: ' || v_reason, 'Cancellation reason: ' || v_reason)
            else notes
        end,
        updated_at = now()
    WHERE id = v_count.id;

    RETURN jsonb_build_object(
        'success', true,
        'count_id', v_count.id,
        'count_number', v_count.count_number,
        'status', 'cancelled',
        'cancelled_at', now()
    );
END;
$$;

ALTER FUNCTION public.cancel_stock_count(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.cancel_stock_count(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_stock_count(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.cancel_stock_count(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_stock_count(jsonb) TO service_role;

-- ---------------------------------------------------------------------------
-- 9. STRICT BLOCKING POSTCONDITIONS / INVARIANT ASSERTIONS (Item I)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v_test record;
BEGIN
    -- 1. Assert adjust_stock exact signature exists
    IF to_regprocedure('public.adjust_stock(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: adjust_stock(jsonb) missing';
    END IF;

    -- 2. Assert record_damaged_stock exact signature exists
    IF to_regprocedure('public.record_damaged_stock(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: record_damaged_stock(jsonb) missing';
    END IF;

    -- 3. Assert stock count RPC signatures exist
    IF to_regprocedure('public.start_stock_count(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: start_stock_count(jsonb) missing';
    END IF;
    IF to_regprocedure('public.submit_stock_count(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: submit_stock_count(jsonb) missing';
    END IF;
    IF to_regprocedure('public.complete_stock_count(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: complete_stock_count(jsonb) missing';
    END IF;
    IF to_regprocedure('public.cancel_stock_count(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: cancel_stock_count(jsonb) missing';
    END IF;

    -- 4. Assert stock_counts and stock_count_lines have RLS enabled
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'stock_counts' AND rowsecurity = true
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: stock_counts RLS not enabled';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'stock_count_lines' AND rowsecurity = true
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: stock_count_lines RLS not enabled';
    END IF;

    -- 5. Assert direct client mutations on stock_counts & stock_count_lines are revoked
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_privileges
        WHERE table_schema = 'public'
          AND table_name IN ('stock_counts', 'stock_count_lines')
          AND grantee = 'authenticated'
          AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: direct client mutations on stock count tables are not revoked';
    END IF;

    -- 6. Assert inventory_balances and inventory_ledger direct mutations remain revoked
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_privileges
        WHERE table_schema = 'public'
          AND table_name IN ('inventory_balances', 'inventory_ledger')
          AND grantee = 'authenticated'
          AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: direct client mutations on balances/ledger are not revoked';
    END IF;

    -- 7. Assert inventory_ledger columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_ledger' AND column_name = 'available_delta'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_ledger' AND column_name = 'committed_delta'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_ledger' AND column_name = 'damaged_delta'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_ledger' AND column_name = 'actor_id'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_ledger columns missing';
    END IF;

    -- 8. Assert inventory_ledger location and variant foreign keys are RESTRICT (not CASCADE)
    IF EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        WHERE t.relname = 'inventory_ledger'
          AND c.conname IN ('inventory_ledger_location_id_fkey', 'inventory_ledger_variant_id_fkey')
          AND c.confdeltype != 'r' -- 'r' = RESTRICT
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_ledger foreign keys must be ON DELETE RESTRICT';
    END IF;

    -- 9. Assert inventory_balances version column and increment trigger exist (Item A)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_balances' AND column_name = 'version'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_balances.version column missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_inventory_balances_version'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: trg_inventory_balances_version trigger missing';
    END IF;

    -- 10. Assert inventory_ledger backward compatibility trigger exists (Item C)
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_inventory_ledger_compat'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: trg_inventory_ledger_compat trigger missing';
    END IF;

    -- 11. Assert stock_counts active-count collision index exists (Item H)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'stock_counts' AND indexname = 'stock_counts_active_location_idx'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: stock_counts_active_location_idx index missing';
    END IF;

    -- 12. Assert stock-count tenant consistency composite foreign key exists (Item D)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'stock_count_lines_count_business_fkey'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: stock_count_lines_count_business_fkey constraint missing';
    END IF;

    -- 13. Assert stock_count_lines versioning columns exist (Item A)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'stock_count_lines' AND column_name = 'snapshot_balance_version'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'stock_count_lines' AND column_name = 'counted_balance_version'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: stock_count_lines versioning columns missing';
    END IF;

    -- 14. Assert anon cannot execute any stock RPC
    IF EXISTS (
        SELECT 1
        FROM information_schema.routine_privileges
        WHERE routine_schema = 'public'
          AND routine_name IN ('adjust_stock', 'record_damaged_stock', 'start_stock_count', 'submit_stock_count', 'complete_stock_count', 'cancel_stock_count')
          AND grantee = 'anon'
          AND privilege_type = 'EXECUTE'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: anon must not have EXECUTE privilege on stock RPCs';
    END IF;

    -- 15. Assert all new RPCs are owned by postgres
    FOR v_test IN
        SELECT proname FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND proname IN ('adjust_stock', 'record_damaged_stock', 'start_stock_count', 'submit_stock_count', 'complete_stock_count', 'cancel_stock_count')
          AND p.proowner != (SELECT oid FROM pg_roles WHERE rolname = 'postgres')
    LOOP
        RAISE EXCEPTION 'Invariant check failed: RPC % is not owned by postgres', v_test.proname;
    END LOOP;

    RAISE NOTICE 'Migration 022 inventory operations foundation invariant checks PASSED successfully.';
END;
$$;

COMMIT;
