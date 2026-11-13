# API reference

Import the supported public entry point:

```dart
import 'package:calendar_date_picker/calendar_date_picker.dart';
```

Do not import `src/calendar_navigation.dart` or `src/calendar_painter.dart` in app code. Those are implementation details.

## `showCalendarMapDatePicker`

Returns `Future<DateTime?>`. A confirmed date is local date-only; dismissal returns `null`.

| Parameter | Type | Default / requirement | Meaning |
| --- | --- | --- | --- |
| `context` | `BuildContext` | Required | Descendant of a Navigator with Material localizations |
| `initialDate` | `DateTime` | Required | Initial selected date/month; year must be in range |
| `firstYear` | `int` | `2000` | First rendered year, inclusive |
| `lastYear` | `int` | `2050` | Last rendered year, inclusive |
| `minDate` | `DateTime?` | `null` | Earliest selectable civil date |
| `maxDate` | `DateTime?` | `null` | Latest selectable civil date |
| `locale` | `Locale` | `Locale('ru')` | Russian or English fallback labels |
| `firstDayOfWeek` | `int` | `DateTime.monday` | `1…7`, Monday…Sunday |
| `theme` | `CalendarMapTheme?` | `null` | Explicit palette or inherited Material brightness |

The helper validates arguments before pushing the route. The route uses the root navigator and a dismissible barrier. The current API does not expose route settings, a custom builder, barrier behavior, labels, animation settings, or a controller. Use the embedded widget in your own presentation when those controls are needed.

## `CalendarMapDatePicker`

A stateful embedded map with an immediate `onDateSelected` callback. It requires bounded layout constraints.

| Parameter | Type | Default / requirement | Meaning |
| --- | --- | --- | --- |
| `key` | `Key?` | `null` | Supply a new key to recreate state |
| `initialDate` | `DateTime` | Required | Seeds state once; not a controlled-value parameter |
| `onDateSelected` | `ValueChanged<DateTime>` | Required | Immediate date-only selection callback |
| `firstYear` | `int` | `2000` | First world year |
| `lastYear` | `int` | `2050` | Last world year |
| `minDate` / `maxDate` | `DateTime?` | `null` | Inclusive selection limits |
| `theme` | `CalendarMapTheme?` | `null` | Explicit palette or Material brightness |
| `locale` | `Locale` | `Locale('ru')` | Built-in label language |
| `labels` | `CalendarMapLabels?` | `null` | Overrides built-in labels |
| `firstDayOfWeek` | `int` | `1` | Monday…Sunday = `1…7` |
| `snapOnPinchEnd` | `bool` | `true` | Automatic settling after scale/pan gestures |
| `animationDuration` | `Duration` | `260 ms` | Programmatic camera-settling duration |
| `animationCurve` | `Curve` | `Cubic(.23, 1, .32, 1)` | Settling interpolation curve |

Use a non-negative duration and a curve suitable for interpolation between 0 and 1. Reduced motion and keyboard commands override animated movement. A callback may repeat the same date if tapped again.

### Validation and updates

`1 <= firstYear <= lastYear <= 9999`. The initial year must belong to that interval. Min/max must be ordered and intersect the interval. Only the date fields are compared. Custom lists must contain exactly 12 months and 7 weekdays.

An initial date outside selection bounds is clamped. Later `initialDate` updates are ignored by existing state. Invalidating the selected date through changed bounds clears it silently. Changing year bounds refocuses the camera; normal parent rebuilds do not.

## `CalendarMapTheme`

Immutable palette. `CalendarMapTheme.dark` and `.light` are predefined constants. The default constructor creates the dark palette; a null widget theme means inherit brightness, not always dark.

| Field | Dark | Light |
| --- | --- | --- |
| `background` | `#171818` | `#F5F5F7` |
| `territory` | `#212222` | `#FFFFFF` |
| `text` | `#E7E7E7` | `#202124` |
| `secondary` | `#A2A3A3` | `#62656A` |
| `muted` | `#626464` | `#96999F` |
| `accent` | `#FF454A` | `#CB263A` |
| `onAccent` | `#FFFFFF` | `#FFFFFF` |

`forBrightness(Brightness)` returns the corresponding built-in palette. There is no `copyWith` yet; construct a palette to override colors. The map theme is not a `ThemeExtension`.

## `CalendarMapLabels`

Immutable label container. Required constructor fields: `months`, `weekdays`, `today`, `zoomIn`, `zoomOut`, `hint`, `map`.

- `months`: 12 names, January…December.
- `weekdays`: 7 names, Monday…Sunday, even when Sunday is displayed first.
- `ru` / `en`: built-in instances.
- `forLocale(Locale)`: Russian for `ru`, English otherwise.
- `date(DateTime)`: simple `day month-name year` label. It is not grammatical/locale-aware `intl` formatting.

Provide stable label lists; do not mutate them during rendering.

## Exported utilities

These helpers are available for custom integrations, but they are not external controllers for the embedded picker. Geometry values are implementation-oriented and may change before a stable release. Do not persist raw world coordinates as user data; persist dates instead.

### `CalendarDates`

- `dateOnly(date)`: local date-only DateTime from the supplied fields.
- `key(date)`: integer `yyyyMMdd`, used for civil-date comparisons.
- `same(a, b)`: compares year/month/day.
- `addDays(date, days)`: UTC-backed day arithmetic, returning a local date-only value.
- Instance `monthDays(year, month, firstDayOfWeek: 1)`: immutable list of 42 UTC dates, including adjacent-month padding; bounded cache of up to 240 month grids.

### `CalendarSelection`

Constructor: `firstYear`, `lastYear`, optional `minDate` and `maxDate`. `enabled(date)` checks all bounds; `clamp(date)` returns the nearest allowed civil date. Use a valid intersecting interval; this low-level helper does not perform the widget constructor's argument validation itself.

### `CalendarGeometry`

- `anchorYear`: system year captured once on first use, stable for the app run.
- `leadingSlots(firstYear)`: empty grid positions needed to put the anchor year in the middle column.
- `yearOrigin(year, firstYear)` / `yearRect(...)`: world-space year position/bounds.
- `worldMonth(year, month, firstYear)`: world-space month bounds.
- `monthRect(month)`: month bounds relative to a year origin.
- `dayRect(index)`: day cell bounds relative to a month origin; index `0…41`.
- `worldBounds(firstYear, lastYear)`: bounding rectangle of the finite layout, including padding slots.
- `hitYear(world, firstYear, lastYear)`: valid year or null; rejects gaps/padding.
- `hitMonth(local)`: `1…12` or null, using year-local coordinates.
- `hitDay(local)`: `0…41` or null, using month-local coordinates.
- Static `monthDays(...)`: cached convenience delegate to CalendarDates.
- `monthNames`: legacy Russian month-name list; prefer CalendarMapLabels for locale-aware UI.

Current world units: year size 1200, year stride 1240, month size 280, three year columns. Month layout is 4×3. Coordinate helpers require valid calendar arguments; hit-testing methods are intended for arbitrary points.

### `CalendarCamera`

A standalone `ChangeNotifier`; dispose it when done. It stores uniform XY scale and translation without using matrix Z.

- `scale`, `translation`: current values.
- `setView(scale, translation)`: clamp scale and apply configured bounds, then notify.
- `pan(delta)`: screen-space movement.
- `zoomAt(focalPoint, factor)`: focal-point zoom; finite bounds take precedence at an edge.
- `worldToScreen(point)` / `screenToWorld(point)`: coordinate conversion.
- `visibleRect(viewport)`: visible world rectangle.
- `configureBounds(bounds, viewport)`: set finite camera bounds; small worlds center on an axis that fits.
- `constrainTranslation(scale, translation)`: compute bounded translation without applying it.
- Static `fitScale(area, viewport)`: scale to fit a rectangle, clamped to supported range.
- Current scale limits: `minScale = .025`, `maxScale = 3.5`.

The picker does not accept a CalendarCamera parameter. Creating one does not move a CalendarMapDatePicker instance.
