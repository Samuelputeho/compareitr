-- =====================================================
-- NOTIFICATIONS FEATURE - DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('order', 'promotion', 'system')),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- NULL = all users
  image_url TEXT,
  action_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create device_tokens table for push notifications
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL UNIQUE,
  platform TEXT CHECK (platform IN ('android', 'ios')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(token);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies for notifications
-- Users can view their own notifications + global notifications (user_id IS NULL)
CREATE POLICY "Users can view own and global notifications" 
ON notifications FOR SELECT 
USING (
  auth.uid() = user_id OR user_id IS NULL
);

-- Users can update their own notifications (mark as read/delete)
CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id OR user_id IS NULL);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" 
ON notifications FOR DELETE 
USING (auth.uid() = user_id OR user_id IS NULL);

-- Admins can insert notifications (you'll do this via Supabase dashboard)
-- No policy needed - admins use service role key

-- 6. Create RLS Policies for device_tokens
-- Users can only view/manage their own device tokens
CREATE POLICY "Users can view own device tokens" 
ON device_tokens FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device tokens" 
ON device_tokens FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own device tokens" 
ON device_tokens FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own device tokens" 
ON device_tokens FOR DELETE 
USING (auth.uid() = user_id);

-- 7. Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_device_token_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS update_device_tokens_updated_at ON device_tokens;
CREATE TRIGGER update_device_tokens_updated_at
BEFORE UPDATE ON device_tokens
FOR EACH ROW
EXECUTE FUNCTION update_device_token_timestamp();

-- 9. Enable Realtime for notifications (for instant updates in app)
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert a global notification (visible to all users)
-- INSERT INTO notifications (title, message, type, user_id)
-- VALUES (
--   'Welcome to CompareItr!',
--   'Thank you for using our app. Check out our latest deals!',
--   'system',
--   NULL  -- NULL means all users will see this
-- );

-- =====================================================
-- ADMIN QUICK REFERENCE - How to Send Notifications
-- =====================================================

-- Send to ALL users:
-- INSERT INTO notifications (title, message, type, user_id)
-- VALUES ('New Sale!', '50% off this weekend!', 'promotion', NULL);

-- Send to SPECIFIC user:
-- INSERT INTO notifications (title, message, type, user_id)
-- VALUES ('Order Ready', 'Your order #123 is ready', 'order', 'user-uuid-here');

-- View all notifications:
-- SELECT * FROM notifications ORDER BY created_at DESC;

-- Delete old notifications (older than 30 days):
-- DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days';

-- =====================================================
-- CLEANUP (if needed)
-- =====================================================
-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS device_tokens CASCADE;







