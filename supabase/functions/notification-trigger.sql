-- =====================================================
-- NOTIFICATION TRIGGER FOR PUSH NOTIFICATIONS
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Create a function that calls the Edge Function
CREATE OR REPLACE FUNCTION send_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  payload JSON;
BEGIN
  -- Prepare the notification payload
  payload := json_build_object(
    'notification', json_build_object(
      'id', NEW.id,
      'title', NEW.title,
      'message', NEW.message,
      'type', NEW.type,
      'user_id', NEW.user_id,
      'image_url', NEW.image_url,
      'action_url', NEW.action_url
    )
  );

  -- Call the Edge Function asynchronously
  PERFORM net.http_post(
    url := current_setting('app.settings.edge_function_url') || '/functions/v1/send-push-notification',
    headers := json_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := payload
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Create the trigger that fires after notification insertion
DROP TRIGGER IF EXISTS trigger_send_push_notification ON notifications;
CREATE TRIGGER trigger_send_push_notification
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION send_push_notification();

-- 3. Set the required settings (you'll need to update these with your actual values)
-- ALTER DATABASE postgres SET app.settings.edge_function_url = 'https://your-project-ref.supabase.co';
-- ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';

-- =====================================================
-- ALTERNATIVE SIMPLER APPROACH (Recommended)
-- =====================================================

-- Instead of using triggers, you can manually call the Edge Function
-- from your app when creating notifications. This gives you more control.

-- Example usage from your app:
-- 
-- 1. Create notification in database
-- 2. Call the Edge Function to send push notification
--
-- const response = await fetch('https://your-project.supabase.co/functions/v1/send-push-notification', {
--   method: 'POST',
--   headers: {
--     'Authorization': 'Bearer your-anon-key',
--     'Content-Type': 'application/json',
--   },
--   body: JSON.stringify({
--     notification: {
--       id: 'notification-id',
--       title: 'Your Title',
--       message: 'Your Message',
--       type: 'system',
--       user_id: 'user-id-or-null-for-all-users',
--       image_url: 'optional-image-url',
--       action_url: 'optional-action-url'
--     }
--   })
-- });
