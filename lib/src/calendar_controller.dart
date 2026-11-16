import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Public detail level of the single continuous calendar map.
enum CalendarMapZoomLevel { overview, year, month }

/// Immutable snapshot emitted after the visible map area changes.
@immutable
class CalendarMapViewport {
  const CalendarMapViewport({
    required this.level,
    required this.centerDate,
    required this.visibleWorld,
    required this.visibleYears,
    required this.scale,
  });

  final CalendarMapZoomLevel level;
  final DateTime centerDate;
  final Rect visibleWorld;
  final List<int> visibleYears;
  final double scale;

  @override
  bool operator ==(Object other) =>
      other is CalendarMapViewport &&
      other.level == level &&
      other.centerDate == centerDate &&
      other.visibleWorld == visibleWorld &&
      listEquals(other.visibleYears, visibleYears) &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(
    level,
    centerDate,
    visibleWorld,
    Object.hashAll(visibleYears),
    scale,
  );
}

/// Commands implemented by the attached map widget.
///
/// This interface is public only so the controller can live separately from
/// the widget implementation. Applications should use [CalendarMapController]
/// rather than implement this interface.
abstract interface class CalendarMapControllerDelegate {
  void showDate(DateTime date, {bool animate});
  void showYear(int year, {bool animate});
  void showOverview({int? centerYear, bool animate});
  void showToday({bool animate});
  void zoomIn({bool animate});
  void zoomOut({bool animate});
  void selectDate(DateTime date);
}

/// Imperative controller and observable state for [CalendarMapDatePicker].
///
/// Commands require an attached picker. The controller can be reused after a
/// picker is disposed and attached to another picker.
class CalendarMapController extends ChangeNotifier {
  CalendarMapControllerDelegate? _delegate;
  CalendarMapViewport? _viewport;
  DateTime? _selectedDate;

  CalendarMapViewport? get viewport => _viewport;
  DateTime? get selectedDate => _selectedDate;
  bool get hasClients => _delegate != null;

  CalendarMapControllerDelegate get _client {
    final client = _delegate;
    if (client == null) {
      throw StateError('CalendarMapController is not attached to a picker');
    }
    return client;
  }

  void showDate(DateTime date, {bool animate = true}) =>
      _client.showDate(date, animate: animate);

  void showYear(int year, {bool animate = true}) =>
      _client.showYear(year, animate: animate);

  void showOverview({int? centerYear, bool animate = true}) =>
      _client.showOverview(centerYear: centerYear, animate: animate);

  void showToday({bool animate = true}) => _client.showToday(animate: animate);

  void zoomIn({bool animate = true}) => _client.zoomIn(animate: animate);
  void zoomOut({bool animate = true}) => _client.zoomOut(animate: animate);
  void selectDate(DateTime date) => _client.selectDate(date);

  @internal
  void attach(CalendarMapControllerDelegate delegate) {
    if (_delegate != null && _delegate != delegate) {
      throw StateError('CalendarMapController is already attached');
    }
    _delegate = delegate;
  }

  @internal
  void detach(CalendarMapControllerDelegate delegate) {
    if (_delegate == delegate) _delegate = null;
  }

  @internal
  void update({
    required CalendarMapViewport viewport,
    required DateTime? selectedDate,
  }) {
    if (_viewport == viewport && _selectedDate == selectedDate) return;
    _viewport = viewport;
    _selectedDate = selectedDate;
    notifyListeners();
  }
}
