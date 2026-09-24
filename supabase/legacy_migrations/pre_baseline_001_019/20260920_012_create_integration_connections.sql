-- External integration connection metadata.
-- Sensitive OAuth tokens / client secrets must NEVER be stored in this table
-- or in Flutter source. Store secrets only in server-side secret storage
-- (Supabase Vault / Edge Function secrets) referenced by secret_ref.

create table if not exists public.integration_connections (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    provider text not null check (provider in ('shopify', 'wix', 'custom')),
    display_name text,
    external_shop_domain text,
    status text not null default 'disconnected'
        check (status in (
            'disconnected',
            'pending_oauth',
            'connected',
            'error',
            'revoked'
        )),
    sync_direction text not null default 'inbound'
        check (sync_direction in ('inbound', 'outbound', 'bidirectional')),
    sync_config jsonb not null default '{}'::jsonb,
    -- Opaque reference to server-side secret storage. Never a raw token.
    secret_ref text,
    last_synced_at timestamptz,
    connected_at timestamptz,
    created_by uuid references public.profiles (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (business_id, provider, external_shop_domain)
);

create table if not exists public.integration_sync_checkpoints (
    id uuid primary key default gen_random_uuid(),
    connection_id uuid not null references public.integration_connections (id) on delete cascade,
    business_id uuid not null references public.businesses (id) on delete cascade,
    resource_type text not null check (resource_type in (
        'products',
        'variants',
        'inventory',
        'orders',
        'locations'
    )),
    cursor_token text,
    last_success_at timestamptz,
    last_error text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (connection_id, resource_type)
);

create or replace function public.set_integration_connection_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_integration_connections_set_updated_at on public.integration_connections;
create trigger trg_integration_connections_set_updated_at
before update on public.integration_connections
for each row
execute function public.set_integration_connection_updated_at();

create or replace function public.set_integration_sync_checkpoint_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_integration_sync_checkpoints_set_updated_at on public.integration_sync_checkpoints;
create trigger trg_integration_sync_checkpoints_set_updated_at
before update on public.integration_sync_checkpoints
for each row
execute function public.set_integration_sync_checkpoint_updated_at();

alter table public.integration_connections enable row level security;
alter table public.integration_sync_checkpoints enable row level security;

drop policy if exists "integration_connections_select_business_members" on public.integration_connections;
create policy "integration_connections_select_business_members"
    on public.integration_connections
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "integration_connections_insert_business_members" on public.integration_connections;
create policy "integration_connections_insert_business_members"
    on public.integration_connections
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "integration_connections_update_business_members" on public.integration_connections;
create policy "integration_connections_update_business_members"
    on public.integration_connections
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "integration_sync_checkpoints_select_business_members" on public.integration_sync_checkpoints;
create policy "integration_sync_checkpoints_select_business_members"
    on public.integration_sync_checkpoints
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "integration_sync_checkpoints_modify_business_members" on public.integration_sync_checkpoints;
create policy "integration_sync_checkpoints_modify_business_members"
    on public.integration_sync_checkpoints
    for all
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

create index if not exists idx_integration_connections_business_id
    on public.integration_connections (business_id);

create index if not exists idx_integration_sync_checkpoints_connection_id
    on public.integration_sync_checkpoints (connection_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.integration_connections to authenticated;
grant select, insert, update, delete on public.integration_sync_checkpoints to authenticated;
