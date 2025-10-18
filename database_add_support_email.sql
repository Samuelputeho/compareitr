-- Add support_email setting to app_settings table
-- This script adds a new setting for the support email address

-- Insert support email setting into app_settings table
INSERT INTO app_settings (setting_key, setting_value, description) 
VALUES ('support_email', 'compareitr@gmail.com', 'Support email address for customer inquiries and complaints')
ON CONFLICT (setting_key) DO NOTHING;

-- Verify the insertion
SELECT * FROM app_settings WHERE setting_key = 'support_email';
