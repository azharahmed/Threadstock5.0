-- Migration: 20260920_015_create_product_media_storage_bucket.sql
-- Description: Sets up the 'product-media' Supabase Storage bucket with 10MB limit,
-- allowed image mime types (PNG, JPG, WEBP), and tenant-isolated RLS policies.

-- 1. Insert 'product-media' bucket into storage.buckets if not exists
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'product-media',
    'product-media',
    true,
    10485760, -- 10MB in bytes
    array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update set
    file_size_limit = 10485760,
    allowed_mime_types = array['image/png', 'image/jpeg', 'image/webp'];

-- 2. Storage Objects RLS Policies for 'product-media' bucket

-- Read Policy: Public or authenticated business members can view product media
drop policy if exists "product_media_storage_select" on storage.objects;
create policy "product_media_storage_select"
    on storage.objects
    for select
    using (
        bucket_id = 'product-media'
    );

-- Insert Policy: Authenticated users can upload product images for their business
drop policy if exists "product_media_storage_insert" on storage.objects;
create policy "product_media_storage_insert"
    on storage.objects
    for insert
    with check (
        bucket_id = 'product-media'
        and auth.role() = 'authenticated'
        and (
            -- Ensure the first path component corresponds to a business the user belongs to
            public.is_business_member((storage.foldername(name))[1]::uuid, auth.uid())
            or public.is_business_owner((storage.foldername(name))[1]::uuid)
        )
    );

-- Update Policy: Authenticated users can update images within their business folder
drop policy if exists "product_media_storage_update" on storage.objects;
create policy "product_media_storage_update"
    on storage.objects
    for update
    using (
        bucket_id = 'product-media'
        and auth.role() = 'authenticated'
        and (
            public.is_business_member((storage.foldername(name))[1]::uuid, auth.uid())
            or public.is_business_owner((storage.foldername(name))[1]::uuid)
        )
    )
    with check (
        bucket_id = 'product-media'
        and auth.role() = 'authenticated'
        and (
            public.is_business_member((storage.foldername(name))[1]::uuid, auth.uid())
            or public.is_business_owner((storage.foldername(name))[1]::uuid)
        )
    );

-- Delete Policy: Authenticated users can delete images within their business folder
drop policy if exists "product_media_storage_delete" on storage.objects;
create policy "product_media_storage_delete"
    on storage.objects
    for delete
    using (
        bucket_id = 'product-media'
        and auth.role() = 'authenticated'
        and (
            public.is_business_member((storage.foldername(name))[1]::uuid, auth.uid())
            or public.is_business_owner((storage.foldername(name))[1]::uuid)
        )
    );
