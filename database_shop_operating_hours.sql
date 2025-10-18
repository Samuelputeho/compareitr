-- Add operating hours JSON column to shops table
ALTER TABLE shops ADD COLUMN IF NOT EXISTS operating_hours JSONB;

-- Create an index on operating_hours for better performance
CREATE INDEX IF NOT EXISTS idx_shops_operating_hours ON shops USING GIN (operating_hours);

-- Insert sample operating hours data for existing shops
-- Update shops with default operating hours (Monday-Friday: 8AM-6PM, Saturday: 9AM-5PM, Sunday: Closed)
UPDATE shops 
SET operating_hours = '{
  "monday": {"open": "08:00", "close": "18:00", "is_open": true},
  "tuesday": {"open": "08:00", "close": "18:00", "is_open": true},
  "wednesday": {"open": "08:00", "close": "18:00", "is_open": true},
  "thursday": {"open": "08:00", "close": "18:00", "is_open": true},
  "friday": {"open": "08:00", "close": "18:00", "is_open": true},
  "saturday": {"open": "09:00", "close": "17:00", "is_open": true},
  "sunday": {"open": null, "close": null, "is_open": false}
}'::jsonb
WHERE operating_hours IS NULL;

-- Example: Update a specific shop with custom hours
-- UPDATE shops 
-- SET operating_hours = '{
--   "monday": {"open": "07:00", "close": "20:00", "is_open": true},
--   "tuesday": {"open": "07:00", "close": "20:00", "is_open": true},
--   "wednesday": {"open": "07:00", "close": "20:00", "is_open": true},
--   "thursday": {"open": "07:00", "close": "20:00", "is_open": true},
--   "friday": {"open": "07:00", "close": "21:00", "is_open": true},
--   "saturday": {"open": "08:00", "close": "22:00", "is_open": true},
--   "sunday": {"open": "10:00", "close": "18:00", "is_open": true}
-- }'::jsonb
-- WHERE shopname = 'Your Shop Name';

-- Create a function to check if a shop is currently open
CREATE OR REPLACE FUNCTION is_shop_open(shop_operating_hours JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    day_name TEXT;
    today_hours JSONB;
    current_time TIME;
    open_time TIME;
    close_time TIME;
BEGIN
    -- Get current day name (lowercase)
    day_name := LOWER(TO_CHAR(NOW(), 'DAY'));
    day_name := TRIM(day_name);
    
    -- Get today's hours from JSON
    today_hours := shop_operating_hours->day_name;
    
    -- Check if shop is open today
    IF (today_hours->>'is_open')::BOOLEAN = false THEN
        RETURN FALSE;
    END IF;
    
    -- Get current time
    current_time := CURRENT_TIME;
    
    -- Parse open and close times
    BEGIN
        open_time := (today_hours->>'open')::TIME;
        close_time := (today_hours->>'close')::TIME;
    EXCEPTION WHEN OTHERS THEN
        RETURN FALSE;
    END;
    
    -- Check if current time is within operating hours
    RETURN current_time >= open_time AND current_time <= close_time;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get next opening time
CREATE OR REPLACE FUNCTION get_next_opening_time(shop_operating_hours JSONB)
RETURNS TEXT AS $$
DECLARE
    day_names TEXT[] := ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    current_day INTEGER;
    i INTEGER;
    check_day INTEGER;
    day_name TEXT;
    day_hours JSONB;
    open_time TEXT;
    result TEXT;
BEGIN
    current_day := EXTRACT(DOW FROM NOW());
    IF current_day = 0 THEN current_day := 7; END IF; -- Convert Sunday from 0 to 7
    
    -- Check today first
    day_name := day_names[current_day];
    day_hours := shop_operating_hours->day_name;
    
    IF (day_hours->>'is_open')::BOOLEAN = true THEN
        open_time := day_hours->>'open';
        IF open_time IS NOT NULL THEN
            -- Check if we haven't passed opening time today
            IF CURRENT_TIME < open_time::TIME THEN
                RETURN INITCAP(day_name) || ' at ' || open_time;
            END IF;
        END IF;
    END IF;
    
    -- Check next 6 days
    FOR i IN 1..6 LOOP
        check_day := (current_day + i - 1) % 7 + 1;
        day_name := day_names[check_day];
        day_hours := shop_operating_hours->day_name;
        
        IF (day_hours->>'is_open')::BOOLEAN = true THEN
            open_time := day_hours->>'open';
            IF open_time IS NOT NULL THEN
                RETURN INITCAP(day_name) || ' at ' || open_time;
            END IF;
        END IF;
    END LOOP;
    
    RETURN 'Closed indefinitely';
END;
$$ LANGUAGE plpgsql;

-- Example queries to test the functions:

-- Check if a shop is currently open
-- SELECT shopname, is_shop_open(operating_hours) as is_open
-- FROM shops 
-- WHERE shopname = 'Your Shop Name';

-- Get next opening time for a shop
-- SELECT shopname, get_next_opening_time(operating_hours) as next_opening
-- FROM shops 
-- WHERE shopname = 'Your Shop Name';

-- Get all currently open shops
-- SELECT shopname, operating_hours->LOWER(TO_CHAR(NOW(), 'DAY')) as today_hours
-- FROM shops 
-- WHERE is_shop_open(operating_hours) = true;









