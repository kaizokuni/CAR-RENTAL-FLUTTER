ALTER TABLE landing_pages ADD COLUMN IF NOT EXISTS whatsapp_number VARCHAR(20);
ALTER TABLE landing_pages ADD COLUMN IF NOT EXISTS social_tiktok TEXT;
ALTER TABLE landing_pages ADD COLUMN IF NOT EXISTS is_live BOOLEAN DEFAULT false;
ALTER TABLE landing_pages ADD COLUMN IF NOT EXISTS selected_cars JSONB DEFAULT '[]'::jsonb;
ALTER TABLE landing_pages DROP COLUMN IF EXISTS social_twitter;
