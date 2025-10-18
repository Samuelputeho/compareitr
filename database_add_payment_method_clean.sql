-- Add payment_method column to orders table
ALTER TABLE orders ADD COLUMN payment_method TEXT;

-- Update existing orders with default payment method
UPDATE orders SET payment_method = 'cash' WHERE payment_method IS NULL;

-- Make payment_method NOT NULL
ALTER TABLE orders ALTER COLUMN payment_method SET NOT NULL;

-- Add constraint for valid payment methods
ALTER TABLE orders ADD CONSTRAINT check_payment_method CHECK (payment_method IN ('cash', 'speedpoint', 'card', 'apple_pay', 'google_pay'));

-- Create index for performance
CREATE INDEX idx_orders_payment_method ON orders(payment_method);

