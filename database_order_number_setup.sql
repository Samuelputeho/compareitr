-- =====================================================
-- Setup for Custom Order Numbers (C0001, C0002, etc.)
-- =====================================================

-- Step 1: Create a table to store the order counter
CREATE TABLE IF NOT EXISTS order_counter (
  id INTEGER PRIMARY KEY DEFAULT 1,
  counter INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Insert initial counter value (if not exists)
INSERT INTO order_counter (id, counter)
VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create function to get next order number
-- This function atomically increments the counter and returns it
CREATE OR REPLACE FUNCTION get_next_order_number()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  next_number INTEGER;
BEGIN
  -- Atomically increment and return the counter
  UPDATE order_counter
  SET counter = counter + 1,
      updated_at = NOW()
  WHERE id = 1
  RETURNING counter INTO next_number;
  
  RETURN next_number;
END;
$$;

-- Step 4: Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_next_order_number() TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_order_number() TO anon;

-- =====================================================
-- Test the function (optional)
-- =====================================================
-- SELECT get_next_order_number();  -- Should return 1
-- SELECT get_next_order_number();  -- Should return 2
-- SELECT get_next_order_number();  -- Should return 3

-- To check current counter value:
-- SELECT * FROM order_counter;

-- To reset counter to specific number (if needed):
-- UPDATE order_counter SET counter = 0 WHERE id = 1;

-- =====================================================
-- IMPORTANT NOTES:
-- =====================================================
-- 1. This function is ATOMIC - safe for concurrent use
-- 2. Multiple users placing orders simultaneously will get unique numbers
-- 3. Numbers are sequential: 1, 2, 3, 4...
-- 4. Your app formats them as: C0001, C0002, C0003, C0004...
-- 5. The counter never resets automatically
-- 6. If you delete orders, numbers won't be reused (by design)

