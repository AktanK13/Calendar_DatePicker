import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calendar_camera.dart';
import 'calendar_dates.dart';
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
    this.theme,
    this.locale = const Locale('ru'),
    this.labels,
    this.firstDayOfWeek = DateTime.monday,
    this.snapOnPinchEnd = true,
    this.showZoomControls = true,
    this.showZoomHint = true,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = const Cubic(.23, 1, .32, 1),
  }) {
    if (firstYear < 1 || lastYear > 9999 || firstYear > lastYear) {
      throw ArgumentError('Expected 1 <= firstYear <= lastYear <= 9999');
    }
    if (initialDate.year < firstYear || initialDate.year > lastYear) {
      throw ArgumentError('initialDate must be inside the year range');
    }
    if (firstDayOfWeek < 1 || firstDayOfWeek > 7)
      throw ArgumentError('firstDayOfWeek must be 1..7');
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
  final int firstDayOfWeek;

  /// Earliest selectable civil day, inclusive; time fields are ignored.
  final DateTime? minDate;

  /// Latest selectable civil day, inclusive; time fields are ignored.
  final DateTime? maxDate;

  /// Defaults to the surrounding Material brightness.
  final CalendarMapTheme? theme;

  /// Set false for fully free pinch zoom without settling to a territory.
  final bool snapOnPinchEnd;

  /// Whether the visible +/− controls are shown. Pinch zoom remains enabled.
  final bool showZoomControls;

  /// Plays one subtle zoom-out/zoom-in hint after the initial month appears.
  /// The hint is skipped when reduced motion is enabled and stops on input.
  final bool showZoomHint;

  /// Settling duration. Reduced motion and keyboard navigation bypass it.
  final Duration animationDuration;

  /// Interpolation for programmatic camera settling, not direct finger motion.
  final Curve animationCurve;

  /// Built-in label language: Russian for ru, English for other language codes.
  final Locale locale;

  /// Optional labels overriding [locale]; exactly 12 months and 7 weekdays.
  final CalendarMapLabels? labels;
  @override
  State<CalendarMapDatePicker> createState() => _CalendarMapDatePickerState();
}

class _CalendarMapDatePickerState extends State<CalendarMapDatePicker>
    with SingleTickerProviderStateMixin {
  final _camera = CalendarCamera();
  late CalendarNavigation _navigation;
  double _sessionScale = 1;
  bool _transitioning = false;
  final _dates = CalendarDates();
  final _focusNode = FocusNode(debugLabel: 'Calendar map');
  late final AnimationController _animation;
  late DateTime _focused;
  DateTime? _selected;
  Size? _viewport;
  bool _gestureActive = false, _gestureHadZoom = false, _gestureHadPan = false;
  bool _hintScheduled = false;
  int _hintPhase = 0;
  double _hintReturnScale = 1;
  Offset _hintReturnTranslation = Offset.zero;
  Offset _panStart = Offset.zero;
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
  );
  CalendarMapLabels get _labels =>
      widget.labels ?? CalendarMapLabels.forLocale(widget.locale);
  @override
  void initState() {
    super.initState();
    _focused = _selection.clamp(widget.initialDate);
    _selected = _focused;
    _navigation = CalendarNavigation(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      date: _focused,
    );
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
                _animation.duration = const Duration(milliseconds: 150);
                _move(_hintReturnScale, _hintReturnTranslation);
                return;
              }
              if (_hintPhase == 2) {
                _hintPhase = 0;
                _animation.duration = widget.animationDuration;
              }
              _transitioning = false;
              _applyBounds();
              if (mounted) setState(() {});
            }
          });
  }

  void _cancelHint() {
    if (_hintPhase == 0) return;
    _hintPhase = 0;
    _animation.duration = widget.animationDuration;
  }

  void _scheduleZoomHint() {
    if (_hintScheduled || !widget.showZoomHint) return;
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
      final hintScale = _camera.scale * .92;
      _hintPhase = 1;
      _animation.duration = const Duration(milliseconds: 110);
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
    _animation.duration = widget.animationDuration;
    if (_selected != null && !_selection.enabled(_selected!)) _selected = null;
    _focused = _selection.clamp(_focused);
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
  }

  void _move(double scale, Offset translation, {bool animate = true}) {
    _animation.stop();
    _transitioning = true;
    _applyBounds();
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      _camera.setView(scale, translation);
      _transitioning = false;
      _applyBounds();
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
    _navigation.focusAt(rect.center);
    _navigation.level = rect.width > CalendarGeometry.monthSize
        ? CalendarLevel.year
        : CalendarLevel.month;
    _settle(animate: animate);
  }

  void _showDate(DateTime date, {bool animate = true}) {
    _navigation.year = date.year;
    _navigation.month = date.month;
    _navigation.level = CalendarLevel.month;
    _settle(animate: animate);
  }

  void _zoom(double factor, {bool animate = true}) {
    _navigation.step(
      factor > 1,
      _camera.screenToWorld(_viewport!.center(Offset.zero)),
    );
    _settle(animate: animate);
  }

  void _finishGesture() {
    if (!mounted || _pointers.isNotEmpty || !_gestureActive) return;
    _gestureActive = false;
    if (_viewport == null) return;
    final ratio = _camera.scale / _sessionScale;
    final shouldSnap = _gestureHadZoom && widget.snapOnPinchEnd;
    _gestureHadZoom = false;
    if (shouldSnap) {
      if (ratio < .88 || ratio > 1.12) _navigation.step(ratio > 1, _snapWorld);
      _settle();
    } else if (_gestureHadPan && widget.snapOnPinchEnd) {
      _navigation.focusAt(
        _camera.screenToWorld(_viewport!.center(Offset.zero)),
      );
      _settle();
    } else {
      _transitioning = false;
      _applyBounds();
    }
    _gestureHadPan = false;
  }

  void _select(DateTime date) {
    if (!_selection.enabled(date)) return;
    setState(() {
      _selected = CalendarDates.dateOnly(date);
      _focused = _selected!;
    });
    widget.onDateSelected(_selected!);
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
    final index = CalendarGeometry.hitDay(
      local - CalendarGeometry.monthRect(month).topLeft,
    );
    if (index == null) return;
    final date = _dates.monthDays(
      year,
      month,
      firstDayOfWeek: widget.firstDayOfWeek,
    )[index];
    if (date.month == month) _select(date);
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
      setState(
        () =>
            _focused = _selection.clamp(CalendarDates.addDays(_focused, delta)),
      );
      _showDate(_focused, animate: false);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _select(_focused);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add) {
      _zoom(1.5, animate: false);
    } else if (key == LogicalKeyboardKey.minus) {
      _zoom(1 / 1.5, animate: false);
    } else if (key == LogicalKeyboardKey.home) {
      _focused = _selection.clamp(DateTime.now());
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
          CalendarMapTheme.forBrightness(Theme.of(context).brightness);
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
                  autofocus: true,
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
                              _camera.zoomAt(
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
                      onTapUp: (d) => _tap(d.localPosition),
                      onScaleStart: (d) {
                        _animation.stop();
                        _focusNode.requestFocus();
                        if (!_gestureActive) {
                          _gestureHadZoom = false;
                          _gestureHadPan = false;
                          _panStart = d.localFocalPoint;
                          _sessionScale = _camera.scale;
                        }
                        _gestureActive = true;
                        _gestureScale = _camera.scale;
                        _anchor = _camera.screenToWorld(d.localFocalPoint);
                      },
                      onScaleUpdate: (d) {
                        if ((d.localFocalPoint - _panStart).distance > 8)
                          _gestureHadPan = true;
                        if ((d.scale - 1).abs() > .02 && !_transitioning) {
                          _transitioning = true;
                          _applyBounds();
                        }
                        final scale = (_gestureScale * d.scale).clamp(
                          CalendarCamera.minScale,
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
                              focused: _focused,
                              today: DateTime.now(),
                              dates: _dates,
                              selection: _selection,
                              theme: theme,
                              labels: _labels,
                              firstDayOfWeek: widget.firstDayOfWeek,
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
                                      ? (_labels == CalendarMapLabels.ru ? 'Год' : 'Year')
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
                        TextButton(
                          onPressed: () => _showDate(
                            CalendarSelection(
                              firstYear: widget.firstYear,
                              lastYear: widget.lastYear,
                            ).clamp(DateTime.now()),
                          ),
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
                            _selected == null ? '—' : _labels.date(_selected!),
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
                child: Material(
                  color: theme.territory,
                  borderRadius: BorderRadius.circular(16),
                  child: Flex(
                    direction: landscape ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _labels.zoomIn,
                        onPressed: () => _zoom(1.5),
                        icon: Icon(Icons.add, color: theme.text),
                      ),
                      IconButton(
                        tooltip: _labels.zoomOut,
                        onPressed: () => _zoom(1 / 1.5),
                        icon: Icon(Icons.remove, color: theme.text),
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
    _animation.dispose();
    _camera.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
