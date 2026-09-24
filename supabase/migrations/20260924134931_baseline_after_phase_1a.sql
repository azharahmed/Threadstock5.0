


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."allocate_sale_line_discounts"("p_lines" "jsonb", "p_subtotal_minor" bigint, "p_discount_minor" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
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


ALTER FUNCTION "public"."allocate_sale_line_discounts"("p_lines" "jsonb", "p_subtotal_minor" bigint, "p_discount_minor" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_sale_discount"("p_subtotal_minor" bigint, "p_discount_type" "text", "p_discount_rate" numeric, "p_flat_minor" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
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


ALTER FUNCTION "public"."calculate_sale_discount"("p_subtotal_minor" bigint, "p_discount_type" "text", "p_discount_rate" numeric, "p_flat_minor" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."complete_sale"("payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."complete_sale"("payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."discard_held_sale"("payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."discard_held_sale"("payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
begin
    insert into public.profiles (id, email, full_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.email)
    )
    on conflict (id) do update
        set email = excluded.email,
            full_name = excluded.full_name,
            updated_at = now();

    return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hold_sale"("payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."hold_sale"("payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_business_member"("p_business_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
    select exists (
        select 1
        from public.memberships m
        where m.business_id = p_business_id
          and m.user_id = p_user_id
          and m.status = 'active'
    );
$$;


ALTER FUNCTION "public"."is_business_member"("p_business_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_business_owner"("p_business_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
    select exists (
        select 1
        from public.businesses b
        where b.id = p_business_id
          and b.owner_user_id = auth.uid()
    );
$$;


ALTER FUNCTION "public"."is_business_owner"("p_business_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."list_held_sales"("p_business_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."list_held_sales"("p_business_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."require_business_access"("p_business_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
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


ALTER FUNCTION "public"."require_business_access"("p_business_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."resolve_sale_lines"("p_business_id" "uuid", "p_items" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'pg_catalog', 'public'
    AS $_$
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
$_$;


ALTER FUNCTION "public"."resolve_sale_lines"("p_business_id" "uuid", "p_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."resume_held_sale"("payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."resume_held_sale"("payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."save_or_publish_product"("payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
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


ALTER FUNCTION "public"."save_or_publish_product"("payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_balance_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_balance_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_brand_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_brand_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_business_commerce_profile_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_business_commerce_profile_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_business_profile_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_business_profile_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_category_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_category_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_collection_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_collection_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_customers_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_customers_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_integration_connection_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_integration_connection_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_integration_sync_checkpoint_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_integration_sync_checkpoint_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_inventory_import_job_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_inventory_import_job_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_locations_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_locations_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_membership_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_membership_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_onboarding_session_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_onboarding_session_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_permissions_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_permissions_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_product_media_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_product_media_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_product_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_product_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_roles_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_roles_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_sales_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_sales_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_suppliers_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_suppliers_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_tax_rule_review_queue_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_tax_rule_review_queue_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_tax_rule_versions_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_tax_rule_versions_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_tax_source_documents_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_tax_source_documents_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_tax_source_registry_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_tax_source_registry_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_team_members_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_team_members_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_variant_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_variant_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."brands" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "brands_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."brands" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."business_commerce_profiles" (
    "business_id" "uuid" NOT NULL,
    "sales_channels" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "preferred_payment_terms" "text" NOT NULL,
    "tax_system" "text" NOT NULL,
    "gst_registered" boolean DEFAULT false NOT NULL,
    "gstin" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "business_commerce_profiles_preferred_payment_terms_check" CHECK (("length"(TRIM(BOTH FROM "preferred_payment_terms")) > 0)),
    CONSTRAINT "business_commerce_profiles_sales_channels_check" CHECK (("array_length"("sales_channels", 1) > 0)),
    CONSTRAINT "business_commerce_profiles_tax_system_check" CHECK (("tax_system" = ANY (ARRAY['GST — India'::"text", 'VAT'::"text", 'Sales Tax'::"text", 'Country tax system'::"text"]))),
    CONSTRAINT "commerce_gstin_required_when_registered" CHECK ((("gst_registered" = false) OR (("gst_registered" = true) AND ("gstin" IS NOT NULL) AND ("length"(TRIM(BOTH FROM "gstin")) > 0))))
);


ALTER TABLE "public"."business_commerce_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."business_profile_settings" (
    "business_id" "uuid" NOT NULL,
    "display_name" "text",
    "legal_entity_name" "text",
    "business_type" "text",
    "registered_country" "text",
    "primary_currency" "text",
    "default_language" "text" DEFAULT 'English (United States)'::"text",
    "timezone" "text" DEFAULT 'UTC'::"text",
    "email" "text",
    "phone" "text",
    "website" "text",
    "street_address" "text",
    "city" "text",
    "postal_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."business_profile_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."businesses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_user_id" "uuid" NOT NULL,
    "legal_name" "text" NOT NULL,
    "business_type" "text" NOT NULL,
    "country_code" "text" NOT NULL,
    "currency_code" "text" NOT NULL,
    "location_range" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "businesses_business_type_check" CHECK (("length"(TRIM(BOTH FROM "business_type")) > 0)),
    CONSTRAINT "businesses_country_code_check" CHECK (("country_code" ~ '^[A-Z]{2}$'::"text")),
    CONSTRAINT "businesses_currency_code_check" CHECK (("currency_code" ~ '^[A-Z]{3}$'::"text")),
    CONSTRAINT "businesses_legal_name_check" CHECK (("length"(TRIM(BOTH FROM "legal_name")) > 0)),
    CONSTRAINT "businesses_location_range_check" CHECK (("location_range" = ANY (ARRAY['1'::"text", '2-5'::"text", '6-20'::"text", '20+'::"text"])))
);


ALTER TABLE "public"."businesses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "parent_category_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "categories_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "season" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "collections_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "email" "text",
    "phone" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "customers_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."integration_connections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "provider" "text" NOT NULL,
    "display_name" "text",
    "external_shop_domain" "text",
    "status" "text" DEFAULT 'disconnected'::"text" NOT NULL,
    "sync_direction" "text" DEFAULT 'inbound'::"text" NOT NULL,
    "sync_config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "secret_ref" "text",
    "last_synced_at" timestamp with time zone,
    "connected_at" timestamp with time zone,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "integration_connections_provider_check" CHECK (("provider" = ANY (ARRAY['shopify'::"text", 'wix'::"text", 'custom'::"text"]))),
    CONSTRAINT "integration_connections_status_check" CHECK (("status" = ANY (ARRAY['disconnected'::"text", 'pending_oauth'::"text", 'connected'::"text", 'error'::"text", 'revoked'::"text"]))),
    CONSTRAINT "integration_connections_sync_direction_check" CHECK (("sync_direction" = ANY (ARRAY['inbound'::"text", 'outbound'::"text", 'bidirectional'::"text"])))
);


ALTER TABLE "public"."integration_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."integration_sync_checkpoints" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "connection_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "resource_type" "text" NOT NULL,
    "cursor_token" "text",
    "last_success_at" timestamp with time zone,
    "last_error" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "integration_sync_checkpoints_resource_type_check" CHECK (("resource_type" = ANY (ARRAY['products'::"text", 'variants'::"text", 'inventory'::"text", 'orders'::"text", 'locations'::"text"])))
);


ALTER TABLE "public"."integration_sync_checkpoints" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_balances" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "location_id" "uuid" NOT NULL,
    "variant_id" "uuid" NOT NULL,
    "available_qty" integer DEFAULT 0 NOT NULL,
    "committed_qty" integer DEFAULT 0 NOT NULL,
    "damaged_qty" integer DEFAULT 0 NOT NULL,
    "last_counted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_balances_available_qty_check" CHECK (("available_qty" >= 0)),
    CONSTRAINT "inventory_balances_committed_qty_check" CHECK (("committed_qty" >= 0)),
    CONSTRAINT "inventory_balances_damaged_qty_check" CHECK (("damaged_qty" >= 0))
);


ALTER TABLE "public"."inventory_balances" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_import_errors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "row_id" "uuid",
    "severity" "text" DEFAULT 'error'::"text" NOT NULL,
    "code" "text",
    "message" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_import_errors_message_check" CHECK (("length"(TRIM(BOTH FROM "message")) > 0)),
    CONSTRAINT "inventory_import_errors_severity_check" CHECK (("severity" = ANY (ARRAY['info'::"text", 'warning'::"text", 'error'::"text"])))
);


ALTER TABLE "public"."inventory_import_errors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_import_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "location_id" "uuid",
    "source_filename" "text" NOT NULL,
    "source_format" "text" NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "total_rows" integer DEFAULT 0 NOT NULL,
    "accepted_rows" integer DEFAULT 0 NOT NULL,
    "rejected_rows" integer DEFAULT 0 NOT NULL,
    "column_mappings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "error_summary" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_import_jobs_accepted_rows_check" CHECK (("accepted_rows" >= 0)),
    CONSTRAINT "inventory_import_jobs_rejected_rows_check" CHECK (("rejected_rows" >= 0)),
    CONSTRAINT "inventory_import_jobs_source_filename_check" CHECK (("length"(TRIM(BOTH FROM "source_filename")) > 0)),
    CONSTRAINT "inventory_import_jobs_source_format_check" CHECK (("source_format" = ANY (ARRAY['csv'::"text", 'xlsx'::"text"]))),
    CONSTRAINT "inventory_import_jobs_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'uploaded'::"text", 'mapping'::"text", 'validating'::"text", 'pending_review'::"text", 'importing'::"text", 'completed'::"text", 'failed'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "inventory_import_jobs_total_rows_check" CHECK (("total_rows" >= 0))
);


ALTER TABLE "public"."inventory_import_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_import_rows" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "row_number" integer NOT NULL,
    "raw_payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "mapped_payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "error_message" "text",
    "created_variant_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_import_rows_row_number_check" CHECK (("row_number" > 0)),
    CONSTRAINT "inventory_import_rows_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'valid'::"text", 'warning'::"text", 'error'::"text", 'imported'::"text", 'skipped'::"text"])))
);


ALTER TABLE "public"."inventory_import_rows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_ledger" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "location_id" "uuid" NOT NULL,
    "variant_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "quantity_delta" integer NOT NULL,
    "reference_type" "text",
    "reference_id" "uuid",
    "source" "text" DEFAULT 'manual'::"text" NOT NULL,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_ledger_event_type_check" CHECK (("event_type" = ANY (ARRAY['stock_in'::"text", 'stock_out'::"text", 'adjustment'::"text", 'sale'::"text", 'return'::"text", 'transfer_in'::"text", 'transfer_out'::"text", 'count_reconciliation'::"text"]))),
    CONSTRAINT "inventory_ledger_source_check" CHECK (("source" = ANY (ARRAY['manual'::"text", 'import'::"text", 'sale'::"text", 'purchase'::"text", 'transfer'::"text", 'ai'::"text", 'automation'::"text"])))
);


ALTER TABLE "public"."inventory_ledger" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."locations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "parent_location_id" "uuid",
    "name" "text" NOT NULL,
    "location_type" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "street_address" "text",
    "city" "text",
    "postal_code" "text",
    "country_code" "text",
    "timezone" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "locations_country_code_check" CHECK ((("country_code" IS NULL) OR ("country_code" ~ '^[A-Z]{2}$'::"text"))),
    CONSTRAINT "locations_location_type_check" CHECK (("location_type" = ANY (ARRAY['retail_store'::"text", 'warehouse'::"text", 'showroom'::"text", 'distribution_hub'::"text", 'pop_up'::"text", 'office'::"text"]))),
    CONSTRAINT "locations_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0)),
    CONSTRAINT "locations_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'maintenance'::"text"])))
);


ALTER TABLE "public"."locations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."memberships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "invited_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "memberships_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'pending'::"text", 'inactive'::"text", 'revoked'::"text"])))
);


ALTER TABLE "public"."memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."onboarding_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "current_step" integer DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'in_progress'::"text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "inventory_start_method" "text",
    CONSTRAINT "onboarding_sessions_current_step_check" CHECK ((("current_step" >= 0) AND ("current_step" <= 6))),
    CONSTRAINT "onboarding_sessions_inventory_start_method_check" CHECK ((("inventory_start_method" IS NULL) OR ("inventory_start_method" = ANY (ARRAY['manual'::"text", 'file_import'::"text", 'shopify'::"text"])))),
    CONSTRAINT "onboarding_sessions_status_check" CHECK (("status" = ANY (ARRAY['in_progress'::"text", 'complete'::"text", 'skipped'::"text"])))
);


ALTER TABLE "public"."onboarding_sessions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."onboarding_sessions"."inventory_start_method" IS 'Onboarding Step 4 selection: manual | file_import | shopify. Null until chosen.';



CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "module" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "permissions_code_check" CHECK (("length"(TRIM(BOTH FROM "code")) > 0)),
    CONSTRAINT "permissions_module_check" CHECK (("length"(TRIM(BOTH FROM "module")) > 0)),
    CONSTRAINT "permissions_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "media_type" "text" DEFAULT 'image'::"text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "alt_text" "text",
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "product_media_media_type_check" CHECK (("media_type" = ANY (ARRAY['image'::"text", 'video'::"text", 'other'::"text"]))),
    CONSTRAINT "product_media_sort_order_check" CHECK (("sort_order" >= 0)),
    CONSTRAINT "product_media_storage_path_check" CHECK (("length"(TRIM(BOTH FROM "storage_path")) > 0))
);


ALTER TABLE "public"."product_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_variants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "product_id" "uuid" NOT NULL,
    "sku" "text" NOT NULL,
    "barcode" "text",
    "color" "text",
    "size" "text",
    "material" "text",
    "retail_price_cents" bigint DEFAULT 0 NOT NULL,
    "cost_price_cents" bigint DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "product_variants_cost_price_cents_check" CHECK (("cost_price_cents" >= 0)),
    CONSTRAINT "product_variants_retail_price_cents_check" CHECK (("retail_price_cents" >= 0)),
    CONSTRAINT "product_variants_sku_check" CHECK (("length"(TRIM(BOTH FROM "sku")) > 0)),
    CONSTRAINT "product_variants_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'draft'::"text", 'inactive'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."product_variants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "brand_id" "uuid",
    "collection_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "supplier_id" "uuid",
    "tax_category" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "track_stock_levels" boolean DEFAULT false NOT NULL,
    "low_stock_threshold" integer DEFAULT 10,
    "published_at" timestamp with time zone,
    CONSTRAINT "products_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0)),
    CONSTRAINT "products_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'draft'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "first_name" "text",
    "last_name" "text",
    "full_name" "text",
    "email" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_system" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0))
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sale_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "product_id" "uuid",
    "variant_id" "uuid",
    "sku_snapshot" "text" NOT NULL,
    "product_name_snapshot" "text" NOT NULL,
    "variant_title_snapshot" "text",
    "quantity" integer NOT NULL,
    "unit_price_minor" bigint NOT NULL,
    "unit_cost_minor" bigint DEFAULT 0 NOT NULL,
    "discount_minor" bigint DEFAULT 0 NOT NULL,
    "taxable_amount_minor" bigint NOT NULL,
    "tax_minor" bigint DEFAULT 0 NOT NULL,
    "line_total_minor" bigint NOT NULL,
    "tax_category_snapshot" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sale_items_discount_minor_check" CHECK (("discount_minor" >= 0)),
    CONSTRAINT "sale_items_line_total_minor_check" CHECK (("line_total_minor" >= 0)),
    CONSTRAINT "sale_items_quantity_check" CHECK (("quantity" > 0)),
    CONSTRAINT "sale_items_tax_minor_check" CHECK (("tax_minor" >= 0)),
    CONSTRAINT "sale_items_taxable_amount_minor_check" CHECK (("taxable_amount_minor" >= 0)),
    CONSTRAINT "sale_items_unit_cost_minor_check" CHECK (("unit_cost_minor" >= 0)),
    CONSTRAINT "sale_items_unit_price_minor_check" CHECK (("unit_price_minor" >= 0))
);


ALTER TABLE "public"."sale_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sale_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "payment_method" "text" NOT NULL,
    "amount_minor" bigint NOT NULL,
    "currency_code" "text" DEFAULT 'INR'::"text" NOT NULL,
    "status" "text" DEFAULT 'completed'::"text" NOT NULL,
    "processing_type" "text" DEFAULT 'recorded'::"text" NOT NULL,
    "reference_number" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sale_payments_amount_minor_check" CHECK (("amount_minor" > 0)),
    CONSTRAINT "sale_payments_payment_method_check" CHECK (("payment_method" = ANY (ARRAY['cash'::"text", 'card'::"text", 'upi'::"text", 'bank_transfer'::"text", 'split'::"text", 'other'::"text"]))),
    CONSTRAINT "sale_payments_processing_type_check" CHECK (("processing_type" = ANY (ARRAY['recorded'::"text", 'electronic'::"text"]))),
    CONSTRAINT "sale_payments_status_check" CHECK (("status" = ANY (ARRAY['completed'::"text", 'pending'::"text", 'failed'::"text", 'refunded'::"text"])))
);


ALTER TABLE "public"."sale_payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "location_id" "uuid" NOT NULL,
    "sale_number" "text" NOT NULL,
    "customer_id" "uuid",
    "status" "text" DEFAULT 'completed'::"text" NOT NULL,
    "subtotal_minor" bigint NOT NULL,
    "discount_minor" bigint DEFAULT 0 NOT NULL,
    "tax_minor" bigint DEFAULT 0 NOT NULL,
    "total_minor" bigint NOT NULL,
    "currency_code" "text" DEFAULT 'INR'::"text" NOT NULL,
    "discount_type" "text",
    "discount_rate" numeric(10,4) DEFAULT 0,
    "note" "text",
    "idempotency_key" "text",
    "created_by" "uuid",
    "completed_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "held_at" timestamp with time zone,
    "held_by" "uuid",
    CONSTRAINT "sales_discount_minor_check" CHECK (("discount_minor" >= 0)),
    CONSTRAINT "sales_discount_type_check" CHECK (("discount_type" = ANY (ARRAY['percentage'::"text", 'flat'::"text", 'none'::"text"]))),
    CONSTRAINT "sales_status_check" CHECK (("status" = ANY (ARRAY['completed'::"text", 'held'::"text", 'cancelled'::"text", 'refunded'::"text", 'partially_refunded'::"text"]))),
    CONSTRAINT "sales_subtotal_minor_check" CHECK (("subtotal_minor" >= 0)),
    CONSTRAINT "sales_tax_minor_check" CHECK (("tax_minor" >= 0)),
    CONSTRAINT "sales_total_minor_check" CHECK (("total_minor" >= 0))
);


ALTER TABLE "public"."sales" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."suppliers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "contact_email" "text",
    "contact_phone" "text",
    "tax_identifier" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "suppliers_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) > 0)),
    CONSTRAINT "suppliers_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."suppliers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tax_rule_audit_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "rule_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "previous_value" "jsonb",
    "new_value" "jsonb",
    "change_reason" "text",
    "source_authority" "text",
    "source_document_reference" "text",
    "detected_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "effective_at" timestamp with time zone,
    "ai_confidence" numeric(4,3),
    "auto_applied" boolean DEFAULT false NOT NULL,
    "approved_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tax_rule_audit_events_event_type_check" CHECK (("event_type" = ANY (ARRAY['detected'::"text", 'proposed'::"text", 'validated'::"text", 'approved'::"text", 'rejected'::"text", 'superseded'::"text", 'scheduled'::"text"])))
);


ALTER TABLE "public"."tax_rule_audit_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tax_rule_review_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "rule_id" "uuid" NOT NULL,
    "review_reason" "text" NOT NULL,
    "review_status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tax_rule_review_queue_review_status_check" CHECK (("review_status" = ANY (ARRAY['open'::"text", 'in_review'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."tax_rule_review_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tax_rule_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_document_id" "uuid" NOT NULL,
    "country_code" "text" NOT NULL,
    "jurisdiction_type" "text" NOT NULL,
    "jurisdiction_code" "text",
    "tax_system" "text" NOT NULL,
    "tax_type" "text" NOT NULL,
    "product_classification" "text",
    "commodity_code" "text",
    "rate" numeric(10,4) NOT NULL,
    "threshold_amount" numeric(18,2),
    "threshold_currency" "text",
    "threshold_inclusive" boolean DEFAULT false NOT NULL,
    "customer_applicability" "text",
    "transaction_conditions" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "effective_from" timestamp with time zone NOT NULL,
    "effective_to" timestamp with time zone,
    "exemptions" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "source_reference" "text",
    "ai_confidence" numeric(4,3),
    "extraction_warnings" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'detected'::"text" NOT NULL,
    "approved_at" timestamp with time zone,
    "approved_by" "uuid",
    "created_by_source" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tax_rule_versions_ai_confidence_check" CHECK ((("ai_confidence" >= (0)::numeric) AND ("ai_confidence" <= (1)::numeric))),
    CONSTRAINT "tax_rule_versions_country_code_check" CHECK (("country_code" ~ '^[A-Z]{2}$'::"text")),
    CONSTRAINT "tax_rule_versions_jurisdiction_type_check" CHECK (("jurisdiction_type" = ANY (ARRAY['country'::"text", 'state'::"text", 'province'::"text", 'region'::"text", 'local'::"text"]))),
    CONSTRAINT "tax_rule_versions_rate_check" CHECK ((("rate" >= (0)::numeric) AND ("rate" <= (1000)::numeric))),
    CONSTRAINT "tax_rule_versions_status_check" CHECK (("status" = ANY (ARRAY['detected'::"text", 'proposed'::"text", 'pending_review'::"text", 'scheduled'::"text", 'active'::"text", 'superseded'::"text", 'rejected'::"text"]))),
    CONSTRAINT "tax_rule_versions_tax_system_check" CHECK (("tax_system" = ANY (ARRAY['GST'::"text", 'VAT'::"text", 'Sales Tax'::"text", 'Other'::"text"]))),
    CONSTRAINT "tax_rule_versions_tax_type_check" CHECK (("length"(TRIM(BOTH FROM "tax_type")) > 0))
);


ALTER TABLE "public"."tax_rule_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tax_source_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_id" "uuid" NOT NULL,
    "country_code" "text" NOT NULL,
    "jurisdiction_type" "text" NOT NULL,
    "jurisdiction_code" "text",
    "authority_name" "text" NOT NULL,
    "source_url" "text" NOT NULL,
    "document_title" "text" NOT NULL,
    "government_reference" "text",
    "publication_date" timestamp with time zone,
    "effective_date" timestamp with time zone,
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "content_hash" "text" NOT NULL,
    "original_document_url" "text",
    "parser_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tax_source_documents_authority_name_check" CHECK (("length"(TRIM(BOTH FROM "authority_name")) > 0)),
    CONSTRAINT "tax_source_documents_content_hash_check" CHECK (("length"(TRIM(BOTH FROM "content_hash")) > 0)),
    CONSTRAINT "tax_source_documents_country_code_check" CHECK (("country_code" ~ '^[A-Z]{2}$'::"text")),
    CONSTRAINT "tax_source_documents_document_title_check" CHECK (("length"(TRIM(BOTH FROM "document_title")) > 0)),
    CONSTRAINT "tax_source_documents_jurisdiction_type_check" CHECK (("jurisdiction_type" = ANY (ARRAY['country'::"text", 'state'::"text", 'province'::"text", 'region'::"text", 'local'::"text"]))),
    CONSTRAINT "tax_source_documents_parser_status_check" CHECK (("parser_status" = ANY (ARRAY['pending'::"text", 'parsed'::"text", 'failed'::"text", 'conflict'::"text", 'review_required'::"text"]))),
    CONSTRAINT "tax_source_documents_source_url_check" CHECK (("length"(TRIM(BOTH FROM "source_url")) > 0))
);


ALTER TABLE "public"."tax_source_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tax_source_registry" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "country_code" "text" NOT NULL,
    "jurisdiction_type" "text" NOT NULL,
    "jurisdiction_code" "text",
    "authority_name" "text" NOT NULL,
    "source_type" "text" NOT NULL,
    "base_url" "text" NOT NULL,
    "listing_url" "text",
    "enabled" boolean DEFAULT true NOT NULL,
    "last_checked_at" timestamp with time zone,
    "last_success_at" timestamp with time zone,
    "check_frequency" "text" DEFAULT 'daily'::"text" NOT NULL,
    "parser_strategy" "text" DEFAULT 'government_publication'::"text" NOT NULL,
    "authority_priority" integer DEFAULT 100 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tax_source_registry_authority_name_check" CHECK (("length"(TRIM(BOTH FROM "authority_name")) > 0)),
    CONSTRAINT "tax_source_registry_authority_priority_check" CHECK (("authority_priority" >= 0)),
    CONSTRAINT "tax_source_registry_base_url_check" CHECK (("length"(TRIM(BOTH FROM "base_url")) > 0)),
    CONSTRAINT "tax_source_registry_check_frequency_check" CHECK (("check_frequency" = ANY (ARRAY['hourly'::"text", 'daily'::"text", 'weekly'::"text", 'manual'::"text"]))),
    CONSTRAINT "tax_source_registry_country_code_check" CHECK (("country_code" ~ '^[A-Z]{2}$'::"text")),
    CONSTRAINT "tax_source_registry_jurisdiction_type_check" CHECK (("jurisdiction_type" = ANY (ARRAY['country'::"text", 'state'::"text", 'province'::"text", 'region'::"text", 'local'::"text"]))),
    CONSTRAINT "tax_source_registry_parser_strategy_check" CHECK (("length"(TRIM(BOTH FROM "parser_strategy")) > 0)),
    CONSTRAINT "tax_source_registry_source_type_check" CHECK (("source_type" = ANY (ARRAY['government'::"text", 'tax_authority'::"text", 'customs'::"text", 'commission'::"text", 'statistical'::"text"])))
);


ALTER TABLE "public"."tax_source_registry" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "location_id" "uuid",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "invited_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "team_members_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'pending'::"text", 'removed'::"text"])))
);


ALTER TABLE "public"."team_members" OWNER TO "postgres";


ALTER TABLE ONLY "public"."brands"
    ADD CONSTRAINT "brands_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."brands"
    ADD CONSTRAINT "brands_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."business_commerce_profiles"
    ADD CONSTRAINT "business_commerce_profiles_pkey" PRIMARY KEY ("business_id");



ALTER TABLE ONLY "public"."business_profile_settings"
    ADD CONSTRAINT "business_profile_settings_pkey" PRIMARY KEY ("business_id");



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."integration_connections"
    ADD CONSTRAINT "integration_connections_business_id_provider_external_shop__key" UNIQUE ("business_id", "provider", "external_shop_domain");



ALTER TABLE ONLY "public"."integration_connections"
    ADD CONSTRAINT "integration_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."integration_sync_checkpoints"
    ADD CONSTRAINT "integration_sync_checkpoints_connection_id_resource_type_key" UNIQUE ("connection_id", "resource_type");



ALTER TABLE ONLY "public"."integration_sync_checkpoints"
    ADD CONSTRAINT "integration_sync_checkpoints_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_balances"
    ADD CONSTRAINT "inventory_balances_business_id_location_id_variant_id_key" UNIQUE ("business_id", "location_id", "variant_id");



ALTER TABLE ONLY "public"."inventory_balances"
    ADD CONSTRAINT "inventory_balances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_import_errors"
    ADD CONSTRAINT "inventory_import_errors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_import_jobs"
    ADD CONSTRAINT "inventory_import_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_import_rows"
    ADD CONSTRAINT "inventory_import_rows_job_id_row_number_key" UNIQUE ("job_id", "row_number");



ALTER TABLE ONLY "public"."inventory_import_rows"
    ADD CONSTRAINT "inventory_import_rows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_ledger"
    ADD CONSTRAINT "inventory_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."memberships"
    ADD CONSTRAINT "memberships_business_id_user_id_key" UNIQUE ("business_id", "user_id");



ALTER TABLE ONLY "public"."memberships"
    ADD CONSTRAINT "memberships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."onboarding_sessions"
    ADD CONSTRAINT "onboarding_sessions_business_id_user_id_key" UNIQUE ("business_id", "user_id");



ALTER TABLE ONLY "public"."onboarding_sessions"
    ADD CONSTRAINT "onboarding_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_media"
    ADD CONSTRAINT "product_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_variants_barcode_key" UNIQUE ("barcode");



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_variants_product_id_sku_key" UNIQUE ("product_id", "sku");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_permission_id_key" UNIQUE ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_business_id_sale_number_key" UNIQUE ("business_id", "sale_number");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_business_id_name_key" UNIQUE ("business_id", "name");



ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tax_rule_audit_events"
    ADD CONSTRAINT "tax_rule_audit_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tax_rule_review_queue"
    ADD CONSTRAINT "tax_rule_review_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tax_rule_versions"
    ADD CONSTRAINT "tax_rule_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tax_source_documents"
    ADD CONSTRAINT "tax_source_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tax_source_documents"
    ADD CONSTRAINT "tax_source_documents_source_id_content_hash_key" UNIQUE ("source_id", "content_hash");



ALTER TABLE ONLY "public"."tax_source_registry"
    ADD CONSTRAINT "tax_source_registry_country_code_jurisdiction_type_jurisdic_key" UNIQUE ("country_code", "jurisdiction_type", "jurisdiction_code", "authority_name");



ALTER TABLE ONLY "public"."tax_source_registry"
    ADD CONSTRAINT "tax_source_registry_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_business_id_user_id_key" UNIQUE ("business_id", "user_id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_brands_business_id" ON "public"."brands" USING "btree" ("business_id");



CREATE INDEX "idx_business_commerce_profiles_business_id" ON "public"."business_commerce_profiles" USING "btree" ("business_id");



CREATE INDEX "idx_business_profile_settings_business_id" ON "public"."business_profile_settings" USING "btree" ("business_id");



CREATE INDEX "idx_businesses_country_code" ON "public"."businesses" USING "btree" ("country_code");



CREATE INDEX "idx_businesses_currency_code" ON "public"."businesses" USING "btree" ("currency_code");



CREATE INDEX "idx_businesses_owner_user_id" ON "public"."businesses" USING "btree" ("owner_user_id");



CREATE INDEX "idx_categories_business_id" ON "public"."categories" USING "btree" ("business_id");



CREATE INDEX "idx_categories_parent_category_id" ON "public"."categories" USING "btree" ("parent_category_id");



CREATE INDEX "idx_collections_business_id" ON "public"."collections" USING "btree" ("business_id");



CREATE INDEX "idx_customers_business_id" ON "public"."customers" USING "btree" ("business_id");



CREATE INDEX "idx_integration_connections_business_id" ON "public"."integration_connections" USING "btree" ("business_id");



CREATE INDEX "idx_integration_sync_checkpoints_connection_id" ON "public"."integration_sync_checkpoints" USING "btree" ("connection_id");



CREATE INDEX "idx_inventory_balances_location_id" ON "public"."inventory_balances" USING "btree" ("location_id");



CREATE INDEX "idx_inventory_balances_variant_id" ON "public"."inventory_balances" USING "btree" ("variant_id");



CREATE INDEX "idx_inventory_import_errors_job_id" ON "public"."inventory_import_errors" USING "btree" ("job_id");



CREATE INDEX "idx_inventory_import_jobs_business_id" ON "public"."inventory_import_jobs" USING "btree" ("business_id");



CREATE INDEX "idx_inventory_import_jobs_status" ON "public"."inventory_import_jobs" USING "btree" ("business_id", "status");



CREATE INDEX "idx_inventory_import_rows_job_id" ON "public"."inventory_import_rows" USING "btree" ("job_id");



CREATE INDEX "idx_inventory_ledger_variant_id" ON "public"."inventory_ledger" USING "btree" ("variant_id");



CREATE INDEX "idx_locations_business_id" ON "public"."locations" USING "btree" ("business_id");



CREATE INDEX "idx_locations_business_type" ON "public"."locations" USING "btree" ("location_type");



CREATE INDEX "idx_locations_parent_location_id" ON "public"."locations" USING "btree" ("parent_location_id");



CREATE INDEX "idx_locations_status" ON "public"."locations" USING "btree" ("status");



CREATE INDEX "idx_memberships_business_id" ON "public"."memberships" USING "btree" ("business_id");



CREATE INDEX "idx_memberships_user_id" ON "public"."memberships" USING "btree" ("user_id");



CREATE INDEX "idx_onboarding_sessions_business_id" ON "public"."onboarding_sessions" USING "btree" ("business_id");



CREATE INDEX "idx_onboarding_sessions_user_id" ON "public"."onboarding_sessions" USING "btree" ("user_id");



CREATE INDEX "idx_permissions_code" ON "public"."permissions" USING "btree" ("code");



CREATE INDEX "idx_product_media_business_id" ON "public"."product_media" USING "btree" ("business_id");



CREATE UNIQUE INDEX "idx_product_media_one_primary_per_product" ON "public"."product_media" USING "btree" ("product_id") WHERE ("is_primary" = true);



CREATE INDEX "idx_product_media_product_id" ON "public"."product_media" USING "btree" ("product_id");



CREATE INDEX "idx_product_variants_product_id" ON "public"."product_variants" USING "btree" ("product_id");



CREATE INDEX "idx_products_brand_id" ON "public"."products" USING "btree" ("brand_id");



CREATE INDEX "idx_products_business_id" ON "public"."products" USING "btree" ("business_id");



CREATE INDEX "idx_products_category_id" ON "public"."products" USING "btree" ("category_id");



CREATE INDEX "idx_products_status" ON "public"."products" USING "btree" ("business_id", "status");



CREATE INDEX "idx_products_supplier_id" ON "public"."products" USING "btree" ("supplier_id");



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_role_permissions_role_id" ON "public"."role_permissions" USING "btree" ("role_id");



CREATE INDEX "idx_roles_business_id" ON "public"."roles" USING "btree" ("business_id");



CREATE INDEX "idx_sale_items_sale_id" ON "public"."sale_items" USING "btree" ("sale_id");



CREATE INDEX "idx_sale_items_variant_id" ON "public"."sale_items" USING "btree" ("variant_id");



CREATE INDEX "idx_sale_payments_business_id" ON "public"."sale_payments" USING "btree" ("business_id");



CREATE INDEX "idx_sale_payments_sale_id" ON "public"."sale_payments" USING "btree" ("sale_id");



CREATE INDEX "idx_sales_business_id_created_at" ON "public"."sales" USING "btree" ("business_id", "created_at" DESC);



CREATE UNIQUE INDEX "idx_sales_business_idempotency" ON "public"."sales" USING "btree" ("business_id", "idempotency_key") WHERE ("idempotency_key" IS NOT NULL);



CREATE INDEX "idx_sales_business_status_held_at" ON "public"."sales" USING "btree" ("business_id", "held_at" DESC NULLS LAST) WHERE ("status" = 'held'::"text");



CREATE INDEX "idx_sales_customer_id" ON "public"."sales" USING "btree" ("customer_id");



CREATE INDEX "idx_sales_location_id" ON "public"."sales" USING "btree" ("location_id");



CREATE INDEX "idx_suppliers_business_id" ON "public"."suppliers" USING "btree" ("business_id");



CREATE INDEX "idx_tax_rule_audit_events_rule_id" ON "public"."tax_rule_audit_events" USING "btree" ("rule_id", "detected_at" DESC);



CREATE INDEX "idx_tax_rule_review_queue_rule_id" ON "public"."tax_rule_review_queue" USING "btree" ("rule_id");



CREATE INDEX "idx_tax_rule_versions_country_code" ON "public"."tax_rule_versions" USING "btree" ("country_code", "effective_from" DESC);



CREATE INDEX "idx_tax_rule_versions_jurisdiction" ON "public"."tax_rule_versions" USING "btree" ("country_code", "jurisdiction_type", "jurisdiction_code", "tax_type");



CREATE INDEX "idx_tax_rule_versions_status" ON "public"."tax_rule_versions" USING "btree" ("status", "effective_from" DESC);



CREATE INDEX "idx_tax_source_documents_country_code" ON "public"."tax_source_documents" USING "btree" ("country_code", "publication_date" DESC);



CREATE INDEX "idx_tax_source_documents_parser_status" ON "public"."tax_source_documents" USING "btree" ("parser_status", "fetched_at" DESC);



CREATE INDEX "idx_tax_source_documents_source_id" ON "public"."tax_source_documents" USING "btree" ("source_id");



CREATE INDEX "idx_tax_source_registry_country_code" ON "public"."tax_source_registry" USING "btree" ("country_code");



CREATE INDEX "idx_tax_source_registry_enabled" ON "public"."tax_source_registry" USING "btree" ("enabled", "check_frequency");



CREATE INDEX "idx_team_members_business_id" ON "public"."team_members" USING "btree" ("business_id");



CREATE INDEX "idx_team_members_role_id" ON "public"."team_members" USING "btree" ("role_id");



CREATE UNIQUE INDEX "uq_brands_business_id_lower_name" ON "public"."brands" USING "btree" ("business_id", "lower"(TRIM(BOTH FROM "name")));



CREATE UNIQUE INDEX "uq_categories_business_id_lower_name" ON "public"."categories" USING "btree" ("business_id", "lower"(TRIM(BOTH FROM "name")));



CREATE OR REPLACE TRIGGER "trg_brands_set_updated_at" BEFORE UPDATE ON "public"."brands" FOR EACH ROW EXECUTE FUNCTION "public"."set_brand_updated_at"();



CREATE OR REPLACE TRIGGER "trg_business_commerce_profiles_set_updated_at" BEFORE UPDATE ON "public"."business_commerce_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_business_commerce_profile_updated_at"();



CREATE OR REPLACE TRIGGER "trg_business_profile_settings_set_updated_at" BEFORE UPDATE ON "public"."business_profile_settings" FOR EACH ROW EXECUTE FUNCTION "public"."set_business_profile_updated_at"();



CREATE OR REPLACE TRIGGER "trg_businesses_set_updated_at" BEFORE UPDATE ON "public"."businesses" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_categories_set_updated_at" BEFORE UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."set_category_updated_at"();



CREATE OR REPLACE TRIGGER "trg_collections_set_updated_at" BEFORE UPDATE ON "public"."collections" FOR EACH ROW EXECUTE FUNCTION "public"."set_collection_updated_at"();



CREATE OR REPLACE TRIGGER "trg_customers_set_updated_at" BEFORE UPDATE ON "public"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."set_customers_updated_at"();



CREATE OR REPLACE TRIGGER "trg_integration_connections_set_updated_at" BEFORE UPDATE ON "public"."integration_connections" FOR EACH ROW EXECUTE FUNCTION "public"."set_integration_connection_updated_at"();



CREATE OR REPLACE TRIGGER "trg_integration_sync_checkpoints_set_updated_at" BEFORE UPDATE ON "public"."integration_sync_checkpoints" FOR EACH ROW EXECUTE FUNCTION "public"."set_integration_sync_checkpoint_updated_at"();



CREATE OR REPLACE TRIGGER "trg_inventory_balances_set_updated_at" BEFORE UPDATE ON "public"."inventory_balances" FOR EACH ROW EXECUTE FUNCTION "public"."set_balance_updated_at"();



CREATE OR REPLACE TRIGGER "trg_inventory_import_jobs_set_updated_at" BEFORE UPDATE ON "public"."inventory_import_jobs" FOR EACH ROW EXECUTE FUNCTION "public"."set_inventory_import_job_updated_at"();



CREATE OR REPLACE TRIGGER "trg_locations_set_updated_at" BEFORE UPDATE ON "public"."locations" FOR EACH ROW EXECUTE FUNCTION "public"."set_locations_updated_at"();



CREATE OR REPLACE TRIGGER "trg_memberships_set_updated_at" BEFORE UPDATE ON "public"."memberships" FOR EACH ROW EXECUTE FUNCTION "public"."set_membership_updated_at"();



CREATE OR REPLACE TRIGGER "trg_onboarding_sessions_set_updated_at" BEFORE UPDATE ON "public"."onboarding_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_onboarding_session_updated_at"();



CREATE OR REPLACE TRIGGER "trg_permissions_set_updated_at" BEFORE UPDATE ON "public"."permissions" FOR EACH ROW EXECUTE FUNCTION "public"."set_permissions_updated_at"();



CREATE OR REPLACE TRIGGER "trg_product_media_set_updated_at" BEFORE UPDATE ON "public"."product_media" FOR EACH ROW EXECUTE FUNCTION "public"."set_product_media_updated_at"();



CREATE OR REPLACE TRIGGER "trg_product_variants_set_updated_at" BEFORE UPDATE ON "public"."product_variants" FOR EACH ROW EXECUTE FUNCTION "public"."set_variant_updated_at"();



CREATE OR REPLACE TRIGGER "trg_products_set_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_product_updated_at"();



CREATE OR REPLACE TRIGGER "trg_roles_set_updated_at" BEFORE UPDATE ON "public"."roles" FOR EACH ROW EXECUTE FUNCTION "public"."set_roles_updated_at"();



CREATE OR REPLACE TRIGGER "trg_sales_set_updated_at" BEFORE UPDATE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."set_sales_updated_at"();



CREATE OR REPLACE TRIGGER "trg_suppliers_set_updated_at" BEFORE UPDATE ON "public"."suppliers" FOR EACH ROW EXECUTE FUNCTION "public"."set_suppliers_updated_at"();



CREATE OR REPLACE TRIGGER "trg_tax_rule_review_queue_set_updated_at" BEFORE UPDATE ON "public"."tax_rule_review_queue" FOR EACH ROW EXECUTE FUNCTION "public"."set_tax_rule_review_queue_updated_at"();



CREATE OR REPLACE TRIGGER "trg_tax_rule_versions_set_updated_at" BEFORE UPDATE ON "public"."tax_rule_versions" FOR EACH ROW EXECUTE FUNCTION "public"."set_tax_rule_versions_updated_at"();



CREATE OR REPLACE TRIGGER "trg_tax_source_documents_set_updated_at" BEFORE UPDATE ON "public"."tax_source_documents" FOR EACH ROW EXECUTE FUNCTION "public"."set_tax_source_documents_updated_at"();



CREATE OR REPLACE TRIGGER "trg_tax_source_registry_set_updated_at" BEFORE UPDATE ON "public"."tax_source_registry" FOR EACH ROW EXECUTE FUNCTION "public"."set_tax_source_registry_updated_at"();



CREATE OR REPLACE TRIGGER "trg_team_members_set_updated_at" BEFORE UPDATE ON "public"."team_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_team_members_updated_at"();



ALTER TABLE ONLY "public"."brands"
    ADD CONSTRAINT "brands_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."business_commerce_profiles"
    ADD CONSTRAINT "business_commerce_profiles_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."business_profile_settings"
    ADD CONSTRAINT "business_profile_settings_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_parent_category_id_fkey" FOREIGN KEY ("parent_category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integration_connections"
    ADD CONSTRAINT "integration_connections_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integration_connections"
    ADD CONSTRAINT "integration_connections_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."integration_sync_checkpoints"
    ADD CONSTRAINT "integration_sync_checkpoints_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."integration_sync_checkpoints"
    ADD CONSTRAINT "integration_sync_checkpoints_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."integration_connections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_balances"
    ADD CONSTRAINT "inventory_balances_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_balances"
    ADD CONSTRAINT "inventory_balances_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_balances"
    ADD CONSTRAINT "inventory_balances_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "public"."product_variants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_errors"
    ADD CONSTRAINT "inventory_import_errors_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_errors"
    ADD CONSTRAINT "inventory_import_errors_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."inventory_import_jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_errors"
    ADD CONSTRAINT "inventory_import_errors_row_id_fkey" FOREIGN KEY ("row_id") REFERENCES "public"."inventory_import_rows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_jobs"
    ADD CONSTRAINT "inventory_import_jobs_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_jobs"
    ADD CONSTRAINT "inventory_import_jobs_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory_import_jobs"
    ADD CONSTRAINT "inventory_import_jobs_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory_import_rows"
    ADD CONSTRAINT "inventory_import_rows_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_import_rows"
    ADD CONSTRAINT "inventory_import_rows_created_variant_id_fkey" FOREIGN KEY ("created_variant_id") REFERENCES "public"."product_variants"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory_import_rows"
    ADD CONSTRAINT "inventory_import_rows_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."inventory_import_jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_ledger"
    ADD CONSTRAINT "inventory_ledger_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_ledger"
    ADD CONSTRAINT "inventory_ledger_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_ledger"
    ADD CONSTRAINT "inventory_ledger_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "public"."product_variants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."locations"
    ADD CONSTRAINT "locations_parent_location_id_fkey" FOREIGN KEY ("parent_location_id") REFERENCES "public"."locations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."memberships"
    ADD CONSTRAINT "memberships_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."memberships"
    ADD CONSTRAINT "memberships_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."memberships"
    ADD CONSTRAINT "memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."onboarding_sessions"
    ADD CONSTRAINT "onboarding_sessions_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."onboarding_sessions"
    ADD CONSTRAINT "onboarding_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_media"
    ADD CONSTRAINT "product_media_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_media"
    ADD CONSTRAINT "product_media_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_variants_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "public"."brands"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."collections"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "public"."suppliers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "public"."product_variants"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_held_by_fkey" FOREIGN KEY ("held_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tax_rule_audit_events"
    ADD CONSTRAINT "tax_rule_audit_events_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."tax_rule_audit_events"
    ADD CONSTRAINT "tax_rule_audit_events_rule_id_fkey" FOREIGN KEY ("rule_id") REFERENCES "public"."tax_rule_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tax_rule_review_queue"
    ADD CONSTRAINT "tax_rule_review_queue_rule_id_fkey" FOREIGN KEY ("rule_id") REFERENCES "public"."tax_rule_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tax_rule_versions"
    ADD CONSTRAINT "tax_rule_versions_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."tax_rule_versions"
    ADD CONSTRAINT "tax_rule_versions_source_document_id_fkey" FOREIGN KEY ("source_document_id") REFERENCES "public"."tax_source_documents"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."tax_source_documents"
    ADD CONSTRAINT "tax_source_documents_source_id_fkey" FOREIGN KEY ("source_id") REFERENCES "public"."tax_source_registry"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."locations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."brands" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brands_modify_business_owner" ON "public"."brands" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "brands_select_business_members" ON "public"."brands" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."business_commerce_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "business_commerce_profiles_delete_business_members" ON "public"."business_commerce_profiles" FOR DELETE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "business_commerce_profiles_insert_business_members" ON "public"."business_commerce_profiles" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "business_commerce_profiles_select_business_members" ON "public"."business_commerce_profiles" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "business_commerce_profiles_update_business_members" ON "public"."business_commerce_profiles" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."business_profile_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "business_profile_settings_select_business_members" ON "public"."business_profile_settings" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "business_profile_settings_update_business_members" ON "public"."business_profile_settings" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "business_profile_settings_upsert_business_members" ON "public"."business_profile_settings" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."businesses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "businesses_delete_own" ON "public"."businesses" FOR DELETE USING (("owner_user_id" = "auth"."uid"()));



CREATE POLICY "businesses_insert_own" ON "public"."businesses" FOR INSERT WITH CHECK (("owner_user_id" = "auth"."uid"()));



CREATE POLICY "businesses_select_own" ON "public"."businesses" FOR SELECT USING (("owner_user_id" = "auth"."uid"()));



CREATE POLICY "businesses_update_own" ON "public"."businesses" FOR UPDATE USING (("owner_user_id" = "auth"."uid"())) WITH CHECK (("owner_user_id" = "auth"."uid"()));



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "categories_modify_business_owner" ON "public"."categories" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "categories_select_business_members" ON "public"."categories" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."collections" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "collections_modify_business_owner" ON "public"."collections" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "collections_select_business_members" ON "public"."collections" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "customers_modify_business_owner_or_member" ON "public"."customers" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "customers_select_business_members" ON "public"."customers" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."integration_connections" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "integration_connections_insert_business_members" ON "public"."integration_connections" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "integration_connections_select_business_members" ON "public"."integration_connections" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "integration_connections_update_business_members" ON "public"."integration_connections" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."integration_sync_checkpoints" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "integration_sync_checkpoints_modify_business_members" ON "public"."integration_sync_checkpoints" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "integration_sync_checkpoints_select_business_members" ON "public"."integration_sync_checkpoints" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."inventory_balances" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inventory_balances_modify_business_owner" ON "public"."inventory_balances" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_balances_select_business_members" ON "public"."inventory_balances" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."inventory_import_errors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inventory_import_errors_insert_business_members" ON "public"."inventory_import_errors" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_import_errors_select_business_members" ON "public"."inventory_import_errors" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."inventory_import_jobs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inventory_import_jobs_insert_business_members" ON "public"."inventory_import_jobs" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_import_jobs_select_business_members" ON "public"."inventory_import_jobs" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_import_jobs_update_business_members" ON "public"."inventory_import_jobs" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."inventory_import_rows" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inventory_import_rows_insert_business_members" ON "public"."inventory_import_rows" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_import_rows_select_business_members" ON "public"."inventory_import_rows" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_import_rows_update_business_members" ON "public"."inventory_import_rows" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."inventory_ledger" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "inventory_ledger_modify_business_owner" ON "public"."inventory_ledger" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "inventory_ledger_select_business_members" ON "public"."inventory_ledger" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."locations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "locations_delete_business_owner" ON "public"."locations" FOR DELETE USING ("public"."is_business_owner"("business_id"));



CREATE POLICY "locations_delete_own_business" ON "public"."locations" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "locations"."business_id") AND ("b"."owner_user_id" = "auth"."uid"())))));



CREATE POLICY "locations_insert_business_owner_or_member" ON "public"."locations" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "locations_insert_own_business" ON "public"."locations" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "locations"."business_id") AND ("b"."owner_user_id" = "auth"."uid"())))));



CREATE POLICY "locations_select_business_members" ON "public"."locations" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "locations_select_own_business" ON "public"."locations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "locations"."business_id") AND ("b"."owner_user_id" = "auth"."uid"())))));



CREATE POLICY "locations_update_business_owner_or_member" ON "public"."locations" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "locations_update_own_business" ON "public"."locations" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "locations"."business_id") AND ("b"."owner_user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "locations"."business_id") AND ("b"."owner_user_id" = "auth"."uid"())))));



ALTER TABLE "public"."memberships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "memberships_delete_business_owner" ON "public"."memberships" FOR DELETE USING ("public"."is_business_owner"("business_id"));



CREATE POLICY "memberships_insert_business_owner" ON "public"."memberships" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_business_owner"("business_id"));



CREATE POLICY "memberships_select_own_or_business_owner" ON "public"."memberships" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "memberships_update_business_owner" ON "public"."memberships" FOR UPDATE TO "authenticated" USING ("public"."is_business_owner"("business_id")) WITH CHECK ("public"."is_business_owner"("business_id"));



ALTER TABLE "public"."onboarding_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "onboarding_sessions_insert_business_members" ON "public"."onboarding_sessions" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "onboarding_sessions_select_business_members" ON "public"."onboarding_sessions" FOR SELECT USING ((("business_id" IN ( SELECT "m"."business_id"
   FROM "public"."memberships" "m"
  WHERE (("m"."user_id" = "auth"."uid"()) AND ("m"."status" = 'active'::"text")))) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "onboarding_sessions_update_business_members" ON "public"."onboarding_sessions" FOR UPDATE USING ((("user_id" = "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK ((("user_id" = "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."permissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "permissions_select_authenticated_user" ON "public"."permissions" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



ALTER TABLE "public"."product_media" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "product_media_delete_business_members" ON "public"."product_media" FOR DELETE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "product_media_insert_business_members" ON "public"."product_media" FOR INSERT WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "product_media_select_business_members" ON "public"."product_media" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "product_media_update_business_members" ON "public"."product_media" FOR UPDATE USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."product_variants" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "product_variants_modify_business_owner" ON "public"."product_variants" USING ((EXISTS ( SELECT 1
   FROM "public"."products" "p"
  WHERE (("p"."id" = "product_variants"."product_id") AND ("public"."is_business_member"("p"."business_id", "auth"."uid"()) OR "public"."is_business_owner"("p"."business_id")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."products" "p"
  WHERE (("p"."id" = "product_variants"."product_id") AND ("public"."is_business_member"("p"."business_id", "auth"."uid"()) OR "public"."is_business_owner"("p"."business_id"))))));



CREATE POLICY "product_variants_select_business_members" ON "public"."product_variants" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."products" "p"
  WHERE (("p"."id" = "product_variants"."product_id") AND ("public"."is_business_member"("p"."business_id", "auth"."uid"()) OR "public"."is_business_owner"("p"."business_id"))))));



ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "products_modify_business_owner" ON "public"."products" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "products_select_business_members" ON "public"."products" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_select_own" ON "public"."profiles" FOR SELECT USING (("id" = "auth"."uid"()));



CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "role_permissions_modify_business_owner" ON "public"."role_permissions" USING ((EXISTS ( SELECT 1
   FROM "public"."roles" "r"
  WHERE (("r"."id" = "role_permissions"."role_id") AND "public"."is_business_owner"("r"."business_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."roles" "r"
  WHERE (("r"."id" = "role_permissions"."role_id") AND "public"."is_business_owner"("r"."business_id")))));



CREATE POLICY "role_permissions_select_business_members" ON "public"."role_permissions" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."roles" "r"
  WHERE (("r"."id" = "role_permissions"."role_id") AND ("public"."is_business_member"("r"."business_id", "auth"."uid"()) OR "public"."is_business_owner"("r"."business_id"))))));



ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "roles_modify_business_owner" ON "public"."roles" USING ("public"."is_business_owner"("business_id")) WITH CHECK ("public"."is_business_owner"("business_id"));



CREATE POLICY "roles_select_business_members" ON "public"."roles" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."sale_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sale_items_select_business_members" ON "public"."sale_items" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."sales" "s"
  WHERE (("s"."id" = "sale_items"."sale_id") AND ("public"."is_business_member"("s"."business_id", "auth"."uid"()) OR "public"."is_business_owner"("s"."business_id"))))));



ALTER TABLE "public"."sale_payments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sale_payments_select_business_members" ON "public"."sale_payments" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sales_select_business_members" ON "public"."sales" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."suppliers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "suppliers_modify_business_owner_or_member" ON "public"."suppliers" USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id"))) WITH CHECK (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



CREATE POLICY "suppliers_select_business_members" ON "public"."suppliers" FOR SELECT USING (("public"."is_business_member"("business_id", "auth"."uid"()) OR "public"."is_business_owner"("business_id")));



ALTER TABLE "public"."tax_rule_audit_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tax_rule_review_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tax_rule_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tax_source_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tax_source_registry" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."team_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "team_members_delete_business_owner" ON "public"."team_members" FOR DELETE USING ("public"."is_business_owner"("business_id"));



CREATE POLICY "team_members_insert_business_owner" ON "public"."team_members" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_business_owner"("business_id"));



CREATE POLICY "team_members_select_business_members" ON "public"."team_members" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR "public"."is_business_owner"("business_id") OR "public"."is_business_member"("business_id", "auth"."uid"())));



CREATE POLICY "team_members_update_business_owner" ON "public"."team_members" FOR UPDATE TO "authenticated" USING ("public"."is_business_owner"("business_id")) WITH CHECK ("public"."is_business_owner"("business_id"));





DO $$
BEGIN
    ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































REVOKE ALL ON ALL FUNCTIONS IN SCHEMA "public" FROM "anon", PUBLIC;

REVOKE ALL ON FUNCTION "public"."allocate_sale_line_discounts"("p_lines" "jsonb", "p_subtotal_minor" bigint, "p_discount_minor" bigint) FROM PUBLIC, "anon", "authenticated";
GRANT ALL ON FUNCTION "public"."allocate_sale_line_discounts"("p_lines" "jsonb", "p_subtotal_minor" bigint, "p_discount_minor" bigint) TO "service_role";



REVOKE ALL ON FUNCTION "public"."calculate_sale_discount"("p_subtotal_minor" bigint, "p_discount_type" "text", "p_discount_rate" numeric, "p_flat_minor" bigint) FROM PUBLIC, "anon", "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_sale_discount"("p_subtotal_minor" bigint, "p_discount_type" "text", "p_discount_rate" numeric, "p_flat_minor" bigint) TO "service_role";



REVOKE ALL ON FUNCTION "public"."complete_sale"("payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."complete_sale"("payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."discard_held_sale"("payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."discard_held_sale"("payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "supabase_auth_admin";



REVOKE ALL ON FUNCTION "public"."hold_sale"("payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hold_sale"("payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."is_business_member"("p_business_id" "uuid", "p_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_business_member"("p_business_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_business_member"("p_business_id" "uuid", "p_user_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_business_owner"("p_business_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_business_owner"("p_business_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_business_owner"("p_business_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_held_sales"("p_business_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_held_sales"("p_business_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."require_business_access"("p_business_id" "uuid") FROM PUBLIC, "anon", "authenticated";
GRANT ALL ON FUNCTION "public"."require_business_access"("p_business_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."resolve_sale_lines"("p_business_id" "uuid", "p_items" "jsonb") FROM PUBLIC, "anon", "authenticated";
GRANT ALL ON FUNCTION "public"."resolve_sale_lines"("p_business_id" "uuid", "p_items" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."resume_held_sale"("payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."resume_held_sale"("payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."save_or_publish_product"("payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."save_or_publish_product"("payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."set_balance_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_balance_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_balance_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_brand_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_brand_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_brand_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_business_commerce_profile_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_business_commerce_profile_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_business_commerce_profile_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_business_profile_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_business_profile_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_business_profile_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_category_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_category_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_category_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_collection_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_collection_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_collection_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_customers_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_customers_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_customers_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_integration_connection_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_integration_connection_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_integration_connection_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_integration_sync_checkpoint_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_integration_sync_checkpoint_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_integration_sync_checkpoint_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_inventory_import_job_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_inventory_import_job_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_inventory_import_job_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_locations_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_locations_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_locations_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_membership_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_membership_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_membership_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_onboarding_session_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_onboarding_session_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_onboarding_session_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_permissions_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_permissions_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_permissions_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_product_media_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_product_media_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_product_media_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_product_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_product_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_product_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_roles_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_roles_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_roles_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_sales_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_sales_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_sales_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_suppliers_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_suppliers_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_suppliers_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_tax_rule_review_queue_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_tax_rule_review_queue_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_tax_rule_review_queue_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_tax_rule_versions_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_tax_rule_versions_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_tax_rule_versions_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_tax_source_documents_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_tax_source_documents_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_tax_source_documents_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_tax_source_registry_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_tax_source_registry_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_tax_source_registry_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_team_members_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_team_members_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_team_members_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_variant_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_variant_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_variant_updated_at"() TO "service_role";


















GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."brands" TO "authenticated";
GRANT ALL ON TABLE "public"."brands" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."business_commerce_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."business_commerce_profiles" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."business_profile_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."business_profile_settings" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."businesses" TO "authenticated";
GRANT ALL ON TABLE "public"."businesses" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."collections" TO "authenticated";
GRANT ALL ON TABLE "public"."collections" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."integration_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."integration_connections" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."integration_sync_checkpoints" TO "authenticated";
GRANT ALL ON TABLE "public"."integration_sync_checkpoints" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."inventory_balances" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_balances" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."inventory_import_errors" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_import_errors" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."inventory_import_jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_import_jobs" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."inventory_import_rows" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_import_rows" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."inventory_ledger" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_ledger" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."locations" TO "authenticated";
GRANT ALL ON TABLE "public"."locations" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."memberships" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."onboarding_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."onboarding_sessions" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."product_media" TO "authenticated";
GRANT ALL ON TABLE "public"."product_media" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."product_variants" TO "authenticated";
GRANT ALL ON TABLE "public"."product_variants" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."sale_items" TO "authenticated";
GRANT ALL ON TABLE "public"."sale_items" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."sale_payments" TO "authenticated";
GRANT ALL ON TABLE "public"."sale_payments" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."sales" TO "authenticated";
GRANT ALL ON TABLE "public"."sales" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."suppliers" TO "authenticated";
GRANT ALL ON TABLE "public"."suppliers" TO "service_role";



GRANT ALL ON TABLE "public"."tax_rule_audit_events" TO "service_role";



GRANT ALL ON TABLE "public"."tax_rule_review_queue" TO "service_role";



GRANT ALL ON TABLE "public"."tax_rule_versions" TO "service_role";



GRANT ALL ON TABLE "public"."tax_source_documents" TO "service_role";



GRANT ALL ON TABLE "public"."tax_source_registry" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."team_members" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" REVOKE ALL ON FUNCTIONS FROM PUBLIC;
































drop extension if exists "pg_net";

revoke delete on table "public"."brands" from "anon";

revoke insert on table "public"."brands" from "anon";

revoke references on table "public"."brands" from "anon";

revoke select on table "public"."brands" from "anon";

revoke trigger on table "public"."brands" from "anon";

revoke truncate on table "public"."brands" from "anon";

revoke update on table "public"."brands" from "anon";

revoke references on table "public"."brands" from "authenticated";

revoke trigger on table "public"."brands" from "authenticated";

revoke truncate on table "public"."brands" from "authenticated";

revoke delete on table "public"."business_commerce_profiles" from "anon";

revoke insert on table "public"."business_commerce_profiles" from "anon";

revoke references on table "public"."business_commerce_profiles" from "anon";

revoke select on table "public"."business_commerce_profiles" from "anon";

revoke trigger on table "public"."business_commerce_profiles" from "anon";

revoke truncate on table "public"."business_commerce_profiles" from "anon";

revoke update on table "public"."business_commerce_profiles" from "anon";

revoke references on table "public"."business_commerce_profiles" from "authenticated";

revoke trigger on table "public"."business_commerce_profiles" from "authenticated";

revoke truncate on table "public"."business_commerce_profiles" from "authenticated";

revoke delete on table "public"."business_profile_settings" from "anon";

revoke insert on table "public"."business_profile_settings" from "anon";

revoke references on table "public"."business_profile_settings" from "anon";

revoke select on table "public"."business_profile_settings" from "anon";

revoke trigger on table "public"."business_profile_settings" from "anon";

revoke truncate on table "public"."business_profile_settings" from "anon";

revoke update on table "public"."business_profile_settings" from "anon";

revoke references on table "public"."business_profile_settings" from "authenticated";

revoke trigger on table "public"."business_profile_settings" from "authenticated";

revoke truncate on table "public"."business_profile_settings" from "authenticated";

revoke delete on table "public"."businesses" from "anon";

revoke insert on table "public"."businesses" from "anon";

revoke references on table "public"."businesses" from "anon";

revoke select on table "public"."businesses" from "anon";

revoke trigger on table "public"."businesses" from "anon";

revoke truncate on table "public"."businesses" from "anon";

revoke update on table "public"."businesses" from "anon";

revoke references on table "public"."businesses" from "authenticated";

revoke trigger on table "public"."businesses" from "authenticated";

revoke truncate on table "public"."businesses" from "authenticated";

revoke delete on table "public"."categories" from "anon";

revoke insert on table "public"."categories" from "anon";

revoke references on table "public"."categories" from "anon";

revoke select on table "public"."categories" from "anon";

revoke trigger on table "public"."categories" from "anon";

revoke truncate on table "public"."categories" from "anon";

revoke update on table "public"."categories" from "anon";

revoke references on table "public"."categories" from "authenticated";

revoke trigger on table "public"."categories" from "authenticated";

revoke truncate on table "public"."categories" from "authenticated";

revoke delete on table "public"."collections" from "anon";

revoke insert on table "public"."collections" from "anon";

revoke references on table "public"."collections" from "anon";

revoke select on table "public"."collections" from "anon";

revoke trigger on table "public"."collections" from "anon";

revoke truncate on table "public"."collections" from "anon";

revoke update on table "public"."collections" from "anon";

revoke references on table "public"."collections" from "authenticated";

revoke trigger on table "public"."collections" from "authenticated";

revoke truncate on table "public"."collections" from "authenticated";

revoke delete on table "public"."customers" from "anon";

revoke insert on table "public"."customers" from "anon";

revoke references on table "public"."customers" from "anon";

revoke select on table "public"."customers" from "anon";

revoke trigger on table "public"."customers" from "anon";

revoke truncate on table "public"."customers" from "anon";

revoke update on table "public"."customers" from "anon";

revoke references on table "public"."customers" from "authenticated";

revoke trigger on table "public"."customers" from "authenticated";

revoke truncate on table "public"."customers" from "authenticated";

revoke delete on table "public"."integration_connections" from "anon";

revoke insert on table "public"."integration_connections" from "anon";

revoke references on table "public"."integration_connections" from "anon";

revoke select on table "public"."integration_connections" from "anon";

revoke trigger on table "public"."integration_connections" from "anon";

revoke truncate on table "public"."integration_connections" from "anon";

revoke update on table "public"."integration_connections" from "anon";

revoke references on table "public"."integration_connections" from "authenticated";

revoke trigger on table "public"."integration_connections" from "authenticated";

revoke truncate on table "public"."integration_connections" from "authenticated";

revoke delete on table "public"."integration_sync_checkpoints" from "anon";

revoke insert on table "public"."integration_sync_checkpoints" from "anon";

revoke references on table "public"."integration_sync_checkpoints" from "anon";

revoke select on table "public"."integration_sync_checkpoints" from "anon";

revoke trigger on table "public"."integration_sync_checkpoints" from "anon";

revoke truncate on table "public"."integration_sync_checkpoints" from "anon";

revoke update on table "public"."integration_sync_checkpoints" from "anon";

revoke references on table "public"."integration_sync_checkpoints" from "authenticated";

revoke trigger on table "public"."integration_sync_checkpoints" from "authenticated";

revoke truncate on table "public"."integration_sync_checkpoints" from "authenticated";

revoke delete on table "public"."inventory_balances" from "anon";

revoke insert on table "public"."inventory_balances" from "anon";

revoke references on table "public"."inventory_balances" from "anon";

revoke select on table "public"."inventory_balances" from "anon";

revoke trigger on table "public"."inventory_balances" from "anon";

revoke truncate on table "public"."inventory_balances" from "anon";

revoke update on table "public"."inventory_balances" from "anon";

revoke references on table "public"."inventory_balances" from "authenticated";

revoke trigger on table "public"."inventory_balances" from "authenticated";

revoke truncate on table "public"."inventory_balances" from "authenticated";

revoke delete on table "public"."inventory_import_errors" from "anon";

revoke insert on table "public"."inventory_import_errors" from "anon";

revoke references on table "public"."inventory_import_errors" from "anon";

revoke select on table "public"."inventory_import_errors" from "anon";

revoke trigger on table "public"."inventory_import_errors" from "anon";

revoke truncate on table "public"."inventory_import_errors" from "anon";

revoke update on table "public"."inventory_import_errors" from "anon";

revoke references on table "public"."inventory_import_errors" from "authenticated";

revoke trigger on table "public"."inventory_import_errors" from "authenticated";

revoke truncate on table "public"."inventory_import_errors" from "authenticated";

revoke delete on table "public"."inventory_import_jobs" from "anon";

revoke insert on table "public"."inventory_import_jobs" from "anon";

revoke references on table "public"."inventory_import_jobs" from "anon";

revoke select on table "public"."inventory_import_jobs" from "anon";

revoke trigger on table "public"."inventory_import_jobs" from "anon";

revoke truncate on table "public"."inventory_import_jobs" from "anon";

revoke update on table "public"."inventory_import_jobs" from "anon";

revoke references on table "public"."inventory_import_jobs" from "authenticated";

revoke trigger on table "public"."inventory_import_jobs" from "authenticated";

revoke truncate on table "public"."inventory_import_jobs" from "authenticated";

revoke delete on table "public"."inventory_import_rows" from "anon";

revoke insert on table "public"."inventory_import_rows" from "anon";

revoke references on table "public"."inventory_import_rows" from "anon";

revoke select on table "public"."inventory_import_rows" from "anon";

revoke trigger on table "public"."inventory_import_rows" from "anon";

revoke truncate on table "public"."inventory_import_rows" from "anon";

revoke update on table "public"."inventory_import_rows" from "anon";

revoke references on table "public"."inventory_import_rows" from "authenticated";

revoke trigger on table "public"."inventory_import_rows" from "authenticated";

revoke truncate on table "public"."inventory_import_rows" from "authenticated";

revoke delete on table "public"."inventory_ledger" from "anon";

revoke insert on table "public"."inventory_ledger" from "anon";

revoke references on table "public"."inventory_ledger" from "anon";

revoke select on table "public"."inventory_ledger" from "anon";

revoke trigger on table "public"."inventory_ledger" from "anon";

revoke truncate on table "public"."inventory_ledger" from "anon";

revoke update on table "public"."inventory_ledger" from "anon";

revoke references on table "public"."inventory_ledger" from "authenticated";

revoke trigger on table "public"."inventory_ledger" from "authenticated";

revoke truncate on table "public"."inventory_ledger" from "authenticated";

revoke delete on table "public"."locations" from "anon";

revoke insert on table "public"."locations" from "anon";

revoke references on table "public"."locations" from "anon";

revoke select on table "public"."locations" from "anon";

revoke trigger on table "public"."locations" from "anon";

revoke truncate on table "public"."locations" from "anon";

revoke update on table "public"."locations" from "anon";

revoke references on table "public"."locations" from "authenticated";

revoke trigger on table "public"."locations" from "authenticated";

revoke truncate on table "public"."locations" from "authenticated";

revoke delete on table "public"."memberships" from "anon";

revoke insert on table "public"."memberships" from "anon";

revoke references on table "public"."memberships" from "anon";

revoke select on table "public"."memberships" from "anon";

revoke trigger on table "public"."memberships" from "anon";

revoke truncate on table "public"."memberships" from "anon";

revoke update on table "public"."memberships" from "anon";

revoke references on table "public"."memberships" from "authenticated";

revoke trigger on table "public"."memberships" from "authenticated";

revoke truncate on table "public"."memberships" from "authenticated";

revoke delete on table "public"."onboarding_sessions" from "anon";

revoke insert on table "public"."onboarding_sessions" from "anon";

revoke references on table "public"."onboarding_sessions" from "anon";

revoke select on table "public"."onboarding_sessions" from "anon";

revoke trigger on table "public"."onboarding_sessions" from "anon";

revoke truncate on table "public"."onboarding_sessions" from "anon";

revoke update on table "public"."onboarding_sessions" from "anon";

revoke references on table "public"."onboarding_sessions" from "authenticated";

revoke trigger on table "public"."onboarding_sessions" from "authenticated";

revoke truncate on table "public"."onboarding_sessions" from "authenticated";

revoke delete on table "public"."permissions" from "anon";

revoke insert on table "public"."permissions" from "anon";

revoke references on table "public"."permissions" from "anon";

revoke select on table "public"."permissions" from "anon";

revoke trigger on table "public"."permissions" from "anon";

revoke truncate on table "public"."permissions" from "anon";

revoke update on table "public"."permissions" from "anon";

revoke delete on table "public"."permissions" from "authenticated";

revoke insert on table "public"."permissions" from "authenticated";

revoke references on table "public"."permissions" from "authenticated";

revoke trigger on table "public"."permissions" from "authenticated";

revoke truncate on table "public"."permissions" from "authenticated";

revoke update on table "public"."permissions" from "authenticated";

revoke delete on table "public"."product_media" from "anon";

revoke insert on table "public"."product_media" from "anon";

revoke references on table "public"."product_media" from "anon";

revoke select on table "public"."product_media" from "anon";

revoke trigger on table "public"."product_media" from "anon";

revoke truncate on table "public"."product_media" from "anon";

revoke update on table "public"."product_media" from "anon";

revoke references on table "public"."product_media" from "authenticated";

revoke trigger on table "public"."product_media" from "authenticated";

revoke truncate on table "public"."product_media" from "authenticated";

revoke delete on table "public"."product_variants" from "anon";

revoke insert on table "public"."product_variants" from "anon";

revoke references on table "public"."product_variants" from "anon";

revoke select on table "public"."product_variants" from "anon";

revoke trigger on table "public"."product_variants" from "anon";

revoke truncate on table "public"."product_variants" from "anon";

revoke update on table "public"."product_variants" from "anon";

revoke references on table "public"."product_variants" from "authenticated";

revoke trigger on table "public"."product_variants" from "authenticated";

revoke truncate on table "public"."product_variants" from "authenticated";

revoke delete on table "public"."products" from "anon";

revoke insert on table "public"."products" from "anon";

revoke references on table "public"."products" from "anon";

revoke select on table "public"."products" from "anon";

revoke trigger on table "public"."products" from "anon";

revoke truncate on table "public"."products" from "anon";

revoke update on table "public"."products" from "anon";

revoke references on table "public"."products" from "authenticated";

revoke trigger on table "public"."products" from "authenticated";

revoke truncate on table "public"."products" from "authenticated";

revoke delete on table "public"."profiles" from "anon";

revoke insert on table "public"."profiles" from "anon";

revoke references on table "public"."profiles" from "anon";

revoke select on table "public"."profiles" from "anon";

revoke trigger on table "public"."profiles" from "anon";

revoke truncate on table "public"."profiles" from "anon";

revoke update on table "public"."profiles" from "anon";

revoke references on table "public"."profiles" from "authenticated";

revoke trigger on table "public"."profiles" from "authenticated";

revoke truncate on table "public"."profiles" from "authenticated";

revoke delete on table "public"."role_permissions" from "anon";

revoke insert on table "public"."role_permissions" from "anon";

revoke references on table "public"."role_permissions" from "anon";

revoke select on table "public"."role_permissions" from "anon";

revoke trigger on table "public"."role_permissions" from "anon";

revoke truncate on table "public"."role_permissions" from "anon";

revoke update on table "public"."role_permissions" from "anon";

revoke references on table "public"."role_permissions" from "authenticated";

revoke trigger on table "public"."role_permissions" from "authenticated";

revoke truncate on table "public"."role_permissions" from "authenticated";

revoke delete on table "public"."roles" from "anon";

revoke insert on table "public"."roles" from "anon";

revoke references on table "public"."roles" from "anon";

revoke select on table "public"."roles" from "anon";

revoke trigger on table "public"."roles" from "anon";

revoke truncate on table "public"."roles" from "anon";

revoke update on table "public"."roles" from "anon";

revoke references on table "public"."roles" from "authenticated";

revoke trigger on table "public"."roles" from "authenticated";

revoke truncate on table "public"."roles" from "authenticated";

revoke delete on table "public"."sale_items" from "anon";

revoke insert on table "public"."sale_items" from "anon";

revoke references on table "public"."sale_items" from "anon";

revoke select on table "public"."sale_items" from "anon";

revoke trigger on table "public"."sale_items" from "anon";

revoke truncate on table "public"."sale_items" from "anon";

revoke update on table "public"."sale_items" from "anon";

revoke delete on table "public"."sale_items" from "authenticated";

revoke insert on table "public"."sale_items" from "authenticated";

revoke references on table "public"."sale_items" from "authenticated";

revoke trigger on table "public"."sale_items" from "authenticated";

revoke truncate on table "public"."sale_items" from "authenticated";

revoke update on table "public"."sale_items" from "authenticated";

revoke delete on table "public"."sale_payments" from "anon";

revoke insert on table "public"."sale_payments" from "anon";

revoke references on table "public"."sale_payments" from "anon";

revoke select on table "public"."sale_payments" from "anon";

revoke trigger on table "public"."sale_payments" from "anon";

revoke truncate on table "public"."sale_payments" from "anon";

revoke update on table "public"."sale_payments" from "anon";

revoke delete on table "public"."sale_payments" from "authenticated";

revoke insert on table "public"."sale_payments" from "authenticated";

revoke references on table "public"."sale_payments" from "authenticated";

revoke trigger on table "public"."sale_payments" from "authenticated";

revoke truncate on table "public"."sale_payments" from "authenticated";

revoke update on table "public"."sale_payments" from "authenticated";

revoke delete on table "public"."sales" from "anon";

revoke insert on table "public"."sales" from "anon";

revoke references on table "public"."sales" from "anon";

revoke select on table "public"."sales" from "anon";

revoke trigger on table "public"."sales" from "anon";

revoke truncate on table "public"."sales" from "anon";

revoke update on table "public"."sales" from "anon";

revoke delete on table "public"."sales" from "authenticated";

revoke insert on table "public"."sales" from "authenticated";

revoke references on table "public"."sales" from "authenticated";

revoke trigger on table "public"."sales" from "authenticated";

revoke truncate on table "public"."sales" from "authenticated";

revoke update on table "public"."sales" from "authenticated";

revoke delete on table "public"."suppliers" from "anon";

revoke insert on table "public"."suppliers" from "anon";

revoke references on table "public"."suppliers" from "anon";

revoke select on table "public"."suppliers" from "anon";

revoke trigger on table "public"."suppliers" from "anon";

revoke truncate on table "public"."suppliers" from "anon";

revoke update on table "public"."suppliers" from "anon";

revoke references on table "public"."suppliers" from "authenticated";

revoke trigger on table "public"."suppliers" from "authenticated";

revoke truncate on table "public"."suppliers" from "authenticated";

revoke delete on table "public"."tax_rule_audit_events" from "anon";

revoke insert on table "public"."tax_rule_audit_events" from "anon";

revoke references on table "public"."tax_rule_audit_events" from "anon";

revoke select on table "public"."tax_rule_audit_events" from "anon";

revoke trigger on table "public"."tax_rule_audit_events" from "anon";

revoke truncate on table "public"."tax_rule_audit_events" from "anon";

revoke update on table "public"."tax_rule_audit_events" from "anon";

revoke delete on table "public"."tax_rule_audit_events" from "authenticated";

revoke insert on table "public"."tax_rule_audit_events" from "authenticated";

revoke references on table "public"."tax_rule_audit_events" from "authenticated";

revoke select on table "public"."tax_rule_audit_events" from "authenticated";

revoke trigger on table "public"."tax_rule_audit_events" from "authenticated";

revoke truncate on table "public"."tax_rule_audit_events" from "authenticated";

revoke update on table "public"."tax_rule_audit_events" from "authenticated";

revoke delete on table "public"."tax_rule_review_queue" from "anon";

revoke insert on table "public"."tax_rule_review_queue" from "anon";

revoke references on table "public"."tax_rule_review_queue" from "anon";

revoke select on table "public"."tax_rule_review_queue" from "anon";

revoke trigger on table "public"."tax_rule_review_queue" from "anon";

revoke truncate on table "public"."tax_rule_review_queue" from "anon";

revoke update on table "public"."tax_rule_review_queue" from "anon";

revoke delete on table "public"."tax_rule_review_queue" from "authenticated";

revoke insert on table "public"."tax_rule_review_queue" from "authenticated";

revoke references on table "public"."tax_rule_review_queue" from "authenticated";

revoke select on table "public"."tax_rule_review_queue" from "authenticated";

revoke trigger on table "public"."tax_rule_review_queue" from "authenticated";

revoke truncate on table "public"."tax_rule_review_queue" from "authenticated";

revoke update on table "public"."tax_rule_review_queue" from "authenticated";

revoke delete on table "public"."tax_rule_versions" from "anon";

revoke insert on table "public"."tax_rule_versions" from "anon";

revoke references on table "public"."tax_rule_versions" from "anon";

revoke select on table "public"."tax_rule_versions" from "anon";

revoke trigger on table "public"."tax_rule_versions" from "anon";

revoke truncate on table "public"."tax_rule_versions" from "anon";

revoke update on table "public"."tax_rule_versions" from "anon";

revoke delete on table "public"."tax_rule_versions" from "authenticated";

revoke insert on table "public"."tax_rule_versions" from "authenticated";

revoke references on table "public"."tax_rule_versions" from "authenticated";

revoke select on table "public"."tax_rule_versions" from "authenticated";

revoke trigger on table "public"."tax_rule_versions" from "authenticated";

revoke truncate on table "public"."tax_rule_versions" from "authenticated";

revoke update on table "public"."tax_rule_versions" from "authenticated";

revoke delete on table "public"."tax_source_documents" from "anon";

revoke insert on table "public"."tax_source_documents" from "anon";

revoke references on table "public"."tax_source_documents" from "anon";

revoke select on table "public"."tax_source_documents" from "anon";

revoke trigger on table "public"."tax_source_documents" from "anon";

revoke truncate on table "public"."tax_source_documents" from "anon";

revoke update on table "public"."tax_source_documents" from "anon";

revoke delete on table "public"."tax_source_documents" from "authenticated";

revoke insert on table "public"."tax_source_documents" from "authenticated";

revoke references on table "public"."tax_source_documents" from "authenticated";

revoke select on table "public"."tax_source_documents" from "authenticated";

revoke trigger on table "public"."tax_source_documents" from "authenticated";

revoke truncate on table "public"."tax_source_documents" from "authenticated";

revoke update on table "public"."tax_source_documents" from "authenticated";

revoke delete on table "public"."tax_source_registry" from "anon";

revoke insert on table "public"."tax_source_registry" from "anon";

revoke references on table "public"."tax_source_registry" from "anon";

revoke select on table "public"."tax_source_registry" from "anon";

revoke trigger on table "public"."tax_source_registry" from "anon";

revoke truncate on table "public"."tax_source_registry" from "anon";

revoke update on table "public"."tax_source_registry" from "anon";

revoke delete on table "public"."tax_source_registry" from "authenticated";

revoke insert on table "public"."tax_source_registry" from "authenticated";

revoke references on table "public"."tax_source_registry" from "authenticated";

revoke select on table "public"."tax_source_registry" from "authenticated";

revoke trigger on table "public"."tax_source_registry" from "authenticated";

revoke truncate on table "public"."tax_source_registry" from "authenticated";

revoke update on table "public"."tax_source_registry" from "authenticated";

revoke delete on table "public"."team_members" from "anon";

revoke insert on table "public"."team_members" from "anon";

revoke references on table "public"."team_members" from "anon";

revoke select on table "public"."team_members" from "anon";

revoke trigger on table "public"."team_members" from "anon";

revoke truncate on table "public"."team_members" from "anon";

revoke update on table "public"."team_members" from "anon";

revoke references on table "public"."team_members" from "authenticated";

revoke trigger on table "public"."team_members" from "authenticated";

revoke truncate on table "public"."team_members" from "authenticated";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ThreadStock product-media Storage Bucket Bootstrap
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-media',
    'product-media',
    true,
    10485760,
    array['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 10485760,
    allowed_mime_types = array['image/png', 'image/jpeg', 'image/webp'];

  create policy "product_media_storage_delete"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'product-media'::text) AND (auth.role() = 'authenticated'::text) AND (public.is_business_member(((storage.foldername(name))[1])::uuid, auth.uid()) OR public.is_business_owner(((storage.foldername(name))[1])::uuid))));



  create policy "product_media_storage_insert"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'product-media'::text) AND (auth.role() = 'authenticated'::text) AND (public.is_business_member(((storage.foldername(name))[1])::uuid, auth.uid()) OR public.is_business_owner(((storage.foldername(name))[1])::uuid))));



  create policy "product_media_storage_select"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'product-media'::text));



  create policy "product_media_storage_update"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'product-media'::text) AND (auth.role() = 'authenticated'::text) AND (public.is_business_member(((storage.foldername(name))[1])::uuid, auth.uid()) OR public.is_business_owner(((storage.foldername(name))[1])::uuid))))
with check (((bucket_id = 'product-media'::text) AND (auth.role() = 'authenticated'::text) AND (public.is_business_member(((storage.foldername(name))[1])::uuid, auth.uid()) OR public.is_business_owner(((storage.foldername(name))[1])::uuid))));



