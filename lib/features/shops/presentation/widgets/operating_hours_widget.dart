import 'package:flutter/material.dart';
import 'package:compareitr/features/shops/domain/entities/operating_hours_entity.dart';

class OperatingHoursWidget extends StatelessWidget {
  final OperatingHoursEntity operatingHours;

  const OperatingHoursWidget({super.key, required this.operatingHours});

  @override
  Widget build(BuildContext context) {
    final todayHours = operatingHours.getTodayHours();
    final isOpen = operatingHours.isCurrentlyOpen();
    final nextOpening = operatingHours.getNextOpeningTime();
    final nextOpeningDay = operatingHours.getNextOpeningDay();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOpen 
            ? Colors.green.shade50.withOpacity(0.8)
            : Colors.red.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Row
          Row(
            children: [
              Icon(
                isOpen ? Icons.access_time : Icons.schedule,
                color: isOpen ? Colors.green.shade600 : Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOpen ? 'Open Now' : 'Closed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Today's Hours
          if (isOpen && todayHours.closeTime != null)
            Text(
              'Closes at ${todayHours.closeTime}',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 14,
              ),
            ),
          
          if (!isOpen && nextOpening != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opens at ${_formatTimeOfDay(nextOpening)}',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                  ),
                ),
                if (nextOpeningDay != null)
                  Text(
                    'on ${_capitalizeFirst(nextOpeningDay)}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          
          if (!isOpen && nextOpening == null)
            Text(
              'Check back later',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
          
          // Today's Hours Info
          if (todayHours.isOpen && todayHours.openTime != null && todayHours.closeTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Today: ${todayHours.openTime} - ${todayHours.closeTime}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class WeeklyOperatingHoursWidget extends StatelessWidget {
  final OperatingHoursEntity operatingHours;

  const WeeklyOperatingHoursWidget({super.key, required this.operatingHours});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final jsonKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade600
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Operating Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weekly Schedule
          ...List.generate(7, (index) {
            final dayName = dayNames[index];
            final jsonKey = jsonKeys[index];
            final dayHours = operatingHours.weeklyHours[jsonKey];
            final isToday = DateTime.now().weekday == index + 1;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    dayHours?.isOpen == true && dayHours?.openTime != null && dayHours?.closeTime != null
                        ? '${dayHours!.openTime} - ${dayHours.closeTime}'
                        : 'Closed',
                    style: TextStyle(
                      color: dayHours?.isOpen == true
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}





