import 'package:flutter/widgets.dart';

import 'calendar_theme.dart';

String calendarFullDate(
  DateTime date,
  Locale locale,
  CalendarMapLabels labels,
) {
  final weekday = labels.weekdays[date.weekday - DateTime.monday];
  final month = labels.months[date.month - 1];
  if (locale.languageCode == 'ru') {
    return '$weekday, ${date.day} $month ${date.year} г.';
  }
  return '$weekday, $month ${date.day}, ${date.year}';
}

String calendarCompactDate(DateTime date, Locale locale) {
  String two(int value) => value.toString().padLeft(2, '0');
  if (locale.languageCode == 'ru') {
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }
  return '${two(date.month)}/${two(date.day)}/${date.year}';
}
