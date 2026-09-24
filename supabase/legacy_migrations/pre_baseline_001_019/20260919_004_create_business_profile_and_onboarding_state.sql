create extension if not exists pgcrypto;

create table if not exists public.business_profile_settings (
    business_id uuid primary key references public.businesses (id) on delete cascade,
    display_name text,
    legal_entity_name text,
    business_type text,
    registered_country text,
    primary_currency text,
    default_language text default 'English (United States)',
    timezone text default 'UTC',
    email text,
    phone text,
    website text,
    street_address text,
    city text,
    postal_code text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.onboarding_sessions (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
    current_step integer not null default 0 check (current_step between 0 and 6),
    status text not null default 'in_progress' check (status in ('in_progress', 'complete', 'skipped')),
    started_at timestamptz not null default now(),
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, user_id)
);

create or replace function public.set_business_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_business_profile_settings_set_updated_at on public.business_profile_settings;
create trigger trg_business_profile_settings_set_updated_at
before update on public.business_profile_settings
for each row
execute function public.set_business_profile_updated_at();

create or replace function public.set_onboarding_session_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_onboarding_sessions_set_updated_at on public.onboarding_sessions;
create trigger trg_onboarding_sessions_set_updated_at
before update on public.onboarding_sessions
for each row
execute function public.set_onboarding_session_updated_at();

alter table public.business_profile_settings enable row level security;
alter table public.onboarding_sessions enable row level security;

drop policy if exists "business_profile_settings_select_business_members" on public.business_profile_settings;
create policy "business_profile_settings_select_business_members"
    on public.business_profile_settings
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "business_profile_settings_upsert_business_members" on public.business_profile_settings;
create policy "business_profile_settings_upsert_business_members"
    on public.business_profile_settings
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "business_profile_settings_update_business_members" on public.business_profile_settings;
create policy "business_profile_settings_update_business_members"
    on public.business_profile_settings
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "onboarding_sessions_select_business_members" on public.onboarding_sessions;
create policy "onboarding_sessions_select_business_members"
    on public.onboarding_sessions
    for select
    using (
        business_id in (
            select m.business_id
            from public.memberships m
            where m.user_id = auth.uid()
              and m.status = 'active'
        )
        or public.is_business_owner(business_id)
    );

drop policy if exists "onboarding_sessions_insert_business_members" on public.onboarding_sessions;
create policy "onboarding_sessions_insert_business_members"
    on public.onboarding_sessions
    for insert
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "onboarding_sessions_update_business_members" on public.onboarding_sessions;
create policy "onboarding_sessions_update_business_members"
    on public.onboarding_sessions
    for update
    using (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    )
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

create index if not exists idx_business_profile_settings_business_id
    on public.business_profile_settings (business_id);

create index if not exists idx_onboarding_sessions_business_id
    on public.onboarding_sessions (business_id);

create index if not exists idx_onboarding_sessions_user_id
    on public.onboarding_sessions (user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.business_profile_settings to authenticated;
grant select, insert, update, delete on public.onboarding_sessions to authenticated;
