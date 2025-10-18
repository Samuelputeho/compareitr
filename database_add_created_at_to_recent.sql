-- =====================================================
-- Add created_at column to recent table
-- Ensures oldest items are deleted first when limit is reached
-- =====================================================

-- Step 1: Add created_at column if it doesn't exist
ALTER TABLE recent 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 2: Update existing rows to have a timestamp
-- (Sets current time for existing items - they'll all have same time, but that's okay)
UPDATE recent 
SET created_at = NOW() 
WHERE created_at IS NULL;

-- Step 3: Create an index for faster ordering
CREATE INDEX IF NOT EXISTS idx_recent_created_at 
ON recent(created_at);

-- =====================================================
-- Verification
-- =====================================================
-- Check column was added:
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'recent' AND column_name = 'created_at';

-- See items ordered by creation time:
-- SELECT id, name, created_at FROM recent ORDER BY created_at;

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. New items added will automatically get current timestamp
-- 2. When fetching, items are ordered oldest first
-- 3. Auto-limit deletes items.first (oldest)
-- 4. Keeps the 20 most recently viewed products
-- =====================================================

