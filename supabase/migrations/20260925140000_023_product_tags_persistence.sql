-- Migration 023: Product Tags Persistence in save_or_publish_product
-- Date: 2026-09-25
-- Description: Safely accept and persist product tags in the server-authoritative
--              save_or_publish_product RPC while preserving cross-tenant checks,
--              inventory.manage granular RBAC, and opening stock invariants.
--
-- IMPORTANT: Migration prepared for review. NOT deployed.

CREATE OR REPLACE FUNCTION public.save_or_publish_product(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $$
declare
    v_business_id uuid := (payload->>'business_id')::uuid;
    v_product_id uuid := nullif(payload->>'id', '')::uuid;
    v_name text := trim(payload->>'name');
    v_description text := payload->>'description';
    v_brand_id uuid := nullif(payload->>'brand_id', '')::uuid;
    v_category_id uuid := nullif(payload->>'category_id', '')::uuid;
    v_supplier_id uuid := nullif(payload->>'supplier_id', '')::uuid;
    v_tax_category text := payload->>'tax_category';
    v_status text := coalesce(payload->>'status', 'draft');
    v_track_stock boolean := coalesce((payload->>'track_stock_levels')::boolean, false);
    v_low_stock integer := (payload->>'low_stock_threshold')::integer;
    v_sku text := nullif(trim(payload->>'sku'), '');
    v_barcode text := nullif(trim(payload->>'barcode'), '');
    v_cost_price_cents bigint := coalesce((payload->>'cost_price_cents')::bigint, 0);
    v_retail_price_cents bigint := coalesce((payload->>'retail_price_cents')::bigint, 0);
    v_location_id uuid := nullif(payload->>'location_id', '')::uuid;
    v_opening_stock integer := coalesce((payload->>'opening_stock')::integer, 0);

    -- Tags handling
    v_has_tags boolean := (payload ? 'tags');
    v_tags text[] := null;

    v_result_product record;
    v_variant_id uuid;
begin
    if v_business_id is null then
        raise exception 'business_id is required';
    end if;

    perform public.require_business_access(v_business_id);

    -- Granular RBAC Check: inventory.manage
    if not public.has_business_permission(v_business_id, 'inventory.manage') then
        raise exception 'Permission denied: inventory.manage required' using errcode = '42501';
    end if;

    if v_name is null or length(v_name) = 0 then
        raise exception 'Product name is required';
    end if;
    if v_cost_price_cents < 0 or v_retail_price_cents < 0 then
        raise exception 'Prices cannot be negative';
    end if;

    -- Parse tags if present in payload
    if v_has_tags then
        if jsonb_typeof(payload->'tags') = 'array' then
            select coalesce(array_agg(trim(elem::text)), '{}'::text[])
            into v_tags
            from jsonb_array_elements_text(payload->'tags') elem
            where trim(elem::text) <> '';
            v_tags := coalesce(v_tags, '{}'::text[]);
        else
            v_tags := '{}'::text[];
        end if;
    end if;

    if v_brand_id is not null and not exists (
        select 1 from public.brands
        where id = v_brand_id and business_id = v_business_id
    ) then
        raise exception 'Brand is not available';
    end if;

    if v_category_id is not null and not exists (
        select 1 from public.categories
        where id = v_category_id and business_id = v_business_id
    ) then
        raise exception 'Category is not available';
    end if;

    if v_supplier_id is not null and not exists (
        select 1 from public.suppliers
        where id = v_supplier_id and business_id = v_business_id
    ) then
        raise exception 'Supplier is not available';
    end if;

    if v_location_id is not null and not exists (
        select 1 from public.locations
        where id = v_location_id and business_id = v_business_id
    ) then
        raise exception 'Location is not available';
    end if;

    if v_status = 'active' then
        if v_brand_id is null then
            raise exception 'Select a brand.';
        end if;
        if v_category_id is null then
            raise exception 'Select a category.';
        end if;
        if v_retail_price_cents <= 0 then
            raise exception 'Enter a selling price greater than 0.';
        end if;
        if v_sku is null then
            raise exception 'A valid System SKU is required to publish.';
        end if;
    end if;

    if v_product_id is not null then
        update public.products
        set
            name = v_name,
            description = v_description,
            brand_id = v_brand_id,
            category_id = v_category_id,
            supplier_id = v_supplier_id,
            tax_category = v_tax_category,
            tags = case when v_has_tags then v_tags else tags end,
            status = v_status,
            track_stock_levels = v_track_stock,
            low_stock_threshold = v_low_stock,
            published_at = case when v_status = 'active' and published_at is null then now() else published_at end,
            updated_at = now()
        where id = v_product_id and business_id = v_business_id
        returning * into v_result_product;

        if v_result_product is null then
            raise exception 'Product is not available';
        end if;
    else
        insert into public.products (
            business_id, name, description, brand_id, category_id, supplier_id,
            tax_category, tags, status, track_stock_levels, low_stock_threshold, published_at
        ) values (
            v_business_id, v_name, v_description, v_brand_id, v_category_id, v_supplier_id,
            v_tax_category, coalesce(v_tags, '{}'::text[]), v_status, v_track_stock, v_low_stock,
            case when v_status = 'active' then now() else null end
        )
        returning * into v_result_product;
        v_product_id := v_result_product.id;
    end if;

    if v_sku is not null or v_retail_price_cents > 0 or v_cost_price_cents > 0 then
        select id into v_variant_id
        from public.product_variants
        where product_id = v_product_id
        limit 1;

        if v_variant_id is not null then
            update public.product_variants
            set
                sku = coalesce(v_sku, sku),
                barcode = v_barcode,
                retail_price_cents = v_retail_price_cents,
                cost_price_cents = v_cost_price_cents,
                status = case when v_status = 'active' then 'active' else 'draft' end,
                updated_at = now()
            where id = v_variant_id;
        else
            insert into public.product_variants (
                product_id, sku, barcode, retail_price_cents, cost_price_cents, status
            ) values (
                v_product_id,
                coalesce(v_sku, 'TS-PRD-' || lpad(floor(random() * 100000)::text, 5, '0')),
                v_barcode,
                v_retail_price_cents,
                v_cost_price_cents,
                case when v_status = 'active' then 'active' else 'draft' end
            )
            returning id into v_variant_id;
        end if;

        -- Opening stock is initialization, including Save Draft then Publish.
        -- A draft may create the variant before any balance exists. Publish
        -- may initialize that variant once. Re-publishing must not add the
        -- quantity again. An existing balance or any ledger movement for
        -- this variant at this location blocks another opening stock write.
        -- Existing quantities are left unchanged.
        if v_status = 'active'
           and v_track_stock
           and v_opening_stock > 0
           and v_location_id is not null
           and not exists (
                select 1
                from public.inventory_balances
                where business_id = v_business_id
                  and location_id = v_location_id
                  and variant_id = v_variant_id
           )
           and not exists (
                select 1
                from public.inventory_ledger
                where business_id = v_business_id
                  and location_id = v_location_id
                  and variant_id = v_variant_id
           )
        then
            insert into public.inventory_balances (
                business_id, location_id, variant_id, available_qty
            ) values (
                v_business_id, v_location_id, v_variant_id, v_opening_stock
            );

            insert into public.inventory_ledger (
                business_id, location_id, variant_id, event_type, quantity_delta,
                reference_type, reference_id, source, metadata
            ) values (
                v_business_id, v_location_id, v_variant_id, 'stock_in', v_opening_stock,
                'opening_stock', v_product_id, 'manual',
                jsonb_build_object('note', 'Initial opening stock upon product publication')
            );
        end if;
    end if;

    return jsonb_build_object(
        'product', row_to_json(v_result_product),
        'variant_id', v_variant_id,
        'status', v_result_product.status
    );
end;
$$;

ALTER FUNCTION public.save_or_publish_product(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_or_publish_product(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_or_publish_product(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.save_or_publish_product(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.save_or_publish_product(jsonb) TO service_role;
