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
| `context` | `BuildContext` | Required | Descendant of a Navigator and app localizations |
| `initialDate` | `DateTime` | Required | Initial selected date/month; year must be in range |
| `firstYear` | `int` | `2000` | First rendered year, inclusive |
| `lastYear` | `int` | `2050` | Last rendered year, inclusive |
| `minDate` | `DateTime?` | `null` | Earliest selectable civil date |
| `maxDate` | `DateTime?` | `null` | Latest selectable civil date |
| `selectableDayPredicate` | `CalendarSelectableDayPredicate?` | `null` | Arbitrary per-day availability rule |
| `currentDate` | `DateTime?` | System date | Day highlighted as today |
| `rangeStart` / `rangeEnd` | `DateTime?` | `null` | Optional visual range; endpoints and intermediate days use distinct styles |
| `locale` | `Locale?` | Ambient | Locale used by labels and date formatting |
| `firstDayOfWeek` | `int?` | Monday | `1…7`, Monday…Sunday |
| `textDirection` | `TextDirection?` | Ambient | LTR/RTL override |
| `controller` | `CalendarMapController?` | `null` | Programmatic camera/selection commands |
| `theme` | `CalendarMapTheme?` | `null` | Explicit palette or platform brightness |
| `labels` | `CalendarMapLabels?` | `null` | Custom map and semantic labels |
| `title` | `String?` | Localized | Dialog heading |
| `confirmText` / `cancelText` | `String?` | Localized | Custom action labels |
| `showConfirmButton` / `showCancelButton` | `bool` | `true` | Include either action |
| `selectImmediately` | `bool` | `false` | Return as soon as an enabled day is tapped |
| `showZoomControls` | `bool` | `true` | Include the +/− controls; gestures remain active |
| `showZoomHint` | `bool` | `true` | Play the initial explanatory zoom gesture |
| `zoomHintDuration` | `Duration` | `520 ms` | Total duration of the explanatory movement |
| `zoomHintScale` | `double` | `.86` | Furthest hint scale; lower values make it more obvious |
| `allowTextInput` | `bool` | `false` | Add calendar/text-entry switching |
| `restorationId` | `String?` | `null` | Restore map selection/navigation below a RestorationScope |
| `barrierDismissible`, `barrierColor`, `barrierLabel` | Route options | Flutter defaults | Modal barrier behavior |
| `useRootNavigator`, `routeSettings`, `anchorPoint`, `useSafeArea`, `builder` | Route options | Flutter defaults | Dialog routing/presentation customization |
| `presentation` | `CalendarPickerPresentation` | `dialog` | iOS-style dialog, Cupertino bottom sheet, or fullscreen route |

The helper validates arguments before pushing the route. Input-specific error, hint, and label strings can be overridden. Use the embedded widget in a bottom sheet or custom route when camera-settling animation timing must also be customized.

`restorationId` restores widget state while the route exists below a `RestorationScope`. Like Flutter's standard `showDatePicker`, this convenience function does not itself make the route restorable after process death; place the embedded picker in a route pushed with `Navigator.restorablePush` when route restoration is required.

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
| `selectableDayPredicate` | `CalendarSelectableDayPredicate?` | `null` | Arbitrary per-day availability rule |
| `selectedDate` | `DateTime?` | `null` | Parent-controlled selection update |
| `selectInitialDate` | `bool` | `true` | Paint initialDate as selected before interaction |
| `currentDate` | `DateTime?` | System date | Today override; system mode refreshes after midnight |
| `rangeStart` / `rangeEnd` | `DateTime?` | `null` | Optional visual range; endpoints and intermediate days use distinct styles |
| `controller` | `CalendarMapController?` | `null` | Programmatic commands and observable viewport |
| `onViewportChanged` | `ValueChanged<CalendarMapViewport>?` | `null` | Visible-map callback |
| `onDisplayedPeriodChanged` | `ValueChanged<DateTime>?` | `null` | Center-month callback |
| `theme` | `CalendarMapTheme?` | `null` | Explicit palette or platform brightness |
| `locale` | `Locale?` | Ambient | Built-in label language/date formatting |
| `labels` | `CalendarMapLabels?` | `null` | Overrides built-in labels |
| `firstDayOfWeek` | `int?` | Monday | Monday…Sunday = `1…7` |
| `textDirection` | `TextDirection?` | Ambient | Mirrors calendar placement and hit-testing in RTL |
| `snapOnPinchEnd` | `bool` | `true` | Automatic settling; a 24 px drag or light flick advances to an adjacent month |
| `showZoomControls` | `bool` | `true` | Show +/− controls; pinch remains active when hidden |
| `showZoomHint` | `bool` | `true` | Initial 8% zoom-out/return explanation |
| `zoomHintDuration` | `Duration` | `520 ms` | Total duration of the explanatory movement |
| `zoomHintScale` | `double` | `.86` | Furthest hint scale; lower values make it more obvious |
| `animationDuration` | `Duration` | `260 ms` | Programmatic camera-settling duration |
| `animationCurve` | `Curve` | `Cubic(.23, 1, .32, 1)` | Settling interpolation curve |
| `enableHapticFeedback` | `bool` | `true` | Selection and zoom-level haptics |
| `autofocus` | `bool` | `true` | Initial keyboard focus |
| `restorationId` | `String?` | `null` | Restore selection and navigation state |

Use non-negative durations and a curve suitable for interpolation between 0 and 1. `zoomHintScale` must be above 0 and below 1. The zoom hint spends 45% of `zoomHintDuration` moving out and 55% returning, is skipped for reduced motion, and is interrupted by input. A zero duration disables the hint. Reduced motion and keyboard commands also override animated movement. A callback may repeat the same date if tapped again.

### Validation and updates

`1 <= firstYear <= lastYear <= 9999`. The initial year must belong to that interval. Min/max must be ordered and intersect the interval. Only the date fields are compared. Custom lists must contain exactly 12 months and 7 weekdays.

An initial date outside selection bounds is clamped. Later `initialDate` updates are ignored by existing state. Invalidating the selected date through changed bounds clears it silently. Changing year bounds refocuses the camera; normal parent rebuilds do not.

## Range API

`CalendarMapDateRangePicker` owns partial and completed range state. `initialRange` seeds it once. `onRangeChanged(null)` means that only the start is currently known; a second tap returns a complete `DateTimeRange<DateTime>`. `onRangeStartChanged` and `onRangeCompleted` are convenience callbacks. `CalendarRangePickerStyle.calendarOnly` has no separate endpoint controls; `guided` adds editable start/end stages.

`showCalendarMapDateRangePicker` returns `Future<DateTimeRange<DateTime>?>` and supports initial range, date limits, predicate, current date, both styles, localization/theme settings, and standard dialog route options.

## `CalendarMapController` and viewport

Attach one controller to one live picker. Commands: `showDate`, `showYear`, `showOverview`, `showToday`, `zoomIn`, `zoomOut`, and `selectDate`. Calling a command without an attached picker throws `StateError`.

The controller is a `ChangeNotifier`. Its `selectedDate` and optional `viewport` update after the widget changes. `CalendarMapViewport` contains `level`, `centerDate`, `visibleWorld`, `visibleYears`, and the current two-dimensional `scale`. Levels are `overview`, `year`, and `month`.

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

`copyWith` and `forBrightness(Brightness)` are provided. Additional state colors cover selected days, range endpoints/middle, today, disabled/weekend days, focus, hover, and press. `yearRadius`, `monthRadius`, and `dayRadius` customize geometry. The map theme is not a `ThemeExtension`.

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

Constructor: `firstYear`, `lastYear`, optional `minDate`, `maxDate`, and `selectableDayPredicate`. `enabled(date)` checks all rules; `clamp(date)` applies contiguous bounds, `nearestEnabled(date)` also searches around predicate-disabled dates, and `move(date, delta)` performs keyboard-style movement while skipping unavailable dates.

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

The picker does not accept a CalendarCamera parameter. Creating one does not move a CalendarMapDatePicker instance; use `CalendarMapController` for that.
