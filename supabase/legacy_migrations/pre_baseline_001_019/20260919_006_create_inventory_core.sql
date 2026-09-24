create extension if not exists pgcrypto;

create table if not exists public.categories (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    parent_category_id uuid references public.categories (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create table if not exists public.collections (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    season text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create table if not exists public.brands (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create table if not exists public.products (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    category_id uuid references public.categories (id) on delete set null,
    brand_id uuid references public.brands (id) on delete set null,
    collection_id uuid references public.collections (id) on delete set null,
    name text not null check (length(trim(name)) > 0),
    description text,
    status text not null default 'active' check (status in ('active', 'draft', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create table if not exists public.product_variants (
    id uuid primary key default gen_random_uuid(),
    product_id uuid not null references public.products (id) on delete cascade,
    sku text not null check (length(trim(sku)) > 0),
    barcode text unique,
    color text,
    size text,
    material text,
    retail_price_cents bigint not null default 0 check (retail_price_cents >= 0),
    cost_price_cents bigint not null default 0 check (cost_price_cents >= 0),
    status text not null default 'active' check (status in ('active', 'inactive', 'archived')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (product_id, sku)
);

create table if not exists public.inventory_balances (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    location_id uuid not null references public.locations (id) on delete cascade,
    variant_id uuid not null references public.product_variants (id) on delete cascade,
    available_qty integer not null default 0 check (available_qty >= 0),
    committed_qty integer not null default 0 check (committed_qty >= 0),
    damaged_qty integer not null default 0 check (damaged_qty >= 0),
    last_counted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, location_id, variant_id)
);

create table if not exists public.inventory_ledger (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    location_id uuid not null references public.locations (id) on delete cascade,
    variant_id uuid not null references public.product_variants (id) on delete cascade,
    event_type text not null check (event_type in ('stock_in', 'stock_out', 'adjustment', 'sale', 'return', 'transfer_in', 'transfer_out', 'count_reconciliation')),
    quantity_delta integer not null,
    reference_type text,
    reference_id uuid,
    source text not null default 'manual' check (source in ('manual', 'import', 'sale', 'purchase', 'transfer', 'ai', 'automation')),
    occurred_at timestamptz not null default now(),
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create or replace function public.set_category_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_categories_set_updated_at on public.categories;
create trigger trg_categories_set_updated_at
before update on public.categories
for each row
execute function public.set_category_updated_at();

create or replace function public.set_collection_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_collections_set_updated_at on public.collections;
create trigger trg_collections_set_updated_at
before update on public.collections
for each row
execute function public.set_collection_updated_at();

create or replace function public.set_brand_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_brands_set_updated_at on public.brands;
create trigger trg_brands_set_updated_at
before update on public.brands
for each row
execute function public.set_brand_updated_at();

create or replace function public.set_product_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_products_set_updated_at on public.products;
create trigger trg_products_set_updated_at
before update on public.products
for each row
execute function public.set_product_updated_at();

create or replace function public.set_variant_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_product_variants_set_updated_at on public.product_variants;
create trigger trg_product_variants_set_updated_at
before update on public.product_variants
for each row
execute function public.set_variant_updated_at();

create or replace function public.set_balance_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_inventory_balances_set_updated_at on public.inventory_balances;
create trigger trg_inventory_balances_set_updated_at
before update on public.inventory_balances
for each row
execute function public.set_balance_updated_at();

alter table public.categories enable row level security;
alter table public.collections enable row level security;
alter table public.brands enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.inventory_balances enable row level security;
alter table public.inventory_ledger enable row level security;

drop policy if exists "categories_select_business_members" on public.categories;
create policy "categories_select_business_members"
    on public.categories
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "categories_modify_business_owner" on public.categories;
create policy "categories_modify_business_owner"
    on public.categories
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "collections_select_business_members" on public.collections;
create policy "collections_select_business_members"
    on public.collections
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "collections_modify_business_owner" on public.collections;
create policy "collections_modify_business_owner"
    on public.collections
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "brands_select_business_members" on public.brands;
create policy "brands_select_business_members"
    on public.brands
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "brands_modify_business_owner" on public.brands;
create policy "brands_modify_business_owner"
    on public.brands
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "products_select_business_members" on public.products;
create policy "products_select_business_members"
    on public.products
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "products_modify_business_owner" on public.products;
create policy "products_modify_business_owner"
    on public.products
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "product_variants_select_business_members" on public.product_variants;
create policy "product_variants_select_business_members"
    on public.product_variants
    for select
    using (
        exists (
            select 1
            from public.products p
            where p.id = product_id
              and (
                  public.is_business_member(p.business_id, auth.uid())
                  or public.is_business_owner(p.business_id)
              )
        )
    );

drop policy if exists "product_variants_modify_business_owner" on public.product_variants;
create policy "product_variants_modify_business_owner"
    on public.product_variants
    for all
    using (
        exists (
            select 1
            from public.products p
            where p.id = product_id
              and (
                  public.is_business_member(p.business_id, auth.uid())
                  or public.is_business_owner(p.business_id)
              )
        )
    )
    with check (
        exists (
            select 1
            from public.products p
            where p.id = product_id
              and (
                  public.is_business_member(p.business_id, auth.uid())
                  or public.is_business_owner(p.business_id)
              )
        )
    );

drop policy if exists "inventory_balances_select_business_members" on public.inventory_balances;
create policy "inventory_balances_select_business_members"
    on public.inventory_balances
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_balances_modify_business_owner" on public.inventory_balances;
create policy "inventory_balances_modify_business_owner"
    on public.inventory_balances
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_ledger_select_business_members" on public.inventory_ledger;
create policy "inventory_ledger_select_business_members"
    on public.inventory_ledger
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_ledger_modify_business_owner" on public.inventory_ledger;
create policy "inventory_ledger_modify_business_owner"
    on public.inventory_ledger
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

create index if not exists idx_categories_business_id
    on public.categories (business_id);

create index if not exists idx_collections_business_id
    on public.collections (business_id);

create index if not exists idx_brands_business_id
    on public.brands (business_id);

create index if not exists idx_products_business_id
    on public.products (business_id);

create index if not exists idx_products_category_id
    on public.products (category_id);

create index if not exists idx_product_variants_product_id
    on public.product_variants (product_id);

create index if not exists idx_inventory_balances_location_id
    on public.inventory_balances (location_id);

create index if not exists idx_inventory_balances_variant_id
    on public.inventory_balances (variant_id);

create index if not exists idx_inventory_ledger_variant_id
    on public.inventory_ledger (variant_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.collections to authenticated;
grant select, insert, update, delete on public.brands to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select, insert, update, delete on public.product_variants to authenticated;
grant select, insert, update, delete on public.inventory_balances to authenticated;
grant select, insert, update, delete on public.inventory_ledger to authenticated;
