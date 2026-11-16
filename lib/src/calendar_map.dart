import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'calendar_camera.dart';
import 'calendar_controller.dart';
import 'calendar_dates.dart';
import 'calendar_format.dart';
import 'calendar_geometry.dart';
import 'calendar_painter.dart';
import 'calendar_theme.dart';
import 'calendar_navigation.dart';

/// One finite, continuous calendar world. Requires bounded parent dimensions.
/// [initialDate] seeds selection once; rebuilding does not reset the camera.
///
/// Use [onDateSelected] for immediate selection, or the separate dialog helper
/// when confirmation is required. The parent must provide finite dimensions.
/// Dates are compared by civil year/month/day and callbacks return local
/// date-only values. [firstYear] and [lastYear] bound the world; [minDate] and
/// [maxDate] bound selection without hiding territories.
///
/// Changing [initialDate] on an existing state does not control its selection.
/// Supply a new key to reset the state. Rotation refits the current level.
class CalendarMapDatePicker extends StatefulWidget {
  CalendarMapDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    this.firstYear = 2000,
    this.lastYear = 2050,
    this.minDate,
    this.maxDate,
    this.selectableDayPredicate,
    this.selectedDate,
    this.selectInitialDate = true,
    this.currentDate,
    this.rangeStart,
    this.rangeEnd,
    this.controller,
    this.onViewportChanged,
    this.onDisplayedPeriodChanged,
    this.theme,
    this.locale,
    this.labels,
    this.firstDayOfWeek,
    this.textDirection,
    this.snapOnPinchEnd = true,
    this.showZoomControls = true,
    this.showZoomHint = true,
    this.zoomHintDuration = const Duration(milliseconds: 520),
    this.zoomHintScale = .86,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = const Cubic(.23, 1, .32, 1),
    this.enableHapticFeedback = true,
    this.autofocus = true,
    this.restorationId,
  }) {
    if (firstYear < 1 || lastYear > 9999 || firstYear > lastYear) {
      throw ArgumentError('Expected 1 <= firstYear <= lastYear <= 9999');
    }
    if (initialDate.year < firstYear || initialDate.year > lastYear) {
      throw ArgumentError('initialDate must be inside the year range');
    }
    if (selectedDate != null &&
        (selectedDate!.year < firstYear || selectedDate!.year > lastYear)) {
      throw ArgumentError('selectedDate must be inside the year range');
    }
    if (firstDayOfWeek != null &&
        (firstDayOfWeek! < 1 || firstDayOfWeek! > 7)) {
      throw ArgumentError('firstDayOfWeek must be 1..7');
    }
    if (zoomHintDuration.isNegative) {
      throw ArgumentError('zoomHintDuration must not be negative');
    }
    if (zoomHintScale <= 0 || zoomHintScale >= 1) {
      throw ArgumentError('zoomHintScale must be greater than 0 and below 1');
    }
    if (labels != null &&
        (labels!.months.length != 12 || labels!.weekdays.length != 7)) {
      throw ArgumentError('Labels require 12 months and 7 weekdays');
    }
    final lo = minDate ?? DateTime(firstYear);
    final hi = maxDate ?? DateTime(lastYear, 12, 31);
    if (CalendarDates.key(lo) > CalendarDates.key(hi) ||
        hi.year < firstYear ||
        lo.year > lastYear) {
      throw ArgumentError('Selection bounds must intersect the year range');
    }
    if (rangeEnd != null && rangeStart == null) {
      throw ArgumentError('rangeEnd requires rangeStart');
    }
    if (rangeStart != null &&
        (rangeStart!.year < firstYear || rangeStart!.year > lastYear)) {
      throw ArgumentError('rangeStart must be inside the year range');
    }
    if (rangeEnd != null &&
        (rangeEnd!.year < firstYear ||
            rangeEnd!.year > lastYear ||
            CalendarDates.key(rangeEnd!) < CalendarDates.key(rangeStart!))) {
      throw ArgumentError('rangeEnd must be on or after rangeStart');
    }
    final selection = CalendarSelection(
      firstYear: firstYear,
      lastYear: lastYear,
      minDate: minDate,
      maxDate: maxDate,
      selectableDayPredicate: selectableDayPredicate,
    );
    final initialSelection = selection.clamp(selectedDate ?? initialDate);
    if (!selection.enabled(initialSelection)) {
      throw ArgumentError(
        'initialDate/selectedDate must satisfy selectableDayPredicate',
      );
    }
  }

  /// Initial civil date. Its year must belong to the configured year range.
  final DateTime initialDate;

  /// Called immediately for each enabled day selection, including repeat taps.
  final ValueChanged<DateTime> onDateSelected;

  /// First rendered year, inclusive, from 1 through 9999.
  final int firstYear;

  /// Last rendered year, inclusive, not before [firstYear].
  final int lastYear;

  /// First weekday: Monday is 1, Sunday is 7, independently of [locale].
  final int? firstDayOfWeek;

  /// Earliest selectable civil day, inclusive; time fields are ignored.
  final DateTime? minDate;

  /// Latest selectable civil day, inclusive; time fields are ignored.
  final DateTime? maxDate;

  /// Optional business rule for weekends, holidays, availability, and similar.
  final CalendarSelectableDayPredicate? selectableDayPredicate;

  /// Controlled selection value. Parent rebuilds can update the selection.
  final DateTime? selectedDate;

  /// Whether [initialDate] is also painted as selected when no controlled value
  /// is supplied. Range pickers disable this before their first tap.
  final bool selectInitialDate;

  /// Date highlighted as today. Null follows the system date and midnight.
  final DateTime? currentDate;

  /// Optional visual range start. It is drawn as an accent endpoint.
  final DateTime? rangeStart;

  /// Optional visual range end. Days between the endpoints use a softer fill.
  final DateTime? rangeEnd;

  /// Optional imperative controller and observable viewport state.
  final CalendarMapController? controller;

  /// Called after the visible map area changes.
  final ValueChanged<CalendarMapViewport>? onViewportChanged;

  /// Called when the month at the viewport center changes.
  final ValueChanged<DateTime>? onDisplayedPeriodChanged;

  /// Defaults to the platform brightness from [MediaQuery].
  final CalendarMapTheme? theme;

  /// Set false for fully free pinch zoom without settling to a territory.
  final bool snapOnPinchEnd;

  /// Whether the visible +/− controls are shown. Pinch zoom remains enabled.
  final bool showZoomControls;

  /// Plays one subtle zoom-out/zoom-in hint after the initial month appears.
  /// The hint is skipped when reduced motion is enabled and stops on input.
  final bool showZoomHint;

  /// Total duration of the initial zoom-out/zoom-in explanation.
  /// Set [showZoomHint] to false to disable it completely.
  final Duration zoomHintDuration;

  /// Scale used at the furthest point of the initial hint.
  /// Lower values make the zoom-out more visible. Must be between 0 and 1.
  final double zoomHintScale;

  /// Settling duration. Reduced motion and keyboard navigation bypass it.
  final Duration animationDuration;

  /// Interpolation for programmatic camera settling, not direct finger motion.
  final Curve animationCurve;

  final bool enableHapticFeedback;
  final bool autofocus;
  final String? restorationId;

  /// Built-in label language: Russian for ru, English for other language codes.
  final Locale? locale;

  /// Overrides the ambient LTR/RTL direction.
  final TextDirection? textDirection;

  /// Optional labels overriding [locale]; exactly 12 months and 7 weekdays.
  final CalendarMapLabels? labels;
  @override
  State<CalendarMapDatePicker> createState() => _CalendarMapDatePickerState();
}

class _CalendarMapDatePickerState extends State<CalendarMapDatePicker>
    with SingleTickerProviderStateMixin, RestorationMixin
    implements CalendarMapControllerDelegate {
  final _camera = CalendarCamera();
  late CalendarNavigation _navigation;
  double _sessionScale = 1;
  bool _transitioning = false;
  final _dates = CalendarDates();
  final _focusNode = FocusNode(debugLabel: 'Calendar map');
  late final AnimationController _animation;
  late DateTime _focused;
  DateTime? _selected;
  DateTime? _hovered, _pressed;
  Timer? _midnightTimer;
  bool _viewportNotificationScheduled = false;
  CalendarMapViewport? _lastViewport;
  DateTime? _lastDisplayedPeriod;
  late final RestorableDateTimeN _restoredSelected;
  late final RestorableDateTime _restoredFocused;
  late final RestorableInt _restoredYear;
  late final RestorableInt _restoredMonth;
  late final RestorableInt _restoredLevel;
  Size? _viewport;
  bool _gestureActive = false, _gestureHadZoom = false, _gestureHadPan = false;
  bool _hintScheduled = false;
  int _hintPhase = 0;
  double _hintReturnScale = 1;
  Offset _hintReturnTranslation = Offset.zero;
  Offset _panStart = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  Velocity _gestureEndVelocity = Velocity.zero;
  Offset _snapWorld = Offset.zero;
  final _pointers = <int>{};
  double _fromScale = 1, _toScale = 1, _gestureScale = 1;
  Offset _fromTranslation = Offset.zero,
      _toTranslation = Offset.zero,
      _anchor = Offset.zero;
  CalendarSelection get _selection => CalendarSelection(
    firstYear: widget.firstYear,
    lastYear: widget.lastYear,
    minDate: widget.minDate,
    maxDate: widget.maxDate,
    selectableDayPredicate: widget.selectableDayPredicate,
  );
  Locale get _locale =>
      widget.locale ??
      Localizations.maybeLocaleOf(context) ??
      const Locale('en');
  CalendarMapLabels get _labels =>
      widget.labels ?? CalendarMapLabels.forLocale(_locale);
  int get _firstDayOfWeek {
    if (widget.firstDayOfWeek != null) return widget.firstDayOfWeek!;
    return DateTime.monday;
  }

  TextDirection get _textDirection =>
      widget.textDirection ?? Directionality.of(context);
  DateTime get _today =>
      CalendarDates.dateOnly(widget.currentDate ?? DateTime.now());

  @override
  String? get restorationId => widget.restorationId;

  @override
  void initState() {
    super.initState();
    _focused = _selection.nearestEnabled(
      widget.selectedDate ?? widget.initialDate,
    );
    _selected = widget.selectedDate != null
        ? CalendarDates.dateOnly(widget.selectedDate!)
        : widget.selectInitialDate
        ? _focused
        : null;
    _navigation = CalendarNavigation(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      date: _focused,
    );
    _restoredSelected = RestorableDateTimeN(_selected);
    _restoredFocused = RestorableDateTime(_focused);
    _restoredYear = RestorableInt(_navigation.year);
    _restoredMonth = RestorableInt(_navigation.month);
    _restoredLevel = RestorableInt(_navigation.level.index);
    _animation =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addListener(() {
            final t = widget.animationCurve.transform(_animation.value);
            _camera.setView(
              _fromScale + (_toScale - _fromScale) * t,
              Offset.lerp(_fromTranslation, _toTranslation, t)!,
            );
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (_hintPhase == 1) {
                _hintPhase = 2;
                _animation.duration = _hintDuration(.55);
                _move(_hintReturnScale, _hintReturnTranslation);
                return;
              }
              if (_hintPhase == 2) {
                _hintPhase = 0;
                _animation.duration = widget.animationDuration;
              }
              _transitioning = false;
              _applyBounds();
              _scheduleViewportNotification();
              if (mounted) setState(() {});
            }
          });
    _camera.addListener(_scheduleViewportNotification);
    widget.controller?.attach(this);
    _scheduleMidnightRefresh();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredSelected, 'selected_date');
    registerForRestoration(_restoredFocused, 'focused_date');
    registerForRestoration(_restoredYear, 'visible_year');
    registerForRestoration(_restoredMonth, 'visible_month');
    registerForRestoration(_restoredLevel, 'zoom_level');
    final restoredSelected = _restoredSelected.value;
    _selected = restoredSelected != null && _selection.enabled(restoredSelected)
        ? restoredSelected
        : null;
    _focused = _selection.nearestEnabled(_restoredFocused.value);
    _navigation.year = _restoredYear.value.clamp(
      widget.firstYear,
      widget.lastYear,
    );
    _navigation.month = _restoredMonth.value.clamp(1, 12);
    _navigation.level = CalendarLevel
        .values[_restoredLevel.value.clamp(0, CalendarLevel.values.length - 1)];
  }

  void _updateRestorationState() {
    _restoredSelected.value = _selected;
    _restoredFocused.value = _focused;
    _restoredYear.value = _navigation.year;
    _restoredMonth.value = _navigation.month;
    _restoredLevel.value = _navigation.level.index;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    if (widget.currentDate != null) return;
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleMidnightRefresh();
      },
    );
  }

  CalendarMapViewport? _viewportSnapshot() {
    final size = _viewport;
    if (size == null) return null;
    final visible = _camera.visibleRect(size);
    final centerNavigation = CalendarNavigation(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      date: _focused,
    )..focusAt(visible.center);
    final years = <int>[];
    final maxRow =
        (widget.lastYear -
            widget.firstYear +
            CalendarGeometry.leadingSlots(widget.firstYear)) ~/
        CalendarGeometry.columns;
    final firstRow = (visible.top / CalendarGeometry.stride).floor().clamp(
      0,
      maxRow,
    );
    final lastRow = (visible.bottom / CalendarGeometry.stride).floor().clamp(
      0,
      maxRow,
    );
    for (var row = firstRow; row <= lastRow; row++) {
      for (var column = 0; column < CalendarGeometry.columns; column++) {
        final year =
            widget.firstYear +
            row * CalendarGeometry.columns +
            column -
            CalendarGeometry.leadingSlots(widget.firstYear);
        if (year >= widget.firstYear &&
            year <= widget.lastYear &&
            CalendarGeometry.yearRect(
              year,
              widget.firstYear,
            ).overlaps(visible)) {
          years.add(year);
        }
      }
    }
    return CalendarMapViewport(
      level: switch (_navigation.level) {
        CalendarLevel.overview => CalendarMapZoomLevel.overview,
        CalendarLevel.year => CalendarMapZoomLevel.year,
        CalendarLevel.month => CalendarMapZoomLevel.month,
      },
      centerDate: DateTime(centerNavigation.year, centerNavigation.month),
      visibleWorld: visible,
      visibleYears: List.unmodifiable(years),
      scale: _camera.scale,
    );
  }

  void _scheduleViewportNotification() {
    if (_viewportNotificationScheduled || !mounted) return;
    _viewportNotificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportNotificationScheduled = false;
      if (!mounted) return;
      final snapshot = _viewportSnapshot();
      if (snapshot == null) return;
      _updateRestorationState();
      widget.controller?.update(viewport: snapshot, selectedDate: _selected);
      if (snapshot == _lastViewport) return;
      _lastViewport = snapshot;
      widget.onViewportChanged?.call(snapshot);
      final displayed = snapshot.centerDate;
      if (_lastDisplayedPeriod == null ||
          _lastDisplayedPeriod!.year != displayed.year ||
          _lastDisplayedPeriod!.month != displayed.month) {
        _lastDisplayedPeriod = displayed;
        widget.onDisplayedPeriodChanged?.call(displayed);
      }
    });
  }

  void _cancelHint() {
    if (_hintPhase == 0) return;
    _hintPhase = 0;
    _animation.duration = widget.animationDuration;
  }

  Duration _hintDuration(double fraction) => Duration(
    microseconds: (widget.zoomHintDuration.inMicroseconds * fraction).round(),
  );

  void _scheduleZoomHint() {
    if (_hintScheduled ||
        !widget.showZoomHint ||
        widget.zoomHintDuration == Duration.zero) {
      return;
    }
    _hintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _viewport == null ||
          MediaQuery.disableAnimationsOf(context) ||
          _navigation.level != CalendarLevel.month) {
        return;
      }
      final rect = _navigation.target;
      final center = _viewport!.center(Offset.zero);
      _hintReturnScale = _camera.scale;
      _hintReturnTranslation = _camera.translation;
      final hintScale = _camera.scale * widget.zoomHintScale;
      _hintPhase = 1;
      _animation.duration = _hintDuration(.45);
      _move(hintScale, center - rect.center * hintScale);
    });
  }

  void _applyBounds() {
    if (_viewport != null)
      _camera.configureBounds(
        _transitioning
            ? CalendarGeometry.worldBounds(
                widget.firstYear,
                widget.lastYear,
              ).expandToInclude(_navigation.overviewBounds)
            : _navigation.panBounds,
        _viewport!,
      );
  }

  @override
  void didUpdateWidget(CalendarMapDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restorationId != widget.restorationId) {
      didUpdateRestorationId();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
    _animation.duration = widget.animationDuration;
    if (oldWidget.currentDate != widget.currentDate) _scheduleMidnightRefresh();
    if (widget.selectedDate != null &&
        !CalendarDates.same(widget.selectedDate!, _selected ?? _focused)) {
      _selected = CalendarDates.dateOnly(widget.selectedDate!);
      _focused = _selected!;
    }
    if (_selected != null && !_selection.enabled(_selected!)) {
      _selected = null;
    }
    _focused = _selection.nearestEnabled(_focused);
    if (oldWidget.firstYear != widget.firstYear ||
        oldWidget.lastYear != widget.lastYear) {
      _animation.stop();
      _navigation = CalendarNavigation(
        firstYear: widget.firstYear,
        lastYear: widget.lastYear,
        date: _focused,
      );
      if (_viewport != null) _showDate(_focused, animate: false);
    }
    _scheduleViewportNotification();
  }

  void _move(double scale, Offset translation, {bool animate = true}) {
    _animation.stop();
    _transitioning = true;
    _applyBounds();
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      _camera.setView(scale, translation);
      _transitioning = false;
      _applyBounds();
      _scheduleViewportNotification();
      setState(() {});
      return;
    }
    _fromScale = _camera.scale;
    _fromTranslation = _camera.translation;
    _toScale = scale;
    _toTranslation = _camera.constrainTranslation(scale, translation);
    _animation.forward(from: 0);
  }

  void _settle({bool animate = true}) {
    final size = _viewport!;
    final rect = _navigation.target;
    final scale = CalendarCamera.fitScale(rect, size);
    _move(
      scale,
      size.center(Offset.zero) - rect.center * scale,
      animate: animate,
    );
  }

  void _showArea(Rect rect, {bool animate = true}) {
    final previousLevel = _navigation.level;
    _navigation.focusAt(rect.center);
    _navigation.level = rect.width > CalendarGeometry.monthSize
        ? CalendarLevel.year
        : CalendarLevel.month;
    if (previousLevel != _navigation.level) _haptic();
    _settle(animate: animate);
  }

  void _showDate(DateTime date, {bool animate = true}) {
    _navigation.year = date.year;
    _navigation.month = date.month;
    _navigation.level = CalendarLevel.month;
    _settle(animate: animate);
  }

  void _zoom(double factor, {bool animate = true}) {
    if (factor < 1 && _navigation.level == CalendarLevel.overview) return;
    final previousLevel = _navigation.level;
    _navigation.step(
      factor > 1,
      _camera.screenToWorld(_viewport!.center(Offset.zero)),
    );
    if (previousLevel != _navigation.level) _haptic();
    _settle(animate: animate);
  }

  double get _minimumInteractiveScale {
    if (_viewport == null) return CalendarCamera.minScale;
    // Apply the overview boundary throughout a pinch, including the frame in
    // which a year first becomes the 3×3 overview. This prevents overshooting
    // the furthest useful scale before the gesture settles to that level.
    return CalendarCamera.fitScale(_navigation.overviewBounds, _viewport!);
  }

  void _zoomAt(Offset focalPoint, double factor) {
    final world = _camera.screenToWorld(focalPoint);
    final next = (_camera.scale * factor).clamp(
      _minimumInteractiveScale,
      CalendarCamera.maxScale,
    );
    _camera.setView(next, focalPoint - world * next);
  }

  void _zoomInToCurrent({bool animate = true}) {
    final current = _selection.nearestEnabled(_today);
    _navigation.year = current.year;
    if (_navigation.level == CalendarLevel.overview) {
      _navigation.level = CalendarLevel.year;
    } else {
      _navigation.month = current.month;
      _navigation.level = CalendarLevel.month;
    }
    _settle(animate: animate);
  }

  @override
  void showDate(DateTime date, {bool animate = true}) {
    final target = _selection.nearestEnabled(date);
    _focused = target;
    _showDate(target, animate: animate);
  }

  @override
  void showYear(int year, {bool animate = true}) {
    _navigation.year = year.clamp(widget.firstYear, widget.lastYear);
    _navigation.level = CalendarLevel.year;
    _settle(animate: animate);
  }

  @override
  void showOverview({int? centerYear, bool animate = true}) {
    if (centerYear != null) {
      _navigation.year = centerYear.clamp(widget.firstYear, widget.lastYear);
    }
    _navigation.level = CalendarLevel.overview;
    _settle(animate: animate);
  }

  @override
  void showToday({bool animate = true}) => showDate(_today, animate: animate);

  @override
  void zoomIn({bool animate = true}) => _zoomInToCurrent(animate: animate);

  @override
  void zoomOut({bool animate = true}) => _zoom(1 / 1.5, animate: animate);

  @override
  void selectDate(DateTime date) => _select(date);

  void _haptic() {
    if (widget.enableHapticFeedback) HapticFeedback.selectionClick();
  }

  void _finishGesture() {
    if (!mounted || _pointers.isNotEmpty || !_gestureActive) return;
    _gestureActive = false;
    if (_viewport == null) return;
    final ratio = _camera.scale / _sessionScale;
    final shouldSnap = _gestureHadZoom && widget.snapOnPinchEnd;
    _gestureHadZoom = false;
    if (shouldSnap) {
      if (ratio < .88 || ratio > 1.12) {
        final previousLevel = _navigation.level;
        _navigation.step(ratio > 1, _snapWorld);
        if (previousLevel != _navigation.level) _haptic();
      }
      _settle();
    } else if (_gestureHadPan && widget.snapOnPinchEnd) {
      if (!_snapToAdjacentMonth()) {
        _navigation.focusAt(
          _camera.screenToWorld(_viewport!.center(Offset.zero)),
        );
      }
      _settle();
    } else {
      _transitioning = false;
      _applyBounds();
    }
    _gestureHadPan = false;
    _gestureEndVelocity = Velocity.zero;
  }

  /// A month is almost a full phone-width at the readable zoom. Waiting for
  /// its centre to cross the viewport midpoint made normal swipes feel stuck.
  /// A short intentional drag or flick now advances to the physical neighbour
  /// in the 4 x 3 month grid, while the map still tracks the finger 1:1.
  bool _snapToAdjacentMonth() {
    if (_navigation.level != CalendarLevel.month || _viewport == null) {
      return false;
    }
    final drag = _lastFocalPoint - _panStart;
    final velocity = _gestureEndVelocity.pixelsPerSecond;
    const projectionSeconds = .16;
    final projected = drag + velocity * projectionSeconds;
    final horizontal = projected.dx.abs() >= projected.dy.abs();
    final distance = horizontal ? drag.dx.abs() : drag.dy.abs();
    final speed = horizontal ? velocity.dx.abs() : velocity.dy.abs();
    if (distance < 24 && speed < 220) return false;

    final month = _navigation.month;
    final column = (month - 1) % 4;
    final row = (month - 1) ~/ 4;
    int target;
    if (horizontal) {
      final direction = projected.dx < 0 ? 1 : -1;
      final nextColumn = column + direction;
      if (nextColumn < 0 || nextColumn > 3) return false;
      target = month + direction;
    } else {
      final direction = projected.dy < 0 ? 1 : -1;
      final nextRow = row + direction;
      if (nextRow < 0 || nextRow > 2) return false;
      target = month + direction * 4;
    }
    if (target == month) return false;
    _navigation.month = target;
    _haptic();
    return true;
  }

  void _select(DateTime date) {
    if (!_selection.enabled(date)) return;
    _haptic();
    setState(() {
      _selected = CalendarDates.dateOnly(date);
      _focused = _selected!;
    });
    widget.onDateSelected(_selected!);
    _scheduleViewportNotification();
  }

  DateTime? _dateAt(Offset screen) {
    if (_viewport == null ||
        _navigation.level != CalendarLevel.month ||
        _camera.scale <
            math.min(
              CalendarMapPainter.readableScale,
              _viewport!.width / CalendarGeometry.monthSize * .95,
            )) {
      return null;
    }
    final world = _camera.screenToWorld(screen);
    final year = CalendarGeometry.hitYear(
      world,
      widget.firstYear,
      widget.lastYear,
    );
    if (year == null) return null;
    final local = world - CalendarGeometry.yearOrigin(year, widget.firstYear);
    final month = CalendarGeometry.hitMonth(local);
    if (month == null) return null;
    final visualIndex = CalendarGeometry.hitDay(
      local - CalendarGeometry.monthRect(month).topLeft,
    );
    if (visualIndex == null) return null;
    final row = visualIndex ~/ 7;
    final column = visualIndex % 7;
    final index = _textDirection == TextDirection.rtl
        ? row * 7 + (6 - column)
        : visualIndex;
    final date = _dates.monthDays(
      year,
      month,
      firstDayOfWeek: _firstDayOfWeek,
    )[index];
    return date.month == month ? date : null;
  }

  void _tap(Offset screen) {
    _focusNode.requestFocus();
    final world = _camera.screenToWorld(screen);
    final year = CalendarGeometry.hitYear(
      world,
      widget.firstYear,
      widget.lastYear,
    );
    if (year == null) return;
    if (_navigation.level == CalendarLevel.overview) {
      _showArea(CalendarGeometry.yearRect(year, widget.firstYear));
      return;
    }
    final local = world - CalendarGeometry.yearOrigin(year, widget.firstYear);
    final month = CalendarGeometry.hitMonth(local);
    if (month == null) {
      _showArea(CalendarGeometry.yearRect(year, widget.firstYear));
      return;
    }
    if (_navigation.level == CalendarLevel.year ||
        _camera.scale <
            math.min(
              CalendarMapPainter.readableScale,
              _viewport!.width / CalendarGeometry.monthSize * .95,
            )) {
      _showArea(CalendarGeometry.worldMonth(year, month, widget.firstYear));
      return;
    }
    final date = _dateAt(screen);
    if (date != null) _select(date);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent)
      return KeyEventResult.ignored;
    final key = event.logicalKey;
    final delta = {
      LogicalKeyboardKey.arrowLeft: -1,
      LogicalKeyboardKey.arrowRight: 1,
      LogicalKeyboardKey.arrowUp: -7,
      LogicalKeyboardKey.arrowDown: 7,
    }[key];
    if (delta != null) {
      setState(() => _focused = _selection.move(_focused, delta));
      _showDate(_focused, animate: false);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _select(_focused);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add) {
      _zoomInToCurrent(animate: false);
    } else if (key == LogicalKeyboardKey.minus) {
      _zoom(1 / 1.5, animate: false);
    } else if (key == LogicalKeyboardKey.home) {
      _focused = _selection.nearestEnabled(_today);
      _showDate(_focused, animate: false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hostSize = constraints.biggest;
      if (!hostSize.isFinite) return const SizedBox.shrink();
      final landscape = hostSize.width > hostSize.height * 1.25;
      final railWidth = landscape ? math.min(200.0, hostSize.width * .34) : 0.0;
      final mapWidth = hostSize.width - railWidth;
      final side = math.max(
        1.0,
        math.min(mapWidth - 24, hostSize.height - (landscape ? 24 : 160)),
      );
      final size = Size.square(side);
      final mapRect = Rect.fromCenter(
        center: Offset(mapWidth / 2, hostSize.height / 2),
        width: side,
        height: side,
      );
      if (_viewport == null) {
        _viewport = size;
        _applyBounds();
        final rect = _navigation.target;
        final scale = CalendarCamera.fitScale(rect, size);
        _camera.setView(scale, size.center(Offset.zero) - rect.center * scale);
        _scheduleZoomHint();
      } else if (_viewport != size) {
        _animation.stop();
        _transitioning = false;
        _viewport = size;
        _applyBounds();
        final rect = _navigation.target;
        final scale = CalendarCamera.fitScale(rect, size);
        _camera.setView(scale, size.center(Offset.zero) - rect.center * scale);
      }
      final theme =
          widget.theme ??
          CalendarMapTheme.forBrightness(
            MediaQuery.platformBrightnessOf(context),
          );
      return ColoredBox(
        color: theme.background,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: mapRect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onKeyEvent: _key,
                  child: Listener(
                    onPointerDown: (event) {
                      _animation.stop();
                      _cancelHint();
                      _pointers.add(event.pointer);
                    },
                    onPointerUp: (event) {
                      _pointers.remove(event.pointer);
                      // ScaleRecognizer may end when the first finger lifts and
                      // omit a second end callback if the remaining finger is still.
                      if (_pointers.isEmpty) scheduleMicrotask(_finishGesture);
                    },
                    onPointerCancel: (event) {
                      _pointers.remove(event.pointer);
                      _gestureHadZoom = false;
                      if (_pointers.isEmpty) _gestureActive = false;
                    },
                    onPointerHover: (event) {
                      final next = _dateAt(event.localPosition);
                      if ((_hovered == null && next == null) ||
                          (_hovered != null &&
                              next != null &&
                              CalendarDates.same(_hovered!, next))) {
                        return;
                      }
                      setState(() => _hovered = next);
                    },
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        GestureBinding.instance.pointerSignalResolver.register(
                          event,
                          (event) {
                            final scroll = event as PointerScrollEvent;
                            _animation.stop();
                            // Horizontal wheel / Shift-wheel pans; vertical wheel zooms at pointer.
                            if (HardwareKeyboard.instance.isShiftPressed ||
                                scroll.scrollDelta.dx.abs() >
                                    scroll.scrollDelta.dy.abs()) {
                              _camera.pan(-scroll.scrollDelta);
                            } else {
                              _zoomAt(
                                scroll.localPosition,
                                math.exp(-scroll.scrollDelta.dy / 350),
                              );
                            }
                          },
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          setState(() => _pressed = _dateAt(d.localPosition)),
                      onTapCancel: () => setState(() => _pressed = null),
                      onTapUp: (d) {
                        setState(() => _pressed = null);
                        _tap(d.localPosition);
                      },
                      onScaleStart: (d) {
                        _animation.stop();
                        _focusNode.requestFocus();
                        if (!_gestureActive) {
                          _gestureHadZoom = false;
                          _gestureHadPan = false;
                          _panStart = d.localFocalPoint;
                          _lastFocalPoint = d.localFocalPoint;
                          _gestureEndVelocity = Velocity.zero;
                          _sessionScale = _camera.scale;
                        }
                        _gestureActive = true;
                        _gestureScale = _camera.scale;
                        _anchor = _camera.screenToWorld(d.localFocalPoint);
                      },
                      onScaleUpdate: (d) {
                        _lastFocalPoint = d.localFocalPoint;
                        if ((d.localFocalPoint - _panStart).distance > 8)
                          _gestureHadPan = true;
                        if ((d.scale - 1).abs() > .02 && !_transitioning) {
                          _transitioning = true;
                          _applyBounds();
                        }
                        final scale = (_gestureScale * d.scale).clamp(
                          _minimumInteractiveScale,
                          CalendarCamera.maxScale,
                        );
                        _camera.setView(
                          scale,
                          d.localFocalPoint - _anchor * scale,
                        );
                        if ((d.scale - 1).abs() > .06) {
                          _gestureHadZoom = true;
                          _snapWorld = _camera.screenToWorld(d.localFocalPoint);
                        }
                      },
                      onScaleEnd: (d) {
                        _gestureEndVelocity = d.velocity;
                        if (d.pointerCount == 0) _finishGesture();
                      },
                      child: AnimatedBuilder(
                        animation: _camera,
                        builder: (context, _) => RepaintBoundary(
                          child: CustomPaint(
                            key: const ValueKey('calendar-surface'),
                            painter: CalendarMapPainter(
                              camera: _camera,
                              level: _navigation.level,
                              viewport: size,
                              firstYear: widget.firstYear,
                              lastYear: widget.lastYear,
                              selected: _selected,
                              rangeStart: widget.rangeStart,
                              rangeEnd: widget.rangeEnd,
                              focused: _focused,
                              today: _today,
                              dates: _dates,
                              selection: _selection,
                              theme: theme,
                              labels: _labels,
                              firstDayOfWeek: _firstDayOfWeek,
                              textDirection: _textDirection,
                              dateLabel: (date) =>
                                  calendarFullDate(date, _locale, _labels),
                              hovered: _hovered,
                              pressed: _pressed,
                              onDate: _select,
                              onArea: _showArea,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: landscape ? mapWidth : 16,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Flex(
                    direction: landscape ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: landscape ? 0 : 1,
                        fit: landscape ? FlexFit.loose : FlexFit.tight,
                        child: IgnorePointer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labels.map,
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_navigation.year} · ${_navigation.level == CalendarLevel.month
                                    ? _labels.months[_navigation.month - 1]
                                    : _navigation.level == CalendarLevel.year
                                    ? _labels.year
                                    : '3 × 3'}',
                                style: TextStyle(
                                  color: theme.secondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        minimumSize: const Size(44, 36),
                        onPressed: () =>
                            _showDate(_selection.nearestEnabled(_today)),
                        child: Text(
                          _labels.today,
                          style: TextStyle(color: theme.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: landscape ? 76 : 20,
              left: landscape ? mapWidth : 16,
              right: landscape ? 12 : 76,
              child: IgnorePointer(
                child: Semantics(
                  liveRegion: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.territory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selected == null
                                ? '—'
                                : calendarFullDate(
                                    _selected!,
                                    _locale,
                                    _labels,
                                  ),
                            style: TextStyle(color: theme.text, fontSize: 16),
                          ),
                          if (size.width > 520)
                            Text(
                              _labels.hint,
                              style: TextStyle(
                                color: theme.secondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showZoomControls)
              Positioned(
                bottom: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.territory,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Flex(
                    direction: landscape ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: _labels.zoomIn,
                        button: true,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(10),
                          minimumSize: const Size(44, 44),
                          onPressed: () => _zoomInToCurrent(),
                          child: Icon(CupertinoIcons.add, color: theme.text),
                        ),
                      ),
                      Semantics(
                        label: _labels.zoomOut,
                        button: true,
                        enabled: _navigation.level != CalendarLevel.overview,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(10),
                          minimumSize: const Size(44, 44),
                          onPressed: _navigation.level == CalendarLevel.overview
                              ? null
                              : () => _zoom(1 / 1.5),
                          child: Icon(
                            CupertinoIcons.minus,
                            color: _navigation.level == CalendarLevel.overview
                                ? theme.muted
                                : theme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
  @override
  void dispose() {
    widget.controller?.detach(this);
    _midnightTimer?.cancel();
    _camera.removeListener(_scheduleViewportNotification);
    _animation.dispose();
    _camera.dispose();
    _focusNode.dispose();
    _restoredSelected.dispose();
    _restoredFocused.dispose();
    _restoredYear.dispose();
    _restoredMonth.dispose();
    _restoredLevel.dispose();
    super.dispose();
  }
}
