-- Add role column to profiles table
-- Run this in Supabase SQL Editor

-- Add role column to profiles table if it doesn't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'customer';

-- Add constraint for valid roles
ALTER TABLE profiles ADD CONSTRAINT IF NOT EXISTS check_role CHECK (role IN ('customer', 'driver', 'admin'));

-- Create index for better performance on role queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Update existing users to have 'customer' role (if they don't have a role set)
UPDATE profiles SET role = 'customer' WHERE role IS NULL;

