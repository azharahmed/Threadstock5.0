-- ThreadStock onboarding Step 4 inventory start method metadata.
-- Selection is not inventory; this only persists how the merchant chose to begin.

alter table public.onboarding_sessions
    add column if not exists inventory_start_method text
        check (
            inventory_start_method is null
            or inventory_start_method in ('manual', 'file_import', 'shopify')
        );

comment on column public.onboarding_sessions.inventory_start_method is
    'Onboarding Step 4 selection: manual | file_import | shopify. Null until chosen.';
