create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    first_name text,
    last_name text,
    full_name text,
    email text unique,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
    insert into public.profiles (id, email, full_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.email)
    )
    on conflict (id) do update
        set email = excluded.email,
            full_name = excluded.full_name,
            updated_at = now();

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();

create table if not exists public.memberships (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
    status text not null default 'active' check (status in ('active', 'pending', 'inactive', 'revoked')),
    invited_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, user_id)
);

create or replace function public.is_business_owner(p_business_id uuid)
returns boolean
language sql
stable
as $$
    select exists (
        select 1
        from public.businesses b
        where b.id = p_business_id
          and b.owner_user_id = auth.uid()
    );
$$;

create or replace function public.is_business_member(p_business_id uuid, p_user_id uuid)
returns boolean
language sql
stable
as $$
    select exists (
        select 1
        from public.memberships m
        where m.business_id = p_business_id
          and m.user_id = p_user_id
          and m.status = 'active'
    );
$$;

create or replace function public.set_membership_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_memberships_set_updated_at on public.memberships;
create trigger trg_memberships_set_updated_at
before update on public.memberships
for each row
execute function public.set_membership_updated_at();

alter table public.profiles enable row level security;
alter table public.memberships enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
    on public.profiles
    for select
    using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
    on public.profiles
    for update
    using (id = auth.uid())
    with check (id = auth.uid());

drop policy if exists "memberships_select_own_or_business_owner" on public.memberships;
create policy "memberships_select_own_or_business_owner"
    on public.memberships
    for select
    using (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "memberships_insert_self_or_business_owner" on public.memberships;
create policy "memberships_insert_self_or_business_owner"
    on public.memberships
    for insert
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "memberships_update_own_or_business_owner" on public.memberships;
create policy "memberships_update_own_or_business_owner"
    on public.memberships
    for update
    using (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    )
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "memberships_delete_business_owner" on public.memberships;
create policy "memberships_delete_business_owner"
    on public.memberships
    for delete
    using (public.is_business_owner(business_id));

create index if not exists idx_profiles_email
    on public.profiles (email);

create index if not exists idx_memberships_business_id
    on public.memberships (business_id);

create index if not exists idx_memberships_user_id
    on public.memberships (user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.memberships to authenticated;
