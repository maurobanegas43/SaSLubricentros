-- +goose Up
-- Add image_url column to vehicles table for persistent image storage
ALTER TABLE vehicles
ADD COLUMN IF NOT EXISTS image_url VARCHAR(500) DEFAULT NULL;

COMMENT ON COLUMN vehicles.image_url IS 'URL to the vehicle image stored in Supabase Storage';

-- +goose Down
-- Remove image_url column
ALTER TABLE vehicles
DROP COLUMN IF EXISTS image_url;
