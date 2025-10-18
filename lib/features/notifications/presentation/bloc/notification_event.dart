part of 'notification_bloc.dart';

@immutable
sealed class NotificationEvent {}

// Get notifications for user
final class GetNotificationsEvent extends NotificationEvent {
  final String userId;

  GetNotificationsEvent({required this.userId});
}

// Get unread count
final class GetUnreadCountEvent extends NotificationEvent {
  final String userId;

  GetUnreadCountEvent({required this.userId});
}

// Mark notification as read
final class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  MarkNotificationAsReadEvent({required this.notificationId});
}

// Mark all as read
final class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  final String userId;

  MarkAllNotificationsAsReadEvent({required this.userId});
}

// Delete notification
final class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  DeleteNotificationEvent({required this.notificationId});
}

// Save device token (for push notifications)
final class SaveDeviceTokenEvent extends NotificationEvent {
  final String userId;
  final String token;
  final String platform;

  SaveDeviceTokenEvent({
    required this.userId,
    required this.token,
    required this.platform,
  });
}

// Start watching notifications (real-time)
final class WatchNotificationsEvent extends NotificationEvent {
  final String userId;

  WatchNotificationsEvent({required this.userId});
}

// Stop watching notifications
final class StopWatchingNotificationsEvent extends NotificationEvent {}

