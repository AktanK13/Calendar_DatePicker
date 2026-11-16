import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'calendar_camera.dart';
import 'calendar_dates.dart';
import 'calendar_geometry.dart';
import 'calendar_navigation.dart';
import 'calendar_theme.dart';

class CalendarMapPainter extends CustomPainter {
  CalendarMapPainter({
    required this.camera,
    required this.level,
    required this.viewport,
    required this.firstYear,
    required this.lastYear,
    required this.selected,
    required this.rangeStart,
    required this.rangeEnd,
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.today,
    required this.dates,
    required this.selection,
    required this.theme,
    required this.labels,
    required this.firstDayOfWeek,
    required this.textDirection,
    required this.dateLabel,
    required this.onDate,
    required this.onArea,
  });
  final CalendarCamera camera;
  final CalendarLevel level;
  final Size viewport;
  final int firstYear, lastYear, firstDayOfWeek;
  final DateTime? selected;
  final DateTime? rangeStart, rangeEnd;
  final DateTime? hovered, pressed;
  final DateTime focused, today;
  final CalendarDates dates;
  final CalendarSelection selection;
  final CalendarMapTheme theme;
  final CalendarMapLabels labels;
  final TextDirection textDirection;
  final String Function(DateTime) dateLabel;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<Rect> onArea;
  static const readableScale = .85;
  double get monthOpacity => ((camera.scale - .14) / .18).clamp(0, 1);
  double get effectiveReadableScale => math.min(
    readableScale,
    viewport.width / CalendarGeometry.monthSize * .95,
  );
  double get dayOpacity =>
      ((camera.scale / effectiveReadableScale - .65) / .35).clamp(0, 1);

  Iterable<int> get visibleYears sync* {
    final visible = camera.visibleRect(viewport);
    final maxRow =
        (lastYear - firstYear + CalendarGeometry.leadingSlots(firstYear)) ~/
        CalendarGeometry.columns;
    final start = (visible.top / CalendarGeometry.stride).floor().clamp(
      0,
      maxRow,
    );
    final end = (visible.bottom / CalendarGeometry.stride).floor().clamp(
      0,
      maxRow,
    );
    for (var row = start; row <= end; row++) {
      for (var col = 0; col < CalendarGeometry.columns; col++) {
        final year =
            firstYear +
            row * CalendarGeometry.columns +
            col -
            CalendarGeometry.leadingSlots(firstYear);
        if (year >= firstYear &&
            year <= lastYear &&
            CalendarGeometry.yearRect(year, firstYear).overlaps(visible))
          yield year;
      }
    }
  }

  void text(
    Canvas canvas,
    String value,
    Offset at,
    double size,
    Color color, {
    double opacity = 1,
    bool center = false,
  }) {
    if (opacity <= 0) return;
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          color: color.withValues(alpha: opacity),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    p.paint(canvas, center ? at - Offset(p.width / 2, p.height / 2) : at);
    p.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(camera.translation.dx, camera.translation.dy);
    canvas.scale(camera.scale);
    final visible = camera.visibleRect(size);
    for (final year in visibleYears) {
      final origin = CalendarGeometry.yearOrigin(year, firstYear);
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 1200, 1200),
          Radius.circular(theme.yearRadius),
        ),
        Paint()..color = theme.territory,
      );
      text(
        canvas,
        '$year',
        const Offset(32, 28),
        math.max(64, 22 / camera.scale),
        theme.text,
      );
      for (var month = 1; month <= 12; month++) {
        final rect = CalendarGeometry.monthRect(month);
        if (!rect.shift(origin).overlaps(visible) || monthOpacity == 0)
          continue;
        canvas.save();
        canvas.translate(rect.left, rect.top);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 280, 280),
            Radius.circular(theme.monthRadius),
          ),
          Paint()
            ..color = theme.background.withValues(alpha: monthOpacity * .45),
        );
        text(
          canvas,
          labels.months[month - 1],
          const Offset(12, 12),
          math.max(22, 10 / camera.scale),
          theme.accent,
          opacity: monthOpacity,
        );
        if (dayOpacity > 0) {
          for (var i = 0; i < 7; i++) {
            text(
              canvas,
              labels.weekdays[(firstDayOfWeek - 1 + i) % 7],
              Offset(
                30 + (textDirection == TextDirection.rtl ? 6 - i : i) * 36,
                57,
              ),
              11,
              theme.secondary,
              opacity: dayOpacity,
              center: true,
            );
          }
          final days = dates.monthDays(
            year,
            month,
            firstDayOfWeek: firstDayOfWeek,
          );
          final rangeStartKey = rangeStart == null
              ? null
              : CalendarDates.key(rangeStart!);
          final rangeEndKey = rangeEnd == null
              ? null
              : CalendarDates.key(rangeEnd!);
          for (var i = 0; i < 42; i++) {
            final d = days[i];
            final row = i ~/ 7;
            final column = i % 7;
            final visualColumn = textDirection == TextDirection.rtl
                ? 6 - column
                : column;
            final cell = CalendarGeometry.dayRect(row * 7 + visualColumn);
            final current = d.month == month;
            final dateKey = CalendarDates.key(d);
            final inRange =
                rangeStartKey != null &&
                rangeEndKey != null &&
                dateKey >= rangeStartKey &&
                dateKey <= rangeEndKey;
            final rangeEndpoint =
                rangeStart != null && CalendarDates.same(d, rangeStart!) ||
                rangeEnd != null && CalendarDates.same(d, rangeEnd!);
            final chosen =
                selected != null &&
                    CalendarDates.same(d, selected!) &&
                    (!inRange || rangeEndpoint) ||
                rangeEndpoint;
            final now = CalendarDates.same(d, today);
            final isHovered =
                hovered != null && CalendarDates.same(d, hovered!);
            final isPressed =
                pressed != null && CalendarDates.same(d, pressed!);
            if (current && inRange && !rangeEndpoint) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  cell.deflate(3),
                  Radius.circular(theme.dayRadius),
                ),
                Paint()
                  ..color = theme.rangeMiddle.withValues(
                    alpha: dayOpacity * .18,
                  ),
              );
            }
            if (current && (isHovered || isPressed) && !chosen) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  cell.deflate(2),
                  Radius.circular(theme.dayRadius),
                ),
                Paint()
                  ..color = (isPressed ? theme.pressed : theme.hover)
                      .withValues(alpha: dayOpacity * (isPressed ? .18 : .10)),
              );
            }
            if (current && chosen) {
              canvas.drawCircle(
                cell.center,
                13,
                Paint()
                  ..color =
                      (rangeEndpoint ? theme.rangeEndpoint : theme.selectedDay)
                          .withValues(alpha: dayOpacity)
                  ..style = PaintingStyle.fill,
              );
            }
            if (current && now && !chosen) {
              canvas.drawCircle(
                cell.center,
                13,
                Paint()
                  ..color = theme.today.withValues(alpha: dayOpacity * .14)
                  ..style = PaintingStyle.fill,
              );
            }
            if (current && !chosen && CalendarDates.same(d, focused)) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  cell.deflate(1),
                  Radius.circular(theme.dayRadius),
                ),
                Paint()
                  ..color = theme.focus.withValues(alpha: dayOpacity * .10)
                  ..style = PaintingStyle.fill,
              );
            }
            text(
              canvas,
              '${d.day}',
              cell.center,
              13,
              current && selection.enabled(d)
                  ? (chosen
                        ? theme.onAccent
                        : inRange
                        ? theme.rangeMiddle
                        : d.weekday >= DateTime.saturday
                        ? theme.weekend
                        : theme.text)
                  : theme.disabledDay,
              opacity: dayOpacity,
              center: true,
            );
          }
        }
        canvas.restore();
      }
      canvas.restore();
    }
    canvas.restore();
  }

  Rect screenRect(Rect world) => Rect.fromPoints(
    camera.worldToScreen(world.topLeft),
    camera.worldToScreen(world.bottomRight),
  );
  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final nodes = <CustomPainterSemantics>[];
    final visible = camera.visibleRect(size);
    for (final year in visibleYears) {
      final yr = CalendarGeometry.yearRect(year, firstYear);
      if (level == CalendarLevel.overview) {
        final semanticsRect = screenRect(yr).intersect(Offset.zero & size);
        if (semanticsRect.isEmpty) continue;
        nodes.add(
          CustomPainterSemantics(
            key: ValueKey('year-$year'),
            rect: semanticsRect,
            properties: SemanticsProperties(
              label: '$year',
              button: true,
              textDirection: textDirection,
              onTap: () => onArea(yr),
            ),
          ),
        );
        continue;
      }
      for (var m = 1; m <= 12; m++) {
        final mr = CalendarGeometry.worldMonth(year, m, firstYear);
        if (!mr.overlaps(visible)) continue;
        if (level == CalendarLevel.year ||
            camera.scale < effectiveReadableScale) {
          final semanticsRect = screenRect(mr).intersect(Offset.zero & size);
          if (semanticsRect.isEmpty) continue;
          nodes.add(
            CustomPainterSemantics(
              key: ValueKey('$year-$m'),
              rect: semanticsRect,
              properties: SemanticsProperties(
                label: '${labels.months[m - 1]} $year',
                button: true,
                textDirection: textDirection,
                onTap: () => onArea(mr),
              ),
            ),
          );
          continue;
        }
        final days = dates.monthDays(year, m, firstDayOfWeek: firstDayOfWeek);
        for (var i = 0; i < 42; i++) {
          final date = days[i];
          final row = i ~/ 7;
          final column = i % 7;
          final visualColumn = textDirection == TextDirection.rtl
              ? 6 - column
              : column;
          final r = CalendarGeometry.dayRect(
            row * 7 + visualColumn,
          ).shift(mr.topLeft);
          if (date.month != m || !r.overlaps(visible)) continue;
          final enabled = selection.enabled(date);
          final semanticsRect = screenRect(r).intersect(Offset.zero & size);
          if (semanticsRect.isEmpty) continue;
          nodes.add(
            CustomPainterSemantics(
              key: ValueKey(CalendarDates.key(date)),
              rect: semanticsRect,
              properties: SemanticsProperties(
                label: [
                  dateLabel(date),
                  if (!enabled) labels.unavailable,
                  if (rangeStart != null &&
                      CalendarDates.same(date, rangeStart!))
                    labels.rangeStart
                  else if (rangeEnd != null &&
                      CalendarDates.same(date, rangeEnd!))
                    labels.rangeEnd
                  else if (selected != null &&
                      CalendarDates.same(date, selected!))
                    labels.selected,
                ].join(', '),
                textDirection: textDirection,
                button: true,
                selected:
                    selected != null && CalendarDates.same(date, selected!) ||
                    rangeStart != null &&
                        rangeEnd != null &&
                        CalendarDates.key(date) >=
                            CalendarDates.key(rangeStart!) &&
                        CalendarDates.key(date) <= CalendarDates.key(rangeEnd!),
                enabled: enabled,
                onTap: enabled ? () => onDate(date) : null,
              ),
            ),
          );
        }
      }
    }
    return nodes;
  };
  @override
  bool shouldRepaint(covariant CalendarMapPainter oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(covariant CalendarMapPainter oldDelegate) => true;
}
