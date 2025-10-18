import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/theme/app_pallete.dart';
import 'package:compareitr/core/utils/show_snackbar.dart';
import 'package:compareitr/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:compareitr/features/notifications/presentation/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userState = context.read<AppUserCubit>().state;
    if (userState is AppUserLoggedIn) {
      // Start watching notifications (real-time updates)
      context.read<NotificationBloc>().add(
            WatchNotificationsEvent(userId: userState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && 
                  state.notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () {
                    final userState = context.read<AppUserCubit>().state;
                    if (userState is AppUserLoggedIn) {
                      context.read<NotificationBloc>().add(
                            MarkAllNotificationsAsReadEvent(
                              userId: userState.user.id,
                            ),
                          );
                    }
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: AppPallete.primaryColor),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationFailure) {
            showSnackBar(context, state.message);
          }
          if (state is NotificationActionSuccess) {
            showSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final userState = context.read<AppUserCubit>().state;
                if (userState is AppUserLoggedIn) {
                  context.read<NotificationBloc>().add(
                        GetNotificationsEvent(userId: userState.user.id),
                      );
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () {
                      if (!notification.isRead) {
                        context.read<NotificationBloc>().add(
                              MarkNotificationAsReadEvent(
                                notificationId: notification.id,
                              ),
                            );
                      }
                    },
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                            DeleteNotificationEvent(
                              notificationId: notification.id,
                            ),
                          );
                    },
                  );
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 100,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop watching notifications when leaving page
    context.read<NotificationBloc>().add(StopWatchingNotificationsEvent());
    super.dispose();
  }
}


