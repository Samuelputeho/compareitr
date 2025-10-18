part of 'notification_bloc.dart';

@immutable
sealed class NotificationState {
  const NotificationState();
}

final class NotificationInitial extends NotificationState {}

final class NotificationLoading extends NotificationState {}

final class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

final class NotificationUnreadCountUpdated extends NotificationState {
  final int unreadCount;

  const NotificationUnreadCountUpdated({required this.unreadCount});
}

final class NotificationActionSuccess extends NotificationState {
  final String message;

  const NotificationActionSuccess({required this.message});
}

final class NotificationFailure extends NotificationState {
  final String message;

  const NotificationFailure({required this.message});
}

// State for real-time updates
final class NotificationsUpdating extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsUpdating({
    required this.notifications,
    required this.unreadCount,
  });
}


