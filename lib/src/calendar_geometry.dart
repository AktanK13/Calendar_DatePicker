import 'package:flutter/widgets.dart';
import 'calendar_dates.dart';

/// Stable square territories: three years per row, twelve months per year.
class CalendarGeometry {
  static const yearSize = 1200.0;
  static const stride = 1240.0;
  static const monthSize = 280.0;
  static const columns = 3;

  /// System year captured once, keeping world coordinates stable for this run.
  static final int anchorYear = DateTime.now().year;

  /// Leading empty slots put the current year in the middle column.
  static int leadingSlots(int firstYear) =>
      (1 - (anchorYear - firstYear) % columns + columns) % columns;
  static const monthNames = [
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
  ];

  static Offset yearOrigin(int year, int firstYear) {
    final index = year - firstYear + leadingSlots(firstYear);
    return Offset((index % columns) * stride, (index ~/ columns) * stride);
  }

  static Rect monthRect(int month) => Rect.fromLTWH(
    24 + ((month - 1) % 4) * 292.0,
    160 + ((month - 1) ~/ 4) * 320.0,
    monthSize,
    monthSize,
  );

  static final _dates = CalendarDates();
  static List<DateTime> monthDays(
    int year,
    int month, {
    int firstDayOfWeek = 1,
  }) => _dates.monthDays(year, month, firstDayOfWeek: firstDayOfWeek);

  static Rect worldBounds(int firstYear, int lastYear) {
    final count = lastYear - firstYear + 1 + leadingSlots(firstYear);
    final width = (count < columns ? count : columns);
    final rows = (count / columns).ceil();
    return Rect.fromLTWH(
      0,
      0,
      (width - 1) * stride + yearSize,
      (rows - 1) * stride + yearSize,
    );
  }

  static Rect yearRect(int year, int firstYear) =>
      yearOrigin(year, firstYear) & const Size(yearSize, yearSize);
  static Rect worldMonth(int year, int month, int firstYear) =>
      monthRect(month).shift(yearOrigin(year, firstYear));
  static int? hitYear(Offset world, int firstYear, int lastYear) {
    final col = (world.dx / stride).floor();
    final row = (world.dy / stride).floor();
    if (col < 0 || col >= columns || row < 0) return null;
    final year = firstYear + row * columns + col - leadingSlots(firstYear);
    return year >= firstYear &&
            year <= lastYear &&
            yearRect(year, firstYear).contains(world)
        ? year
        : null;
  }

  static int? hitMonth(Offset local) {
    for (var month = 1; month <= 12; month++) {
      if (monthRect(month).contains(local)) return month;
    }
    return null;
  }

  static int? hitDay(Offset local) {
    for (var i = 0; i < 42; i++) {
      if (dayRect(i).contains(local)) return i;
    }
    return null;
  }

  static Rect dayRect(int index) =>
      Rect.fromLTWH(12 + (index % 7) * 36.0, 76 + (index ~/ 7) * 30.0, 36, 30);
}
