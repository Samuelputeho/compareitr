import 'dart:async';

import 'package:compareitr/features/notifications/domain/entities/notification_entity.dart';
import 'package:compareitr/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/save_device_token_usecase.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:compareitr/features/notifications/data/models/notification_model.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final MarkAllAsReadUseCase _markAllAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final SaveDeviceTokenUseCase _saveDeviceTokenUseCase;
  final NotificationRepository _notificationRepository;

  StreamSubscription<List<NotificationEntity>>? _notificationSubscription;
  String? _currentUserId;

  NotificationBloc({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required MarkAllAsReadUseCase markAllAsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required SaveDeviceTokenUseCase saveDeviceTokenUseCase,
    required NotificationRepository notificationRepository,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _markAsReadUseCase = markAsReadUseCase,
        _markAllAsReadUseCase = markAllAsReadUseCase,
        _deleteNotificationUseCase = deleteNotificationUseCase,
        _saveDeviceTokenUseCase = saveDeviceTokenUseCase,
        _notificationRepository = notificationRepository,
        super(NotificationInitial()) {
    on<NotificationEvent>((_, emit) => emit(NotificationLoading()));
    on<GetNotificationsEvent>(_onGetNotifications);
    on<GetUnreadCountEvent>(_onGetUnreadCount);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<SaveDeviceTokenEvent>(_onSaveDeviceToken);
    on<WatchNotificationsEvent>(_onWatchNotifications);
    on<StopWatchingNotificationsEvent>(_onStopWatchingNotifications);
  }

  void _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    // First, check for cached notifications in Hive
    final box = Hive.box('recently_viewed');
    final cacheKey = 'notifications_${event.userId}';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 NotificationBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedNotifications = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 NotificationBloc: Parsing cached notification: ${itemData['id']}');
        return NotificationModel.fromJson(itemData);
      }).toList();
      
      if (cachedNotifications.isNotEmpty) {
        print('✅ NotificationBloc: Using cached notifications (${cachedNotifications.length} notifications)');
        print('🔍 NotificationBloc: First notification: ${cachedNotifications.first.title}');
        emit(NotificationsLoaded(
          notifications: cachedNotifications,
          unreadCount: cachedNotifications.where((n) => !n.isRead).length,
        ));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }

    final notificationsResult = await _getNotificationsUseCase(
      GetNotificationsParams(userId: event.userId),
    );

    await notificationsResult.fold(
      (failure) async {
        // If server error, try to use cached data as fallback
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedNotifications = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return NotificationModel.fromJson(itemData);
          }).toList();
          
          if (cachedNotifications.isNotEmpty) {
            print('✅ NotificationBloc: Server error, using cached notifications (${cachedNotifications.length} notifications)');
            emit(NotificationsLoaded(
              notifications: cachedNotifications,
              unreadCount: cachedNotifications.where((n) => !n.isRead).length,
            ));
            return;
          }
        }
        
        emit(NotificationFailure(message: failure.message));
      },
      (notifications) async {
        // Also get unread count
        final countResult = await _getUnreadCountUseCase(event.userId);
        final unreadCount = countResult.fold(
          (failure) => 0,
          (count) => count,
        );

        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      },
    );
  }

  void _onGetUnreadCount(
    GetUnreadCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _getUnreadCountUseCase(event.userId);

    result.fold(
      (failure) => emit(NotificationFailure(message: failure.message)),
      (count) => emit(NotificationUnreadCountUpdated(unreadCount: count)),
    );
  }

  void _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _markAsReadUseCase(event.notificationId);

    await result.fold(
      (failure) async => emit(NotificationFailure(message: failure.message)),
      (_) async {
        // Refresh notifications if we have a user ID
        if (_currentUserId != null) {
          add(GetNotificationsEvent(userId: _currentUserId!));
        }
      },
    );
  }

  void _onMarkAllAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _markAllAsReadUseCase(event.userId);

    await result.fold(
      (failure) async => emit(NotificationFailure(message: failure.message)),
      (_) async {
        emit(const NotificationActionSuccess(
          message: 'All notifications marked as read',
        ));
        // Refresh notifications
        add(GetNotificationsEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _deleteNotificationUseCase(event.notificationId);

    await result.fold(
      (failure) async => emit(NotificationFailure(message: failure.message)),
      (_) async {
        // Refresh notifications if we have a user ID
        if (_currentUserId != null) {
          add(GetNotificationsEvent(userId: _currentUserId!));
        }
      },
    );
  }

  void _onSaveDeviceToken(
    SaveDeviceTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _saveDeviceTokenUseCase(
      SaveDeviceTokenParams(
        userId: event.userId,
        token: event.token,
        platform: event.platform,
      ),
    );

    result.fold(
      (failure) {
        print('Failed to save device token: ${failure.message}');
      },
      (_) {
        print('Device token saved successfully');
      },
    );
  }

  void _onWatchNotifications(
    WatchNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    _currentUserId = event.userId;
    
    // For now, just do a regular fetch
    // Real-time will be added later to avoid Bloc complexity
    add(GetNotificationsEvent(userId: event.userId));
  }

  void _onStopWatchingNotifications(
    StopWatchingNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}

