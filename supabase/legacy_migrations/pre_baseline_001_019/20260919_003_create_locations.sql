create extension if not exists pgcrypto;

create table if not exists public.locations (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    parent_location_id uuid references public.locations (id) on delete set null,
    name text not null check (length(trim(name)) > 0),
    location_type text not null check (location_type in ('retail_store', 'warehouse', 'showroom', 'distribution_hub', 'pop_up', 'office')),
    status text not null default 'active' check (status in ('active', 'inactive', 'maintenance')),
    street_address text,
    city text,
    postal_code text,
    country_code text check (country_code is null or country_code ~ '^[A-Z]{2}$'),
    timezone text,
    created_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

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

drop policy if exists "locations_select_business_members" on public.locations;
create policy "locations_select_business_members"
    on public.locations
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "locations_insert_business_owner_or_member" on public.locations;
create policy "locations_insert_business_owner_or_member"
    on public.locations
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "locations_update_business_owner_or_member" on public.locations;
create policy "locations_update_business_owner_or_member"
    on public.locations
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "locations_delete_business_owner" on public.locations;
create policy "locations_delete_business_owner"
    on public.locations
    for delete
    using (public.is_business_owner(business_id));

create index if not exists idx_locations_business_id
    on public.locations (business_id);

create index if not exists idx_locations_parent_location_id
    on public.locations (parent_location_id);

create index if not exists idx_locations_status
    on public.locations (status);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
