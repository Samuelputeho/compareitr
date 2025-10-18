-- Insert delivery fee setting into app_settings table
INSERT INTO app_settings (setting_key, setting_value, description) 
VALUES ('delivery_fee', '60.0', 'Delivery fee per shop in Namibian Dollars')
ON CONFLICT (setting_key) DO UPDATE SET 
    setting_value = EXCLUDED.setting_value,
    description = EXCLUDED.description;

-- Verify the insertion
SELECT * FROM app_settings WHERE setting_key = 'delivery_fee';

