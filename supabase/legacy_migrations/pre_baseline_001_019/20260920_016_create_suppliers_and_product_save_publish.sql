-- Migration: 20260920_016_create_suppliers_and_product_save_publish.sql
-- Description: Creates the suppliers table, extends products and product_variants tables
-- with supplier, tax, tags, inventory settings, and draft/published timestamps,
-- and provides an atomic RPC function for product persistence and opening inventory.

create extension if not exists pgcrypto;

-- 1. Suppliers Table
create table if not exists public.suppliers (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    contact_email text,
    contact_phone text,
    tax_identifier text,
    status text not null default 'active' check (status in ('active', 'inactive', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create index if not exists idx_suppliers_business_id
    on public.suppliers (business_id);

create or replace function public.set_suppliers_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_suppliers_set_updated_at on public.suppliers;
create trigger trg_suppliers_set_updated_at
before update on public.suppliers
for each row
execute function public.set_suppliers_updated_at();

alter table public.suppliers enable row level security;

drop policy if exists "suppliers_select_business_members" on public.suppliers;
create policy "suppliers_select_business_members"
    on public.suppliers
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "suppliers_modify_business_owner_or_member" on public.suppliers;
create policy "suppliers_modify_business_owner_or_member"
    on public.suppliers
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.suppliers to authenticated;

-- 2. Extend products table with supplier, tax, tags, and inventory settings
alter table public.products
    add column if not exists supplier_id uuid references public.suppliers (id) on delete set null,
    add column if not exists tax_category text,
    add column if not exists tags text[] not null default '{}'::text[],
    add column if not exists track_stock_levels boolean not null default false,
    add column if not exists low_stock_threshold integer default 10,
    add column if not exists published_at timestamptz;

create index if not exists idx_products_supplier_id
    on public.products (supplier_id);

create index if not exists idx_products_status
    on public.products (business_id, status);

-- 3. Extend product_variants status to allow 'draft'
do $$
begin
    -- Drop old check constraint if present and replace with draft-aware check
    alter table public.product_variants drop constraint if exists product_variants_status_check;
    alter table public.product_variants add constraint product_variants_status_check
        check (status in ('active', 'draft', 'inactive', 'archived'));
exception
    when others then
        null;
end $$;

-- 4. Atomic Product Save / Publish RPC
create or replace function public.save_or_publish_product(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
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
    -- Basic validation
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;
    if v_name is null or length(v_name) = 0 then
        raise exception 'Product name is required';
    end if;
    if v_cost_price_cents < 0 or v_retail_price_cents < 0 then
        raise exception 'Prices cannot be negative';
    end if;

    -- If status is active (published), enforce required publication fields
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

    -- Upsert Product
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
            raise exception 'Product not found or access denied';
        end if;
    else
        insert into public.products (
            business_id,
            name,
            description,
            brand_id,
            category_id,
            supplier_id,
            tax_category,
            status,
            track_stock_levels,
            low_stock_threshold,
            published_at
        ) values (
            v_business_id,
            v_name,
            v_description,
            v_brand_id,
            v_category_id,
            v_supplier_id,
            v_tax_category,
            v_status,
            v_track_stock,
            v_low_stock,
            case when v_status = 'active' then now() else null end
        )
        returning * into v_result_product;
        v_product_id := v_result_product.id;
    end if;

    -- Upsert Variant if SKU or prices provided
    if v_sku is not null or v_retail_price_cents > 0 or v_cost_price_cents > 0 then
        -- Check if primary variant already exists for product
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
                product_id,
                sku,
                barcode,
                retail_price_cents,
                cost_price_cents,
                status
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

        -- Record opening inventory if requested
        if v_status = 'active' and v_track_stock and v_opening_stock > 0 and v_location_id is not null then
            insert into public.inventory_balances (
                business_id,
                location_id,
                variant_id,
                available_qty
            ) values (
                v_business_id,
                v_location_id,
                v_variant_id,
                v_opening_stock
            )
            on conflict (business_id, location_id, variant_id) do update set
                available_qty = public.inventory_balances.available_qty + excluded.available_qty,
                updated_at = now();

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
                v_variant_id,
                'stock_in',
                v_opening_stock,
                'opening_stock',
                v_product_id,
                'manual',
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

grant execute on function public.save_or_publish_product(jsonb) to authenticated;
