## 0.3.0

- Add first-class single-date and date-range APIs, including guided and calendar-only range flows.
- Add `CalendarMapController`, viewport callbacks, controlled selection, and state restoration.
- Add arbitrary selectable-day predicates, current-date overrides, RTL, localization, and automatic midnight refresh.
- Add Cupertino dialog, bottom-sheet, fullscreen, action, zoom-control, and typed-input presentation without visible Material UI.
- Add configurable camera and introductory zoom animations with reduced-motion support.
- Make short 24 px drags and light flicks snap to adjacent months in the physical 4×3 map grid.
- Keep the nine-year overview as the furthest zoom level and preserve bounded camera navigation.
- Add separate theme colors for selected days, today, ranges, disabled days, focus, hover, and press states.
- Remove borders and dots from selected days; use soft fills for today and keyboard focus.
- Improve semantics, keyboard navigation, haptics, hover/press feedback, and visible-item rendering.
- Expand the adaptive Cupertino example and the English/Russian user documentation.

## 0.1.2

- Remove the extra dot shown below today when today is selected.

## 0.1.1

- Use absolute screenshot and documentation links for pub.dev README rendering.
- No changes to the date picker API or behavior.

## 0.1.0

Initial release.

- Add a continuous calendar map with month, year and nine-year camera levels.
- Center the system current year in its 3×3 overview independently of the range start.
- Support pinch, bounded pan, tap navigation and interruptible camera settling.
- Add single-date selection, inclusive min/max dates and a finite year range.
- Add a confirmation dialog returning a date or null on cancellation.
- Add light/dark palettes, Russian/English labels and configurable first weekday.
- Support rounded square layouts in portrait and landscape.
- Add keyboard navigation, visible-item semantics and reduced-motion behavior.
- Provide a Cupertino example for iOS.
- Document API contracts, state behavior, platform limitations.
