-- Auditable inventory import jobs for CSV / Excel ingestion.
-- No demo seed rows. Stock changes must still go through inventory_ledger.

create table if not exists public.inventory_import_jobs (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    location_id uuid references public.locations (id) on delete set null,
    source_filename text not null check (length(trim(source_filename)) > 0),
    source_format text not null check (source_format in ('csv', 'xlsx')),
    status text not null default 'draft'
        check (status in (
            'draft',
            'uploaded',
            'mapping',
            'validating',
            'pending_review',
            'importing',
            'completed',
            'failed',
            'cancelled'
        )),
    total_rows integer not null default 0 check (total_rows >= 0),
    accepted_rows integer not null default 0 check (accepted_rows >= 0),
    rejected_rows integer not null default 0 check (rejected_rows >= 0),
    column_mappings jsonb not null default '{}'::jsonb,
    error_summary text,
    created_by uuid references public.profiles (id) on delete set null,
    created_at timestamptz not null default now(),
    started_at timestamptz,
    completed_at timestamptz,
    updated_at timestamptz not null default now()
);

create table if not exists public.inventory_import_rows (
    id uuid primary key default gen_random_uuid(),
    job_id uuid not null references public.inventory_import_jobs (id) on delete cascade,
    business_id uuid not null references public.businesses (id) on delete cascade,
    row_number integer not null check (row_number > 0),
    raw_payload jsonb not null default '{}'::jsonb,
    mapped_payload jsonb not null default '{}'::jsonb,
    status text not null default 'pending'
        check (status in ('pending', 'valid', 'warning', 'error', 'imported', 'skipped')),
    error_message text,
    created_variant_id uuid references public.product_variants (id) on delete set null,
    created_at timestamptz not null default now(),
    unique (job_id, row_number)
);

create table if not exists public.inventory_import_errors (
    id uuid primary key default gen_random_uuid(),
    job_id uuid not null references public.inventory_import_jobs (id) on delete cascade,
    business_id uuid not null references public.businesses (id) on delete cascade,
    row_id uuid references public.inventory_import_rows (id) on delete cascade,
    severity text not null default 'error' check (severity in ('info', 'warning', 'error')),
    code text,
    message text not null check (length(trim(message)) > 0),
    created_at timestamptz not null default now()
);

create or replace function public.set_inventory_import_job_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_inventory_import_jobs_set_updated_at on public.inventory_import_jobs;
create trigger trg_inventory_import_jobs_set_updated_at
before update on public.inventory_import_jobs
for each row
execute function public.set_inventory_import_job_updated_at();

alter table public.inventory_import_jobs enable row level security;
alter table public.inventory_import_rows enable row level security;
alter table public.inventory_import_errors enable row level security;

drop policy if exists "inventory_import_jobs_select_business_members" on public.inventory_import_jobs;
create policy "inventory_import_jobs_select_business_members"
    on public.inventory_import_jobs
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_jobs_insert_business_members" on public.inventory_import_jobs;
create policy "inventory_import_jobs_insert_business_members"
    on public.inventory_import_jobs
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_jobs_update_business_members" on public.inventory_import_jobs;
create policy "inventory_import_jobs_update_business_members"
    on public.inventory_import_jobs
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_rows_select_business_members" on public.inventory_import_rows;
create policy "inventory_import_rows_select_business_members"
    on public.inventory_import_rows
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_rows_insert_business_members" on public.inventory_import_rows;
create policy "inventory_import_rows_insert_business_members"
    on public.inventory_import_rows
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_rows_update_business_members" on public.inventory_import_rows;
create policy "inventory_import_rows_update_business_members"
    on public.inventory_import_rows
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_errors_select_business_members" on public.inventory_import_errors;
create policy "inventory_import_errors_select_business_members"
    on public.inventory_import_errors
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "inventory_import_errors_insert_business_members" on public.inventory_import_errors;
create policy "inventory_import_errors_insert_business_members"
    on public.inventory_import_errors
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

create index if not exists idx_inventory_import_jobs_business_id
    on public.inventory_import_jobs (business_id);

create index if not exists idx_inventory_import_jobs_status
    on public.inventory_import_jobs (business_id, status);

create index if not exists idx_inventory_import_rows_job_id
    on public.inventory_import_rows (job_id);

create index if not exists idx_inventory_import_errors_job_id
    on public.inventory_import_errors (job_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.inventory_import_jobs to authenticated;
grant select, insert, update, delete on public.inventory_import_rows to authenticated;
grant select, insert, update on public.inventory_import_errors to authenticated;
