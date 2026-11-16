import 'package:flutter/widgets.dart';

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
    Color? selectedDay,
    Color? rangeEndpoint,
    Color? rangeMiddle,
    Color? today,
    Color? disabledDay,
    Color? weekend,
    Color? focus,
    Color? hover,
    Color? pressed,
    this.yearRadius = 24,
    this.monthRadius = 12,
    this.dayRadius = 7,
  }) : selectedDay = selectedDay ?? accent,
       rangeEndpoint = rangeEndpoint ?? accent,
       rangeMiddle = rangeMiddle ?? accent,
       today = today ?? accent,
       disabledDay = disabledDay ?? muted,
       weekend = weekend ?? text,
       focus = focus ?? secondary,
       hover = hover ?? accent,
       pressed = pressed ?? accent;

  final Color background, territory, text, secondary, muted, accent, onAccent;
  final Color selectedDay,
      rangeEndpoint,
      rangeMiddle,
      today,
      disabledDay,
      weekend,
      focus,
      hover,
      pressed;
  final double yearRadius, monthRadius, dayRadius;

  CalendarMapTheme copyWith({
    Color? background,
    Color? territory,
    Color? text,
    Color? secondary,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? selectedDay,
    Color? rangeEndpoint,
    Color? rangeMiddle,
    Color? today,
    Color? disabledDay,
    Color? weekend,
    Color? focus,
    Color? hover,
    Color? pressed,
    double? yearRadius,
    double? monthRadius,
    double? dayRadius,
  }) => CalendarMapTheme(
    background: background ?? this.background,
    territory: territory ?? this.territory,
    text: text ?? this.text,
    secondary: secondary ?? this.secondary,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    selectedDay: selectedDay ?? this.selectedDay,
    rangeEndpoint: rangeEndpoint ?? this.rangeEndpoint,
    rangeMiddle: rangeMiddle ?? this.rangeMiddle,
    today: today ?? this.today,
    disabledDay: disabledDay ?? this.disabledDay,
    weekend: weekend ?? this.weekend,
    focus: focus ?? this.focus,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    yearRadius: yearRadius ?? this.yearRadius,
    monthRadius: monthRadius ?? this.monthRadius,
    dayRadius: dayRadius ?? this.dayRadius,
  );
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
    this.year = 'Year',
    this.unavailable = 'Unavailable',
    this.selected = 'Selected',
    this.rangeStart = 'Range start',
    this.rangeEnd = 'Range end',
  });
  final List<String> months,
      weekdays; // Weekdays ordered Monday through Sunday.
  final String today,
      zoomIn,
      zoomOut,
      hint,
      map,
      year,
      unavailable,
      selected,
      rangeStart,
      rangeEnd;
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
    year: 'Год',
    unavailable: 'Недоступно',
    selected: 'Выбрано',
    rangeStart: 'Начало диапазона',
    rangeEnd: 'Конец диапазона',
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
