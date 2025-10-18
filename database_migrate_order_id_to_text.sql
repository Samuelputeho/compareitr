-- =====================================================
-- Migration: Change order_id from UUID to TEXT
-- This allows C0001 format order numbers
-- =====================================================

-- IMPORTANT: Run this in Supabase SQL Editor

-- Step 1: Alter the order_id column to TEXT type
ALTER TABLE orders 
ALTER COLUMN order_id TYPE TEXT;

-- Step 2: If there are any foreign key constraints referencing order_id, 
-- you may need to update those tables as well
-- (Check your schema for any tables that reference orders.order_id)

-- =====================================================
-- Verification
-- =====================================================
-- Check the column type has changed:
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'order_id';
-- Should show: order_id | text

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. This migration is SAFE - existing UUID values stay as text
-- 2. Old orders with UUID format: "3a7f571d-28e0-4896-bfc7..."
-- 3. New orders with C format: "C0001", "C0002", etc.
-- 4. Both formats work together in the TEXT column
-- 5. No data loss - all existing orders remain unchanged
-- =====================================================

