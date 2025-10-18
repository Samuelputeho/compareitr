-- Add service_fee_percentage column to shops table
ALTER TABLE shops ADD COLUMN service_fee_percentage DECIMAL(5,2) DEFAULT 15.00;

-- Add constraint for valid percentage (0-100%)
ALTER TABLE shops ADD CONSTRAINT check_service_fee_percentage 
CHECK (service_fee_percentage >= 0 AND service_fee_percentage <= 100);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_shops_service_fee_percentage ON shops(service_fee_percentage);

-- Add fallback setting in app_settings
INSERT INTO app_settings (setting_key, setting_value, description) 
VALUES ('default_service_fee_percentage', '15.0', 'Default service fee percentage for shops without specific setting')
ON CONFLICT (setting_key) DO NOTHING;

