-- =====================================================
-- Simple version: Add payment_method column to orders table
-- =====================================================

-- Step 1: Add the payment_method column
ALTER TABLE orders 
ADD COLUMN payment_method TEXT;

-- Step 2: Update existing orders with default payment method
UPDATE orders 
SET payment_method = 'cash' 
WHERE payment_method IS NULL;

-- Step 3: Make payment_method NOT NULL after setting defaults
ALTER TABLE orders 
ALTER COLUMN payment_method SET NOT NULL;

-- Step 4: Add constraint to ensure valid payment methods
ALTER TABLE orders 
ADD CONSTRAINT check_payment_method 
CHECK (payment_method IN ('cash', 'speedpoint', 'card', 'apple_pay', 'google_pay'));

-- Step 5: Create index for faster queries on payment method
CREATE INDEX idx_orders_payment_method 
ON orders(payment_method);

-- =====================================================
-- Verification (run these to check the results)
-- =====================================================

-- Check that all orders have payment_method set
-- SELECT COUNT(*) FROM orders WHERE payment_method IS NULL;

-- Check payment method distribution
-- SELECT payment_method, COUNT(*) as order_count 
-- FROM orders 
-- GROUP BY payment_method 
-- ORDER BY order_count DESC;

