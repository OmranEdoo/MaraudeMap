import 'package:flutter/material.dart';

import '../config/theme.dart';

class DateSelectorBar extends StatelessWidget {
  const DateSelectorBar({
    super.key,
    required this.selectedDate,
    required this.onLeftPressed,
    required this.onRightPressed,
  });

  final DateTime selectedDate;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;

  int _selectedDateOffsetFromToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(selectedDate);
    return selected.difference(today).inDays;
  }

  String _selectedDateLabel() {
    switch (_selectedDateOffsetFromToday()) {
      case 0:
        return 'Aujourd\'hui';
      case 1:
        return 'Demain';
      case -1:
        return 'Hier';
      default:
        const weekdays = [
          'Lundi',
          'Mardi',
          'Mercredi',
          'Jeudi',
          'Vendredi',
          'Samedi',
          'Dimanche',
        ];
        return weekdays[selectedDate.weekday - 1];
    }
  }

  String _formattedSelectedDate() {
    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final isPastDate = _selectedDateOffsetFromToday() < 0;
    final textColor = isPastDate ? Colors.grey : AppTheme.primaryColor;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftPressed,
          ),
          Column(
            children: [
              Text(
                _selectedDateLabel(),
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedSelectedDate(),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightPressed,
          ),
        ],
      ),
    );
  }
}
