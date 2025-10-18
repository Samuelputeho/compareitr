import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:compareitr/features/notifications/data/models/notification_model.dart';
import 'package:compareitr/features/notifications/domain/entities/notification_entity.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    required String userId,
  }) async {
    try {
      // First, check for cached notifications
      final box = Hive.box('recently_viewed'); // Use the same box as other cached data
      final cacheKey = 'notifications_$userId';
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final notifications = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return NotificationModel.fromJson(itemData);
        }).toList();
        
        if (notifications.isNotEmpty) {
          print('✅ Using cached notifications (${notifications.length} notifications)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(notifications);
          }
          
          // If online, continue to fetch fresh data below
        }
      }

      // If offline and no cached notifications, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached notifications available'));
      }

      final notifications = await remoteDataSource.getNotifications(
        userId: userId,
      );
      
      // Cache the fresh data
      final cacheData = notifications.map((notification) => notification.toJson()).toList();
      
      print('🔍 Repository: Caching notifications data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached notification: ${cacheData.first}');
      }
      
      box.put(cacheKey, cacheData);
      
      // Store notification images in Hive for offline use (non-blocking)
      _storeNotificationImagesInHive(notifications);
      
      print('✅ Notifications: Cached ${notifications.length} notifications');
      return right(notifications);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      final box = Hive.box('recently_viewed');
      final cacheKey = 'notifications_$userId';
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final notifications = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return NotificationModel.fromJson(itemData);
        }).toList();
        
        if (notifications.isNotEmpty) {
          print('✅ Server error, using cached notifications: ${e.message}');
          return right(notifications);
        }
      }
      return left(Failure(e.message));
    } catch (e) {
      // Check if it's a network-related error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') || errorMessage.contains('network') || errorMessage.contains('client')) {
        return left(Failure('Network connection error. Please check your internet connection.'));
      }
      return left(Failure('Failed to get notifications: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount({
    required String userId,
  }) async {
    try {
      final count = await remoteDataSource.getUnreadCount(userId: userId);
      return right(count);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to get unread count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String notificationId,
  }) async {
    try {
      await remoteDataSource.markAsRead(notificationId: notificationId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to mark as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead({
    required String userId,
  }) async {
    try {
      await remoteDataSource.markAllAsRead(userId: userId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to mark all as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification({
    required String notificationId,
  }) async {
    try {
      await remoteDataSource.deleteNotification(
        notificationId: notificationId,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to delete notification: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    try {
      await remoteDataSource.saveDeviceToken(
        userId: userId,
        token: token,
        platform: platform,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to save device token: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDeviceToken({
    required String token,
  }) async {
    try {
      await remoteDataSource.deleteDeviceToken(token: token);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Failed to delete device token: ${e.toString()}'));
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String userId,
  }) {
    try {
      return remoteDataSource.watchNotifications(userId: userId);
    } catch (e) {
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  // Store notification images as base64 in Hive for offline persistence
  Future<void> _storeNotificationImagesInHive(List<NotificationEntity> notifications) async {
    try {
      final box = Hive.box('recently_viewed');
      
      for (final notification in notifications) {
        final imageUrl = notification.imageUrl;
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'notificationImage_${notification.id.hashCode}';
              await box.put(imageKey, base64Image);
              print('🔔 Stored notification image: ${notification.title}');
            }
          } catch (e) {
            print('❌ Failed to store notification image ${notification.title}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing notification images in Hive: $e');
    }
  }
}

