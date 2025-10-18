class DeliveryConfigEntity {
  final int deliveryTimeMinutes;
  final DateTime lastUpdated;

  const DeliveryConfigEntity({
    required this.deliveryTimeMinutes,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeliveryConfigEntity &&
        other.deliveryTimeMinutes == deliveryTimeMinutes &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return deliveryTimeMinutes.hashCode ^ lastUpdated.hashCode;
  }

  @override
  String toString() {
    return 'DeliveryConfigEntity(deliveryTimeMinutes: $deliveryTimeMinutes, lastUpdated: $lastUpdated)';
  }
}









