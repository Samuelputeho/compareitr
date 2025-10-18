# 🔔 PUSH NOTIFICATIONS SETUP GUIDE

## 🎯 Overview

Your app now has complete push notification infrastructure! When you create notifications in Supabase, users will receive push notifications on their devices (even when the app is closed).

## ✅ What's Already Working

- ✅ Firebase FCM initialized
- ✅ Device tokens generated and saved to Supabase
- ✅ In-app notifications working via Supabase Realtime
- ✅ Edge Function created (`send-push-notification`)
- ✅ Database schema ready

## 🚀 Setup Steps

### Step 1: Get Your Firebase Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Click **Cloud Messaging** tab
5. Copy your **Server Key** (looks like: `AAAA...`)

### Step 2: Deploy the Edge Function

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project**:
   ```bash
   supabase link --project-ref your-project-ref
   ```

4. **Set the FCM Server Key**:
   ```bash
   supabase secrets set FCM_SERVER_KEY=your-firebase-server-key-here
   ```

5. **Deploy the Edge Function**:
   ```bash
   supabase functions deploy send-push-notification
   ```

### Step 3: Test Push Notifications

#### Option A: Manual Test via Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Functions**
3. Find `send-push-notification` function
4. Click **Invoke** and use this test payload:

```json
{
  "notification": {
    "id": "test-123",
    "title": "Test Push Notification",
    "message": "This is a test push notification!",
    "type": "system",
    "user_id": null,
    "image_url": null,
    "action_url": null
  }
}
```

#### Option B: Test via SQL (Send to All Users)

```sql
-- Insert a notification that will trigger push notifications
INSERT INTO notifications (title, message, type, user_id)
VALUES (
  '🔥 New Feature!', 
  'Check out our amazing new feature!', 
  'promotion', 
  NULL  -- NULL = send to all users
);
```

#### Option C: Test via SQL (Send to Specific User)

```sql
-- Replace 'user-uuid-here' with an actual user ID
INSERT INTO notifications (title, message, type, user_id)
VALUES (
  '📦 Order Update', 
  'Your order is ready for pickup!', 
  'order', 
  'user-uuid-here'
);
```

## 🧪 Expected Results

### ✅ Success Indicators:
- Console shows: `✅ Push sent to android user user-id`
- Users receive push notifications on their devices
- Notifications appear in the app's notification list

### ❌ Troubleshooting:

**No push notifications received:**
1. Check FCM Server Key is correct
2. Verify device token is saved in `device_tokens` table
3. Check Edge Function logs in Supabase dashboard
4. Ensure app has notification permissions

**Edge Function errors:**
1. Check Supabase logs: **Functions** → **Logs**
2. Verify `FCM_SERVER_KEY` secret is set
3. Check device token format in database

## 📱 How It Works

1. **User logs in** → Device token saved to `device_tokens` table
2. **You create notification** → Inserted into `notifications` table
3. **Edge Function triggered** → Fetches device tokens and sends via FCM
4. **User receives push** → Notification appears on device (even when app closed)
5. **User opens app** → Notification also appears in-app

## 🎛️ Notification Types

Your app supports 3 notification types with different colors:

- 🛍️ **`order`** - Blue (order updates, delivery status)
- 🔥 **`promotion`** - Orange (sales, special offers)
- ⚙️ **`system`** - Purple (app updates, maintenance)

## 🔧 Advanced Usage

### Send to Specific User:
```json
{
  "notification": {
    "title": "Personal Message",
    "message": "This is just for you!",
    "type": "system",
    "user_id": "specific-user-uuid"
  }
}
```

### Send to All Users:
```json
{
  "notification": {
    "title": "App Update",
    "message": "New version available!",
    "type": "system",
    "user_id": null
  }
}
```

### With Image and Action:
```json
{
  "notification": {
    "title": "Special Offer!",
    "message": "50% off everything!",
    "type": "promotion",
    "user_id": null,
    "image_url": "https://example.com/sale-image.jpg",
    "action_url": "https://yourapp.com/sale"
  }
}
```

## 🎉 You're All Set!

Your push notifications are now fully functional! Users will receive notifications on their devices whenever you create them in Supabase.

**Next time you create a notification, users will get both:**
- ✅ **Push notification** (when app is closed)
- ✅ **In-app notification** (when app is open)

Happy notifying! 🔔
