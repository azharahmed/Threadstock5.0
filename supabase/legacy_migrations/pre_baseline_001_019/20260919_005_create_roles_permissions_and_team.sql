create extension if not exists pgcrypto;

create table if not exists public.roles (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    description text,
    is_system boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, name)
);

create table if not exists public.permissions (
    id uuid primary key default gen_random_uuid(),
    code text not null unique check (length(trim(code)) > 0),
    name text not null check (length(trim(name)) > 0),
    module text not null check (length(trim(module)) > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.role_permissions (
    id uuid primary key default gen_random_uuid(),
    role_id uuid not null references public.roles (id) on delete cascade,
    permission_id uuid not null references public.permissions (id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (role_id, permission_id)
);

create table if not exists public.team_members (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
    role_id uuid not null references public.roles (id) on delete restrict,
    location_id uuid references public.locations (id) on delete set null,
    status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'removed')),
    invited_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, user_id)
);

create or replace function public.set_roles_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_roles_set_updated_at on public.roles;
create trigger trg_roles_set_updated_at
before update on public.roles
for each row
execute function public.set_roles_updated_at();

create or replace function public.set_permissions_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_permissions_set_updated_at on public.permissions;
create trigger trg_permissions_set_updated_at
before update on public.permissions
for each row
execute function public.set_permissions_updated_at();

create or replace function public.set_team_members_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_team_members_set_updated_at on public.team_members;
create trigger trg_team_members_set_updated_at
before update on public.team_members
for each row
execute function public.set_team_members_updated_at();

alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.team_members enable row level security;

drop policy if exists "roles_select_business_members" on public.roles;
create policy "roles_select_business_members"
    on public.roles
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "roles_modify_business_owner" on public.roles;
create policy "roles_modify_business_owner"
    on public.roles
    for all
    using (public.is_business_owner(business_id))
    with check (public.is_business_owner(business_id));

drop policy if exists "permissions_select_business_members" on public.permissions;
create policy "permissions_select_business_members"
    on public.permissions
    for select
    using (true);

drop policy if exists "permissions_modify_business_owner" on public.permissions;
create policy "permissions_modify_business_owner"
    on public.permissions
    for all
    using (true)
    with check (true);

drop policy if exists "role_permissions_select_business_members" on public.role_permissions;
create policy "role_permissions_select_business_members"
    on public.role_permissions
    for select
    using (
        exists (
            select 1
            from public.roles r
            where r.id = role_id
              and (
                  public.is_business_member(r.business_id, auth.uid())
                  or public.is_business_owner(r.business_id)
              )
        )
    );

drop policy if exists "role_permissions_modify_business_owner" on public.role_permissions;
create policy "role_permissions_modify_business_owner"
    on public.role_permissions
    for all
    using (
        exists (
            select 1
            from public.roles r
            where r.id = role_id
              and public.is_business_owner(r.business_id)
        )
    )
    with check (
        exists (
            select 1
            from public.roles r
            where r.id = role_id
              and public.is_business_owner(r.business_id)
        )
    );

drop policy if exists "team_members_select_business_members" on public.team_members;
create policy "team_members_select_business_members"
    on public.team_members
    for select
    using (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
        or public.is_business_member(business_id, auth.uid())
    );

drop policy if exists "team_members_insert_business_owner_or_self" on public.team_members;
create policy "team_members_insert_business_owner_or_self"
    on public.team_members
    for insert
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "team_members_update_business_owner_or_self" on public.team_members;
create policy "team_members_update_business_owner_or_self"
    on public.team_members
    for update
    using (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    )
    with check (
        user_id = auth.uid()
        or public.is_business_owner(business_id)
    );

drop policy if exists "team_members_delete_business_owner" on public.team_members;
create policy "team_members_delete_business_owner"
    on public.team_members
    for delete
    using (public.is_business_owner(business_id));

create index if not exists idx_roles_business_id
    on public.roles (business_id);

create index if not exists idx_permissions_code
    on public.permissions (code);

create index if not exists idx_role_permissions_role_id
    on public.role_permissions (role_id);

create index if not exists idx_team_members_business_id
    on public.team_members (business_id);

create index if not exists idx_team_members_role_id
    on public.team_members (role_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.roles to authenticated;
grant select, insert, update, delete on public.permissions to authenticated;
grant select, insert, update, delete on public.role_permissions to authenticated;
grant select, insert, update, delete on public.team_members to authenticated;
