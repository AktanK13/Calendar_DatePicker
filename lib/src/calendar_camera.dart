import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// An explicitly two-dimensional camera. No scale is inferred from matrix Z.
class CalendarCamera extends ChangeNotifier {
  static const minScale = .025;
  static const maxScale = 3.5;
  double _scale = 1;
  Rect? _bounds;
  Size? _viewport;

  /// Keep the finite map inside the viewport without allowing empty overscroll.
  /// If an axis fits entirely, center it rather than permitting empty panning.
  void configureBounds(Rect bounds, Size viewport) {
    if (_bounds == bounds && _viewport == viewport) return;
    final shift = _viewport == null
        ? Offset.zero
        : viewport.center(Offset.zero) - _viewport!.center(Offset.zero);
    _bounds = bounds;
    _viewport = viewport;
    setView(scale, translation + shift);
  }

  Offset constrainTranslation(double scale, Offset translation) {
    final bounds = _bounds;
    final viewport = _viewport;
    if (bounds == null || viewport == null) return translation;
    double axis(double value, double start, double end, double extent) {
      final padding = 0.0;
      if ((end - start) * scale <= extent - padding * 2) {
        return extent / 2 - (start + end) * scale / 2;
      }
      return value.clamp(
        extent - padding - end * scale,
        padding - start * scale,
      );
    }

    return Offset(
      axis(translation.dx, bounds.left, bounds.right, viewport.width),
      axis(translation.dy, bounds.top, bounds.bottom, viewport.height),
    );
  }

  Offset _translation = Offset.zero;
  double get scale => _scale;
  Offset get translation => _translation;
  Offset worldToScreen(Offset point) => point * scale + translation;
  Offset screenToWorld(Offset point) => (point - translation) / scale;
  Rect visibleRect(Size viewport) => Rect.fromPoints(
    screenToWorld(Offset.zero),
    screenToWorld(viewport.bottomRight(Offset.zero)),
  );
  void setView(double scale, Offset translation) {
    _scale = scale.clamp(minScale, maxScale);
    _translation = constrainTranslation(_scale, translation);
    notifyListeners();
  }

  void pan(Offset delta) => setView(scale, translation + delta);
  void zoomAt(Offset focalPoint, double factor) {
    final world = screenToWorld(focalPoint);
    final next = (scale * factor).clamp(minScale, maxScale);
    setView(next, focalPoint - world * next);
  }

  static double fitScale(Rect area, Size viewport) => math
      .min(viewport.width / area.width, viewport.height / area.height)
      .clamp(minScale, maxScale);
}
