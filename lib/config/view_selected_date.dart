import 'package:flutter/material.dart';

class ViewSelectedDate {
  static DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  static DateTime get selectedDate => _selectedDate;

  static void update(DateTime date) {
    _selectedDate = DateUtils.dateOnly(date);
  }
}
