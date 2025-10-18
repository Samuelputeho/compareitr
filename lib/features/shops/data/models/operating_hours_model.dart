import 'package:compareitr/features/shops/domain/entities/operating_hours_entity.dart';

class DayHoursModel extends DayHoursEntity {
  const DayHoursModel({
    required super.openTime,
    required super.closeTime,
    required super.isOpen,
  });

  factory DayHoursModel.fromJson(Map<String, dynamic> json) {
    return DayHoursModel(
      openTime: json['open'],
      closeTime: json['close'],
      isOpen: json['is_open'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': openTime,
      'close': closeTime,
      'is_open': isOpen,
    };
  }
}

class OperatingHoursModel extends OperatingHoursEntity {
  const OperatingHoursModel({
    required super.weeklyHours,
  });

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    final weeklyHours = <String, DayHoursEntity>{};
    
    for (final entry in json.entries) {
      weeklyHours[entry.key] = DayHoursModel.fromJson(entry.value);
    }
    
    return OperatingHoursModel(weeklyHours: weeklyHours);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    for (final entry in weeklyHours.entries) {
      result[entry.key] = (entry.value as DayHoursModel).toJson();
    }
    return result;
  }

  OperatingHoursEntity toEntity() {
    return OperatingHoursEntity(weeklyHours: weeklyHours);
  }
}





