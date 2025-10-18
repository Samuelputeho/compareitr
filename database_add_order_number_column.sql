-- =====================================================
-- Add order_number column to orders table
-- =====================================================
-- This keeps order_id as UUID (primary key)
-- And adds order_number as TEXT for customer-facing display

-- Step 1: Add the order_number column
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS order_number TEXT;

-- Step 2: Create a unique index on order_number
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_order_number 
ON orders(order_number);

-- Step 3: Update existing orders with temporary order numbers (optional)
-- This gives existing orders a number based on their creation order
WITH numbered_orders AS (
  SELECT 
    order_id,
    'C' || LPAD(ROW_NUMBER() OVER (ORDER BY order_date)::TEXT, 4, '0') as new_order_number
  FROM orders
  WHERE order_number IS NULL
)
UPDATE orders
SET order_number = numbered_orders.new_order_number
FROM numbered_orders
WHERE orders.order_id = numbered_orders.order_id;

-- =====================================================
-- Create the counter table and function
-- =====================================================

-- Create counter table
CREATE TABLE IF NOT EXISTS order_counter (
  id INTEGER PRIMARY KEY DEFAULT 1,
  counter INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set initial counter based on existing orders
INSERT INTO order_counter (id, counter)
SELECT 1, COALESCE(MAX(SUBSTRING(order_number FROM 2)::INTEGER), 0)
FROM orders
WHERE order_number LIKE 'C%'
ON CONFLICT (id) DO UPDATE
SET counter = EXCLUDED.counter;

-- Create function to get next order number
CREATE OR REPLACE FUNCTION get_next_order_number()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  next_number INTEGER;
BEGIN
  UPDATE order_counter
  SET counter = counter + 1,
      updated_at = NOW()
  WHERE id = 1
  RETURNING counter INTO next_number;
  
  RETURN next_number;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_next_order_number() TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_order_number() TO anon;

-- =====================================================
-- Verification
-- =====================================================
-- Check column was added:
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'orders' AND column_name = 'order_number';

-- See existing orders with their new numbers:
-- SELECT order_id, order_number, order_date FROM orders ORDER BY order_date;

-- Test the function:
-- SELECT get_next_order_number();

