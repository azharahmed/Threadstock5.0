create extension if not exists pgcrypto;

create table if not exists public.business_commerce_profiles (
    business_id uuid primary key references public.businesses (id) on delete cascade,
    sales_channels text[] not null default '{}'::text[] check (array_length(sales_channels, 1) > 0),
    preferred_payment_terms text not null check (length(trim(preferred_payment_terms)) > 0),
    tax_system text not null check (tax_system in ('GST — India', 'VAT', 'Sales Tax', 'Country tax system')),
    gst_registered boolean not null default false,
    gstin text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint commerce_gstin_required_when_registered
        check (
            (gst_registered = false)
            or (gst_registered = true and gstin is not null and length(trim(gstin)) > 0)
        )
);

create index if not exists idx_business_commerce_profiles_business_id
    on public.business_commerce_profiles (business_id);

create or replace function public.set_business_commerce_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_business_commerce_profiles_set_updated_at on public.business_commerce_profiles;
create trigger trg_business_commerce_profiles_set_updated_at
before update on public.business_commerce_profiles
for each row
execute function public.set_business_commerce_profile_updated_at();

alter table public.business_commerce_profiles enable row level security;

drop policy if exists "business_commerce_profiles_select_business_members" on public.business_commerce_profiles;
create policy "business_commerce_profiles_select_business_members"
    on public.business_commerce_profiles
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "business_commerce_profiles_insert_business_members" on public.business_commerce_profiles;
create policy "business_commerce_profiles_insert_business_members"
    on public.business_commerce_profiles
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "business_commerce_profiles_update_business_members" on public.business_commerce_profiles;
create policy "business_commerce_profiles_update_business_members"
    on public.business_commerce_profiles
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "business_commerce_profiles_delete_business_members" on public.business_commerce_profiles;
create policy "business_commerce_profiles_delete_business_members"
    on public.business_commerce_profiles
    for delete
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.business_commerce_profiles to authenticated;
