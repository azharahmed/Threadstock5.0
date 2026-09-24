-- Migration: 20260922_017_create_sales_backend_and_complete_sale_rpc.sql
-- Description: Creates customers, sales, sale_items, sale_payments tables with
-- strict RLS, indexes, triggers, and the atomic complete_sale RPC function
-- with inventory validation, row locking, and inventory ledger integration.

create extension if not exists pgcrypto;

-- 1. Customers Table
create table if not exists public.customers (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    email text,
    phone text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_customers_business_id
    on public.customers (business_id);

create or replace function public.set_customers_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_customers_set_updated_at on public.customers;
create trigger trg_customers_set_updated_at
before update on public.customers
for each row
execute function public.set_customers_updated_at();

alter table public.customers enable row level security;

drop policy if exists "customers_select_business_members" on public.customers;
create policy "customers_select_business_members"
    on public.customers
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "customers_modify_business_owner_or_member" on public.customers;
create policy "customers_modify_business_owner_or_member"
    on public.customers
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

grant select, insert, update, delete on public.customers to authenticated;

-- 2. Sales Table
create table if not exists public.sales (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    location_id uuid not null references public.locations (id) on delete restrict,
    sale_number text not null,
    customer_id uuid references public.customers (id) on delete set null,
    status text not null default 'completed' check (status in ('completed', 'held', 'cancelled', 'refunded', 'partially_refunded')),
    subtotal_minor bigint not null check (subtotal_minor >= 0),
    discount_minor bigint not null default 0 check (discount_minor >= 0),
    tax_minor bigint not null default 0 check (tax_minor >= 0),
    total_minor bigint not null check (total_minor >= 0),
    currency_code text not null default 'INR',
    discount_type text check (discount_type in ('percentage', 'flat', 'none')),
    discount_rate numeric(10,4) default 0,
    note text,
    idempotency_key text,
    created_by uuid references auth.users (id) on delete set null,
    held_at timestamptz,
    held_by uuid references public.profiles (id) on delete set null,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, sale_number)
);

create index if not exists idx_sales_business_id_created_at
    on public.sales (business_id, created_at desc);

create index if not exists idx_sales_location_id
    on public.sales (location_id);

create index if not exists idx_sales_customer_id
    on public.sales (customer_id);

create unique index if not exists idx_sales_business_idempotency
    on public.sales (business_id, idempotency_key)
    where idempotency_key is not null;

create or replace function public.set_sales_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_sales_set_updated_at on public.sales;
create trigger trg_sales_set_updated_at
before update on public.sales
for each row
execute function public.set_sales_updated_at();

alter table public.sales enable row level security;

drop policy if exists "sales_select_business_members" on public.sales;
create policy "sales_select_business_members"
    on public.sales
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "sales_modify_business_owner_or_member" on public.sales;
create policy "sales_modify_business_owner_or_member"
    on public.sales
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

grant select, insert, update, delete on public.sales to authenticated;

-- 3. Sale Items Table
create table if not exists public.sale_items (
    id uuid primary key default gen_random_uuid(),
    sale_id uuid not null references public.sales (id) on delete cascade,
    product_id uuid references public.products (id) on delete set null,
    variant_id uuid references public.product_variants (id) on delete set null,
    sku_snapshot text not null,
    product_name_snapshot text not null,
    variant_title_snapshot text,
    quantity integer not null check (quantity > 0),
    unit_price_minor bigint not null check (unit_price_minor >= 0),
    unit_cost_minor bigint not null default 0 check (unit_cost_minor >= 0),
    discount_minor bigint not null default 0 check (discount_minor >= 0),
    taxable_amount_minor bigint not null check (taxable_amount_minor >= 0),
    tax_minor bigint not null default 0 check (tax_minor >= 0),
    line_total_minor bigint not null check (line_total_minor >= 0),
    tax_category_snapshot text,
    created_at timestamptz not null default now()
);

create index if not exists idx_sale_items_sale_id
    on public.sale_items (sale_id);

create index if not exists idx_sale_items_variant_id
    on public.sale_items (variant_id);

alter table public.sale_items enable row level security;

drop policy if exists "sale_items_select_business_members" on public.sale_items;
create policy "sale_items_select_business_members"
    on public.sale_items
    for select
    using (
        exists (
            select 1 from public.sales s
            where s.id = sale_items.sale_id
              and (
                  public.is_business_member(s.business_id, auth.uid())
                  or public.is_business_owner(s.business_id)
              )
        )
    );

drop policy if exists "sale_items_modify_business_owner_or_member" on public.sale_items;
create policy "sale_items_modify_business_owner_or_member"
    on public.sale_items
    for all
    using (
        exists (
            select 1 from public.sales s
            where s.id = sale_items.sale_id
              and (
                  public.is_business_member(s.business_id, auth.uid())
                  or public.is_business_owner(s.business_id)
              )
        )
    )
    with check (
        exists (
            select 1 from public.sales s
            where s.id = sale_items.sale_id
              and (
                  public.is_business_member(s.business_id, auth.uid())
                  or public.is_business_owner(s.business_id)
              )
        )
    );

grant select, insert, update, delete on public.sale_items to authenticated;

-- 4. Sale Payments Table
create table if not exists public.sale_payments (
    id uuid primary key default gen_random_uuid(),
    sale_id uuid not null references public.sales (id) on delete cascade,
    business_id uuid not null references public.businesses (id) on delete cascade,
    payment_method text not null check (payment_method in ('cash', 'card', 'upi', 'bank_transfer', 'split', 'other')),
    amount_minor bigint not null check (amount_minor > 0),
    currency_code text not null default 'INR',
    status text not null default 'completed' check (status in ('completed', 'pending', 'failed', 'refunded')),
    processing_type text not null default 'recorded' check (processing_type in ('recorded', 'electronic')),
    reference_number text,
    notes text,
    created_at timestamptz not null default now()
);

create index if not exists idx_sale_payments_sale_id
    on public.sale_payments (sale_id);

create index if not exists idx_sale_payments_business_id
    on public.sale_payments (business_id);

alter table public.sale_payments enable row level security;

drop policy if exists "sale_payments_select_business_members" on public.sale_payments;
create policy "sale_payments_select_business_members"
    on public.sale_payments
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "sale_payments_modify_business_owner_or_member" on public.sale_payments;
create policy "sale_payments_modify_business_owner_or_member"
    on public.sale_payments
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

grant select, insert, update, delete on public.sale_payments to authenticated;

-- 5. Atomic complete_sale RPC Function
create or replace function public.complete_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_customer_id uuid := nullif(payload->>'customer_id', '')::uuid;
    v_subtotal_minor bigint := coalesce((payload->>'subtotal_minor')::bigint, 0);
    v_discount_minor bigint := coalesce((payload->>'discount_minor')::bigint, 0);
    v_tax_minor bigint := coalesce((payload->>'tax_minor')::bigint, 0);
    v_total_minor bigint := coalesce((payload->>'total_minor')::bigint, 0);
    v_currency_code text := coalesce(nullif(trim(payload->>'currency_code'), ''), 'INR');
    v_discount_type text := coalesce(payload->>'discount_type', 'none');
    v_discount_rate numeric := coalesce((payload->>'discount_rate')::numeric, 0);
    v_note text := payload->>'note';
    v_idempotency_key text := nullif(trim(payload->>'idempotency_key'), '');
    v_requested_sale_id uuid := nullif(payload->>'sale_id', '')::uuid;
    v_items jsonb := coalesce(payload->'items', '[]'::jsonb);
    v_payments jsonb := coalesce(payload->'payments', '[]'::jsonb);

    v_existing_sale record;
    v_sale_id uuid;
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

    v_current_available integer;
    v_total_payments bigint := 0;
    v_payment jsonb;
    v_pay_method text;
    v_pay_amount bigint;
    v_pay_proc text;
    v_pay_ref text;
    v_pay_notes text;
begin
    -- 1. Validate business_id
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    -- 2. Authorization check (if called by authenticated user)
    if auth.uid() is not null then
        if not (public.is_business_member(v_business_id, auth.uid()) or public.is_business_owner(v_business_id)) then
            raise exception 'Not authorized for this business';
        end if;
    end if;

    -- 3. Idempotency check: if key already exists, return previous sale without re-executing
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

    -- 4. Location resolution: if not supplied, pick the primary or first active location
    if v_location_id is null then
        select id into v_location_id
        from public.locations
        where business_id = v_business_id
        order by created_at asc
        limit 1;
    else
        if not exists (
            select 1
            from public.locations
            where id = v_location_id
              and business_id = v_business_id
        ) then
            raise exception 'Location does not belong to this business';
        end if;
    end if;

    if v_location_id is null then
        raise exception 'No valid location found for this business. Configure a location before making sales.';
    end if;

    -- 5. Validate items count
    if jsonb_array_length(v_items) = 0 then
        raise exception 'Cart is empty. Add at least one item to complete a sale.';
    end if;

    -- 6. Validate payments
    if jsonb_array_length(v_payments) = 0 then
        raise exception 'No payment method selected. Please choose a payment method.';
    end if;

    for v_payment in select * from jsonb_array_elements(v_payments) loop
        v_pay_amount := coalesce((v_payment->>'amount_minor')::bigint, 0);
        if v_pay_amount <= 0 then
            raise exception 'Payment amount must be greater than zero.';
        end if;
        v_total_payments := v_total_payments + v_pay_amount;
    end loop;

    if v_total_payments < v_total_minor then
        raise exception 'Total payments (%s) are less than the sale total (%s).', v_total_payments, v_total_minor;
    end if;

    -- 7. Validate inventory and row lock FOR UPDATE before inserting anything
    for v_item in select * from jsonb_array_elements(v_items) loop
        v_item_prod_id := nullif(v_item->>'product_id', '')::uuid;
        v_item_var_id := nullif(v_item->>'variant_id', '')::uuid;
        v_item_qty := coalesce((v_item->>'quantity')::integer, 0);
        v_item_name := coalesce(v_item->>'product_name_snapshot', 'Product');
        v_item_sku := v_item->>'sku_snapshot';

        if v_item_qty <= 0 then
            raise exception 'Quantity for % must be greater than 0.', v_item_name;
        end if;

        -- Auto-resolve variant if omitted
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

        -- ROW-LEVEL LOCK ON INVENTORY BALANCE
        select available_qty into v_current_available
        from public.inventory_balances
        where business_id = v_business_id
          and location_id = v_location_id
          and variant_id = v_item_var_id
        for update;

        if v_current_available is null or v_current_available < v_item_qty then
            raise exception '% only has % units available. Reduce the quantity before completing this sale.',
                v_item_name,
                coalesce(v_current_available, 0);
        end if;
    end loop;

    -- 8. Continue an existing held sale, or allocate a new sale number.
    if v_requested_sale_id is not null then
        select * into v_existing_sale
        from public.sales
        where id = v_requested_sale_id
        for update;

        if not found or v_existing_sale.business_id is distinct from v_business_id then
            raise exception 'Held sale not found';
        end if;
        if v_existing_sale.status <> 'held' then
            raise exception 'This sale is no longer held';
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
        where id = v_sale_id;

        delete from public.sale_items where sale_id = v_sale_id;
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

    -- 10. Insert Sale Items, Decrement Inventory, Record Ledger
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

        -- Insert Line Item Snapshot
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

        -- Decrement Inventory Balance
        update public.inventory_balances
        set available_qty = available_qty - v_item_qty,
            updated_at = now()
        where business_id = v_business_id
          and location_id = v_location_id
          and variant_id = v_item_var_id;

        -- Record Immutable Inventory Ledger Event
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
            v_item_var_id,
            'sale',
            -v_item_qty,
            'sale',
            v_sale_id,
            'sale',
            jsonb_build_object(
                'sale_number', v_sale_number,
                'unit_price_cents', v_item_price,
                'sku', v_item_sku,
                'product_name', v_item_name
            )
        );
    end loop;

    -- 11. Insert Payments
    for v_payment in select * from jsonb_array_elements(v_payments) loop
        v_pay_method := coalesce(v_payment->>'payment_method', 'cash');
        v_pay_amount := (v_payment->>'amount_minor')::bigint;
        v_pay_proc := coalesce(v_payment->>'processing_type', 'recorded');
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

    -- 12. Return Success Payload
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

grant execute on function public.complete_sale(jsonb) to authenticated, service_role;

-- Notify PostgREST to reload its schema cache immediately so complete_sale is discovered
notify pgrst, 'reload schema';
