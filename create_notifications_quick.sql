-- =====================================================
-- QUICK SETUP: Create Notifications Table & Test Data
-- Copy and paste this into Supabase SQL Editor
-- =====================================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('order', 'promotion', 'system')),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  image_url TEXT,
  action_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create device_tokens table
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL UNIQUE,
  platform TEXT CHECK (platform IN ('android', 'ios')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- 4. Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for notifications
DROP POLICY IF EXISTS "Users can view own and global notifications" ON notifications;
CREATE POLICY "Users can view own and global notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
CREATE POLICY "Users can delete own notifications" 
ON notifications FOR DELETE 
USING (auth.uid() = user_id OR user_id IS NULL);

-- 6. RLS Policies for device_tokens
DROP POLICY IF EXISTS "Users can view own device tokens" ON device_tokens;
CREATE POLICY "Users can view own device tokens" 
ON device_tokens FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
CREATE POLICY "Users can insert own device tokens" 
ON device_tokens FOR INSERT 
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
CREATE POLICY "Users can update own device tokens" 
ON device_tokens FOR UPDATE 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;
CREATE POLICY "Users can delete own device tokens" 
ON device_tokens FOR DELETE 
USING (auth.uid() = user_id);

-- 7. Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- =====================================================
-- INSERT FIRST TEST NOTIFICATIONS
-- =====================================================

-- Welcome notification (visible to ALL users)
INSERT INTO notifications (title, message, type, user_id)
VALUES (
  '🎉 Welcome to CompareItr!',
  'Thank you for using our app. Start comparing prices and save money!',
  'system',
  NULL
);

-- Promotion notification (visible to ALL users)
INSERT INTO notifications (title, message, type, user_id)
VALUES (
  '🔥 Weekend Sale!',
  '50% off on selected items this weekend. Don''t miss out!',
  'promotion',
  NULL
);

-- System notification (visible to ALL users)
INSERT INTO notifications (title, message, type, user_id)
VALUES (
  '📢 New Feature Available',
  'Check out our new notifications feature! Stay updated on deals and orders.',
  'system',
  NULL
);

-- =====================================================
-- SUCCESS! You should now see 3 notifications in your app
-- =====================================================















