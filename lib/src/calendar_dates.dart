/// Calendar arithmetic is UTC internally; public selections are local date-only.
class CalendarDates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static int key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  static bool same(DateTime a, DateTime b) => key(a) == key(b);
  static DateTime addDays(DateTime d, int days) {
    final result = DateTime.utc(d.year, d.month, d.day + days);
    return dateOnly(result);
  }

  final _cache = <(int, int, int), List<DateTime>>{};
  List<DateTime> monthDays(int year, int month, {int firstDayOfWeek = 1}) {
    assert(firstDayOfWeek >= 1 && firstDayOfWeek <= 7);
    final key = (year, month, firstDayOfWeek);
    return _cache.putIfAbsent(key, () {
      // Bound memory even when exploring the entire supported range.
      if (_cache.length >= 240) _cache.remove(_cache.keys.first);
      final first = DateTime.utc(year, month);
      final offset = (first.weekday - firstDayOfWeek + 7) % 7;
      return List.unmodifiable(
        List.generate(42, (i) => DateTime.utc(year, month, 1 - offset + i)),
      );
    });
  }
}

/// Selection constraints do not restrict exploration of the map.
class CalendarSelection {
  CalendarSelection({
    required this.firstYear,
    required this.lastYear,
    this.minDate,
    this.maxDate,
  });
  final int firstYear, lastYear;
  final DateTime? minDate, maxDate;
  bool enabled(DateTime d) =>
      d.year >= firstYear &&
      d.year <= lastYear &&
      (minDate == null ||
          CalendarDates.key(d) >= CalendarDates.key(minDate!)) &&
      (maxDate == null || CalendarDates.key(d) <= CalendarDates.key(maxDate!));
  DateTime clamp(DateTime d) {
    var lo = DateTime(firstYear);
    var hi = DateTime(lastYear, 12, 31);
    if (minDate != null && CalendarDates.key(minDate!) > CalendarDates.key(lo))
      lo = minDate!;
    if (maxDate != null && CalendarDates.key(maxDate!) < CalendarDates.key(hi))
      hi = maxDate!;
    return CalendarDates.dateOnly(
      CalendarDates.key(d) < CalendarDates.key(lo)
          ? lo
          : CalendarDates.key(d) > CalendarDates.key(hi)
          ? hi
          : d,
    );
  }
}
