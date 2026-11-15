import 'package:flutter/material.dart';
import 'calendar_dates.dart';
import 'calendar_map.dart';
import 'calendar_theme.dart';

/// Opens a map picker. Confirm returns a date; cancel/back/barrier return null.
/// Theme follows the host Material brightness unless [theme] is supplied.
///
/// [context] must be below a Navigator and Material localizations. Tapping a
/// day updates only the dialog's draft selection; confirming returns it.
/// [initialDate] is preselected (clamped to [minDate]/[maxDate]), so confirming
/// without another day tap still returns a date. Cancellation returns null.
///
/// The year range is inclusive and must satisfy 1 <= firstYear <= lastYear <=
/// 9999. The initial year must be inside it; selection bounds must intersect it.
/// Invalid arguments throw [ArgumentError] before the route is opened.
///
/// This convenience helper uses default animation and label settings. For
/// custom labels, animation parameters or presentation, embed
/// [CalendarMapDatePicker] in your own route instead.
Future<DateTime?> showCalendarMapDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  int firstYear = 2000,
  int lastYear = 2050,
  DateTime? minDate,
  DateTime? maxDate,
  Locale locale = const Locale('ru'),
  int firstDayOfWeek = DateTime.monday,
  CalendarMapTheme? theme,
  String? title,
  String? confirmText,
  String? cancelText,
  bool showConfirmButton = true,
  bool showCancelButton = true,
  bool selectImmediately = false,
  bool showZoomControls = true,
  bool showZoomHint = true,
}) {
  // Validate before opening the route, using the same API as the embedded map.
  CalendarMapDatePicker(
    initialDate: initialDate,
    firstYear: firstYear,
    lastYear: lastYear,
    minDate: minDate,
    maxDate: maxDate,
    firstDayOfWeek: firstDayOfWeek,
    onDateSelected: (_) {},
  );
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _CalendarDialog(
      initialDate: initialDate,
      firstYear: firstYear,
      lastYear: lastYear,
      minDate: minDate,
      maxDate: maxDate,
      locale: locale,
      firstDayOfWeek: firstDayOfWeek,
      theme: theme,
      title: title,
      confirmText: confirmText,
      cancelText: cancelText,
      showConfirmButton: showConfirmButton,
      showCancelButton: showCancelButton,
      selectImmediately: selectImmediately,
      showZoomControls: showZoomControls,
      showZoomHint: showZoomHint,
    ),
  );
}

class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({
    required this.initialDate,
    required this.firstYear,
    required this.lastYear,
    required this.minDate,
    required this.maxDate,
    required this.locale,
    required this.firstDayOfWeek,
    required this.theme,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.showConfirmButton,
    required this.showCancelButton,
    required this.selectImmediately,
    required this.showZoomControls,
    required this.showZoomHint,
  });
  final DateTime initialDate;
  final int firstYear, lastYear, firstDayOfWeek;
  final DateTime? minDate, maxDate;
  final Locale locale;
  final CalendarMapTheme? theme;
  final String? title, confirmText, cancelText;
  final bool showConfirmButton, showCancelButton, selectImmediately;
  final bool showZoomControls, showZoomHint;
  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  final _mapKey = GlobalKey();
  late DateTime _selected;
  @override
  void initState() {
    super.initState();
    _selected = CalendarSelection(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
    ).clamp(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    final ru = widget.locale.languageCode == 'ru';
    final colors =
        widget.theme ??
        CalendarMapTheme.forBrightness(Theme.of(context).brightness);
    final cancel = TextButton(
      key: const ValueKey('cancel-date'),
      onPressed: () => Navigator.of(context).pop(),
      child: Text(widget.cancelText ?? (ru ? 'Отмена' : 'Cancel')),
    );
    final confirm = FilledButton(
      key: const ValueKey('confirm-date'),
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
      ),
      onPressed: () => Navigator.of(context).pop(_selected),
      child: Text(widget.confirmText ?? (ru ? 'Выбрать' : 'Select')),
    );
    final title = Text(
      widget.title ?? (ru ? 'Выбор даты' : 'Choose date'),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
    );
    final calendar = CalendarMapDatePicker(
      key: _mapKey,
      initialDate: widget.initialDate,
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      locale: widget.locale,
      firstDayOfWeek: widget.firstDayOfWeek,
      theme: widget.theme,
      showZoomControls: widget.showZoomControls,
      showZoomHint: widget.showZoomHint,
      onDateSelected: (date) {
        if (widget.selectImmediately) {
          Navigator.of(context).pop(date);
        } else {
          setState(() => _selected = date);
        }
      },
    );
    return Dialog(
      backgroundColor: colors.background,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      constraints: const BoxConstraints(maxWidth: 920, maxHeight: 740),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight * 1.25;
          if (landscape) {
            return Row(
              children: [
                Expanded(child: calendar),
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const Spacer(),
                        if (widget.showCancelButton) cancel,
                        if (widget.showCancelButton && widget.showConfirmButton)
                          const SizedBox(height: 8),
                        if (widget.showConfirmButton) confirm,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: title,
              ),
              Expanded(child: calendar),
              if (widget.showCancelButton || widget.showConfirmButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.showCancelButton) cancel,
                      if (widget.showCancelButton && widget.showConfirmButton)
                        const SizedBox(width: 12),
                      if (widget.showConfirmButton) confirm,
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
