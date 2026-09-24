-- ThreadStock Business onboarding schema
-- Scope: one canonical business record for the onboarding/business-profile flow.
-- This script intentionally keeps a single source of truth for the business name and setup values.

create extension if not exists pgcrypto;

create table if not exists public.businesses (
    id uuid primary key default gen_random_uuid(),
    owner_user_id uuid not null references auth.users (id) on delete cascade,
    legal_name text not null check (length(trim(legal_name)) > 0),
    business_type text not null check (length(trim(business_type)) > 0),
    country_code text not null check (country_code ~ '^[A-Z]{2}$'),
    currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
    location_range text not null check (location_range in ('1', '2-5', '6-20', '20+')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_businesses_owner_user_id
    on public.businesses (owner_user_id);

create index if not exists idx_businesses_country_code
    on public.businesses (country_code);

create index if not exists idx_businesses_currency_code
    on public.businesses (currency_code);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_businesses_set_updated_at on public.businesses;
create trigger trg_businesses_set_updated_at
before update on public.businesses
for each row
execute function public.set_updated_at();

alter table public.businesses enable row level security;

drop policy if exists "businesses_select_own" on public.businesses;
create policy "businesses_select_own"
    on public.businesses
    for select
    using (owner_user_id = auth.uid());

drop policy if exists "businesses_insert_own" on public.businesses;
create policy "businesses_insert_own"
    on public.businesses
    for insert
    with check (owner_user_id = auth.uid());

drop policy if exists "businesses_update_own" on public.businesses;
create policy "businesses_update_own"
    on public.businesses
    for update
    using (owner_user_id = auth.uid())
    with check (owner_user_id = auth.uid());

drop policy if exists "businesses_delete_own" on public.businesses;
create policy "businesses_delete_own"
    on public.businesses
    for delete
    using (owner_user_id = auth.uid());

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.businesses to authenticated;
