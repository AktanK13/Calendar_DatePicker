import 'package:flutter/cupertino.dart';
import 'calendar_dates.dart';
import 'calendar_controller.dart';
import 'calendar_map.dart';
import 'calendar_theme.dart';

enum CalendarPickerPresentation { dialog, bottomSheet, fullscreen }

/// Opens a map picker. Confirm returns a date; cancel/back/barrier return null.
/// Theme follows the platform brightness unless [theme] is supplied.
///
/// [context] must be below a Navigator. Tapping a
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
  CalendarSelectableDayPredicate? selectableDayPredicate,
  DateTime? currentDate,
  DateTime? rangeStart,
  DateTime? rangeEnd,
  Locale? locale,
  int? firstDayOfWeek,
  TextDirection? textDirection,
  CalendarMapController? controller,
  CalendarMapTheme? theme,
  CalendarMapLabels? labels,
  String? title,
  String? confirmText,
  String? cancelText,
  bool showConfirmButton = true,
  bool showCancelButton = true,
  bool selectImmediately = false,
  bool showZoomControls = true,
  bool showZoomHint = true,
  Duration zoomHintDuration = const Duration(milliseconds: 520),
  double zoomHintScale = .86,
  bool allowTextInput = false,
  String? errorFormatText,
  String? errorInvalidText,
  String? fieldHintText,
  String? fieldLabelText,
  String? restorationId,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool useSafeArea = true,
  TransitionBuilder? builder,
  CalendarPickerPresentation presentation = CalendarPickerPresentation.dialog,
}) {
  // Validate before opening the route, using the same API as the embedded map.
  CalendarMapDatePicker(
    initialDate: initialDate,
    firstYear: firstYear,
    lastYear: lastYear,
    minDate: minDate,
    maxDate: maxDate,
    selectableDayPredicate: selectableDayPredicate,
    currentDate: currentDate,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    firstDayOfWeek: firstDayOfWeek,
    textDirection: textDirection,
    controller: controller,
    labels: labels,
    zoomHintDuration: zoomHintDuration,
    zoomHintScale: zoomHintScale,
    onDateSelected: (_) {},
  );
  Widget dialog = _CalendarDialog(
    initialDate: initialDate,
    firstYear: firstYear,
    lastYear: lastYear,
    minDate: minDate,
    maxDate: maxDate,
    selectableDayPredicate: selectableDayPredicate,
    currentDate: currentDate,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    locale: locale,
    firstDayOfWeek: firstDayOfWeek,
    textDirection: textDirection,
    controller: controller,
    theme: theme,
    labels: labels,
    title: title,
    confirmText: confirmText,
    cancelText: cancelText,
    showConfirmButton: showConfirmButton,
    showCancelButton: showCancelButton,
    selectImmediately: selectImmediately,
    showZoomControls: showZoomControls,
    showZoomHint: showZoomHint,
    zoomHintDuration: zoomHintDuration,
    zoomHintScale: zoomHintScale,
    allowTextInput: allowTextInput,
    errorFormatText: errorFormatText,
    errorInvalidText: errorInvalidText,
    fieldHintText: fieldHintText,
    fieldLabelText: fieldLabelText,
    restorationId: restorationId,
    presentation: presentation,
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
  Widget routeChild(BuildContext context) =>
      builder == null ? dialog : builder(context, dialog);
  return switch (presentation) {
    CalendarPickerPresentation.dialog => showGeneralDialog<DateTime>(
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
        final child = routeChild(context);
        return useSafeArea ? SafeArea(child: child) : child;
      },
    ),
    CalendarPickerPresentation.bottomSheet => showCupertinoModalPopup<DateTime>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? kCupertinoModalBarrierColor,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: routeChild,
    ),
    CalendarPickerPresentation.fullscreen =>
      Navigator.of(context, rootNavigator: useRootNavigator).push<DateTime>(
        CupertinoPageRoute<DateTime>(
          settings: routeSettings,
          fullscreenDialog: true,
          builder: routeChild,
        ),
      ),
  };
}

class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({
    required this.initialDate,
    required this.firstYear,
    required this.lastYear,
    required this.minDate,
    required this.maxDate,
    required this.selectableDayPredicate,
    required this.currentDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.locale,
    required this.firstDayOfWeek,
    required this.textDirection,
    required this.controller,
    required this.theme,
    required this.labels,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.showConfirmButton,
    required this.showCancelButton,
    required this.selectImmediately,
    required this.showZoomControls,
    required this.showZoomHint,
    required this.zoomHintDuration,
    required this.zoomHintScale,
    required this.allowTextInput,
    required this.errorFormatText,
    required this.errorInvalidText,
    required this.fieldHintText,
    required this.fieldLabelText,
    required this.restorationId,
    required this.presentation,
  });
  final DateTime initialDate;
  final int firstYear, lastYear;
  final int? firstDayOfWeek;
  final DateTime? minDate, maxDate, currentDate;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final DateTime? rangeStart, rangeEnd;
  final Locale? locale;
  final TextDirection? textDirection;
  final CalendarMapController? controller;
  final CalendarMapTheme? theme;
  final CalendarMapLabels? labels;
  final String? title, confirmText, cancelText;
  final bool showConfirmButton, showCancelButton, selectImmediately;
  final bool showZoomControls, showZoomHint;
  final Duration zoomHintDuration;
  final double zoomHintScale;
  final bool allowTextInput;
  final String? errorFormatText,
      errorInvalidText,
      fieldHintText,
      fieldLabelText;
  final String? restorationId;
  final CalendarPickerPresentation presentation;
  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  final _mapKey = GlobalKey();
  late final TextEditingController _inputController;
  late DateTime _selected;
  bool _inputMode = false;
  bool _inputInitialized = false;
  String? _inputError;
  @override
  void initState() {
    super.initState();
    _selected = CalendarSelection(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      selectableDayPredicate: widget.selectableDayPredicate,
    ).nearestEnabled(widget.initialDate);
    _inputController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inputInitialized) {
      _inputInitialized = true;
      _inputController.text = _compactDate(_selected);
    }
  }

  bool get _ru =>
      (widget.locale ?? Localizations.localeOf(context)).languageCode == 'ru';

  String _compactDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return _ru
        ? '${two(date.day)}.${two(date.month)}.${date.year}'
        : '${two(date.month)}/${two(date.day)}/${date.year}';
  }

  bool _commitInput() {
    final values = RegExp(r'\d+')
        .allMatches(_inputController.text)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    DateTime? parsed;
    if (values.length == 3) {
      final day = _ru ? values[0] : values[1];
      final month = _ru ? values[1] : values[0];
      final year = values[2];
      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        parsed = candidate;
      }
    }
    final selection = CalendarSelection(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
    if (parsed == null || !selection.enabled(parsed)) {
      setState(() {
        _inputError =
            widget.errorInvalidText ??
            (_ru ? 'Дата недоступна' : 'Date unavailable');
      });
      return false;
    }
    setState(() {
      _selected = parsed!;
      _inputError = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ru = _ru;
    final colors =
        widget.theme ??
        CalendarMapTheme.forBrightness(
          MediaQuery.platformBrightnessOf(context),
        );
    final cancel = CupertinoButton(
      key: const ValueKey('cancel-date'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onPressed: () => Navigator.of(context).pop(),
      child: Text(widget.cancelText ?? (ru ? 'Отмена' : 'Cancel')),
    );
    final confirm = CupertinoButton(
      key: const ValueKey('confirm-date'),
      color: colors.accent,
      disabledColor: colors.muted.withValues(alpha: .35),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      onPressed: () {
        if (_inputMode && !_commitInput()) return;
        Navigator.of(context).pop(_selected);
      },
      child: Text(
        widget.confirmText ?? (ru ? 'Готово' : 'Done'),
        style: TextStyle(color: colors.onAccent),
      ),
    );
    final title = Row(
      children: [
        Expanded(
          child: Text(
            widget.title ?? (ru ? 'Выбор даты' : 'Choose date'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ),
        if (widget.allowTextInput)
          Semantics(
            label: _inputMode
                ? (ru ? 'Открыть календарь' : 'Open calendar')
                : (ru ? 'Ввести дату' : 'Enter date'),
            button: true,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(44, 44),
              onPressed: () => setState(() => _inputMode = !_inputMode),
              child: Icon(
                _inputMode ? CupertinoIcons.calendar : CupertinoIcons.pencil,
                color: colors.text,
              ),
            ),
          ),
      ],
    );
    final calendar = CalendarMapDatePicker(
      key: _mapKey,
      initialDate: widget.initialDate,
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      selectableDayPredicate: widget.selectableDayPredicate,
      selectedDate: _selected,
      currentDate: widget.currentDate,
      rangeStart: widget.rangeStart,
      rangeEnd: widget.rangeEnd,
      locale: widget.locale,
      firstDayOfWeek: widget.firstDayOfWeek,
      textDirection: widget.textDirection,
      controller: widget.controller,
      theme: widget.theme,
      labels: widget.labels,
      showZoomControls: widget.showZoomControls,
      showZoomHint: widget.showZoomHint,
      zoomHintDuration: widget.zoomHintDuration,
      zoomHintScale: widget.zoomHintScale,
      restorationId: widget.restorationId,
      onDateSelected: (date) {
        if (widget.selectImmediately) {
          Navigator.of(context).pop(date);
        } else {
          setState(() => _selected = date);
        }
      },
    );
    final content = _inputMode
        ? Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fieldLabelText ?? (ru ? 'Дата' : 'Date'),
                      style: TextStyle(color: colors.secondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _inputController,
                      autofocus: true,
                      keyboardType: TextInputType.datetime,
                      placeholder:
                          widget.fieldHintText ??
                          (ru ? 'ДД.ММ.ГГГГ' : 'MM/DD/YYYY'),
                      padding: const EdgeInsets.all(14),
                      style: TextStyle(color: colors.text, fontSize: 17),
                      decoration: BoxDecoration(
                        color: colors.territory,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSubmitted: (_) {
                        if (_commitInput() && widget.selectImmediately) {
                          Navigator.of(context).pop(_selected);
                        }
                      },
                    ),
                    if (_inputError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _inputError!,
                        style: TextStyle(color: colors.accent, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        : calendar;
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight * 1.25;
        if (landscape) {
          return Row(
            children: [
              Expanded(child: content),
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
            Expanded(child: content),
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
    );
    if (widget.presentation == CalendarPickerPresentation.dialog) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 740),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(color: colors.background, child: body),
            ),
          ),
        ),
      );
    }
    final framed = ColoredBox(color: colors.background, child: body);
    if (widget.presentation == CalendarPickerPresentation.fullscreen) {
      return framed;
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: framed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
