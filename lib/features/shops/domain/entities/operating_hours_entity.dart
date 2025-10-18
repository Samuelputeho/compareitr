import 'package:flutter/material.dart';

class DayHoursEntity {
  final String? openTime;
  final String? closeTime;
  final bool isOpen;

  const DayHoursEntity({
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayHoursEntity &&
        other.openTime == openTime &&
        other.closeTime == closeTime &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode {
    return openTime.hashCode ^ closeTime.hashCode ^ isOpen.hashCode;
  }
}

class OperatingHoursEntity {
  final Map<String, DayHoursEntity> weeklyHours;

  const OperatingHoursEntity({
    required this.weeklyHours,
  });

  // Helper methods
  DayHoursEntity getTodayHours() {
    final today = DateTime.now().weekday;
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final todayName = dayNames[today - 1];
    return weeklyHours[todayName] ?? const DayHoursEntity(openTime: null, closeTime: null, isOpen: false);
  }

  bool isCurrentlyOpen() {
    final todayHours = getTodayHours();
    if (!todayHours.isOpen || todayHours.openTime == null || todayHours.closeTime == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final openTime = _parseTime(todayHours.openTime!);
    final closeTime = _parseTime(todayHours.closeTime!);

    return _isTimeInRange(currentTime, openTime, closeTime);
  }

  TimeOfDay? getNextOpeningTime() {
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayName = dayNames[checkDate.weekday - 1];
      final dayHours = weeklyHours[dayName];
      
      if (dayHours?.isOpen == true && dayHours?.openTime != null) {
        if (i == 0) {
          final openTime = _parseTime(dayHours!.openTime!);
          final currentTime = TimeOfDay.fromDateTime(now);
          final closeTime = _parseTime(dayHours.closeTime!);
          
          if (_isTimeInRange(currentTime, openTime, closeTime)) {
            continue; // Shop is currently open
          }
          if (currentTime.hour < openTime.hour || 
              (currentTime.hour == openTime.hour && currentTime.minute < openTime.minute)) {
            return openTime; // Opens today
          }
        } else {
          return _parseTime(dayHours!.openTime!); // Opens on future day
        }
      }
    }
    return null;
  }

  String? getNextOpeningDay() {
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayName = dayNames[checkDate.weekday - 1];
      final dayHours = weeklyHours[dayName];
      
      if (dayHours?.isOpen == true && dayHours?.openTime != null) {
        if (i == 0) {
          final openTime = _parseTime(dayHours!.openTime!);
          final currentTime = TimeOfDay.fromDateTime(now);
          final closeTime = _parseTime(dayHours.closeTime!);
          
          if (_isTimeInRange(currentTime, openTime, closeTime)) {
            continue; // Shop is currently open
          }
          if (currentTime.hour < openTime.hour || 
              (currentTime.hour == openTime.hour && currentTime.minute < openTime.minute)) {
            return null; // Opens today
          }
        } else {
          return dayName; // Opens on future day
        }
      }
    }
    return null;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay open, TimeOfDay close) {
    final currentMinutes = current.hour * 60 + current.minute;
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;
    
    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperatingHoursEntity &&
        other.weeklyHours.toString() == weeklyHours.toString();
  }

  @override
  int get hashCode => weeklyHours.hashCode;
}





