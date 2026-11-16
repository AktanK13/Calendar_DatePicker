import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import 'calendar_controller.dart';
import 'calendar_dates.dart';
import 'calendar_format.dart';
import 'calendar_map.dart';
import 'calendar_theme.dart';

enum CalendarRangePickerStyle { guided, calendarOnly }

/// A first-class date-range picker built on the same continuous time map.
class CalendarMapDateRangePicker extends StatefulWidget {
  CalendarMapDateRangePicker({
    super.key,
    required this.onRangeChanged,
    this.initialRange,
    this.onRangeCompleted,
    this.onRangeStartChanged,
    this.style = CalendarRangePickerStyle.calendarOnly,
    this.firstYear = 2000,
    this.lastYear = 2050,
    this.minDate,
    this.maxDate,
    this.selectableDayPredicate,
    this.currentDate,
    this.theme,
    this.locale,
    this.labels,
    this.firstDayOfWeek,
    this.textDirection,
    this.controller,
    this.onViewportChanged,
    this.showZoomControls = true,
    this.showZoomHint = true,
    this.zoomHintDuration = const Duration(milliseconds: 520),
    this.zoomHintScale = .86,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = const Cubic(.23, 1, .32, 1),
    this.enableHapticFeedback = true,
    this.restorationId,
  }) : assert(firstYear >= 1 && firstYear <= lastYear && lastYear <= 9999) {
    if (firstYear < 1 || firstYear > lastYear || lastYear > 9999) {
      throw ArgumentError('Expected 1 <= firstYear <= lastYear <= 9999');
    }
    final selection = CalendarSelection(
      firstYear: firstYear,
      lastYear: lastYear,
      minDate: minDate,
      maxDate: maxDate,
      selectableDayPredicate: selectableDayPredicate,
    );
    selection.nearestEnabled(currentDate ?? DateTime.now());
    final range = initialRange;
    if (range != null &&
        (!selection.enabled(range.start) ||
            !selection.enabled(range.end) ||
            range.end.isBefore(range.start))) {
      throw ArgumentError('initialRange must contain two selectable dates');
    }
  }

  final DateTimeRange<DateTime>? initialRange;
  final ValueChanged<DateTimeRange<DateTime>?> onRangeChanged;
  final ValueChanged<DateTimeRange<DateTime>>? onRangeCompleted;
  final ValueChanged<DateTime>? onRangeStartChanged;
  final CalendarRangePickerStyle style;
  final int firstYear, lastYear;
  final DateTime? minDate, maxDate, currentDate;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final CalendarMapTheme? theme;
  final Locale? locale;
  final CalendarMapLabels? labels;
  final int? firstDayOfWeek;
  final TextDirection? textDirection;
  final CalendarMapController? controller;
  final ValueChanged<CalendarMapViewport>? onViewportChanged;
  final bool showZoomControls, showZoomHint, enableHapticFeedback;
  final Duration zoomHintDuration, animationDuration;
  final double zoomHintScale;
  final Curve animationCurve;
  final String? restorationId;

  @override
  State<CalendarMapDateRangePicker> createState() =>
      _CalendarMapDateRangePickerState();
}

class _CalendarMapDateRangePickerState extends State<CalendarMapDateRangePicker>
    with RestorationMixin {
  DateTime? _start;
  DateTime? _end;
  bool _selectingEnd = false;
  late final RestorableDateTimeN _restoredStart;
  late final RestorableDateTimeN _restoredEnd;
  late final RestorableBool _restoredSelectingEnd;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void initState() {
    super.initState();
    _applyInitial(widget.initialRange);
    _restoredStart = RestorableDateTimeN(_start);
    _restoredEnd = RestorableDateTimeN(_end);
    _restoredSelectingEnd = RestorableBool(_selectingEnd);
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredStart, 'range_start');
    registerForRestoration(_restoredEnd, 'range_end');
    registerForRestoration(_restoredSelectingEnd, 'selecting_end');
    _start = _restoredStart.value;
    _end = _restoredEnd.value;
    _selectingEnd = _restoredSelectingEnd.value;
  }

  @override
  void didUpdateWidget(CalendarMapDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restorationId != widget.restorationId) {
      didUpdateRestorationId();
    }
  }

  void _applyInitial(DateTimeRange<DateTime>? range) {
    _start = range == null ? null : CalendarDates.dateOnly(range.start);
    _end = range == null ? null : CalendarDates.dateOnly(range.end);
    _selectingEnd = _start != null && _end == null;
  }

  void _updateRestoration() {
    _restoredStart.value = _start;
    _restoredEnd.value = _end;
    _restoredSelectingEnd.value = _selectingEnd;
  }

  void _setSelectingEnd(bool value) {
    setState(() => _selectingEnd = value);
    _updateRestoration();
  }

  CalendarSelection get _selection => CalendarSelection(
    firstYear: widget.firstYear,
    lastYear: widget.lastYear,
    minDate: widget.minDate,
    maxDate: widget.maxDate,
    selectableDayPredicate: widget.selectableDayPredicate,
  );

  DateTime get _initialDate => _selection.nearestEnabled(
    _end ?? _start ?? widget.currentDate ?? DateTime.now(),
  );

  void _select(DateTime date) {
    if (!_selectingEnd) {
      setState(() {
        _start = date;
        _end = null;
        _selectingEnd = true;
      });
      _updateRestoration();
      widget.onRangeStartChanged?.call(date);
      widget.onRangeChanged(null);
      return;
    }
    final range = DateTimeRange<DateTime>(start: _start!, end: date);
    setState(() {
      _end = date;
      _selectingEnd = false;
    });
    _updateRestoration();
    widget.onRangeChanged(range);
    widget.onRangeCompleted?.call(range);
  }

  String _format(BuildContext context, DateTime? date) => date == null
      ? '—'
      : calendarCompactDate(
          date,
          widget.locale ?? Localizations.localeOf(context),
        );

  @override
  Widget build(BuildContext context) {
    final ru =
        (widget.locale ?? Localizations.localeOf(context)).languageCode == 'ru';
    final map = CalendarMapDatePicker(
      initialDate: _initialDate,
      selectedDate: _end ?? _start,
      selectInitialDate: _start != null,
      onDateSelected: _select,
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: _selectingEnd ? _start : widget.minDate,
      maxDate: widget.maxDate,
      selectableDayPredicate: widget.selectableDayPredicate,
      currentDate: widget.currentDate,
      rangeStart: _start,
      rangeEnd: _end,
      theme: widget.theme,
      locale: widget.locale,
      labels: widget.labels,
      firstDayOfWeek: widget.firstDayOfWeek,
      textDirection: widget.textDirection,
      controller: widget.controller,
      onViewportChanged: widget.onViewportChanged,
      showZoomControls: widget.showZoomControls,
      showZoomHint: widget.showZoomHint,
      zoomHintDuration: widget.zoomHintDuration,
      zoomHintScale: widget.zoomHintScale,
      animationDuration: widget.animationDuration,
      animationCurve: widget.animationCurve,
      enableHapticFeedback: widget.enableHapticFeedback,
      restorationId: widget.restorationId == null
          ? null
          : '${widget.restorationId}_map',
    );
    if (widget.style == CalendarRangePickerStyle.calendarOnly) return map;
    final accent =
        widget.theme?.accent ?? CupertinoTheme.of(context).primaryColor;
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _RangeStageButton(
                    label: ru ? 'Начало' : 'Start',
                    value: _format(context, _start),
                    active: !_selectingEnd,
                    accent: accent,
                    onPressed: () => _setSelectingEnd(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RangeStageButton(
                    label: ru ? 'Конец' : 'End',
                    value: _format(context, _end),
                    active: _selectingEnd,
                    accent: accent,
                    onPressed: _start == null
                        ? null
                        : () => _setSelectingEnd(true),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: map),
      ],
    );
  }

  @override
  void dispose() {
    _restoredStart.dispose();
    _restoredEnd.dispose();
    _restoredSelectingEnd.dispose();
    super.dispose();
  }
}

class _RangeStageButton extends StatelessWidget {
  const _RangeStageButton({
    required this.label,
    required this.value,
    required this.active,
    required this.accent,
    required this.onPressed,
  });

  final String label, value;
  final bool active;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: .10)
            : CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active
                    ? accent
                    : CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<DateTimeRange<DateTime>?> showCalendarMapDateRangePicker({
  required BuildContext context,
  DateTimeRange<DateTime>? initialDateRange,
  int firstYear = 2000,
  int lastYear = 2050,
  DateTime? minDate,
  DateTime? maxDate,
  CalendarSelectableDayPredicate? selectableDayPredicate,
  DateTime? currentDate,
  CalendarRangePickerStyle style = CalendarRangePickerStyle.calendarOnly,
  CalendarMapTheme? theme,
  Locale? locale,
  CalendarMapLabels? labels,
  int? firstDayOfWeek,
  TextDirection? textDirection,
  CalendarMapController? controller,
  ValueChanged<CalendarMapViewport>? onViewportChanged,
  String? restorationId,
  String? title,
  String? confirmText,
  String? cancelText,
  bool showZoomControls = true,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool useSafeArea = true,
  TransitionBuilder? builder,
}) {
  CalendarMapDateRangePicker(
    initialRange: initialDateRange,
    onRangeChanged: (_) {},
    firstYear: firstYear,
    lastYear: lastYear,
    minDate: minDate,
    maxDate: maxDate,
    selectableDayPredicate: selectableDayPredicate,
    currentDate: currentDate,
  );
  Widget dialog = _CalendarRangeDialog(
    initialRange: initialDateRange,
    firstYear: firstYear,
    lastYear: lastYear,
    minDate: minDate,
    maxDate: maxDate,
    selectableDayPredicate: selectableDayPredicate,
    currentDate: currentDate,
    style: style,
    theme: theme,
    locale: locale,
    labels: labels,
    firstDayOfWeek: firstDayOfWeek,
    textDirection: textDirection,
    controller: controller,
    onViewportChanged: onViewportChanged,
    restorationId: restorationId,
    title: title,
    confirmText: confirmText,
    cancelText: cancelText,
    showZoomControls: showZoomControls,
  );
  if (textDirection != null) {
    dialog = Directionality(textDirection: textDirection, child: dialog);
  }
  if (locale != null) {
    dialog = Localizations.override(
      context: context,
      locale: locale,
      child: dialog,
    );
  }
  return showGeneralDialog<DateTimeRange<DateTime>>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? const Color(0x99000000),
    barrierLabel: barrierLabel ?? 'Dismiss',
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(.23, 1, .32, 1),
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      final child = builder == null ? dialog : builder(context, dialog);
      return useSafeArea ? SafeArea(child: child) : child;
    },
  );
}

class _CalendarRangeDialog extends StatefulWidget {
  const _CalendarRangeDialog({
    required this.initialRange,
    required this.firstYear,
    required this.lastYear,
    required this.minDate,
    required this.maxDate,
    required this.selectableDayPredicate,
    required this.currentDate,
    required this.style,
    required this.theme,
    required this.locale,
    required this.labels,
    required this.firstDayOfWeek,
    required this.textDirection,
    required this.controller,
    required this.onViewportChanged,
    required this.restorationId,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.showZoomControls,
  });

  final DateTimeRange<DateTime>? initialRange;
  final int firstYear, lastYear;
  final DateTime? minDate, maxDate, currentDate;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final CalendarRangePickerStyle style;
  final CalendarMapTheme? theme;
  final Locale? locale;
  final CalendarMapLabels? labels;
  final int? firstDayOfWeek;
  final TextDirection? textDirection;
  final CalendarMapController? controller;
  final ValueChanged<CalendarMapViewport>? onViewportChanged;
  final String? restorationId;
  final String? title, confirmText, cancelText;
  final bool showZoomControls;

  @override
  State<_CalendarRangeDialog> createState() => _CalendarRangeDialogState();
}

class _CalendarRangeDialogState extends State<_CalendarRangeDialog> {
  DateTimeRange<DateTime>? _range;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    final ru =
        (widget.locale ?? Localizations.localeOf(context)).languageCode == 'ru';
    final colors =
        widget.theme ??
        CalendarMapTheme.forBrightness(
          MediaQuery.platformBrightnessOf(context),
        );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: colors.background,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(
                      widget.title ??
                          ((widget.locale ?? Localizations.localeOf(context))
                                      .languageCode ==
                                  'ru'
                              ? 'Выбор диапазона'
                              : 'Choose range'),
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CalendarMapDateRangePicker(
                      initialRange: widget.initialRange,
                      onRangeChanged: (range) => setState(() => _range = range),
                      firstYear: widget.firstYear,
                      lastYear: widget.lastYear,
                      minDate: widget.minDate,
                      maxDate: widget.maxDate,
                      selectableDayPredicate: widget.selectableDayPredicate,
                      currentDate: widget.currentDate,
                      style: widget.style,
                      theme: widget.theme,
                      locale: widget.locale,
                      labels: widget.labels,
                      firstDayOfWeek: widget.firstDayOfWeek,
                      textDirection: widget.textDirection,
                      controller: widget.controller,
                      onViewportChanged: widget.onViewportChanged,
                      restorationId: widget.restorationId,
                      showZoomControls: widget.showZoomControls,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            widget.cancelText ?? (ru ? 'Отмена' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          color: colors.accent,
                          disabledColor: colors.muted.withValues(alpha: .35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          onPressed: _range == null
                              ? null
                              : () => Navigator.of(context).pop(_range),
                          child: Text(
                            widget.confirmText ?? (ru ? 'Готово' : 'Done'),
                            style: TextStyle(color: colors.onAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
