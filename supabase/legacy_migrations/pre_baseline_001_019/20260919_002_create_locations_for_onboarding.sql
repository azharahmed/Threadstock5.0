-- ThreadStock location onboarding schema
-- Scope: location records tied to the canonical business created during Step 1.
-- This script keeps the business as the source of truth and stores only the location data required by onboarding.

create extension if not exists pgcrypto;

create table if not exists public.locations (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    location_type text not null check (location_type in ('Flagship Store', 'Retail Store', 'Warehouse', 'Stockroom', 'Showroom', 'Office', 'Other')),
    street_address text not null check (length(trim(street_address)) > 0),
    city text not null check (length(trim(city)) > 0),
    postal_code text not null check (length(trim(postal_code)) > 0),
    inherit_business_currency_tax boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create index if not exists idx_locations_business_id
    on public.locations (business_id);

create index if not exists idx_locations_business_type
    on public.locations (location_type);

create or replace function public.set_locations_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_locations_set_updated_at on public.locations;
create trigger trg_locations_set_updated_at
before update on public.locations
for each row
execute function public.set_locations_updated_at();

alter table public.locations enable row level security;

drop policy if exists "locations_select_own_business" on public.locations;
create policy "locations_select_own_business"
    on public.locations
    for select
    using (
        exists (
            select 1
            from public.businesses b
            where b.id = business_id
              and b.owner_user_id = auth.uid()
        )
    );

drop policy if exists "locations_insert_own_business" on public.locations;
create policy "locations_insert_own_business"
    on public.locations
    for insert
    with check (
        exists (
            select 1
            from public.businesses b
            where b.id = business_id
              and b.owner_user_id = auth.uid()
        )
    );

drop policy if exists "locations_update_own_business" on public.locations;
create policy "locations_update_own_business"
    on public.locations
    for update
    using (
        exists (
            select 1
            from public.businesses b
            where b.id = business_id
              and b.owner_user_id = auth.uid()
        )
    )
    with check (
        exists (
            select 1
            from public.businesses b
            where b.id = business_id
              and b.owner_user_id = auth.uid()
        )
    );

drop policy if exists "locations_delete_own_business" on public.locations;
create policy "locations_delete_own_business"
    on public.locations
    for delete
    using (
        exists (
            select 1
            from public.businesses b
            where b.id = business_id
              and b.owner_user_id = auth.uid()
        )
    );

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
