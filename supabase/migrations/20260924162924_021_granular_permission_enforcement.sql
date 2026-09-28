-- ===========================================================================
-- THREADSTOCK — MIGRATION 021: GRANULAR PERMISSION ENFORCEMENT
-- ===========================================================================
-- Description:
--   Upgrades ThreadStock operational security from membership-only baseline
--   to authoritative granular RBAC enforcement using public.has_business_permission().
--
-- Scope:
--   1. Harden existing application RPCs:
--      - complete_sale        -> sales.create
--      - hold_sale            -> sales.hold
--      - resume_held_sale     -> sales.hold
--      - discard_held_sale    -> sales.hold
--      - list_held_sales      -> sales.view
--      - save_or_publish_product -> inventory.manage
--   2. Team invitation delegation and role escalation protection:
--      - create_team_invitation -> team.manage (prevent Owner role escalation & non-delegable perms)
--      - revoke_team_invitation -> team.manage (prevent non-owner revoking Owner invitations)
--      - update_team_member_role -> secure RPC with delegation validation & owner row immutability
--   3. Inventory balances & ledger lockdown:
--      - Revoke direct INSERT/UPDATE/DELETE on inventory_balances & inventory_ledger
--      - Ledger is strictly append-only and client-immutable
--      - Introduce adjust_stock(payload jsonb) RPC requiring inventory.adjust
--   4. Permission-specific RLS policies for business tables:
--      - products, product_variants, brands, categories, collections -> inventory.manage (mutation), inventory.view (read)
--      - customers -> customers.manage (mutation), customers.view (read)
--      - suppliers -> purchasing.manage (mutation), purchasing.view (read)
--      - locations -> settings.manage (mutation), member read preserved for checkout/inventory
--      - business_profile_settings, business_commerce_profiles -> settings.manage (mutation), member read preserved
--      - inventory_import_jobs, inventory_import_rows, inventory_import_errors -> inventory.import
--      - sales, sale_items, sale_payments -> sales.view (read), mutations strictly via secure RPCs
--      - memberships, team_members -> team.view (read), mutations strictly Owner-governed
--   5. Invariant assertions ensuring 100% fail-closed authorization.
-- ===========================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. HARDEN EXISTING APPLICATION RPCS WITH GRANULAR PERMISSIONS
-- ---------------------------------------------------------------------------

-- 1A. complete_sale (requires sales.create)
CREATE OR REPLACE FUNCTION public.complete_sale(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_customer_id uuid := nullif(payload->>'customer_id', '')::uuid;
    v_subtotal_minor bigint;
    v_discount_minor bigint;
    v_tax_minor bigint;
    v_total_minor bigint;
    v_currency_code text;
    v_discount_type text := coalesce(nullif(payload->>'discount_type', ''), 'none');
    v_discount_rate numeric := coalesce((payload->>'discount_rate')::numeric, 0);
    v_flat_minor bigint := coalesce((payload->>'discount_minor')::bigint, 0);
    v_note text := payload->>'note';
    v_idempotency_key text := nullif(trim(payload->>'idempotency_key'), '');
    v_requested_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_items jsonb := case
        when payload->'items' is null or jsonb_typeof(payload->'items') <> 'array'
        then '[]'::jsonb
        else payload->'items'
    end;
    v_payments jsonb := case
        when payload->'payments' is null or jsonb_typeof(payload->'payments') <> 'array'
        then '[]'::jsonb
        else payload->'payments'
    end;
    v_resolved jsonb;
    v_lines jsonb;
    v_quote jsonb;
    v_line jsonb;
    v_line_index integer := 0;
    v_discounts jsonb;
    v_line_gross bigint;
    v_item_disc bigint;
    v_item_taxable bigint;
    v_stock record;

    v_existing_sale record;
    v_sale_id uuid;
    v_sale_number text;
    v_seq integer;

    v_current_available integer;
    v_total_payments bigint := 0;
    v_payment jsonb;
    v_pay_method text;
    v_pay_amount bigint;
    v_pay_proc text;
    v_pay_ref text;
    v_pay_notes text;
begin
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: sales.create
    if not public.has_business_permission(v_business_id, 'sales.create') then
        raise exception 'Permission denied: sales.create required' using errcode = '42501';
    end if;

    if v_idempotency_key is not null then
        select * into v_existing_sale
        from public.sales
        where business_id = v_business_id
          and idempotency_key = v_idempotency_key
        limit 1;

        if v_existing_sale is not null and v_existing_sale.status = 'completed' then
            return jsonb_build_object(
                'success', true,
                'is_idempotent_replay', true,
                'sale_id', v_existing_sale.id,
                'sale_number', v_existing_sale.sale_number,
                'subtotal_minor', v_existing_sale.subtotal_minor,
                'discount_minor', v_existing_sale.discount_minor,
                'tax_minor', v_existing_sale.tax_minor,
                'total_minor', v_existing_sale.total_minor,
                'currency_code', v_existing_sale.currency_code,
                'completed_at', v_existing_sale.completed_at
            );
        end if;
    end if;

    if v_location_id is null then
        select id into v_location_id
        from public.locations
        where business_id = v_business_id
        order by created_at asc
        limit 1;
    elsif not exists (
        select 1
        from public.locations
        where id = v_location_id
          and business_id = v_business_id
    ) then
        raise exception 'Location is not available';
    end if;

    if v_location_id is null then
        raise exception 'No valid location found for this business. Configure a location before making sales.';
    end if;

    if v_customer_id is not null and not exists (
        select 1
        from public.customers
        where id = v_customer_id
          and business_id = v_business_id
    ) then
        raise exception 'Customer is not available';
    end if;

    if jsonb_array_length(v_items) = 0 then
        raise exception 'Cart is empty. Add at least one item to complete a sale.';
    end if;

    v_resolved := public.resolve_sale_lines(v_business_id, v_items);
    v_currency_code := v_resolved->>'currency_code';
    v_subtotal_minor := (v_resolved->>'subtotal_minor')::bigint;
    v_lines := v_resolved->'lines';
    v_quote := public.calculate_sale_discount(v_subtotal_minor, v_discount_type, v_discount_rate, v_flat_minor);
    v_discount_type := v_quote->>'discount_type';
    v_discount_rate := (v_quote->>'discount_rate')::numeric;
    v_discount_minor := (v_quote->>'discount_minor')::bigint;
    v_tax_minor := (v_quote->>'tax_minor')::bigint;
    v_total_minor := (v_quote->>'total_minor')::bigint;

    if v_total_minor < 0 then
        raise exception 'Sale total is not valid';
    end if;

    -- sale_payments.amount_minor is the amount applied to the sale.
    -- There is no tendered/change column, so the stored payments must
    -- equal the server total. A zero total needs no payment row.
    for v_payment in select * from jsonb_array_elements(v_payments) loop
        v_pay_amount := coalesce((v_payment->>'amount_minor')::bigint, 0);
        if v_pay_amount <= 0 then
            raise exception 'Payment amount must be greater than zero.';
        end if;
        v_total_payments := v_total_payments + v_pay_amount;
    end loop;

    if v_total_minor > 0 and jsonb_array_length(v_payments) = 0 then
        raise exception 'No payment method selected. Please choose a payment method.';
    end if;

    if v_total_payments <> v_total_minor then
        raise exception 'Total payments (%) must equal the sale total (%).', v_total_payments, v_total_minor;
    end if;

    for v_stock in
        select
            (line->>'variant_id')::uuid as variant_id,
            sum((line->>'quantity')::integer) as quantity,
            max(line->>'product_name_snapshot') as product_name
        from jsonb_array_elements(v_lines) line
        group by (line->>'variant_id')::uuid
    loop
        select available_qty into v_current_available
        from public.inventory_balances
        where business_id = v_business_id
          and location_id = v_location_id
          and variant_id = v_stock.variant_id
        for update;

        if v_current_available is null or v_current_available < v_stock.quantity then
            raise exception '% only has % units available. Reduce the quantity before completing this sale.',
                v_stock.product_name,
                coalesce(v_current_available, 0);
        end if;
    end loop;

    if v_requested_sale_id is not null then
        select * into v_existing_sale
        from public.sales
        where id = v_requested_sale_id
          and business_id = v_business_id
        for update;

        if not found or v_existing_sale.status <> 'held' then
            raise exception 'Held sale not found';
        end if;

        v_sale_id := v_existing_sale.id;
        v_sale_number := v_existing_sale.sale_number;

        update public.sales
        set location_id = v_location_id,
            customer_id = v_customer_id,
            status = 'completed',
            subtotal_minor = v_subtotal_minor,
            discount_minor = v_discount_minor,
            tax_minor = v_tax_minor,
            total_minor = v_total_minor,
            currency_code = v_currency_code,
            discount_type = v_discount_type,
            discount_rate = v_discount_rate,
            note = v_note,
            idempotency_key = coalesce(v_idempotency_key, idempotency_key),
            completed_at = now()
        where id = v_sale_id
          and business_id = v_business_id
          and status = 'held';

        delete from public.sale_items si
        using public.sales s
        where si.sale_id = s.id
          and s.id = v_sale_id
          and s.business_id = v_business_id;
    else
        select count(*) + 1 into v_seq
        from public.sales
        where business_id = v_business_id
          and extract(year from created_at) = extract(year from now());

        v_sale_number := 'TS-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 6, '0');
        while exists (
            select 1 from public.sales
            where business_id = v_business_id and sale_number = v_sale_number
        ) loop
            v_seq := v_seq + 1;
            v_sale_number := 'TS-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 6, '0');
        end loop;

        insert into public.sales (
            business_id,
            location_id,
            sale_number,
            customer_id,
            status,
            subtotal_minor,
            discount_minor,
            tax_minor,
            total_minor,
            currency_code,
            discount_type,
            discount_rate,
            note,
            idempotency_key,
            created_by,
            completed_at
        ) values (
            v_business_id,
            v_location_id,
            v_sale_number,
            v_customer_id,
            'completed',
            v_subtotal_minor,
            v_discount_minor,
            v_tax_minor,
            v_total_minor,
            v_currency_code,
            v_discount_type,
            v_discount_rate,
            v_note,
            v_idempotency_key,
            auth.uid(),
            now()
        ) returning id into v_sale_id;
    end if;

    v_discounts := public.allocate_sale_line_discounts(v_lines, v_subtotal_minor, v_discount_minor);
    for v_line in select value from jsonb_array_elements(v_lines) loop
        v_line_index := v_line_index + 1;
        v_line_gross := (v_line->>'line_gross_minor')::bigint;
        v_item_disc := coalesce((v_discounts->>(v_line_index - 1))::bigint, 0);
        v_item_taxable := v_line_gross - v_item_disc;

        insert into public.sale_items (
            sale_id,
            product_id,
            variant_id,
            sku_snapshot,
            product_name_snapshot,
            variant_title_snapshot,
            quantity,
            unit_price_minor,
            unit_cost_minor,
            discount_minor,
            taxable_amount_minor,
            tax_minor,
            line_total_minor,
            tax_category_snapshot
        ) values (
            v_sale_id,
            (v_line->>'product_id')::uuid,
            (v_line->>'variant_id')::uuid,
            v_line->>'sku_snapshot',
            v_line->>'product_name_snapshot',
            v_line->>'variant_title_snapshot',
            (v_line->>'quantity')::integer,
            (v_line->>'unit_price_minor')::bigint,
            (v_line->>'unit_cost_minor')::bigint,
            v_item_disc,
            v_item_taxable,
            0,
            v_item_taxable,
            v_line->>'tax_category_snapshot'
        );

        update public.inventory_balances
        set available_qty = available_qty - (v_line->>'quantity')::integer,
            updated_at = now()
        where business_id = v_business_id
          and location_id = v_location_id
          and variant_id = (v_line->>'variant_id')::uuid;

        insert into public.inventory_ledger (
            business_id,
            location_id,
            variant_id,
            event_type,
            quantity_delta,
            reference_type,
            reference_id,
            source,
            metadata
        ) values (
            v_business_id,
            v_location_id,
            (v_line->>'variant_id')::uuid,
            'sale',
            -(v_line->>'quantity')::integer,
            'sale',
            v_sale_id,
            'sale',
            jsonb_build_object(
                'sale_number', v_sale_number,
                'unit_price_cents', (v_line->>'unit_price_minor')::bigint,
                'sku', v_line->>'sku_snapshot',
                'product_name', v_line->>'product_name_snapshot'
            )
        );
    end loop;

    for v_payment in select * from jsonb_array_elements(v_payments) loop
        v_pay_method := coalesce(v_payment->>'payment_method', 'cash');
        v_pay_amount := (v_payment->>'amount_minor')::bigint;
        v_pay_proc := 'recorded';
        v_pay_ref := v_payment->>'reference_number';
        v_pay_notes := v_payment->>'notes';

        insert into public.sale_payments (
            sale_id,
            business_id,
            payment_method,
            amount_minor,
            currency_code,
            status,
            processing_type,
            reference_number,
            notes
        ) values (
            v_sale_id,
            v_business_id,
            v_pay_method,
            v_pay_amount,
            v_currency_code,
            'completed',
            v_pay_proc,
            v_pay_ref,
            v_pay_notes
        );
    end loop;

    return jsonb_build_object(
        'success', true,
        'sale_id', v_sale_id,
        'sale_number', v_sale_number,
        'subtotal_minor', v_subtotal_minor,
        'discount_minor', v_discount_minor,
        'tax_minor', v_tax_minor,
        'total_minor', v_total_minor,
        'currency_code', v_currency_code,
        'completed_at', now()
    );
end;
$$;

ALTER FUNCTION public.complete_sale(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_sale(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_sale(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_sale(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.complete_sale(jsonb) TO service_role;


-- 1B. hold_sale (requires sales.hold)
CREATE OR REPLACE FUNCTION public.hold_sale(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_customer_id uuid := nullif(payload->>'customer_id', '')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_subtotal_minor bigint;
    v_discount_minor bigint;
    v_tax_minor bigint;
    v_total_minor bigint;
    v_currency_code text;
    v_discount_type text := coalesce(nullif(payload->>'discount_type', ''), 'none');
    v_discount_rate numeric := coalesce((payload->>'discount_rate')::numeric, 0);
    v_flat_minor bigint := coalesce((payload->>'discount_minor')::bigint, 0);
    v_note text := nullif(trim(payload->>'note'), '');
    v_items jsonb := case
        when payload->'items' is null or jsonb_typeof(payload->'items') <> 'array'
        then '[]'::jsonb
        else payload->'items'
    end;
    v_resolved jsonb;
    v_lines jsonb;
    v_quote jsonb;
    v_line jsonb;
    v_line_index integer := 0;
    v_discounts jsonb;
    v_line_gross bigint;
    v_item_disc bigint;
    v_item_taxable bigint;

    v_existing_sale record;
    v_sale_number text;
    v_seq integer;
    v_held_at timestamptz := now();
begin
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: sales.hold
    if not public.has_business_permission(v_business_id, 'sales.hold') then
        raise exception 'Permission denied: sales.hold required' using errcode = '42501';
    end if;

    if v_location_id is null then
        select id into v_location_id
        from public.locations
        where business_id = v_business_id
        order by created_at asc
        limit 1;
    elsif not exists (
        select 1
        from public.locations
        where id = v_location_id
          and business_id = v_business_id
    ) then
        raise exception 'Location is not available';
    end if;

    if v_location_id is null then
        raise exception 'No valid location found for this business. Configure a location before holding a sale.';
    end if;

    if v_customer_id is not null and not exists (
        select 1
        from public.customers
        where id = v_customer_id
          and business_id = v_business_id
    ) then
        raise exception 'Customer is not available';
    end if;

    if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) = 0 then
        raise exception 'Cart is empty. Add at least one item to hold a sale.';
    end if;

    v_resolved := public.resolve_sale_lines(v_business_id, v_items);
    v_currency_code := v_resolved->>'currency_code';
    v_subtotal_minor := (v_resolved->>'subtotal_minor')::bigint;
    v_lines := v_resolved->'lines';
    v_quote := public.calculate_sale_discount(v_subtotal_minor, v_discount_type, v_discount_rate, v_flat_minor);
    v_discount_type := v_quote->>'discount_type';
    v_discount_rate := (v_quote->>'discount_rate')::numeric;
    v_discount_minor := (v_quote->>'discount_minor')::bigint;
    v_tax_minor := (v_quote->>'tax_minor')::bigint;
    v_total_minor := (v_quote->>'total_minor')::bigint;

    if v_sale_id is not null then
        select * into v_existing_sale
        from public.sales
        where id = v_sale_id
          and business_id = v_business_id
        for update;

        if not found or v_existing_sale.status <> 'held' then
            raise exception 'Held sale not found';
        end if;

        v_sale_number := v_existing_sale.sale_number;

        update public.sales
        set location_id = v_location_id,
            customer_id = v_customer_id,
            subtotal_minor = v_subtotal_minor,
            discount_minor = v_discount_minor,
            tax_minor = v_tax_minor,
            total_minor = v_total_minor,
            currency_code = v_currency_code,
            discount_type = v_discount_type,
            discount_rate = v_discount_rate,
            note = v_note,
            held_at = v_held_at,
            held_by = auth.uid(),
            completed_at = null
        where id = v_sale_id
          and business_id = v_business_id
          and status = 'held';

        delete from public.sale_items si
        using public.sales s
        where si.sale_id = s.id
          and s.id = v_sale_id
          and s.business_id = v_business_id;
    else
        perform pg_advisory_xact_lock(hashtext('threadstock-sale-' || v_business_id::text));

        select count(*) + 1 into v_seq
        from public.sales
        where business_id = v_business_id
          and extract(year from created_at) = extract(year from now());

        v_sale_number := 'TS-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 6, '0');
        while exists (
            select 1
            from public.sales
            where business_id = v_business_id
              and sale_number = v_sale_number
        ) loop
            v_seq := v_seq + 1;
            v_sale_number := 'TS-' || to_char(now(), 'YYYY') || '-' || lpad(v_seq::text, 6, '0');
        end loop;

        insert into public.sales (
            business_id,
            location_id,
            sale_number,
            customer_id,
            status,
            subtotal_minor,
            discount_minor,
            tax_minor,
            total_minor,
            currency_code,
            discount_type,
            discount_rate,
            note,
            created_by,
            held_by,
            held_at,
            completed_at
        ) values (
            v_business_id,
            v_location_id,
            v_sale_number,
            v_customer_id,
            'held',
            v_subtotal_minor,
            v_discount_minor,
            v_tax_minor,
            v_total_minor,
            v_currency_code,
            v_discount_type,
            v_discount_rate,
            v_note,
            auth.uid(),
            auth.uid(),
            v_held_at,
            null
        ) returning id into v_sale_id;
    end if;

    v_discounts := public.allocate_sale_line_discounts(v_lines, v_subtotal_minor, v_discount_minor);
    for v_line in select value from jsonb_array_elements(v_lines) loop
        v_line_index := v_line_index + 1;
        v_line_gross := (v_line->>'line_gross_minor')::bigint;
        v_item_disc := coalesce((v_discounts->>(v_line_index - 1))::bigint, 0);
        v_item_taxable := v_line_gross - v_item_disc;

        insert into public.sale_items (
            sale_id,
            product_id,
            variant_id,
            sku_snapshot,
            product_name_snapshot,
            variant_title_snapshot,
            quantity,
            unit_price_minor,
            unit_cost_minor,
            discount_minor,
            taxable_amount_minor,
            tax_minor,
            line_total_minor,
            tax_category_snapshot
        ) values (
            v_sale_id,
            (v_line->>'product_id')::uuid,
            (v_line->>'variant_id')::uuid,
            v_line->>'sku_snapshot',
            v_line->>'product_name_snapshot',
            v_line->>'variant_title_snapshot',
            (v_line->>'quantity')::integer,
            (v_line->>'unit_price_minor')::bigint,
            (v_line->>'unit_cost_minor')::bigint,
            v_item_disc,
            v_item_taxable,
            0,
            v_item_taxable,
            v_line->>'tax_category_snapshot'
        );
    end loop;

    return jsonb_build_object(
        'success', true,
        'sale_id', v_sale_id,
        'sale_number', v_sale_number,
        'status', 'held',
        'business_id', v_business_id,
        'location_id', v_location_id,
        'customer_id', v_customer_id,
        'subtotal_minor', v_subtotal_minor,
        'discount_minor', v_discount_minor,
        'tax_minor', v_tax_minor,
        'total_minor', v_total_minor,
        'currency_code', v_currency_code,
        'discount_type', v_discount_type,
        'discount_rate', v_discount_rate,
        'note', v_note,
        'held_at', v_held_at,
        'held_by', auth.uid()
    );
end;
$$;

ALTER FUNCTION public.hold_sale(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.hold_sale(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.hold_sale(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.hold_sale(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.hold_sale(jsonb) TO service_role;


-- 1C. resume_held_sale (requires sales.hold)
CREATE OR REPLACE FUNCTION public.resume_held_sale(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_sale record;
    v_item record;
    v_items jsonb := '[]'::jsonb;
    v_warnings jsonb := '[]'::jsonb;
    v_available integer;
    v_product_in_tenant boolean;
    v_variant_in_tenant boolean;
begin
    if v_business_id is null or v_sale_id is null then
        raise exception 'business_id and sale_id are required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: sales.hold
    if not public.has_business_permission(v_business_id, 'sales.hold') then
        raise exception 'Permission denied: sales.hold required' using errcode = '42501';
    end if;

    select
        s.*,
        c.id as joined_customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        l.id as joined_location_id,
        l.name as location_name,
        pr.full_name as held_by_name
    into v_sale
    from public.sales s
    left join public.customers c
        on c.id = s.customer_id
       and c.business_id = s.business_id
    left join public.locations l
        on l.id = s.location_id
       and l.business_id = s.business_id
    left join public.profiles pr on pr.id = s.held_by
    where s.id = v_sale_id
      and s.business_id = v_business_id;

    if not found or v_sale.status <> 'held' then
        raise exception 'Held sale not found';
    end if;

    for v_item in
        select *
        from public.sale_items
        where sale_id = v_sale.id
        order by created_at
    loop
        v_product_in_tenant := v_item.product_id is not null and exists (
            select 1
            from public.products p
            where p.id = v_item.product_id
              and p.business_id = v_business_id
        );

        v_variant_in_tenant := v_item.variant_id is not null and exists (
            select 1
            from public.product_variants pv
            join public.products p on p.id = pv.product_id
            where pv.id = v_item.variant_id
              and p.business_id = v_business_id
              and (v_item.product_id is null or pv.product_id = v_item.product_id)
        );

        v_available := 0;
        if v_variant_in_tenant then
            select ib.available_qty into v_available
            from public.inventory_balances ib
            join public.product_variants pv on pv.id = ib.variant_id
            join public.products p on p.id = pv.product_id
            where ib.business_id = v_business_id
              and ib.location_id = v_sale.joined_location_id
              and ib.variant_id = v_item.variant_id
              and p.business_id = v_business_id
              and (v_item.product_id is null or pv.product_id = v_item.product_id);
            v_available := coalesce(v_available, 0);
        end if;

        v_items := v_items || jsonb_build_array(
            jsonb_build_object(
                'id', v_item.id,
                'sale_id', v_item.sale_id,
                'product_id', case when v_product_in_tenant then v_item.product_id else null end,
                'variant_id', case when v_variant_in_tenant then v_item.variant_id else null end,
                'sku_snapshot', v_item.sku_snapshot,
                'product_name_snapshot', v_item.product_name_snapshot,
                'variant_title_snapshot', v_item.variant_title_snapshot,
                'quantity', v_item.quantity,
                'unit_price_minor', v_item.unit_price_minor,
                'unit_cost_minor', v_item.unit_cost_minor,
                'discount_minor', v_item.discount_minor,
                'taxable_amount_minor', v_item.taxable_amount_minor,
                'tax_minor', v_item.tax_minor,
                'line_total_minor', v_item.line_total_minor,
                'tax_category_snapshot', v_item.tax_category_snapshot,
                'available_qty', v_available
            )
        );

        if v_variant_in_tenant and v_item.quantity > v_available then
            v_warnings := v_warnings || jsonb_build_array(
                jsonb_build_object(
                    'product_name', v_item.product_name_snapshot,
                    'sku', v_item.sku_snapshot,
                    'variant_id', v_item.variant_id,
                    'requested', v_item.quantity,
                    'available', v_available
                )
            );
        end if;
    end loop;

    return jsonb_build_object(
        'success', true,
        'sale', jsonb_build_object(
            'id', v_sale.id,
            'business_id', v_sale.business_id,
            'location_id', v_sale.joined_location_id,
            'location_name', v_sale.location_name,
            'sale_number', v_sale.sale_number,
            'customer_id', v_sale.joined_customer_id,
            'customer_name', v_sale.customer_name,
            'customer_phone', v_sale.customer_phone,
            'status', v_sale.status,
            'subtotal_minor', v_sale.subtotal_minor,
            'discount_minor', v_sale.discount_minor,
            'tax_minor', v_sale.tax_minor,
            'total_minor', v_sale.total_minor,
            'currency_code', v_sale.currency_code,
            'discount_type', v_sale.discount_type,
            'discount_rate', v_sale.discount_rate,
            'note', v_sale.note,
            'held_at', v_sale.held_at,
            'held_by', v_sale.held_by,
            'held_by_name', v_sale.held_by_name,
            'created_at', v_sale.created_at,
            'items', v_items
        ),
        'stock_warnings', v_warnings
    );
end;
$$;

ALTER FUNCTION public.resume_held_sale(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.resume_held_sale(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resume_held_sale(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.resume_held_sale(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.resume_held_sale(jsonb) TO service_role;


-- 1D. discard_held_sale (requires sales.hold)
CREATE OR REPLACE FUNCTION public.discard_held_sale(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_sale record;
begin
    if v_business_id is null or v_sale_id is null then
        raise exception 'business_id and sale_id are required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: sales.hold
    if not public.has_business_permission(v_business_id, 'sales.hold') then
        raise exception 'Permission denied: sales.hold required' using errcode = '42501';
    end if;

    select * into v_sale
    from public.sales
    where id = v_sale_id
      and business_id = v_business_id
    for update;

    if not found or v_sale.status <> 'held' then
        raise exception 'Held sale not found';
    end if;

    update public.sales
    set status = 'cancelled',
        completed_at = null
    where id = v_sale_id
      and business_id = v_business_id
      and status = 'held';

    return jsonb_build_object(
        'success', true,
        'sale_id', v_sale_id,
        'sale_number', v_sale.sale_number,
        'status', 'cancelled'
    );
end;
$$;

ALTER FUNCTION public.discard_held_sale(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.discard_held_sale(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.discard_held_sale(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.discard_held_sale(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.discard_held_sale(jsonb) TO service_role;


-- 1E. list_held_sales (requires sales.view)
CREATE OR REPLACE FUNCTION public.list_held_sales(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_sale record;
    v_items jsonb;
    v_result jsonb := '[]'::jsonb;
begin
    if p_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(p_business_id);

    -- Granular RBAC Check: sales.view
    if not public.has_business_permission(p_business_id, 'sales.view') then
        raise exception 'Permission denied: sales.view required' using errcode = '42501';
    end if;

    for v_sale in
        select
            s.*,
            c.id as joined_customer_id,
            c.name as customer_name,
            c.phone as customer_phone,
            l.id as joined_location_id,
            l.name as location_name,
            pr.full_name as held_by_name
        from public.sales s
        left join public.customers c
            on c.id = s.customer_id
           and c.business_id = s.business_id
        left join public.locations l
            on l.id = s.location_id
           and l.business_id = s.business_id
        left join public.profiles pr on pr.id = s.held_by
        where s.business_id = p_business_id
          and s.status = 'held'
        order by coalesce(s.held_at, s.created_at) desc
    loop
        select coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id', si.id,
                    'sale_id', si.sale_id,
                    'product_id', case
                        when exists (
                            select 1
                            from public.products p
                            where p.id = si.product_id
                              and p.business_id = p_business_id
                        ) then si.product_id
                        else null
                    end,
                    'variant_id', case
                        when exists (
                            select 1
                            from public.product_variants pv
                            join public.products p on p.id = pv.product_id
                            where pv.id = si.variant_id
                              and p.business_id = p_business_id
                              and (si.product_id is null or pv.product_id = si.product_id)
                        ) then si.variant_id
                        else null
                    end,
                    'sku_snapshot', si.sku_snapshot,
                    'product_name_snapshot', si.product_name_snapshot,
                    'variant_title_snapshot', si.variant_title_snapshot,
                    'quantity', si.quantity,
                    'unit_price_minor', si.unit_price_minor,
                    'unit_cost_minor', si.unit_cost_minor,
                    'discount_minor', si.discount_minor,
                    'taxable_amount_minor', si.taxable_amount_minor,
                    'tax_minor', si.tax_minor,
                    'line_total_minor', si.line_total_minor,
                    'tax_category_snapshot', si.tax_category_snapshot
                )
                order by si.created_at
            ),
            '[]'::jsonb
        )
        into v_items
        from public.sale_items si
        where si.sale_id = v_sale.id;

        v_result := v_result || jsonb_build_array(
            jsonb_build_object(
                'id', v_sale.id,
                'business_id', v_sale.business_id,
                'location_id', v_sale.joined_location_id,
                'location_name', v_sale.location_name,
                'sale_number', v_sale.sale_number,
                'customer_id', v_sale.joined_customer_id,
                'customer_name', v_sale.customer_name,
                'customer_phone', v_sale.customer_phone,
                'status', v_sale.status,
                'subtotal_minor', v_sale.subtotal_minor,
                'discount_minor', v_sale.discount_minor,
                'tax_minor', v_sale.tax_minor,
                'total_minor', v_sale.total_minor,
                'currency_code', v_sale.currency_code,
                'discount_type', v_sale.discount_type,
                'discount_rate', v_sale.discount_rate,
                'note', v_sale.note,
                'held_at', v_sale.held_at,
                'held_by', v_sale.held_by,
                'held_by_name', v_sale.held_by_name,
                'created_at', v_sale.created_at,
                'items', v_items
            )
        );
    end loop;

    return v_result;
end;
$$;

ALTER FUNCTION public.list_held_sales(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_held_sales(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_held_sales(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_held_sales(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.list_held_sales(uuid) TO service_role;


-- 1F. save_or_publish_product (requires inventory.manage)
CREATE OR REPLACE FUNCTION public.save_or_publish_product(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_product_id uuid := nullif(payload->>'id', '')::uuid;
    v_name text := trim(payload->>'name');
    v_description text := payload->>'description';
    v_brand_id uuid := nullif(payload->>'brand_id', '')::uuid;
    v_category_id uuid := nullif(payload->>'category_id', '')::uuid;
    v_supplier_id uuid := nullif(payload->>'supplier_id', '')::uuid;
    v_tax_category text := payload->>'tax_category';
    v_status text := coalesce(payload->>'status', 'draft');
    v_track_stock boolean := coalesce((payload->>'track_stock_levels')::boolean, false);
    v_low_stock integer := (payload->>'low_stock_threshold')::integer;
    v_sku text := nullif(trim(payload->>'sku'), '');
    v_barcode text := nullif(trim(payload->>'barcode'), '');
    v_cost_price_cents bigint := coalesce((payload->>'cost_price_cents')::bigint, 0);
    v_retail_price_cents bigint := coalesce((payload->>'retail_price_cents')::bigint, 0);
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_opening_stock integer := coalesce((payload->>'opening_stock')::integer, 0);

    v_result_product record;
    v_variant_id uuid;
begin
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: inventory.manage
    if not public.has_business_permission(v_business_id, 'inventory.manage') then
        raise exception 'Permission denied: inventory.manage required' using errcode = '42501';
    end if;

    if v_name is null or length(v_name) = 0 then
        raise exception 'Product name is required';
    end if;
    if v_cost_price_cents < 0 or v_retail_price_cents < 0 then
        raise exception 'Prices cannot be negative';
    end if;

    if v_brand_id is not null and not exists (
        select 1 from public.brands
        where id = v_brand_id and business_id = v_business_id
    ) then
        raise exception 'Brand is not available';
    end if;

    if v_category_id is not null and not exists (
        select 1 from public.categories
        where id = v_category_id and business_id = v_business_id
    ) then
        raise exception 'Category is not available';
    end if;

    if v_supplier_id is not null and not exists (
        select 1 from public.suppliers
        where id = v_supplier_id and business_id = v_business_id
    ) then
        raise exception 'Supplier is not available';
    end if;

    if v_location_id is not null and not exists (
        select 1 from public.locations
        where id = v_location_id and business_id = v_business_id
    ) then
        raise exception 'Location is not available';
    end if;

    if v_status = 'active' then
        if v_brand_id is null then
            raise exception 'Select a brand.';
        end if;
        if v_category_id is null then
            raise exception 'Select a category.';
        end if;
        if v_retail_price_cents <= 0 then
            raise exception 'Enter a selling price greater than 0.';
        end if;
        if v_sku is null then
            raise exception 'A valid System SKU is required to publish.';
        end if;
    end if;

    if v_product_id is not null then
        update public.products
        set
            name = v_name,
            description = v_description,
            brand_id = v_brand_id,
            category_id = v_category_id,
            supplier_id = v_supplier_id,
            tax_category = v_tax_category,
            status = v_status,
            track_stock_levels = v_track_stock,
            low_stock_threshold = v_low_stock,
            published_at = case when v_status = 'active' and published_at is null then now() else published_at end,
            updated_at = now()
        where id = v_product_id and business_id = v_business_id
        returning * into v_result_product;

        if v_result_product is null then
            raise exception 'Product is not available';
        end if;
    else
        insert into public.products (
            business_id, name, description, brand_id, category_id, supplier_id,
            tax_category, status, track_stock_levels, low_stock_threshold, published_at
        ) values (
            v_business_id, v_name, v_description, v_brand_id, v_category_id, v_supplier_id,
            v_tax_category, v_status, v_track_stock, v_low_stock,
            case when v_status = 'active' then now() else null end
        )
        returning * into v_result_product;
        v_product_id := v_result_product.id;
    end if;

    if v_sku is not null or v_retail_price_cents > 0 or v_cost_price_cents > 0 then
        select id into v_variant_id
        from public.product_variants
        where product_id = v_product_id
        limit 1;

        if v_variant_id is not null then
            update public.product_variants
            set
                sku = coalesce(v_sku, sku),
                barcode = v_barcode,
                retail_price_cents = v_retail_price_cents,
                cost_price_cents = v_cost_price_cents,
                status = case when v_status = 'active' then 'active' else 'draft' end,
                updated_at = now()
            where id = v_variant_id;
        else
            insert into public.product_variants (
                product_id, sku, barcode, retail_price_cents, cost_price_cents, status
            ) values (
                v_product_id,
                coalesce(v_sku, 'TS-PRD-' || lpad(floor(random() * 100000)::text, 5, '0')),
                v_barcode,
                v_retail_price_cents,
                v_cost_price_cents,
                case when v_status = 'active' then 'active' else 'draft' end
            )
            returning id into v_variant_id;
        end if;

        -- Opening stock is initialization, including Save Draft then Publish.
        -- A draft may create the variant before any balance exists. Publish
        -- may initialize that variant once. Re-publishing must not add the
        -- quantity again. An existing balance or any ledger movement for
        -- this variant at this location blocks another opening stock write.
        -- Existing quantities are left unchanged.
        if v_status = 'active'
           and v_track_stock
           and v_opening_stock > 0
           and v_location_id is not null
           and not exists (
                select 1
                from public.inventory_balances
                where business_id = v_business_id
                  and location_id = v_location_id
                  and variant_id = v_variant_id
           )
           and not exists (
                select 1
                from public.inventory_ledger
                where business_id = v_business_id
                  and location_id = v_location_id
                  and variant_id = v_variant_id
           )
        then
            insert into public.inventory_balances (
                business_id, location_id, variant_id, available_qty
            ) values (
                v_business_id, v_location_id, v_variant_id, v_opening_stock
            );

            insert into public.inventory_ledger (
                business_id, location_id, variant_id, event_type, quantity_delta,
                reference_type, reference_id, source, metadata
            ) values (
                v_business_id, v_location_id, v_variant_id, 'stock_in', v_opening_stock,
                'opening_stock', v_product_id, 'manual',
                jsonb_build_object('note', 'Initial opening stock upon product publication')
            );
        end if;
    end if;

    return jsonb_build_object(
        'product', row_to_json(v_result_product),
        'variant_id', v_variant_id,
        'status', v_result_product.status
    );
end;
$$;

ALTER FUNCTION public.save_or_publish_product(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_or_publish_product(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_or_publish_product(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.save_or_publish_product(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.save_or_publish_product(jsonb) TO service_role;


-- ---------------------------------------------------------------------------
-- 2. TEAM INVITATION & TEAM MANAGEMENT HARDENING
-- ---------------------------------------------------------------------------

-- 2A. create_team_invitation (requires team.manage + delegation protections)
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
    v_target_role_name text;
    v_is_actual_owner boolean;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_business_id IS NULL THEN
        RAISE EXCEPTION 'business_id is required' USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: team.manage
    IF NOT public.has_business_permission(p_business_id, 'team.manage') THEN
        RAISE EXCEPTION 'Permission denied: team.manage required' USING ERRCODE = '42501';
    END IF;

    -- Role is strictly required for team invitations
    IF p_role_id IS NULL THEN
        RAISE EXCEPTION 'Role assignment is required for team invitations' USING ERRCODE = '22023';
    END IF;

    -- Validate role belongs to same business
    SELECT r.name INTO v_target_role_name
    FROM public.roles r
    WHERE r.id = p_role_id AND r.business_id = p_business_id;

    IF v_target_role_name IS NULL THEN
        RAISE EXCEPTION 'Role does not belong to this business' USING ERRCODE = '23503';
    END IF;

    v_is_actual_owner := public.is_business_owner(p_business_id);

    -- Delegation Protection 1: Only actual business owner may assign Owner role
    IF v_target_role_name = 'Owner' AND NOT v_is_actual_owner THEN
        RAISE EXCEPTION 'Privilege escalation denied: only business owners can assign the Owner role' USING ERRCODE = '42501';
    END IF;

    -- Delegation Protection 2: Non-owners cannot assign roles containing permissions they lack
    IF NOT v_is_actual_owner THEN
        IF EXISTS (
            SELECT 1
            FROM public.role_permissions rp
            JOIN public.permissions p ON p.id = rp.permission_id
            WHERE rp.role_id = p_role_id
              AND NOT public.has_business_permission(p_business_id, p.code)
        ) THEN
            RAISE EXCEPTION 'Privilege escalation denied: cannot assign a role with permissions exceeding your own' USING ERRCODE = '42501';
        END IF;
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

    -- Fail-closed delegation protection: non-owners cannot invite or reactivate users with ANY existing membership
    IF NOT v_is_actual_owner THEN
        IF EXISTS (
            SELECT 1
            FROM public.memberships m
            JOIN auth.users u ON u.id = m.user_id
            WHERE m.business_id = p_business_id
              AND lower(trim(u.email)) = v_clean_email
        ) THEN
            RAISE EXCEPTION 'Privilege escalation denied: only business owners can re-invite or reactivate existing members' USING ERRCODE = '42501';
        END IF;
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

    -- Calculate expiration (NULL, 0, or negative -> default 7 days)
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
        'success', true,
        'invitation_id', v_invitation_id,
        'business_id', p_business_id,
        'email', v_clean_email,
        'role_id', p_role_id,
        'role_name', v_target_role_name,
        'location_id', p_location_id,
        'token', v_raw_token,
        'raw_token', v_raw_token,
        'expires_at', v_expires_at
    );
END;
$$;

ALTER FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) TO authenticated;
GRANT ALL ON FUNCTION public.create_team_invitation(uuid, text, uuid, uuid, integer) TO service_role;


-- 2B. revoke_team_invitation (requires team.manage + owner invitation protection)
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
    v_role_name text;
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

    -- Granular RBAC Check: team.manage
    IF NOT public.has_business_permission(v_invitation.business_id, 'team.manage') THEN
        RAISE EXCEPTION 'Permission denied: team.manage required' USING ERRCODE = '42501';
    END IF;

    -- Protection: Only actual business owner may revoke invitations for Owner role
    SELECT r.name INTO v_role_name
    FROM public.roles r
    WHERE r.id = v_invitation.role_id;

    IF v_role_name = 'Owner' AND NOT public.is_business_owner(v_invitation.business_id) THEN
        RAISE EXCEPTION 'Unauthorized: only business owners can revoke Owner invitations' USING ERRCODE = '42501';
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
GRANT ALL ON FUNCTION public.revoke_team_invitation(uuid) TO service_role;


-- 2C. update_team_member_role (secure RPC for role management without direct table mutations)
CREATE OR REPLACE FUNCTION public.update_team_member_role(
    p_business_id uuid,
    p_user_id uuid,
    p_role_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
DECLARE
    v_caller_id uuid;
    v_actual_owner_id uuid;
    v_target_role_name text;
    v_is_actual_owner boolean;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_business_id IS NULL OR p_user_id IS NULL OR p_role_id IS NULL THEN
        RAISE EXCEPTION 'business_id, user_id, and role_id are required' USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: team.manage
    IF NOT public.has_business_permission(p_business_id, 'team.manage') THEN
        RAISE EXCEPTION 'Permission denied: team.manage required' USING ERRCODE = '42501';
    END IF;

    SELECT b.owner_user_id INTO v_actual_owner_id
    FROM public.businesses b
    WHERE b.id = p_business_id;

    IF v_actual_owner_id IS NULL THEN
        RAISE EXCEPTION 'Business not found' USING ERRCODE = 'P0002';
    END IF;

    v_is_actual_owner := (v_actual_owner_id = v_caller_id);

    -- Protection 1: Non-owners cannot modify the actual owner's team row
    IF p_user_id = v_actual_owner_id AND NOT v_is_actual_owner THEN
        RAISE EXCEPTION 'Privilege escalation denied: cannot modify the business owner team assignment' USING ERRCODE = '42501';
    END IF;

    -- Verify target role exists in same business
    SELECT r.name INTO v_target_role_name
    FROM public.roles r
    WHERE r.id = p_role_id AND r.business_id = p_business_id;

    IF v_target_role_name IS NULL THEN
        RAISE EXCEPTION 'Role does not belong to this business' USING ERRCODE = '23503';
    END IF;

    -- Protection 2: Only actual owner can assign the Owner role
    IF v_target_role_name = 'Owner' AND NOT v_is_actual_owner THEN
        RAISE EXCEPTION 'Privilege escalation denied: only business owners can assign the Owner role' USING ERRCODE = '42501';
    END IF;

    -- Protection 3: Non-owners cannot assign roles containing permissions they lack
    IF NOT v_is_actual_owner THEN
        IF EXISTS (
            SELECT 1
            FROM public.role_permissions rp
            JOIN public.permissions p ON p.id = rp.permission_id
            WHERE rp.role_id = p_role_id
              AND NOT public.has_business_permission(p_business_id, p.code)
        ) THEN
            RAISE EXCEPTION 'Privilege escalation denied: cannot assign a role with permissions exceeding your own' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Protection 4: Target user must have an active membership in the business
    IF NOT EXISTS (
        SELECT 1 FROM public.memberships m
        WHERE m.business_id = p_business_id AND m.user_id = p_user_id AND m.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Target user does not have an active membership in this business' USING ERRCODE = '42501';
    END IF;

    -- Update or insert team_members record
    INSERT INTO public.team_members (
        business_id,
        user_id,
        role_id,
        status,
        updated_at
    ) VALUES (
        p_business_id,
        p_user_id,
        p_role_id,
        'active',
        now()
    )
    ON CONFLICT (business_id, user_id)
    DO UPDATE SET
        role_id = p_role_id,
        status = 'active',
        updated_at = now();

    RETURN jsonb_build_object(
        'success', true,
        'business_id', p_business_id,
        'user_id', p_user_id,
        'role_id', p_role_id,
        'role_name', v_target_role_name,
        'updated_at', now()
    );
END;
$$;

ALTER FUNCTION public.update_team_member_role(uuid, uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.update_team_member_role(uuid, uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_team_member_role(uuid, uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_team_member_role(uuid, uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.update_team_member_role(uuid, uuid, uuid) TO service_role;


-- 2D. list_team_invitations (secure RPC for viewing team invitations without exposing token_hash)
CREATE OR REPLACE FUNCTION public.list_team_invitations(
    p_business_id uuid
)
RETURNS TABLE (
    id uuid,
    business_id uuid,
    email text,
    role_id uuid,
    role_name text,
    location_id uuid,
    status text,
    invited_by uuid,
    expires_at timestamptz,
    accepted_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'extensions'
AS $$
DECLARE
    v_caller_id uuid;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_business_id IS NULL THEN
        RAISE EXCEPTION 'business_id is required' USING ERRCODE = '22023';
    END IF;

    -- Granular RBAC Check: team.manage required
    IF NOT public.has_business_permission(p_business_id, 'team.manage') THEN
        RAISE EXCEPTION 'Permission denied: team.manage required' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT 
        bi.id,
        bi.business_id,
        bi.email,
        bi.role_id,
        r.name AS role_name,
        bi.location_id,
        bi.status,
        bi.invited_by,
        bi.expires_at,
        bi.accepted_at,
        bi.created_at,
        bi.updated_at
    FROM public.business_invitations bi
    LEFT JOIN public.roles r ON r.id = bi.role_id
    WHERE bi.business_id = p_business_id
    ORDER BY bi.created_at DESC;
END;
$$;

ALTER FUNCTION public.list_team_invitations(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_team_invitations(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_team_invitations(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_team_invitations(uuid) TO authenticated;
GRANT ALL ON FUNCTION public.list_team_invitations(uuid) TO service_role;



-- ---------------------------------------------------------------------------
-- 3. INVENTORY BALANCES & LEDGER LOCKDOWN + adjust_stock RPC
-- ---------------------------------------------------------------------------

-- 3A. Revoke all direct client mutations
REVOKE INSERT, UPDATE, DELETE ON TABLE public.inventory_balances FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.inventory_balances FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.inventory_ledger FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.inventory_ledger FROM anon;

DROP POLICY IF EXISTS "inventory_balances_modify_business_owner" ON public.inventory_balances;
DROP POLICY IF EXISTS "inventory_ledger_modify_business_owner" ON public.inventory_ledger;

-- 3B. adjust_stock RPC (atomic balance update + append-only ledger transaction)
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

    IF v_balance IS NULL THEN
        v_previous_available := 0;
        v_new_available := v_quantity_delta;
        IF v_new_available < 0 THEN
            RAISE EXCEPTION 'Insufficient stock: available quantity cannot be negative (current: 0, requested delta: %)', v_quantity_delta USING ERRCODE = '22003';
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
            now(),
            now(),
            now()
        ) RETURNING * INTO v_balance;
    ELSE
        v_previous_available := v_balance.available_qty;
        v_new_available := v_previous_available + v_quantity_delta;
        IF v_new_available < 0 THEN
            RAISE EXCEPTION 'Insufficient stock: available quantity cannot be negative (current: %, requested delta: %)', v_previous_available, v_quantity_delta USING ERRCODE = '22003';
        END IF;

        UPDATE public.inventory_balances
        SET available_qty = v_new_available,
            last_counted_at = now(),
            updated_at = now()
        WHERE id = v_balance.id
        RETURNING * INTO v_balance;
    END IF;

    -- Strictly append-only ledger write
    INSERT INTO public.inventory_ledger (
        business_id,
        location_id,
        variant_id,
        event_type,
        quantity_delta,
        reference_type,
        reference_id,
        source,
        occurred_at,
        metadata,
        created_at
    ) VALUES (
        v_business_id,
        v_location_id,
        v_variant_id,
        'adjustment',
        v_quantity_delta,
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
        now()
    ) RETURNING id INTO v_ledger_id;

    RETURN jsonb_build_object(
        'success', true,
        'balance_id', v_balance.id,
        'location_id', v_location_id,
        'variant_id', v_variant_id,
        'previous_qty', v_previous_available,
        'quantity_delta', v_quantity_delta,
        'available_qty', v_new_available,
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
-- 4. PERMISSION-SPECIFIC RLS POLICIES
-- ---------------------------------------------------------------------------

-- 4A. Products & Catalog (inventory.manage for mutation, inventory.view for SELECT)
DROP POLICY IF EXISTS "products_modify_business_owner" ON "public"."products";
DROP POLICY IF EXISTS "products_select_business_members" ON "public"."products";

CREATE POLICY "products_modify_inventory_manage" ON "public"."products"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.manage'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.manage'));

CREATE POLICY "products_select_inventory_view" ON "public"."products"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4B. Product Variants
DROP POLICY IF EXISTS "product_variants_modify_business_owner" ON "public"."product_variants";
DROP POLICY IF EXISTS "product_variants_select_business_members" ON "public"."product_variants";

CREATE POLICY "product_variants_modify_inventory_manage" ON "public"."product_variants"
FOR ALL TO "authenticated"
USING (EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_variants.product_id
      AND public.has_business_permission(p.business_id, 'inventory.manage')
))
WITH CHECK (EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_variants.product_id
      AND public.has_business_permission(p.business_id, 'inventory.manage')
));

CREATE POLICY "product_variants_select_inventory_view" ON "public"."product_variants"
FOR SELECT TO "authenticated"
USING (EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_variants.product_id
      AND public.has_business_permission(p.business_id, 'inventory.view')
));

-- 4C. Brands
DROP POLICY IF EXISTS "brands_modify_business_owner" ON "public"."brands";
DROP POLICY IF EXISTS "brands_select_business_members" ON "public"."brands";

CREATE POLICY "brands_modify_inventory_manage" ON "public"."brands"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.manage'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.manage'));

CREATE POLICY "brands_select_inventory_view" ON "public"."brands"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4D. Categories
DROP POLICY IF EXISTS "categories_modify_business_owner" ON "public"."categories";
DROP POLICY IF EXISTS "categories_select_business_members" ON "public"."categories";

CREATE POLICY "categories_modify_inventory_manage" ON "public"."categories"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.manage'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.manage'));

CREATE POLICY "categories_select_inventory_view" ON "public"."categories"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4E. Collections
DROP POLICY IF EXISTS "collections_modify_business_owner" ON "public"."collections";
DROP POLICY IF EXISTS "collections_select_business_members" ON "public"."collections";

CREATE POLICY "collections_modify_inventory_manage" ON "public"."collections"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.manage'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.manage'));

CREATE POLICY "collections_select_inventory_view" ON "public"."collections"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4F. Product Media
DROP POLICY IF EXISTS "product_media_delete_business_members" ON "public"."product_media";
DROP POLICY IF EXISTS "product_media_insert_business_members" ON "public"."product_media";
DROP POLICY IF EXISTS "product_media_update_business_members" ON "public"."product_media";
DROP POLICY IF EXISTS "product_media_select_business_members" ON "public"."product_media";

CREATE POLICY "product_media_modify_inventory_manage" ON "public"."product_media"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.manage'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.manage'));

CREATE POLICY "product_media_select_inventory_view" ON "public"."product_media"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4G. Customers (customers.manage for mutation, customers.view for SELECT)
DROP POLICY IF EXISTS "customers_modify_business_owner_or_member" ON "public"."customers";
DROP POLICY IF EXISTS "customers_select_business_members" ON "public"."customers";

CREATE POLICY "customers_modify_customers_manage" ON "public"."customers"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'customers.manage'))
WITH CHECK (public.has_business_permission(business_id, 'customers.manage'));

CREATE POLICY "customers_select_customers_view" ON "public"."customers"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'customers.view'));

-- 4H. Suppliers (purchasing.manage for mutation, purchasing.view for SELECT)
DROP POLICY IF EXISTS "suppliers_modify_business_owner_or_member" ON "public"."suppliers";
DROP POLICY IF EXISTS "suppliers_select_business_members" ON "public"."suppliers";

CREATE POLICY "suppliers_modify_purchasing_manage" ON "public"."suppliers"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'purchasing.manage'))
WITH CHECK (public.has_business_permission(business_id, 'purchasing.manage'));

CREATE POLICY "suppliers_select_purchasing_view" ON "public"."suppliers"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'purchasing.view'));

-- 4I. Locations (settings.manage for mutation; active member read preserved for checkout/inventory selection)
DROP POLICY IF EXISTS "locations_delete_business_owner" ON "public"."locations";
DROP POLICY IF EXISTS "locations_delete_own_business" ON "public"."locations";
DROP POLICY IF EXISTS "locations_insert_business_owner_or_member" ON "public"."locations";
DROP POLICY IF EXISTS "locations_insert_own_business" ON "public"."locations";
DROP POLICY IF EXISTS "locations_update_business_owner_or_member" ON "public"."locations";
DROP POLICY IF EXISTS "locations_update_own_business" ON "public"."locations";

CREATE POLICY "locations_modify_settings_manage" ON "public"."locations"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'settings.manage'))
WITH CHECK (public.has_business_permission(business_id, 'settings.manage'));

-- 4J. Business Profile Settings & Commerce Profiles (settings.manage for mutation; member read preserved)
DROP POLICY IF EXISTS "business_profile_settings_update_business_members" ON "public"."business_profile_settings";
DROP POLICY IF EXISTS "business_profile_settings_upsert_business_members" ON "public"."business_profile_settings";

CREATE POLICY "business_profile_settings_modify_settings_manage" ON "public"."business_profile_settings"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'settings.manage'))
WITH CHECK (public.has_business_permission(business_id, 'settings.manage'));

DROP POLICY IF EXISTS "business_commerce_profiles_delete_business_members" ON "public"."business_commerce_profiles";
DROP POLICY IF EXISTS "business_commerce_profiles_insert_business_members" ON "public"."business_commerce_profiles";
DROP POLICY IF EXISTS "business_commerce_profiles_update_business_members" ON "public"."business_commerce_profiles";

CREATE POLICY "business_commerce_profiles_modify_settings_manage" ON "public"."business_commerce_profiles"
FOR ALL TO "authenticated"
USING (public.has_business_permission(business_id, 'settings.manage'))
WITH CHECK (public.has_business_permission(business_id, 'settings.manage'));

-- 4K. Inventory Imports (inventory.import)
-- Revoke destructive/unsupported client permissions to enforce immutable audit trail
REVOKE DELETE ON TABLE public.inventory_import_jobs FROM authenticated;
REVOKE DELETE ON TABLE public.inventory_import_jobs FROM anon;
REVOKE DELETE ON TABLE public.inventory_import_rows FROM authenticated;
REVOKE DELETE ON TABLE public.inventory_import_rows FROM anon;
REVOKE UPDATE, DELETE ON TABLE public.inventory_import_errors FROM authenticated;
REVOKE UPDATE, DELETE ON TABLE public.inventory_import_errors FROM anon;

-- Clean up any legacy or broad policies
DROP POLICY IF EXISTS "inventory_import_jobs_modify_inventory_import" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_insert_business_members" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_update_business_members" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_select_business_members" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_select_inventory_import" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_insert_inventory_import" ON "public"."inventory_import_jobs";
DROP POLICY IF EXISTS "inventory_import_jobs_update_inventory_import" ON "public"."inventory_import_jobs";

CREATE POLICY "inventory_import_jobs_select_inventory_import" ON "public"."inventory_import_jobs"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.import'));

CREATE POLICY "inventory_import_jobs_insert_inventory_import" ON "public"."inventory_import_jobs"
FOR INSERT TO "authenticated"
WITH CHECK (public.has_business_permission(business_id, 'inventory.import'));

CREATE POLICY "inventory_import_jobs_update_inventory_import" ON "public"."inventory_import_jobs"
FOR UPDATE TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.import'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.import'));

DROP POLICY IF EXISTS "inventory_import_rows_modify_inventory_import" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_insert_business_members" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_update_business_members" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_select_business_members" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_select_inventory_import" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_insert_inventory_import" ON "public"."inventory_import_rows";
DROP POLICY IF EXISTS "inventory_import_rows_update_inventory_import" ON "public"."inventory_import_rows";

CREATE POLICY "inventory_import_rows_select_inventory_import" ON "public"."inventory_import_rows"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.import'));

CREATE POLICY "inventory_import_rows_insert_inventory_import" ON "public"."inventory_import_rows"
FOR INSERT TO "authenticated"
WITH CHECK (public.has_business_permission(business_id, 'inventory.import'));

CREATE POLICY "inventory_import_rows_update_inventory_import" ON "public"."inventory_import_rows"
FOR UPDATE TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.import'))
WITH CHECK (public.has_business_permission(business_id, 'inventory.import'));

DROP POLICY IF EXISTS "inventory_import_errors_modify_inventory_import" ON "public"."inventory_import_errors";
DROP POLICY IF EXISTS "inventory_import_errors_insert_business_members" ON "public"."inventory_import_errors";
DROP POLICY IF EXISTS "inventory_import_errors_select_business_members" ON "public"."inventory_import_errors";
DROP POLICY IF EXISTS "inventory_import_errors_select_inventory_import" ON "public"."inventory_import_errors";
DROP POLICY IF EXISTS "inventory_import_errors_insert_inventory_import" ON "public"."inventory_import_errors";

CREATE POLICY "inventory_import_errors_select_inventory_import" ON "public"."inventory_import_errors"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.import'));

CREATE POLICY "inventory_import_errors_insert_inventory_import" ON "public"."inventory_import_errors"
FOR INSERT TO "authenticated"
WITH CHECK (public.has_business_permission(business_id, 'inventory.import'));


-- 4L. Sales Tables Read Access (sales.view)
DROP POLICY IF EXISTS "sales_select_business_members" ON "public"."sales";
CREATE POLICY "sales_select_sales_view" ON "public"."sales"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'sales.view'));

DROP POLICY IF EXISTS "sale_items_select_business_members" ON "public"."sale_items";
CREATE POLICY "sale_items_select_sales_view" ON "public"."sale_items"
FOR SELECT TO "authenticated"
USING (EXISTS (
    SELECT 1 FROM public.sales s
    WHERE s.id = sale_items.sale_id
      AND public.has_business_permission(s.business_id, 'sales.view')
));

DROP POLICY IF EXISTS "sale_payments_select_business_members" ON "public"."sale_payments";
CREATE POLICY "sale_payments_select_sales_view" ON "public"."sale_payments"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'sales.view'));

-- 4M. Inventory Balances & Ledger Read Access (inventory.view)
DROP POLICY IF EXISTS "inventory_balances_select_business_members" ON "public"."inventory_balances";
CREATE POLICY "inventory_balances_select_inventory_view" ON "public"."inventory_balances"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

DROP POLICY IF EXISTS "inventory_ledger_select_business_members" ON "public"."inventory_ledger";
CREATE POLICY "inventory_ledger_select_inventory_view" ON "public"."inventory_ledger"
FOR SELECT TO "authenticated"
USING (public.has_business_permission(business_id, 'inventory.view'));

-- 4N. Team & Membership Read Access
DROP POLICY IF EXISTS "team_members_select_business_members" ON "public"."team_members";
CREATE POLICY "team_members_select_team_view" ON "public"."team_members"
FOR SELECT TO "authenticated"
USING (
    user_id = auth.uid()
    OR public.is_business_owner(business_id)
    OR public.has_business_permission(business_id, 'team.view')
);

DROP POLICY IF EXISTS "memberships_select_own_or_business_owner" ON "public"."memberships";
CREATE POLICY "memberships_select_own_or_team_view" ON "public"."memberships"
FOR SELECT TO "authenticated"
USING (
    user_id = auth.uid()
    OR public.is_business_owner(business_id)
    OR public.has_business_permission(business_id, 'team.view')
);


-- 4O. Product Media Storage Objects Hardening (inventory.manage)
DROP POLICY IF EXISTS "product_media_storage_insert" ON storage.objects;
CREATE POLICY "product_media_storage_insert"
ON storage.objects
AS PERMISSIVE
FOR INSERT
TO public
WITH CHECK (
    (bucket_id = 'product-media'::text)
    AND (auth.role() = 'authenticated'::text)
    AND public.has_business_permission(((storage.foldername(name))[1])::uuid, 'inventory.manage')
);

DROP POLICY IF EXISTS "product_media_storage_update" ON storage.objects;
CREATE POLICY "product_media_storage_update"
ON storage.objects
AS PERMISSIVE
FOR UPDATE
TO public
USING (
    (bucket_id = 'product-media'::text)
    AND (auth.role() = 'authenticated'::text)
    AND public.has_business_permission(((storage.foldername(name))[1])::uuid, 'inventory.manage')
)
WITH CHECK (
    (bucket_id = 'product-media'::text)
    AND (auth.role() = 'authenticated'::text)
    AND public.has_business_permission(((storage.foldername(name))[1])::uuid, 'inventory.manage')
);

DROP POLICY IF EXISTS "product_media_storage_delete" ON storage.objects;
CREATE POLICY "product_media_storage_delete"
ON storage.objects
AS PERMISSIVE
FOR DELETE
TO public
USING (
    (bucket_id = 'product-media'::text)
    AND (auth.role() = 'authenticated'::text)
    AND public.has_business_permission(((storage.foldername(name))[1])::uuid, 'inventory.manage')
);


-- ---------------------------------------------------------------------------
-- 5. MIGRATION POSTCONDITION INVARIANT ASSERTIONS
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v_unprotected_tables integer;
    v_anon_rpc_count integer;
    v_balance_mutation_privs integer;
    v_ledger_mutation_privs integer;
    v_sales_auth_count integer;
    v_inv_auth_count integer;
BEGIN
    -- 1. Assert all 35 public tables have RLS enabled
    SELECT count(*) INTO v_unprotected_tables
    FROM pg_tables
    WHERE schemaname = 'public'
      AND rowsecurity = false;

    IF v_unprotected_tables > 0 THEN
        RAISE EXCEPTION 'Invariant check failed: % tables have RLS disabled', v_unprotected_tables;
    END IF;

    -- 2. Assert exact function signatures exist via regprocedure
    IF to_regprocedure('public.create_team_invitation(uuid, text, uuid, uuid, integer)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: create_team_invitation(uuid, text, uuid, uuid, integer) exact signature missing';
    END IF;

    IF to_regprocedure('public.accept_team_invitation(text)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: accept_team_invitation(text) exact signature missing';
    END IF;

    IF to_regprocedure('public.revoke_team_invitation(uuid)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: revoke_team_invitation(uuid) exact signature missing';
    END IF;

    IF to_regprocedure('public.list_team_invitations(uuid)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: list_team_invitations(uuid) exact signature missing';
    END IF;

    IF to_regprocedure('public.adjust_stock(jsonb)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: adjust_stock(jsonb) exact signature missing';
    END IF;

    IF to_regprocedure('public.update_team_member_role(uuid, uuid, uuid)') IS NULL THEN
        RAISE EXCEPTION 'Invariant check failed: update_team_member_role(uuid, uuid, uuid) exact signature missing';
    END IF;

    -- Assert functions are owned by postgres
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.create_team_invitation(uuid, text, uuid, uuid, integer)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: create_team_invitation not owned by postgres';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.accept_team_invitation(text)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: accept_team_invitation not owned by postgres';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.revoke_team_invitation(uuid)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: revoke_team_invitation not owned by postgres';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.list_team_invitations(uuid)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: list_team_invitations not owned by postgres';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.adjust_stock(jsonb)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: adjust_stock not owned by postgres';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_roles r ON r.oid = p.proowner
        WHERE n.nspname = 'public'
          AND r.rolname = 'postgres'
          AND p.oid = 'public.update_team_member_role(uuid, uuid, uuid)'::regprocedure
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: update_team_member_role not owned by postgres';
    END IF;

    -- Assert list_team_invitations execution privileges
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routine_privileges
        WHERE routine_schema = 'public'
          AND routine_name = 'list_team_invitations'
          AND grantee = 'authenticated'
          AND privilege_type = 'EXECUTE'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: authenticated lacks EXECUTE on list_team_invitations';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.routine_privileges
        WHERE routine_schema = 'public'
          AND routine_name = 'list_team_invitations'
          AND grantee = 'anon'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: anon possessed EXECUTE on list_team_invitations';
    END IF;

    -- 3. Assert product-media storage mutation policies require inventory.manage
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'product_media_storage_insert'
          AND with_check LIKE '%inventory.manage%'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: product_media_storage_insert does not require inventory.manage';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'product_media_storage_update'
          AND qual LIKE '%inventory.manage%'
          AND with_check LIKE '%inventory.manage%'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: product_media_storage_update does not require inventory.manage';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'product_media_storage_delete'
          AND qual LIKE '%inventory.manage%'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: product_media_storage_delete does not require inventory.manage';
    END IF;

    -- 4. Assert public.product_media mutation policy uses inventory.manage
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'product_media'
          AND (qual LIKE '%inventory.manage%' OR with_check LIKE '%inventory.manage%')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: public.product_media mutation policy does not use inventory.manage';
    END IF;

    -- 5. Assert direct client mutations on inventory_balances and inventory_ledger are revoked
    SELECT count(*) INTO v_balance_mutation_privs
    FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'inventory_balances'
      AND grantee IN ('anon', 'authenticated')
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE');

    IF v_balance_mutation_privs > 0 THEN
        RAISE EXCEPTION 'Invariant check failed: direct mutations on inventory_balances are not revoked';
    END IF;

    SELECT count(*) INTO v_ledger_mutation_privs
    FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'inventory_ledger'
      AND grantee IN ('anon', 'authenticated')
      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE');

    IF v_ledger_mutation_privs > 0 THEN
        RAISE EXCEPTION 'Invariant check failed: direct mutations on inventory_ledger are not revoked';
    END IF;

    -- 6. Assert inventory import audit trail immutability
    IF EXISTS (
        SELECT 1 FROM information_schema.table_privileges
        WHERE table_schema = 'public'
          AND table_name = 'inventory_import_jobs'
          AND grantee = 'authenticated'
          AND privilege_type = 'DELETE'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_import_jobs authenticated DELETE is not false';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.table_privileges
        WHERE table_schema = 'public'
          AND table_name = 'inventory_import_rows'
          AND grantee = 'authenticated'
          AND privilege_type = 'DELETE'
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_import_rows authenticated DELETE is not false';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.table_privileges
        WHERE table_schema = 'public'
          AND table_name = 'inventory_import_errors'
          AND grantee = 'authenticated'
          AND privilege_type IN ('UPDATE', 'DELETE')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: inventory_import_errors authenticated UPDATE/DELETE is not false';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'inventory_import_jobs'
          AND cmd IN ('DELETE', 'ALL')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: permissive DELETE/ALL policy exists on inventory_import_jobs';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'inventory_import_rows'
          AND cmd IN ('DELETE', 'ALL')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: permissive DELETE/ALL policy exists on inventory_import_rows';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'inventory_import_errors'
          AND cmd IN ('UPDATE', 'DELETE', 'ALL')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: permissive UPDATE/DELETE/ALL policy exists on inventory_import_errors';
    END IF;

    -- 7. Assert zero execution grants to anon on application RPCs
    SELECT count(*) INTO v_anon_rpc_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee = 'anon'
      AND routine_name IN (
          'complete_sale', 'hold_sale', 'resume_held_sale', 'discard_held_sale',
          'list_held_sales', 'save_or_publish_product', 'create_team_invitation',
          'accept_team_invitation', 'revoke_team_invitation', 'list_team_invitations',
          'adjust_stock', 'update_team_member_role'
      );

    IF v_anon_rpc_count > 0 THEN
        RAISE EXCEPTION 'Invariant check failed: anon possesses execute grants on application RPCs';
    END IF;

    -- 8. Assert sales RPC grants remain authenticated-only
    IF EXISTS (
        SELECT 1 FROM information_schema.routine_privileges
        WHERE routine_schema = 'public'
          AND routine_name IN ('complete_sale', 'hold_sale', 'resume_held_sale', 'discard_held_sale', 'list_held_sales')
          AND grantee NOT IN ('postgres', 'authenticated', 'service_role')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: sales RPC grants are not authenticated-only';
    END IF;

    SELECT count(DISTINCT routine_name) INTO v_sales_auth_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee = 'authenticated'
      AND routine_name IN ('complete_sale', 'hold_sale', 'resume_held_sale', 'discard_held_sale', 'list_held_sales');

    IF v_sales_auth_count < 5 THEN
        RAISE EXCEPTION 'Invariant check failed: authenticated lacks execute grants on all sales RPCs';
    END IF;

    -- 9. Assert invitation RPC grants remain authenticated-only
    IF EXISTS (
        SELECT 1 FROM information_schema.routine_privileges
        WHERE routine_schema = 'public'
          AND routine_name IN ('create_team_invitation', 'accept_team_invitation', 'revoke_team_invitation', 'list_team_invitations')
          AND grantee NOT IN ('postgres', 'authenticated', 'service_role')
    ) THEN
        RAISE EXCEPTION 'Invariant check failed: invitation RPC grants are not authenticated-only';
    END IF;

    SELECT count(DISTINCT routine_name) INTO v_inv_auth_count
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'public'
      AND grantee = 'authenticated'
      AND routine_name IN ('create_team_invitation', 'accept_team_invitation', 'revoke_team_invitation', 'list_team_invitations');

    IF v_inv_auth_count < 4 THEN
        RAISE EXCEPTION 'Invariant check failed: authenticated lacks execute grants on all invitation RPCs';
    END IF;
END;
$$;

COMMIT;
