import 'package:compareitr/features/shops/domain/entities/operating_hours_entity.dart';

class ShopEntity {
  final String shopName;
  final String shopLogoUrl;
  final String id;
  final String shopType;
  final OperatingHoursEntity? operatingHours;
  final double serviceFeePercentage;

  ShopEntity({
    required this.shopName,
    required this.shopLogoUrl,
    required this.id,
    required this.shopType,
    this.operatingHours,
    required this.serviceFeePercentage,
  });
}
