import 'dart:async';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/features/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({required String userId});
  Future<int> getUnreadCount({required String userId});
  Future<void> markAsRead({required String notificationId});
  Future<void> markAllAsRead({required String userId});
  Future<void> deleteNotification({required String notificationId});
  Future<void> saveDeviceToken({
    required String userId,
    required String token,
    required String platform,
  });
  Future<void> deleteDeviceToken({required String token});
  Stream<List<NotificationModel>> watchNotifications({required String userId});
}

class NotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  NotificationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
  }) async {
    try {
      print('🔍 Notifications: Fetching from remote data source for user: $userId');
      final response = await supabaseClient
          .from('notifications')
          .select()
          .or('user_id.eq.$userId,user_id.is.null') // User's or global notifications
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout

      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      print('✅ Notifications: Successfully fetched ${notifications.length} notifications from remote');
      return notifications;
    } on PostgrestException catch (e) {
      print('❌ Notifications: PostgrestException - ${e.message}');
      throw ServerException('Failed to fetch notifications: ${e.message}');
    } on TimeoutException {
      print('❌ Notifications: TimeoutException - Request timed out');
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print('❌ Notifications: Unexpected error - $e');
      throw ServerException('Failed to fetch notifications: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadCount({required String userId}) async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw ServerException('Failed to get unread count: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    try {
      await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException('Failed to mark as read: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead({required String userId}) async {
    try {
      await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .or('user_id.eq.$userId,user_id.is.null')
          .eq('is_read', false);
    } catch (e) {
      throw ServerException('Failed to mark all as read: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNotification({required String notificationId}) async {
    try {
      await supabaseClient
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException('Failed to delete notification: ${e.toString()}');
    }
  }

  @override
  Future<void> saveDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    try {
      // Upsert: insert if not exists, update if exists
      await supabaseClient.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      throw ServerException('Failed to save device token: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteDeviceToken({required String token}) async {
    try {
      await supabaseClient
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (e) {
      throw ServerException('Failed to delete device token: ${e.toString()}');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications({
    required String userId,
  }) {
    try {
      return supabaseClient
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) {
            // Filter for user's notifications and global ones
            final filtered = data.where((json) {
              final notifUserId = json['user_id'];
              return notifUserId == null || notifUserId == userId;
            }).toList();

            return filtered
                .map((json) => NotificationModel.fromJson(json))
                .toList();
          });
    } catch (e) {
      throw ServerException(
          'Failed to watch notifications: ${e.toString()}');
    }
  }
}

