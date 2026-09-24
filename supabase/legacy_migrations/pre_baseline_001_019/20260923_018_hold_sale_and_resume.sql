-- Migration: 20260923_018_hold_sale_and_resume.sql
-- Adds held-sale columns (if an earlier sales migration omitted them) and the
-- atomic hold / list / resume / discard RPCs.
-- Holding a sale persists the cart on public.sales (status = 'held').
-- It does not reserve or decrement inventory_balances or inventory_ledger.
-- Completing a held sale reuses public.complete_sale(payload.sale_id), which
-- transitions that same row from held to completed and then decrements stock.
-- Discard sets status = 'cancelled' and does not change inventory.

alter table public.sales
    add column if not exists held_at timestamptz;

alter table public.sales
    add column if not exists held_by uuid references public.profiles (id) on delete set null;

create index if not exists idx_sales_business_status_held_at
    on public.sales (business_id, held_at desc nulls last)
    where status = 'held';

create or replace function public.hold_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_customer_id uuid := nullif(payload->>'customer_id', '')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_subtotal_minor bigint := coalesce((payload->>'subtotal_minor')::bigint, 0);
    v_discount_minor bigint := coalesce((payload->>'discount_minor')::bigint, 0);
    v_tax_minor bigint := coalesce((payload->>'tax_minor')::bigint, 0);
    v_total_minor bigint := coalesce((payload->>'total_minor')::bigint, 0);
    v_currency_code text := coalesce(nullif(trim(payload->>'currency_code'), ''), 'INR');
    v_discount_type text := coalesce(nullif(payload->>'discount_type', ''), 'none');
    v_discount_rate numeric := coalesce((payload->>'discount_rate')::numeric, 0);
    v_note text := nullif(trim(payload->>'note'), '');
    v_items jsonb := coalesce(payload->'items', '[]'::jsonb);

    v_existing_sale record;
    v_sale_number text;
    v_seq integer;
    v_item jsonb;
    v_item_prod_id uuid;
    v_item_var_id uuid;
    v_item_qty integer;
    v_item_price bigint;
    v_item_cost bigint;
    v_item_disc bigint;
    v_item_taxable bigint;
    v_item_tax bigint;
    v_item_line_total bigint;
    v_item_sku text;
    v_item_name text;
    v_item_variant_title text;
    v_item_tax_cat text;
    v_held_at timestamptz := now();
begin
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    if auth.uid() is not null then
        if not (
            public.is_business_member(v_business_id, auth.uid())
            or public.is_business_owner(v_business_id)
        ) then
            raise exception 'Not authorized for this business';
        end if;
    end if;

    if v_discount_type not in ('percentage', 'flat', 'none') then
        raise exception 'Invalid discount type';
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
        raise exception 'Location does not belong to this business';
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
        raise exception 'Customer does not belong to this business';
    end if;

    if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) = 0 then
        raise exception 'Cart is empty. Add at least one item to hold a sale.';
    end if;

    for v_item in select * from jsonb_array_elements(v_items) loop
        v_item_prod_id := nullif(v_item->>'product_id', '')::uuid;
        v_item_var_id := nullif(v_item->>'variant_id', '')::uuid;
        v_item_qty := coalesce((v_item->>'quantity')::integer, 0);
        v_item_name := coalesce(v_item->>'product_name_snapshot', 'Product');

        if v_item_qty <= 0 then
            raise exception 'Quantity for % must be greater than 0.', v_item_name;
        end if;

        if v_item_var_id is null and v_item_prod_id is not null then
            select id into v_item_var_id
            from public.product_variants
            where product_id = v_item_prod_id
              and status = 'active'
            order by created_at asc
            limit 1;
        end if;

        if v_item_var_id is null then
            raise exception 'Variant not found for %', v_item_name;
        end if;

        if not exists (
            select 1
            from public.product_variants pv
            join public.products p on p.id = pv.product_id
            where pv.id = v_item_var_id
              and p.business_id = v_business_id
              and (v_item_prod_id is null or pv.product_id = v_item_prod_id)
        ) then
            raise exception 'Product variant is not available for this business';
        end if;
    end loop;

    if v_sale_id is not null then
        select * into v_existing_sale
        from public.sales
        where id = v_sale_id
        for update;

        if not found or v_existing_sale.business_id is distinct from v_business_id then
            raise exception 'Held sale not found';
        end if;
        if v_existing_sale.status <> 'held' then
            raise exception 'This sale is no longer held';
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
        where id = v_sale_id;

        delete from public.sale_items where sale_id = v_sale_id;
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

    for v_item in select * from jsonb_array_elements(v_items) loop
        v_item_prod_id := nullif(v_item->>'product_id', '')::uuid;
        v_item_var_id := nullif(v_item->>'variant_id', '')::uuid;
        v_item_qty := (v_item->>'quantity')::integer;
        v_item_price := coalesce((v_item->>'unit_price_minor')::bigint, 0);
        v_item_cost := coalesce((v_item->>'unit_cost_minor')::bigint, 0);
        v_item_disc := coalesce((v_item->>'discount_minor')::bigint, 0);
        v_item_taxable := coalesce((v_item->>'taxable_amount_minor')::bigint, v_item_price * v_item_qty - v_item_disc);
        v_item_tax := coalesce((v_item->>'tax_minor')::bigint, 0);
        v_item_line_total := coalesce((v_item->>'line_total_minor')::bigint, v_item_taxable + v_item_tax);
        v_item_sku := coalesce(v_item->>'sku_snapshot', 'SKU-UNKNOWN');
        v_item_name := coalesce(v_item->>'product_name_snapshot', 'Product');
        v_item_variant_title := v_item->>'variant_title_snapshot';
        v_item_tax_cat := v_item->>'tax_category_snapshot';

        if v_item_var_id is null and v_item_prod_id is not null then
            select id, sku into v_item_var_id, v_item_sku
            from public.product_variants
            where product_id = v_item_prod_id
              and status = 'active'
            order by created_at asc
            limit 1;
        end if;

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
            v_item_prod_id,
            v_item_var_id,
            v_item_sku,
            v_item_name,
            v_item_variant_title,
            v_item_qty,
            v_item_price,
            v_item_cost,
            v_item_disc,
            v_item_taxable,
            v_item_tax,
            v_item_line_total,
            v_item_tax_cat
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
set search_path = public
as $$
declare
    v_sale record;
    v_items jsonb;
    v_result jsonb := '[]'::jsonb;
begin
    if p_business_id is null then
        raise exception 'business_id is required';
    end if;

    if auth.uid() is not null then
        if not (
            public.is_business_member(p_business_id, auth.uid())
            or public.is_business_owner(p_business_id)
        ) then
            raise exception 'Not authorized for this business';
        end if;
    end if;

    for v_sale in
        select
            s.*,
            c.name as customer_name,
            c.phone as customer_phone,
            l.name as location_name,
            pr.full_name as held_by_name
        from public.sales s
        left join public.customers c on c.id = s.customer_id
        left join public.locations l on l.id = s.location_id
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
                    'product_id', si.product_id,
                    'variant_id', si.variant_id,
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
                'location_id', v_sale.location_id,
                'location_name', v_sale.location_name,
                'sale_number', v_sale.sale_number,
                'customer_id', v_sale.customer_id,
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
set search_path = public
as $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_sale record;
    v_item record;
    v_items jsonb := '[]'::jsonb;
    v_warnings jsonb := '[]'::jsonb;
    v_available integer;
begin
    if v_business_id is null or v_sale_id is null then
        raise exception 'business_id and sale_id are required';
    end if;

    if auth.uid() is not null then
        if not (
            public.is_business_member(v_business_id, auth.uid())
            or public.is_business_owner(v_business_id)
        ) then
            raise exception 'Not authorized for this business';
        end if;
    end if;

    select
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        l.name as location_name,
        pr.full_name as held_by_name
    into v_sale
    from public.sales s
    left join public.customers c on c.id = s.customer_id
    left join public.locations l on l.id = s.location_id
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
        v_available := null;
        if v_item.variant_id is not null then
            select available_qty into v_available
            from public.inventory_balances
            where business_id = v_business_id
              and location_id = v_sale.location_id
              and variant_id = v_item.variant_id;
        end if;

        v_available := coalesce(v_available, 0);

        v_items := v_items || jsonb_build_array(
            jsonb_build_object(
                'id', v_item.id,
                'sale_id', v_item.sale_id,
                'product_id', v_item.product_id,
                'variant_id', v_item.variant_id,
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

        if v_item.quantity > v_available then
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
            'location_id', v_sale.location_id,
            'location_name', v_sale.location_name,
            'sale_number', v_sale.sale_number,
            'customer_id', v_sale.customer_id,
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
set search_path = public
as $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_sale record;
begin
    if v_business_id is null or v_sale_id is null then
        raise exception 'business_id and sale_id are required';
    end if;

    if auth.uid() is not null then
        if not (
            public.is_business_member(v_business_id, auth.uid())
            or public.is_business_owner(v_business_id)
        ) then
            raise exception 'Not authorized for this business';
        end if;
    end if;

    select * into v_sale
    from public.sales
    where id = v_sale_id
    for update;

    if not found or v_sale.business_id is distinct from v_business_id or v_sale.status <> 'held' then
        raise exception 'Held sale not found';
    end if;

    update public.sales
    set status = 'cancelled',
        completed_at = null
    where id = v_sale_id;

    return jsonb_build_object(
        'success', true,
        'sale_id', v_sale_id,
        'sale_number', v_sale.sale_number,
        'status', 'cancelled'
    );
end;
$$;

revoke all on function public.hold_sale(jsonb) from public;
revoke all on function public.list_held_sales(uuid) from public;
revoke all on function public.resume_held_sale(jsonb) from public;
revoke all on function public.discard_held_sale(jsonb) from public;

grant execute on function public.hold_sale(jsonb) to authenticated;
grant execute on function public.list_held_sales(uuid) to authenticated;
grant execute on function public.resume_held_sale(jsonb) to authenticated;
grant execute on function public.discard_held_sale(jsonb) to authenticated;

notify pgrst, 'reload schema';
