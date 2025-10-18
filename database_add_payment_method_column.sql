-- =====================================================
-- Add payment_method column to orders table
-- =====================================================
-- This adds payment method tracking for orders
-- Valid values: cash, speedpoint, card, apple_pay, google_pay

-- Step 1: Add the payment_method column
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- Step 2: Add constraint to ensure valid payment methods
ALTER TABLE orders 
ADD CONSTRAINT check_payment_method 
CHECK (payment_method IN ('cash', 'speedpoint', 'card', 'apple_pay', 'google_pay'));

-- Step 3: Update existing orders with default payment method
-- Set existing orders to 'cash' as default (most common method)
UPDATE orders 
SET payment_method = 'cash' 
WHERE payment_method IS NULL;

-- Step 4: Make payment_method NOT NULL after setting defaults
ALTER TABLE orders 
ALTER COLUMN payment_method SET NOT NULL;

-- Step 5: Create index for faster queries on payment method
CREATE INDEX IF NOT EXISTS idx_orders_payment_method 
ON orders(payment_method);

-- =====================================================
-- Verification Queries (Optional - for testing)
-- =====================================================

-- Check that all orders have payment_method set
-- SELECT COUNT(*) FROM orders WHERE payment_method IS NULL;

-- Check payment method distribution
-- SELECT payment_method, COUNT(*) as order_count 
-- FROM orders 
-- GROUP BY payment_method 
-- ORDER BY order_count DESC;

-- =====================================================
-- IMPORTANT NOTES:
-- =====================================================
-- 1. This migration is backward compatible
-- 2. Existing orders will default to 'cash' payment method
-- 3. New orders will require payment_method to be specified
-- 4. The constraint ensures only valid payment methods are stored
-- 5. Index improves performance for payment method analytics
