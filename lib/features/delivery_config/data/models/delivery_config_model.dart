import 'package:compareitr/features/delivery_config/domain/entities/delivery_config_entity.dart';

class DeliveryConfigModel extends DeliveryConfigEntity {
  const DeliveryConfigModel({
    required super.deliveryTimeMinutes,
    required super.lastUpdated,
  });

  factory DeliveryConfigModel.fromJson(Map<String, dynamic> json) {
    return DeliveryConfigModel(
      deliveryTimeMinutes: int.parse(json['setting_value'] ?? '90'),
      lastUpdated: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_time_minutes': deliveryTimeMinutes,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  DeliveryConfigEntity toEntity() {
    return DeliveryConfigEntity(
      deliveryTimeMinutes: deliveryTimeMinutes,
      lastUpdated: lastUpdated,
    );
  }
}





