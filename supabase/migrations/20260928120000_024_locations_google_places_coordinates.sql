-- ==============================================================================
-- MIGRATION: 024_locations_google_places_coordinates.sql
-- DESCRIPTION: Prepared migration to persist Google Place metadata and geo-coordinates
--              for location map previews, geofencing, and delivery logistics.
-- STATUS: PREPARED ONLY — NOT DEPLOYED TO PRODUCTION YET.
-- ==============================================================================

-- 1. Add Google Places and Coordinate columns to public.locations
ALTER TABLE public.locations
  ADD COLUMN IF NOT EXISTS google_place_id TEXT NULL,
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION NULL,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION NULL,
  ADD COLUMN IF NOT EXISTS formatted_address TEXT NULL;

-- 2. Add sensible validation constraints for geo-coordinates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_locations_latitude'
  ) THEN
    ALTER TABLE public.locations
      ADD CONSTRAINT chk_locations_latitude
      CHECK (latitude IS NULL OR (latitude >= -90.0 AND latitude <= 90.0));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_locations_longitude'
  ) THEN
    ALTER TABLE public.locations
      ADD CONSTRAINT chk_locations_longitude
      CHECK (longitude IS NULL OR (longitude >= -180.0 AND longitude <= 180.0));
  END IF;
END $$;

-- 3. Add an index for quick lookup by Google Place ID
CREATE INDEX IF NOT EXISTS idx_locations_google_place_id 
  ON public.locations(google_place_id) 
  WHERE google_place_id IS NOT NULL;

-- 4. Document the schema additions
COMMENT ON COLUMN public.locations.google_place_id IS 'Unique Google Places identifier for place details and geocoding refresh.';
COMMENT ON COLUMN public.locations.latitude IS 'Geographical latitude coordinate (double precision, between -90 and 90).';
COMMENT ON COLUMN public.locations.longitude IS 'Geographical longitude coordinate (double precision, between -180 and 180).';
COMMENT ON COLUMN public.locations.formatted_address IS 'Full canonical address string returned from Google Places API.';
