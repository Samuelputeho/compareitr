import '../entities/shop_entity.dart';
import 'package:compareitr/features/shops/data/models/operating_hours_model.dart';

class ShopModel extends ShopEntity {
  ShopModel({
    required super.shopName,
    required super.shopLogoUrl,
    required super.id,
    required super.shopType,
    super.operatingHours,
    required super.serviceFeePercentage,
  });

// from json
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      shopName: json['shopName'] as String? ?? '',
      shopLogoUrl: json['shopLogoUrl'] as String? ?? '',
      id: json['id'] as String? ?? '',
      shopType: json['shopType'] as String? ?? '',
      operatingHours: json['operating_hours'] != null 
          ? OperatingHoursModel.fromJson(json['operating_hours']).toEntity()
          : null,
      serviceFeePercentage: (json['service_fee_percentage'] as num?)?.toDouble() ?? 15.0, // Default to 15%
    );
  }
}
