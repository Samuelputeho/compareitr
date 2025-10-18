class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final String type; // 'order', 'promotion', 'system'
  final String? userId; // null = all users
  final String? imageUrl;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    this.imageUrl,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
    this.expiresAt,
  });

  // Copy with method for updating properties
  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? userId,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Check if notification is global (for all users)
  bool get isGlobal => userId == null;

  // Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Get notification icon based on type
  String get iconName {
    switch (type) {
      case 'order':
        return 'shopping_bag';
      case 'promotion':
        return 'local_offer';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }
}

