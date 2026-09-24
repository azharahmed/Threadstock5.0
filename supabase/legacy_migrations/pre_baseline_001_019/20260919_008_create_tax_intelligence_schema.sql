create extension if not exists pgcrypto;

create table if not exists public.tax_source_registry (
    id uuid primary key default gen_random_uuid(),
    country_code text not null check (country_code ~ '^[A-Z]{2}$'),
    jurisdiction_type text not null check (jurisdiction_type in ('country', 'state', 'province', 'region', 'local')),
    jurisdiction_code text,
    authority_name text not null check (length(trim(authority_name)) > 0),
    source_type text not null check (source_type in ('government', 'tax_authority', 'customs', 'commission', 'statistical')),
    base_url text not null check (length(trim(base_url)) > 0),
    listing_url text,
    enabled boolean not null default true,
    last_checked_at timestamptz,
    last_success_at timestamptz,
    check_frequency text not null default 'daily' check (check_frequency in ('hourly', 'daily', 'weekly', 'manual')),
    parser_strategy text not null default 'government_publication' check (length(trim(parser_strategy)) > 0),
    authority_priority integer not null default 100 check (authority_priority >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (country_code, jurisdiction_type, jurisdiction_code, authority_name)
);

create index if not exists idx_tax_source_registry_country_code
    on public.tax_source_registry (country_code);

create index if not exists idx_tax_source_registry_enabled
    on public.tax_source_registry (enabled, check_frequency);

create table if not exists public.tax_source_documents (
    id uuid primary key default gen_random_uuid(),
    source_id uuid not null references public.tax_source_registry (id) on delete cascade,
    country_code text not null check (country_code ~ '^[A-Z]{2}$'),
    jurisdiction_type text not null check (jurisdiction_type in ('country', 'state', 'province', 'region', 'local')),
    jurisdiction_code text,
    authority_name text not null check (length(trim(authority_name)) > 0),
    source_url text not null check (length(trim(source_url)) > 0),
    document_title text not null check (length(trim(document_title)) > 0),
    government_reference text,
    publication_date timestamptz,
    effective_date timestamptz,
    fetched_at timestamptz not null default now(),
    content_hash text not null check (length(trim(content_hash)) > 0),
    original_document_url text,
    parser_status text not null default 'pending' check (parser_status in ('pending', 'parsed', 'failed', 'conflict', 'review_required')),
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (source_id, content_hash)
);

create index if not exists idx_tax_source_documents_source_id
    on public.tax_source_documents (source_id);

create index if not exists idx_tax_source_documents_country_code
    on public.tax_source_documents (country_code, publication_date desc);

create index if not exists idx_tax_source_documents_parser_status
    on public.tax_source_documents (parser_status, fetched_at desc);

create table if not exists public.tax_rule_versions (
    id uuid primary key default gen_random_uuid(),
    source_document_id uuid not null references public.tax_source_documents (id) on delete restrict,
    country_code text not null check (country_code ~ '^[A-Z]{2}$'),
    jurisdiction_type text not null check (jurisdiction_type in ('country', 'state', 'province', 'region', 'local')),
    jurisdiction_code text,
    tax_system text not null check (tax_system in ('GST', 'VAT', 'Sales Tax', 'Other')),
    tax_type text not null check (length(trim(tax_type)) > 0),
    product_classification text,
    commodity_code text,
    rate numeric(10,4) not null check (rate >= 0 and rate <= 1000),
    threshold_amount numeric(18,2),
    threshold_currency text,
    threshold_inclusive boolean not null default false,
    customer_applicability text,
    transaction_conditions jsonb not null default '{}'::jsonb,
    effective_from timestamptz not null,
    effective_to timestamptz,
    exemptions jsonb not null default '[]'::jsonb,
    source_reference text,
    ai_confidence numeric(4,3) check (ai_confidence between 0 and 1),
    extraction_warnings jsonb not null default '[]'::jsonb,
    status text not null default 'detected' check (status in ('detected', 'proposed', 'pending_review', 'scheduled', 'active', 'superseded', 'rejected')),
    approved_at timestamptz,
    approved_by uuid references public.profiles (id),
    created_by_source boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_tax_rule_versions_country_code
    on public.tax_rule_versions (country_code, effective_from desc);

create index if not exists idx_tax_rule_versions_status
    on public.tax_rule_versions (status, effective_from desc);

create index if not exists idx_tax_rule_versions_jurisdiction
    on public.tax_rule_versions (country_code, jurisdiction_type, jurisdiction_code, tax_type);

create table if not exists public.tax_rule_review_queue (
    id uuid primary key default gen_random_uuid(),
    rule_id uuid not null references public.tax_rule_versions (id) on delete cascade,
    review_reason text not null,
    review_status text not null default 'open' check (review_status in ('open', 'in_review', 'approved', 'rejected')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_tax_rule_review_queue_rule_id
    on public.tax_rule_review_queue (rule_id);

create table if not exists public.tax_rule_audit_events (
    id uuid primary key default gen_random_uuid(),
    rule_id uuid not null references public.tax_rule_versions (id) on delete cascade,
    event_type text not null check (event_type in ('detected', 'proposed', 'validated', 'approved', 'rejected', 'superseded', 'scheduled')),
    previous_value jsonb,
    new_value jsonb,
    change_reason text,
    source_authority text,
    source_document_reference text,
    detected_at timestamptz not null default now(),
    effective_at timestamptz,
    ai_confidence numeric(4,3),
    auto_applied boolean not null default false,
    approved_by uuid references public.profiles (id),
    created_at timestamptz not null default now()
);

create index if not exists idx_tax_rule_audit_events_rule_id
    on public.tax_rule_audit_events (rule_id, detected_at desc);

create or replace function public.set_tax_source_registry_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_tax_source_registry_set_updated_at on public.tax_source_registry;
create trigger trg_tax_source_registry_set_updated_at
before update on public.tax_source_registry
for each row
execute function public.set_tax_source_registry_updated_at();

create or replace function public.set_tax_source_documents_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_tax_source_documents_set_updated_at on public.tax_source_documents;
create trigger trg_tax_source_documents_set_updated_at
before update on public.tax_source_documents
for each row
execute function public.set_tax_source_documents_updated_at();

create or replace function public.set_tax_rule_versions_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_tax_rule_versions_set_updated_at on public.tax_rule_versions;
create trigger trg_tax_rule_versions_set_updated_at
before update on public.tax_rule_versions
for each row
execute function public.set_tax_rule_versions_updated_at();

create or replace function public.set_tax_rule_review_queue_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_tax_rule_review_queue_set_updated_at on public.tax_rule_review_queue;
create trigger trg_tax_rule_review_queue_set_updated_at
before update on public.tax_rule_review_queue
for each row
execute function public.set_tax_rule_review_queue_updated_at();

alter table public.tax_source_registry enable row level security;
alter table public.tax_source_documents enable row level security;
alter table public.tax_rule_versions enable row level security;
alter table public.tax_rule_review_queue enable row level security;
alter table public.tax_rule_audit_events enable row level security;

create policy "tax_source_registry_select_authenticated"
    on public.tax_source_registry
    for select
    using (auth.role() = 'authenticated');

create policy "tax_source_registry_insert_authenticated"
    on public.tax_source_registry
    for insert
    with check (auth.role() = 'authenticated');

create policy "tax_source_registry_update_authenticated"
    on public.tax_source_registry
    for update
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

create policy "tax_source_registry_delete_authenticated"
    on public.tax_source_registry
    for delete
    using (auth.role() = 'authenticated');

create policy "tax_source_documents_select_authenticated"
    on public.tax_source_documents
    for select
    using (auth.role() = 'authenticated');

create policy "tax_source_documents_insert_authenticated"
    on public.tax_source_documents
    for insert
    with check (auth.role() = 'authenticated');

create policy "tax_source_documents_update_authenticated"
    on public.tax_source_documents
    for update
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

create policy "tax_source_documents_delete_authenticated"
    on public.tax_source_documents
    for delete
    using (auth.role() = 'authenticated');

create policy "tax_rule_versions_select_authenticated"
    on public.tax_rule_versions
    for select
    using (auth.role() = 'authenticated');

create policy "tax_rule_versions_insert_authenticated"
    on public.tax_rule_versions
    for insert
    with check (auth.role() = 'authenticated');

create policy "tax_rule_versions_update_authenticated"
    on public.tax_rule_versions
    for update
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

create policy "tax_rule_versions_delete_authenticated"
    on public.tax_rule_versions
    for delete
    using (auth.role() = 'authenticated');

create policy "tax_rule_review_queue_select_authenticated"
    on public.tax_rule_review_queue
    for select
    using (auth.role() = 'authenticated');

create policy "tax_rule_review_queue_insert_authenticated"
    on public.tax_rule_review_queue
    for insert
    with check (auth.role() = 'authenticated');

create policy "tax_rule_review_queue_update_authenticated"
    on public.tax_rule_review_queue
    for update
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

create policy "tax_rule_review_queue_delete_authenticated"
    on public.tax_rule_review_queue
    for delete
    using (auth.role() = 'authenticated');

create policy "tax_rule_audit_events_select_authenticated"
    on public.tax_rule_audit_events
    for select
    using (auth.role() = 'authenticated');

create policy "tax_rule_audit_events_insert_authenticated"
    on public.tax_rule_audit_events
    for insert
    with check (auth.role() = 'authenticated');

create policy "tax_rule_audit_events_update_authenticated"
    on public.tax_rule_audit_events
    for update
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

create policy "tax_rule_audit_events_delete_authenticated"
    on public.tax_rule_audit_events
    for delete
    using (auth.role() = 'authenticated');

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.tax_source_registry to authenticated;
grant select, insert, update, delete on public.tax_source_documents to authenticated;
grant select, insert, update, delete on public.tax_rule_versions to authenticated;
grant select, insert, update, delete on public.tax_rule_review_queue to authenticated;
grant select, insert, update, delete on public.tax_rule_audit_events to authenticated;
