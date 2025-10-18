import 'package:compareitr/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    super.userId,
    super.imageUrl,
    super.actionUrl,
    required super.isRead,
    required super.createdAt,
    super.expiresAt,
  });

  // From JSON (Supabase response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      userId: json['user_id'] as String?,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  // To JSON (for creating/updating)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'user_id': userId,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // From Entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      userId: entity.userId,
      imageUrl: entity.imageUrl,
      actionUrl: entity.actionUrl,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
    );
  }

  // CopyWith for model
  NotificationModel copyWith({
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
    return NotificationModel(
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
}

