-- Migration: 20260920_014_ensure_categories_schema_and_case_insensitive_unique.sql
-- Description: Ensures categories table exists with proper tenant-isolation, indexes, case-insensitive uniqueness,
-- and verifies foreign key relationship on products(category_id).
-- Starts with 0 categories (no seed/demo categories).

create extension if not exists pgcrypto;

-- 1. Ensure table public.categories exists
create table if not exists public.categories (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    parent_category_id uuid references public.categories (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

-- 2. Case-insensitive unique index per business (prevents duplicate 'Formal Wear' and 'formal wear')
create unique index if not exists uq_categories_business_id_lower_name
    on public.categories (business_id, lower(trim(name)));

-- 3. Business ID foreign key index for high performance tenant queries
create index if not exists idx_categories_business_id
    on public.categories (business_id);

create index if not exists idx_categories_parent_category_id
    on public.categories (parent_category_id);

-- 4. Automatic updated_at trigger
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

-- 5. Row Level Security
alter table public.categories enable row level security;

-- SELECT policy: Only members or owners of the business can read its categories
drop policy if exists "categories_select_business_members" on public.categories;
create policy "categories_select_business_members"
    on public.categories
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

-- INSERT / UPDATE / DELETE policy: Only members or owners of the business can mutate its categories
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

-- 6. Permissions
grant select, insert, update, delete on public.categories to authenticated;

-- 7. Ensure products table references categories(id)
do $$
begin
    if exists (
        select 1 from information_schema.tables
        where table_schema = 'public' and table_name = 'products'
    ) then
        if not exists (
            select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'products' and column_name = 'category_id'
        ) then
            alter table public.products
                add column category_id uuid references public.categories (id) on delete set null;
        end if;

        create index if not exists idx_products_category_id
            on public.products (category_id);
    end if;
end;
$$;
