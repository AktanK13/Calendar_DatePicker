import 'package:flutter/widgets.dart';
import 'calendar_geometry.dart';

enum CalendarLevel { overview, year, month }

/// Stable camera destinations on the same world, never separate screens.
class CalendarNavigation {
  CalendarNavigation({
    required this.firstYear,
    required this.lastYear,
    required DateTime date,
  }) : year = date.year,
       month = date.month;
  final int firstYear, lastYear;
  int year, month;
  CalendarLevel level = CalendarLevel.month;
  Rect get yearBounds => CalendarGeometry.yearRect(year, firstYear);
  Rect get overviewBounds {
    final origin = CalendarGeometry.yearOrigin(year, firstYear);
    // A sliding three-row window; the anchor/current year is column 1.
    return Rect.fromLTWH(
      0,
      origin.dy - CalendarGeometry.stride,
      3 * CalendarGeometry.stride - 40,
      3 * CalendarGeometry.stride - 40,
    );
  }

  Rect get target => switch (level) {
    CalendarLevel.month => CalendarGeometry.worldMonth(year, month, firstYear),
    CalendarLevel.year => yearBounds,
    CalendarLevel.overview => overviewBounds,
  };
  Rect get panBounds => level == CalendarLevel.overview
      ? CalendarGeometry.worldBounds(
          firstYear,
          lastYear,
        ).expandToInclude(overviewBounds)
      : yearBounds;

  void focusAt(Offset point) {
    final row = (point.dy / CalendarGeometry.stride).floor().clamp(
      0,
      (lastYear - firstYear + CalendarGeometry.leadingSlots(firstYear)) ~/
          CalendarGeometry.columns,
    );
    final col = (point.dx / CalendarGeometry.stride).floor().clamp(
      0,
      CalendarGeometry.columns - 1,
    );
    year =
        (firstYear +
                row * CalendarGeometry.columns +
                col -
                CalendarGeometry.leadingSlots(firstYear))
            .clamp(firstYear, lastYear);
    final local = point - CalendarGeometry.yearOrigin(year, firstYear);
    var distance = double.infinity;
    for (var m = 1; m <= 12; m++) {
      final rect = CalendarGeometry.monthRect(m);
      final closest = Offset(
        local.dx.clamp(rect.left, rect.right),
        local.dy.clamp(rect.top, rect.bottom),
      );
      final d = (closest - local).distanceSquared;
      if (d < distance) {
        month = m;
        distance = d;
      }
    }
  }

  void step(bool zoomIn, Offset focalWorld) {
    if (zoomIn) focusAt(focalWorld);
    level = CalendarLevel.values[(level.index + (zoomIn ? 1 : -1)).clamp(0, 2)];
  }
}
