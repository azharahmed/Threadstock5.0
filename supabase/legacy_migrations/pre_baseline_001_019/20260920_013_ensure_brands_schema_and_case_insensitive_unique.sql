-- Migration: 20260920_013_ensure_brands_schema_and_case_insensitive_unique.sql
-- Description: Ensures brands table exists with proper tenant-isolation, indexes, case-insensitive uniqueness,
-- and links foreign key relationship on products(brand_id).
-- Starts with 0 brands (no seed/demo brands).

create extension if not exists pgcrypto;

-- 1. Ensure table public.brands exists
create table if not exists public.brands (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

-- 2. Case-insensitive unique index per business (prevents duplicate 'Azhar Couture' and 'azhar couture')
create unique index if not exists uq_brands_business_id_lower_name
    on public.brands (business_id, lower(trim(name)));

-- 3. Business ID foreign key index for high performance tenant queries
create index if not exists idx_brands_business_id
    on public.brands (business_id);

-- 4. Automatic updated_at trigger
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

-- 5. Row Level Security
alter table public.brands enable row level security;

-- SELECT policy: Only members or owners of the business can read its brands
drop policy if exists "brands_select_business_members" on public.brands;
create policy "brands_select_business_members"
    on public.brands
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

-- INSERT / UPDATE / DELETE policy: Only members or owners of the business can mutate its brands
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

-- 6. Permissions
grant select, insert, update, delete on public.brands to authenticated;

-- 7. Ensure products table references brands(id)
do $$
begin
    if exists (
        select 1 from information_schema.tables
        where table_schema = 'public' and table_name = 'products'
    ) then
        if not exists (
            select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'products' and column_name = 'brand_id'
        ) then
            alter table public.products
                add column brand_id uuid references public.brands (id) on delete set null;
        end if;

        create index if not exists idx_products_brand_id
            on public.products (brand_id);
    end if;
end;
$$;
