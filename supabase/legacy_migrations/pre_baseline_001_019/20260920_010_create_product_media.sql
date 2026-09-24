-- Product media for catalog imagery. Belongs to products within a business.

create table if not exists public.product_media (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses (id) on delete cascade,
    product_id uuid not null references public.products (id) on delete cascade,
    storage_path text not null check (length(trim(storage_path)) > 0),
    media_type text not null default 'image' check (media_type in ('image', 'video', 'other')),
    sort_order integer not null default 0 check (sort_order >= 0),
    alt_text text,
    is_primary boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create or replace function public.set_product_media_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_product_media_set_updated_at on public.product_media;
create trigger trg_product_media_set_updated_at
before update on public.product_media
for each row
execute function public.set_product_media_updated_at();

alter table public.product_media enable row level security;

drop policy if exists "product_media_select_business_members" on public.product_media;
create policy "product_media_select_business_members"
    on public.product_media
    for select
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "product_media_insert_business_members" on public.product_media;
create policy "product_media_insert_business_members"
    on public.product_media
    for insert
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "product_media_update_business_members" on public.product_media;
create policy "product_media_update_business_members"
    on public.product_media
    for update
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    )
    with check (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

drop policy if exists "product_media_delete_business_members" on public.product_media;
create policy "product_media_delete_business_members"
    on public.product_media
    for delete
    using (
        public.is_business_member(business_id, auth.uid())
        or public.is_business_owner(business_id)
    );

create index if not exists idx_product_media_business_id
    on public.product_media (business_id);

create index if not exists idx_product_media_product_id
    on public.product_media (product_id);

create unique index if not exists idx_product_media_one_primary_per_product
    on public.product_media (product_id)
    where is_primary = true;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.product_media to authenticated;
