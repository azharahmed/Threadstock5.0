-- Migration: 20260923_019_security_phase_1a_authorization.sql
-- SECURITY PHASE 1A DRAFT. Do not apply until reviewed.
--
-- Run this file as one script. BEGIN/COMMIT make it atomic: a failed
-- assertion rolls back every change in this migration.
--
-- This migration hardens grants and RLS. It does not disable RLS, does not
-- FORCE RLS, does not delete rows, and does not expose service_role keys.
--
-- Anonymous Auth (signInAnonymously) still produces role "authenticated"
-- with a real auth.uid(). The database role "anon" is the key with no JWT.
-- Flutter keeps working because it calls the API as "authenticated".
-- The database role "anon" loses table DML and function EXECUTE.

begin;

-- ---------------------------------------------------------------------------
-- 1. Shared authorization helper used by SECURITY DEFINER RPCs.
--    security invoker is enough: auth.uid() reads the request JWT, and the
--    caller of this helper from a security-definer RPC is the function owner.
--    Clients are not granted EXECUTE, so PostgREST cannot call it directly.
-- ---------------------------------------------------------------------------
create or replace function public.require_business_access(p_business_id uuid)
returns void
language plpgsql
stable
security invoker
set search_path = pg_catalog, public
as $$
begin
    if p_business_id is null then
        raise exception 'business_id is required';
    end if;

    -- A missing JWT must fail. Sale RPCs previously skipped authorization
    -- when the session had no uid.
    if auth.uid() is null then
        raise exception 'Authentication required';
    end if;

    if not (
        public.is_business_member(p_business_id, auth.uid())
        or public.is_business_owner(p_business_id)
    ) then
        raise exception 'Not authorized for this business';
    end if;
end;
$$;

revoke all on function public.require_business_access(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Commercial resolution. SECURITY INVOKER is enough because sale RPCs call
-- it while running as the function owner. Clients are not granted EXECUTE.
-- Prices, names, SKUs, tax categories, and currency come from the database.
-- Quantity is the only item field taken from the request.
--
-- AUTHORITATIVE TAX CALCULATION NOT AVAILABLE.
-- tax_rule_versions stores reviewed rate documents. No function selects an
-- active rule for a business, product, and date, and no minor-unit tax
-- rounding contract exists. This migration does not invent GST, VAT, or
-- country rates, and it does not store payload.tax_minor. Stored tax is 0
-- until that contract exists.
-- ---------------------------------------------------------------------------
create or replace function public.resolve_sale_lines(p_business_id uuid, p_items jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = pg_catalog, public
as $$
declare
    v_item jsonb;
    v_lines jsonb := '[]'::jsonb;
    v_requested_product_id uuid;
    v_product_id uuid;
    v_variant_id uuid;
    v_qty integer;
    v_sku text;
    v_name text;
    v_tax_category text;
    v_variant_title text;
    v_price bigint;
    v_cost bigint;
    v_currency text;
    v_subtotal bigint := 0;
begin
    if p_business_id is null then
        raise exception 'business_id is required';
    end if;
    if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
        raise exception 'Cart is empty. Add at least one item.';
    end if;

    select b.currency_code into v_currency
    from public.businesses b
    where b.id = p_business_id;

    if v_currency is null or v_currency !~ '^[A-Z]{3}$' then
        raise exception 'Business currency is not configured';
    end if;

    for v_item in select value from jsonb_array_elements(p_items) loop
        v_requested_product_id := nullif(v_item->>'product_id', '')::uuid;
        v_variant_id := nullif(v_item->>'variant_id', '')::uuid;
        v_qty := coalesce((v_item->>'quantity')::integer, 0);

        if v_qty <= 0 then
            raise exception 'Quantity must be greater than 0.';
        end if;

        if v_variant_id is null and v_requested_product_id is not null then
            select pv.id into v_variant_id
            from public.product_variants pv
            join public.products p on p.id = pv.product_id
            where pv.product_id = v_requested_product_id
              and p.business_id = p_business_id
              and p.status = 'active'
              and pv.status = 'active'
              and pv.retail_price_cents > 0
            order by pv.created_at asc
            limit 1;
        end if;

        select
            p.id,
            pv.id,
            pv.sku,
            p.name,
            p.tax_category,
            nullif(trim(concat_ws(
                ' / ',
                nullif(trim(pv.color), ''),
                nullif(trim(pv.size), ''),
                nullif(trim(pv.material), '')
            )), ''),
            pv.retail_price_cents,
            pv.cost_price_cents
        into
            v_product_id,
            v_variant_id,
            v_sku,
            v_name,
            v_tax_category,
            v_variant_title,
            v_price,
            v_cost
        from public.product_variants pv
        join public.products p on p.id = pv.product_id
        where pv.id = v_variant_id
          and p.business_id = p_business_id
          and p.status = 'active'
          and pv.status = 'active'
          and pv.retail_price_cents > 0
          and (v_requested_product_id is null or p.id = v_requested_product_id);

        if not found then
            raise exception 'Product is not available';
        end if;

        v_subtotal := v_subtotal + (v_price * v_qty);
        v_lines := v_lines || jsonb_build_array(jsonb_build_object(
            'product_id', v_product_id,
            'variant_id', v_variant_id,
            'quantity', v_qty,
            'sku_snapshot', v_sku,
            'product_name_snapshot', v_name,
            'variant_title_snapshot', v_variant_title,
            'unit_price_minor', v_price,
            'unit_cost_minor', v_cost,
            'tax_category_snapshot', v_tax_category,
            'line_gross_minor', v_price * v_qty
        ));
    end loop;

    return jsonb_build_object(
        'currency_code', v_currency,
        'subtotal_minor', v_subtotal,
        'lines', v_lines
    );
end;
$$;

revoke all on function public.resolve_sale_lines(uuid, jsonb) from public, anon, authenticated;

-- Requested discount only. The amount is calculated from the server subtotal.
-- Percentage 0.1 means 0.1 percent. 0.1 percent of 150000 minor units is 150.
-- Tax stays 0 until an authoritative tax contract exists. See the comment
-- on resolve_sale_lines.
create or replace function public.calculate_sale_discount(
    p_subtotal_minor bigint,
    p_discount_type text,
    p_discount_rate numeric,
    p_flat_minor bigint
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = pg_catalog, public
as $$
declare
    v_type text := coalesce(nullif(trim(p_discount_type), ''), 'none');
    v_rate numeric := coalesce(p_discount_rate, 0);
    v_discount bigint := 0;
begin
    if p_subtotal_minor is null or p_subtotal_minor < 0 then
        raise exception 'Subtotal is not valid';
    end if;

    if v_type not in ('none', 'percentage', 'flat') then
        raise exception 'Invalid discount type';
    end if;

    if v_type = 'none' then
        v_rate := 0;
        v_discount := 0;
    elsif v_type = 'percentage' then
        if v_rate < 0 or v_rate > 100 then
            raise exception 'Discount cannot exceed 100%%';
        end if;
        v_discount := round((p_subtotal_minor::numeric * v_rate) / 100)::bigint;
    else
        v_discount := coalesce(p_flat_minor, 0);
        v_rate := 0;
        if v_discount < 0 or v_discount > p_subtotal_minor then
            raise exception 'Discount cannot exceed the order subtotal.';
        end if;
    end if;

    return jsonb_build_object(
        'discount_type', v_type,
        'discount_rate', v_rate,
        'discount_minor', v_discount,
        'tax_minor', 0,
        'total_minor', p_subtotal_minor - v_discount
    );
end;
$$;

revoke all on function public.calculate_sale_discount(bigint, text, numeric, bigint) from public, anon, authenticated;

-- Largest-remainder allocation in minor units. Each line discount stays
-- within 0..line gross, and the discounts sum to the sale discount.
-- Clients cannot call this helper.
create or replace function public.allocate_sale_line_discounts(
    p_lines jsonb,
    p_subtotal_minor bigint,
    p_discount_minor bigint
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = pg_catalog, public
as $$
declare
    v_count integer;
    v_gross bigint[];
    v_base bigint[];
    v_frac numeric[];
    v_allocated bigint := 0;
    v_remainder bigint;
    v_i integer;
    v_best integer;
    v_best_frac numeric;
    v_result jsonb := '[]'::jsonb;
begin
    if p_subtotal_minor is null or p_subtotal_minor < 0
        or p_discount_minor is null or p_discount_minor < 0
        or p_discount_minor > p_subtotal_minor
    then
        raise exception 'Discount allocation is not valid';
    end if;

    if p_lines is null or jsonb_typeof(p_lines) <> 'array' then
        v_count := 0;
    else
        v_count := jsonb_array_length(p_lines);
    end if;
    if v_count = 0 then
        return '[]'::jsonb;
    end if;

    for v_i in 0 .. v_count - 1 loop
        v_gross[v_i + 1] := (p_lines->v_i->>'line_gross_minor')::bigint;
        if v_gross[v_i + 1] is null or v_gross[v_i + 1] < 0 then
            raise exception 'Discount allocation is not valid';
        end if;
        if p_subtotal_minor = 0 or p_discount_minor = 0 then
            v_base[v_i + 1] := 0;
            v_frac[v_i + 1] := 0;
        else
            v_frac[v_i + 1] := (v_gross[v_i + 1]::numeric * p_discount_minor) / p_subtotal_minor;
            v_base[v_i + 1] := floor(v_frac[v_i + 1])::bigint;
            v_frac[v_i + 1] := v_frac[v_i + 1] - v_base[v_i + 1];
        end if;
        if v_base[v_i + 1] < 0 or v_base[v_i + 1] > v_gross[v_i + 1] then
            raise exception 'Discount allocation is not valid';
        end if;
        v_allocated := v_allocated + v_base[v_i + 1];
    end loop;

    v_remainder := p_discount_minor - v_allocated;
    while v_remainder > 0 loop
        v_best := null;
        v_best_frac := -1;
        for v_i in 1 .. v_count loop
            if v_base[v_i] < v_gross[v_i] and v_frac[v_i] > v_best_frac then
                v_best := v_i;
                v_best_frac := v_frac[v_i];
            end if;
        end loop;
        if v_best is null then
            raise exception 'Discount allocation is not valid';
        end if;
        v_base[v_best] := v_base[v_best] + 1;
        v_frac[v_best] := -1;
        v_remainder := v_remainder - 1;
    end loop;

    for v_i in 1 .. v_count loop
        v_result := v_result || jsonb_build_array(v_base[v_i]);
    end loop;
    return v_result;
end;
$$;

revoke all on function public.allocate_sale_line_discounts(jsonb, bigint, bigint) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Sale RPCs. Full CREATE OR REPLACE from the local 017/018 definitions.
--    Authorization is unconditional. Caller-supplied ids are checked inside
--    the function because SECURITY DEFINER bypasses RLS.
--    Error text does not say whether an id exists in another business.
-- ---------------------------------------------------------------------------
create or replace function public.complete_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
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
        -- No payment processor is integrated. A client cannot mark a card
        -- payment as electronically confirmed.
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

create or replace function public.hold_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
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

    -- Hold stores database snapshots for the inbox. Completing the held sale
    -- calls complete_sale, which resolves price and stock again. The held
    -- row is not a price lock.
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

create or replace function public.list_held_sales(p_business_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_sale record;
    v_items jsonb;
    v_result jsonb := '[]'::jsonb;
begin
    if p_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(p_business_id);

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

create or replace function public.resume_held_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
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

create or replace function public.discard_held_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_sale record;
begin
    if v_business_id is null or v_sale_id is null then
        raise exception 'business_id and sale_id are required';
    end if;

    perform public.require_business_access(v_business_id);

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

-- ---------------------------------------------------------------------------
-- 3. save_or_publish_product had no auth check and accepted foreign-tenant
--    brand, category, supplier, and location ids. SECURITY DEFINER bypasses
--    RLS, so those checks have to live inside the function.
--    Members of the business may still publish. That matches the current app.
--    Errors do not say whether an id exists in another business.
-- ---------------------------------------------------------------------------
create or replace function public.save_or_publish_product(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
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
    perform public.require_business_access(v_business_id);

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

-- ---------------------------------------------------------------------------
-- 4. EXECUTE grants.
--    Postgres grants EXECUTE to PUBLIC by default. Supabase default privileges
--    also grant anon and authenticated explicitly, so REVOKE FROM PUBLIC alone
--    does not remove anon. Revoke both.
--    Trigger helpers stay executable by authenticated, because an UPDATE fired
--    by the app must be allowed to run set_*_updated_at.
--    is_business_member / is_business_owner stay executable by authenticated,
--    because RLS policies call them as the requesting user.
-- ---------------------------------------------------------------------------
revoke all on all functions in schema public from public;
revoke all on all functions in schema public from anon;

-- Internal trigger. Inserts into auth.users are performed by supabase_auth_admin,
-- not by the Flutter client. Do not leave a PostgREST entry point.
revoke all on function public.handle_new_user() from authenticated, anon, public;
do $$
begin
    if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
        grant execute on function public.handle_new_user() to supabase_auth_admin;
    end if;
end;
$$;

-- Platform event trigger, when present. Not part of the ThreadStock migrations.
-- Clients must not call it. Signature is discovered so a different argument
-- list does not abort the migration.
do $$
declare
    fn regprocedure;
begin
    for fn in
        select p.oid::regprocedure
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'rls_auto_enable'
    loop
        execute format('revoke all on function %s from public, anon, authenticated', fn);
    end loop;
end;
$$;

-- App RPCs: authenticated JWT only. service_role is revoked so a leaked
-- service key is not a second client path for these functions. The tax
-- monitor does not call them.
revoke all on function public.complete_sale(jsonb) from public, anon, authenticated, service_role;
revoke all on function public.hold_sale(jsonb) from public, anon, authenticated, service_role;
revoke all on function public.resume_held_sale(jsonb) from public, anon, authenticated, service_role;
revoke all on function public.discard_held_sale(jsonb) from public, anon, authenticated, service_role;
revoke all on function public.list_held_sales(uuid) from public, anon, authenticated, service_role;
revoke all on function public.save_or_publish_product(jsonb) from public, anon, authenticated, service_role;

grant execute on function public.complete_sale(jsonb) to authenticated;
grant execute on function public.hold_sale(jsonb) to authenticated;
grant execute on function public.resume_held_sale(jsonb) to authenticated;
grant execute on function public.discard_held_sale(jsonb) to authenticated;
grant execute on function public.list_held_sales(uuid) to authenticated;
grant execute on function public.save_or_publish_product(jsonb) to authenticated;

-- RLS helpers and trigger functions must remain callable by authenticated
-- after the PUBLIC revoke above. Re-grant the known ThreadStock functions.
grant execute on function public.is_business_owner(uuid) to authenticated;
grant execute on function public.is_business_member(uuid, uuid) to authenticated;

do $$
declare
    fn regprocedure;
begin
    for fn in
        select p.oid::regprocedure
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname like 'set\_%\_updated\_at' escape '\'
    loop
        execute format('grant execute on function %s to authenticated', fn);
    end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. search_path on helper functions that currently inherit the caller's path.
--    These bodies use schema-qualified auth.uid() or only assign new.updated_at.
--    pg_catalog is listed first so a mutable search_path cannot shadow built-ins.
--    rls_auto_enable is intentionally excluded: its body is not in this repo
--    and may reference another schema.
--    The six app RPCs already set search_path in their CREATE OR REPLACE.
-- ---------------------------------------------------------------------------
do $$
declare
    fn regprocedure;
begin
    for fn in
        select p.oid::regprocedure
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and (
              p.proname in ('is_business_owner', 'is_business_member', 'set_updated_at')
              or p.proname like 'set\_%\_updated\_at' escape '\'
          )
    loop
        execute format('alter function %s set search_path = pg_catalog, public', fn);
    end loop;
end;
$$;

alter function public.handle_new_user() set search_path = pg_catalog, public, auth;

-- ---------------------------------------------------------------------------
-- 6. permissions is a global catalog (code, name, module). It has no
--    business_id. The old ALL policy let every role that held a table grant
--    rewrite the catalog, including the anon role.
--    Clients may read the catalog when they have a JWT. They may not write it.
-- ---------------------------------------------------------------------------
drop policy if exists "permissions_modify_business_owner" on public.permissions;
drop policy if exists "permissions_select_business_members" on public.permissions;
drop policy if exists "permissions_select_authenticated_user" on public.permissions;

create policy "permissions_select_authenticated_user"
    on public.permissions
    for select
    to authenticated
    using (auth.uid() is not null);

revoke insert, update, delete, truncate, trigger, references on public.permissions from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 7. Tax intelligence is a platform corpus, not tenant data. No business_id.
--    Flutter does not read these tables. supabase/functions/tax-monitor uses
--    the service_role key, which bypasses RLS as long as FORCE RLS stays off.
--    Remove every client policy and every anon/authenticated grant.
--    service_role table grants are left in place.
-- ---------------------------------------------------------------------------
drop policy if exists "tax_source_registry_select_authenticated" on public.tax_source_registry;
drop policy if exists "tax_source_registry_insert_authenticated" on public.tax_source_registry;
drop policy if exists "tax_source_registry_update_authenticated" on public.tax_source_registry;
drop policy if exists "tax_source_registry_delete_authenticated" on public.tax_source_registry;
drop policy if exists "tax_source_documents_select_authenticated" on public.tax_source_documents;
drop policy if exists "tax_source_documents_insert_authenticated" on public.tax_source_documents;
drop policy if exists "tax_source_documents_update_authenticated" on public.tax_source_documents;
drop policy if exists "tax_source_documents_delete_authenticated" on public.tax_source_documents;
drop policy if exists "tax_rule_versions_select_authenticated" on public.tax_rule_versions;
drop policy if exists "tax_rule_versions_insert_authenticated" on public.tax_rule_versions;
drop policy if exists "tax_rule_versions_update_authenticated" on public.tax_rule_versions;
drop policy if exists "tax_rule_versions_delete_authenticated" on public.tax_rule_versions;
drop policy if exists "tax_rule_review_queue_select_authenticated" on public.tax_rule_review_queue;
drop policy if exists "tax_rule_review_queue_insert_authenticated" on public.tax_rule_review_queue;
drop policy if exists "tax_rule_review_queue_update_authenticated" on public.tax_rule_review_queue;
drop policy if exists "tax_rule_review_queue_delete_authenticated" on public.tax_rule_review_queue;
drop policy if exists "tax_rule_audit_events_select_authenticated" on public.tax_rule_audit_events;
drop policy if exists "tax_rule_audit_events_insert_authenticated" on public.tax_rule_audit_events;
drop policy if exists "tax_rule_audit_events_update_authenticated" on public.tax_rule_audit_events;
drop policy if exists "tax_rule_audit_events_delete_authenticated" on public.tax_rule_audit_events;

revoke all on table
    public.tax_source_registry,
    public.tax_source_documents,
    public.tax_rule_versions,
    public.tax_rule_review_queue,
    public.tax_rule_audit_events
from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 8. memberships self-insert let any JWT add itself to any business, which
--    then satisfies is_business_member. Onboarding still works: it inserts
--    the business with owner_user_id = auth.uid() first, then upserts the
--    owner membership. Only that owner may insert or update memberships.
-- ---------------------------------------------------------------------------
drop policy if exists "memberships_insert_self_or_business_owner" on public.memberships;
drop policy if exists "memberships_insert_business_owner" on public.memberships;
create policy "memberships_insert_business_owner"
    on public.memberships
    for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists "memberships_update_own_or_business_owner" on public.memberships;
drop policy if exists "memberships_update_business_owner" on public.memberships;
create policy "memberships_update_business_owner"
    on public.memberships
    for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

-- team_members is not consulted by is_business_member. Flutter does not write
-- this table. Owners remain the only writers.
drop policy if exists "team_members_insert_business_owner_or_self" on public.team_members;
drop policy if exists "team_members_insert_business_owner" on public.team_members;
create policy "team_members_insert_business_owner"
    on public.team_members
    for insert
    to authenticated
    with check (public.is_business_owner(business_id));

drop policy if exists "team_members_update_business_owner_or_self" on public.team_members;
drop policy if exists "team_members_update_business_owner" on public.team_members;
create policy "team_members_update_business_owner"
    on public.team_members
    for update
    to authenticated
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

-- ---------------------------------------------------------------------------
-- 9. Table privileges.
--    anon: no table access. The app signs in anonymously and then uses the
--    authenticated role.
--    authenticated: keep SELECT/INSERT/UPDATE/DELETE on tenant tables so
--    PostgREST and RLS continue to work. Remove TRUNCATE, TRIGGER, and
--    REFERENCES, which the Data API does not need.
--    sales, sale_items, and sale_payments are the exception. Flutter only
--    SELECTs them (sales history and embedded lines/payments). Holds,
--    resumes, discards, and completes go through the RPCs above.
--    Direct INSERT/UPDATE/DELETE are removed, and the FOR ALL write policies
--    are dropped so a later grant cannot reopen client writes. SELECT policies
--    stay. service_role table grants are left in place. FORCE RLS is not enabled.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke truncate, trigger, references on all tables in schema public from authenticated, anon;

drop policy if exists "sales_modify_business_owner_or_member" on public.sales;
drop policy if exists "sale_items_modify_business_owner_or_member" on public.sale_items;
drop policy if exists "sale_payments_modify_business_owner_or_member" on public.sale_payments;

revoke insert, update, delete, truncate, trigger, references on table
    public.sales,
    public.sale_items,
    public.sale_payments
from public, anon, authenticated;

grant select on table
    public.sales,
    public.sale_items,
    public.sale_payments
to authenticated;

-- Sequences are unused by the current uuid-key schema. Do not leave them
-- usable by clients if a future serial column appears under old defaults.
revoke all on all sequences in schema public from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 10. Future objects created by the ThreadStock migration role.
--
-- SUPABASE PLATFORM-OWNED DEFAULT PRIVILEGES:
-- OUTSIDE THREADSTOCK MIGRATION OWNERSHIP
--
-- Hosted Supabase runs migrations as postgres. That role is not a superuser
-- and is not a member of supabase_admin, so this migration must not execute
-- ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin. Platform defaults owned
-- by supabase_admin stay as Supabase shipped them.
--
-- Objects created by the ThreadStock migration role are deny-by-default to
-- anon, authenticated, and PUBLIC unless a later statement explicitly grants
-- them. Tables and sequences stay schema-scoped: they have no built-in client
-- grant. Functions are different. PostgreSQL's built-in default grants
-- EXECUTE to PUBLIC, and a schema-scoped REVOKE does not remove that global
-- default. The PUBLIC revoke below is intentionally not limited to a schema.
-- anon and authenticated are revoked in schema public. This migration does
-- not create an event trigger. Hosted postgres cannot own superuser-only DDL.
-- Functions already created above still have explicit revokes and grants.
-- Defaults do not replace those statements.
--
-- Application RPCs above are revoked from public, anon, and authenticated,
-- then granted to authenticated. Internal helpers stay revoked from all
-- three. service_role is not added as a future-function default.
-- ---------------------------------------------------------------------------
do $$
begin
    execute format(
        'alter default privileges for role %I in schema public revoke all on tables from anon, authenticated, public',
        current_user
    );
    execute format(
        'alter default privileges for role %I in schema public revoke all on sequences from anon, authenticated, public',
        current_user
    );
    -- No IN SCHEMA. This is the statement that removes the built-in
    -- EXECUTE grant to PUBLIC for functions this role creates later.
    execute format(
        'alter default privileges for role %I revoke execute on functions from public',
        current_user
    );
    execute format(
        'alter default privileges for role %I in schema public revoke execute on functions from anon, authenticated',
        current_user
    );
end;
$$;

-- ---------------------------------------------------------------------------
-- 11. Postconditions. Any failure raises and, with the opening BEGIN, leaves
--    none of this migration applied.
--    The function probe is created after the migration role's default
--    privileges change, with no further grant or revoke, so its ACL is the
--    ACL a later function created by this role receives.
-- ---------------------------------------------------------------------------
create function public.threadstock_default_privilege_probe()
returns void
language sql
as 'select 1';

do $post$
declare
    v_count integer;
    v_sig text;
    fn regprocedure;
    app_sigs text[] := array[
        'public.complete_sale(jsonb)',
        'public.hold_sale(jsonb)',
        'public.list_held_sales(uuid)',
        'public.resume_held_sale(jsonb)',
        'public.discard_held_sale(jsonb)',
        'public.save_or_publish_product(jsonb)'
    ];
begin
    select count(*) into v_count
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
          'complete_sale',
          'hold_sale',
          'list_held_sales',
          'resume_held_sale',
          'discard_held_sale'
      )
      and strpos(p.prosrc, 'if auth.uid() is not null then') > 0;

    if v_count <> 0 then
        raise exception 'Postcondition failed: optional auth.uid() bypass remains in % sale RPC(s)', v_count;
    end if;

    select count(*) into v_count
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
          'complete_sale',
          'hold_sale',
          'list_held_sales',
          'resume_held_sale',
          'discard_held_sale'
      )
      and strpos(p.prosrc, 'perform public.require_business_access(') > 0;

    if v_count <> 5 then
        raise exception 'Postcondition failed: a sale RPC is missing require_business_access';
    end if;

    if pg_get_function_identity_arguments('public.complete_sale(jsonb)'::regprocedure) is distinct from 'payload jsonb'
        or pg_get_function_identity_arguments('public.hold_sale(jsonb)'::regprocedure) is distinct from 'payload jsonb'
        or pg_get_function_identity_arguments('public.list_held_sales(uuid)'::regprocedure) is distinct from 'p_business_id uuid'
        or pg_get_function_identity_arguments('public.resume_held_sale(jsonb)'::regprocedure) is distinct from 'payload jsonb'
        or pg_get_function_identity_arguments('public.discard_held_sale(jsonb)'::regprocedure) is distinct from 'payload jsonb'
        or pg_get_function_identity_arguments('public.save_or_publish_product(jsonb)'::regprocedure) is distinct from 'payload jsonb'
    then
        raise exception 'Postcondition failed: an application RPC signature changed';
    end if;

    foreach v_sig in array app_sigs loop
        if has_function_privilege('anon', v_sig, 'execute') then
            raise exception 'Postcondition failed: anon can execute %', v_sig;
        end if;
        if not has_function_privilege('authenticated', v_sig, 'execute') then
            raise exception 'Postcondition failed: authenticated cannot execute %', v_sig;
        end if;
    end loop;

    if has_function_privilege('anon', 'public.handle_new_user()', 'execute')
        or has_function_privilege('authenticated', 'public.handle_new_user()', 'execute')
    then
        raise exception 'Postcondition failed: handle_new_user is still executable by anon or authenticated';
    end if;

    for fn in
        select p.oid::regprocedure
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'rls_auto_enable'
    loop
        if has_function_privilege('anon', fn, 'execute')
            or has_function_privilege('authenticated', fn, 'execute')
        then
            raise exception 'Postcondition failed: rls_auto_enable is still executable by anon or authenticated';
        end if;
    end loop;

    select count(*) into v_count
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proname in (
          'complete_sale',
          'hold_sale',
          'list_held_sales',
          'resume_held_sale',
          'discard_held_sale',
          'save_or_publish_product',
          'handle_new_user'
      )
      and has_function_privilege('anon', p.oid, 'execute');

    if v_count <> 0 then
        raise exception 'Postcondition failed: anon can execute % security definer application function(s)', v_count;
    end if;

    select count(*) into v_count
    from pg_policy pol
    join pg_class c on c.oid = pol.polrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'permissions'
      and pol.polcmd in ('a', 'w', 'd', '*');

    if v_count <> 0 then
        raise exception 'Postcondition failed: permissions still has a write policy';
    end if;

    select count(*) into v_count
    from pg_policy pol
    join pg_class c on c.oid = pol.polrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in (
          'tax_source_registry',
          'tax_source_documents',
          'tax_rule_versions',
          'tax_rule_review_queue',
          'tax_rule_audit_events'
      );

    if v_count <> 0 then
        raise exception 'Postcondition failed: tax client policies remain';
    end if;

    select count(*) into v_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    cross join lateral aclexplode(c.relacl) a
    left join pg_roles g on g.oid = a.grantee
    where n.nspname = 'public'
      and c.relname in ('sales', 'sale_items', 'sale_payments')
      and c.relacl is not null
      and a.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
      and (a.grantee = 0 or g.rolname in ('anon', 'authenticated', 'public'));

    if v_count <> 0 then
        raise exception 'Postcondition failed: sales tables still grant direct writes to a client role';
    end if;

    if not has_table_privilege('authenticated', 'public.sales', 'SELECT')
        or not has_table_privilege('authenticated', 'public.sale_items', 'SELECT')
        or not has_table_privilege('authenticated', 'public.sale_payments', 'SELECT')
    then
        raise exception 'Postcondition failed: authenticated lost SELECT on a sales table';
    end if;

    if has_table_privilege('authenticated', 'public.sales', 'INSERT')
        or has_table_privilege('authenticated', 'public.sales', 'UPDATE')
        or has_table_privilege('authenticated', 'public.sales', 'DELETE')
        or has_table_privilege('authenticated', 'public.sale_items', 'INSERT')
        or has_table_privilege('authenticated', 'public.sale_items', 'UPDATE')
        or has_table_privilege('authenticated', 'public.sale_items', 'DELETE')
        or has_table_privilege('authenticated', 'public.sale_payments', 'INSERT')
        or has_table_privilege('authenticated', 'public.sale_payments', 'UPDATE')
        or has_table_privilege('authenticated', 'public.sale_payments', 'DELETE')
    then
        raise exception 'Postcondition failed: authenticated can still mutate a sales table';
    end if;

    select count(*) into v_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'
      and not c.relrowsecurity;

    if v_count <> 0 then
        raise exception 'Postcondition failed: % public table(s) have RLS disabled', v_count;
    end if;

    if exists (
        select 1
        from pg_default_acl d
        join pg_namespace n on n.oid = d.defaclnamespace
        join pg_roles owner on owner.oid = d.defaclrole
        cross join lateral aclexplode(d.defaclacl) a
        left join pg_roles g on g.oid = a.grantee
        where owner.rolname = current_user
          and n.nspname = 'public'
          and d.defaclobjtype in ('r', 'S', 'f')
          and (a.grantee = 0 or g.rolname in ('anon', 'authenticated', 'public'))
    ) then
        raise exception 'Postcondition failed: migration-role default privileges still expose a client role';
    end if;

    create table public.threadstock_default_privilege_table_probe (id integer);
    if has_table_privilege('anon', 'public.threadstock_default_privilege_table_probe', 'SELECT')
        or has_table_privilege('anon', 'public.threadstock_default_privilege_table_probe', 'INSERT')
        or has_table_privilege('authenticated', 'public.threadstock_default_privilege_table_probe', 'SELECT')
        or has_table_privilege('authenticated', 'public.threadstock_default_privilege_table_probe', 'INSERT')
    then
        raise exception 'Postcondition failed: a new table is exposed to a client role';
    end if;
    drop table public.threadstock_default_privilege_table_probe;

    create sequence public.threadstock_default_privilege_seq_probe;
    if has_sequence_privilege('anon', 'public.threadstock_default_privilege_seq_probe', 'USAGE')
        or has_sequence_privilege('anon', 'public.threadstock_default_privilege_seq_probe', 'SELECT')
        or has_sequence_privilege('authenticated', 'public.threadstock_default_privilege_seq_probe', 'USAGE')
        or has_sequence_privilege('authenticated', 'public.threadstock_default_privilege_seq_probe', 'SELECT')
    then
        raise exception 'Postcondition failed: a new sequence is exposed to a client role';
    end if;
    drop sequence public.threadstock_default_privilege_seq_probe;

    if has_function_privilege('anon', 'public.threadstock_default_privilege_probe()', 'execute')
        or has_function_privilege('authenticated', 'public.threadstock_default_privilege_probe()', 'execute')
    then
        raise exception 'Postcondition failed: a new function is still executable by anon or authenticated';
    end if;

    if has_function_privilege('anon', 'public.resolve_sale_lines(uuid, jsonb)', 'execute')
        or has_function_privilege('authenticated', 'public.resolve_sale_lines(uuid, jsonb)', 'execute')
        or has_function_privilege('anon', 'public.calculate_sale_discount(bigint, text, numeric, bigint)', 'execute')
        or has_function_privilege('authenticated', 'public.calculate_sale_discount(bigint, text, numeric, bigint)', 'execute')
        or has_function_privilege('anon', 'public.allocate_sale_line_discounts(jsonb, bigint, bigint)', 'execute')
        or has_function_privilege('authenticated', 'public.allocate_sale_line_discounts(jsonb, bigint, bigint)', 'execute')
    then
        raise exception 'Postcondition failed: a commercial helper is executable by a client role';
    end if;

    if strpos(pg_get_functiondef('public.complete_sale(jsonb)'::regprocedure), 'public.resolve_sale_lines(') = 0
        or strpos(pg_get_functiondef('public.hold_sale(jsonb)'::regprocedure), 'public.resolve_sale_lines(') = 0
        or strpos(pg_get_functiondef('public.complete_sale(jsonb)'::regprocedure), 'payload->>''currency_code''') > 0
        or strpos(pg_get_functiondef('public.complete_sale(jsonb)'::regprocedure), 'payload->>''subtotal_minor''') > 0
        or strpos(pg_get_functiondef('public.complete_sale(jsonb)'::regprocedure), 'payload->>''total_minor''') > 0
        or strpos(pg_get_functiondef('public.complete_sale(jsonb)'::regprocedure), 'payload->>''unit_price_minor''') > 0
        or strpos(pg_get_functiondef('public.save_or_publish_product(jsonb)'::regprocedure), 'excluded.available_qty') > 0
        or strpos(pg_get_functiondef('public.save_or_publish_product(jsonb)'::regprocedure), 'v_new_variant') > 0
    then
        raise exception 'Postcondition failed: commercial authority checks are missing';
    end if;

    if exists (
        select 1
        from pg_event_trigger
        where evtname = 'threadstock_lock_new_function_privileges'
    ) then
        raise exception 'Postcondition failed: custom function privilege event trigger still exists';
    end if;
end;
$post$;

drop function public.threadstock_default_privilege_probe();

notify pgrst, 'reload schema';

commit;
