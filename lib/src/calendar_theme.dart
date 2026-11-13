import 'package:flutter/material.dart';

@immutable
class CalendarMapTheme {
  const CalendarMapTheme({
    this.background = const Color(0xFF171818),
    this.territory = const Color(0xFF212222),
    this.text = const Color(0xFFE7E7E7),
    this.secondary = const Color(0xFFA2A3A3),
    this.muted = const Color(0xFF626464),
    this.accent = const Color(0xFFFF454A),
    this.onAccent = const Color(0xFFFFFFFF),
  });
  final Color background, territory, text, secondary, muted, accent, onAccent;
  static const dark = CalendarMapTheme();
  static const light = CalendarMapTheme(
    background: Color(0xFFF5F5F7),
    territory: Color(0xFFFFFFFF),
    text: Color(0xFF202124),
    secondary: Color(0xFF62656A),
    muted: Color(0xFF96999F),
    accent: Color(0xFFCB263A),
  );
  static CalendarMapTheme forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Built-in Russian and English labels; other languages may supply their own.
@immutable
class CalendarMapLabels {
  const CalendarMapLabels({
    required this.months,
    required this.weekdays,
    required this.today,
    required this.zoomIn,
    required this.zoomOut,
    required this.hint,
    required this.map,
  });
  final List<String> months,
      weekdays; // Weekdays ordered Monday through Sunday.
  final String today, zoomIn, zoomOut, hint, map;
  static const ru = CalendarMapLabels(
    months: [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ],
    weekdays: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    today: 'Сегодня',
    zoomIn: 'Приблизить',
    zoomOut: 'Отдалить',
    map: 'Карта времени',
    hint: 'Перетаскивайте · Приближайте · Выбирайте',
  );
  static const en = CalendarMapLabels(
    months: [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    weekdays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    today: 'Today',
    zoomIn: 'Zoom in',
    zoomOut: 'Zoom out',
    map: 'Time map',
    hint: 'Drag · Zoom · Select',
  );
  static CalendarMapLabels forLocale(Locale locale) =>
      locale.languageCode == 'ru' ? ru : en;
  String date(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
}
