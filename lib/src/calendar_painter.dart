import 'dart:math' as math;
import 'package:flutter/material.dart';
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
    required this.focused,
    required this.today,
    required this.dates,
    required this.selection,
    required this.theme,
    required this.labels,
    required this.firstDayOfWeek,
    required this.onDate,
    required this.onArea,
  });
  final CalendarCamera camera;
  final CalendarLevel level;
  final Size viewport;
  final int firstYear, lastYear, firstDayOfWeek;
  final DateTime? selected;
  final DateTime focused, today;
  final CalendarDates dates;
  final CalendarSelection selection;
  final CalendarMapTheme theme;
  final CalendarMapLabels labels;
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
      textDirection: TextDirection.ltr,
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
          const Radius.circular(24),
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
            const Radius.circular(12),
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
              Offset(30 + i * 36, 57),
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
          for (var i = 0; i < 42; i++) {
            final d = days[i];
            final cell = CalendarGeometry.dayRect(i);
            final current = d.month == month;
            final chosen = selected != null && CalendarDates.same(d, selected!);
            final now = CalendarDates.same(d, today);
            if (current && (chosen || now)) {
              canvas.drawCircle(
                cell.center,
                13,
                Paint()
                  ..color = theme.accent.withValues(alpha: dayOpacity)
                  ..style = chosen ? PaintingStyle.fill : PaintingStyle.stroke
                  ..strokeWidth = 1.5,
              );
              // Today retains an additional dot even when selected.
              if (now && chosen)
                canvas.drawCircle(
                  cell.center + const Offset(0, 11),
                  2,
                  Paint()..color = theme.text.withValues(alpha: dayOpacity),
                );
            }
            if (current && CalendarDates.same(d, focused)) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  cell.deflate(1),
                  const Radius.circular(5),
                ),
                Paint()
                  ..color = theme.secondary.withValues(alpha: dayOpacity * .65)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = .8,
              );
            }
            text(
              canvas,
              '${d.day}',
              cell.center,
              13,
              current && selection.enabled(d)
                  ? (chosen ? theme.onAccent : theme.text)
                  : theme.muted,
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
        nodes.add(
          CustomPainterSemantics(
            key: ValueKey('year-$year'),
            rect: screenRect(yr).intersect(Offset.zero & size),
            properties: SemanticsProperties(
              label: '$year',
              button: true,
              textDirection: TextDirection.ltr,
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
          nodes.add(
            CustomPainterSemantics(
              key: ValueKey('$year-$m'),
              rect: screenRect(mr).intersect(Offset.zero & size),
              properties: SemanticsProperties(
                label: '${labels.months[m - 1]} $year',
                button: true,
                textDirection: TextDirection.ltr,
                onTap: () => onArea(mr),
              ),
            ),
          );
          continue;
        }
        final days = dates.monthDays(year, m, firstDayOfWeek: firstDayOfWeek);
        for (var i = 0; i < 42; i++) {
          final date = days[i];
          final r = CalendarGeometry.dayRect(i).shift(mr.topLeft);
          if (date.month != m || !r.overlaps(visible)) continue;
          final enabled = selection.enabled(date);
          nodes.add(
            CustomPainterSemantics(
              key: ValueKey(CalendarDates.key(date)),
              rect: screenRect(r).intersect(Offset.zero & size),
              properties: SemanticsProperties(
                label: labels.date(date),
                textDirection: TextDirection.ltr,
                button: true,
                selected:
                    selected != null && CalendarDates.same(date, selected!),
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
