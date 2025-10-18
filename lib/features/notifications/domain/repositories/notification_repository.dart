import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/notifications/domain/entities/notification_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class NotificationRepository {
  // Get all notifications for current user (including global ones)
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    required String userId,
  });

  // Get unread notifications count
  Future<Either<Failure, int>> getUnreadCount({
    required String userId,
  });

  // Mark notification as read
  Future<Either<Failure, void>> markAsRead({
    required String notificationId,
  });

  // Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead({
    required String userId,
  });

  // Delete notification
  Future<Either<Failure, void>> deleteNotification({
    required String notificationId,
  });

  // Save device token for push notifications
  Future<Either<Failure, void>> saveDeviceToken({
    required String userId,
    required String token,
    required String platform,
  });

  // Delete device token (when user logs out)
  Future<Either<Failure, void>> deleteDeviceToken({
    required String token,
  });

  // Stream notifications (real-time updates)
  Stream<List<NotificationEntity>> watchNotifications({
    required String userId,
  });
}

