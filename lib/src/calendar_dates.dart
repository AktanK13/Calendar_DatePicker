/// Returns whether a civil day can be selected.
typedef CalendarSelectableDayPredicate = bool Function(DateTime date);

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
    this.selectableDayPredicate,
  });
  final int firstYear, lastYear;
  final DateTime? minDate, maxDate;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  bool enabled(DateTime d) =>
      d.year >= firstYear &&
      d.year <= lastYear &&
      (minDate == null ||
          CalendarDates.key(d) >= CalendarDates.key(minDate!)) &&
      (maxDate == null ||
          CalendarDates.key(d) <= CalendarDates.key(maxDate!)) &&
      (selectableDayPredicate == null || selectableDayPredicate!(d));
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

  /// Nearest enabled date, preferring later dates at equal distance.
  DateTime nearestEnabled(DateTime date) {
    final bounded = clamp(date);
    if (enabled(bounded)) return bounded;
    final lo = clamp(DateTime(firstYear));
    final hi = clamp(DateTime(lastYear, 12, 31));
    for (var distance = 1; ; distance++) {
      final after = CalendarDates.addDays(bounded, distance);
      final before = CalendarDates.addDays(bounded, -distance);
      final canTryAfter = CalendarDates.key(after) <= CalendarDates.key(hi);
      final canTryBefore = CalendarDates.key(before) >= CalendarDates.key(lo);
      if (canTryAfter && enabled(after)) return after;
      if (canTryBefore && enabled(before)) return before;
      if (!canTryAfter && !canTryBefore) {
        throw StateError(
          'No selectable date exists inside the configured range',
        );
      }
    }
  }

  /// Moves by [dayDelta] while skipping dates rejected by the predicate.
  DateTime move(DateTime from, int dayDelta) {
    if (dayDelta == 0) return nearestEnabled(from);
    final direction = dayDelta.sign;
    var remaining = dayDelta.abs();
    var candidate = from;
    while (remaining > 0) {
      candidate = CalendarDates.addDays(candidate, direction);
      final bounded = clamp(candidate);
      if (!CalendarDates.same(candidate, bounded))
        return nearestEnabled(bounded);
      if (enabled(candidate)) remaining--;
    }
    return candidate;
  }
}
