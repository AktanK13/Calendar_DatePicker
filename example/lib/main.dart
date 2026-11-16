import 'package:calendar_date_picker/calendar_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material show DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const CalendarExample());

enum _Appearance { light, dark, system }

class _PickedRange {
  const _PickedRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});

  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  static const _accent = Color(0xFFFF454A);
  _Appearance _appearance = _Appearance.system;
  DateTime? _confirmed;
  DateTime? _instant;
  _PickedRange? _range;
  _PickedRange? _calendarOnlyRange;

  String _date(DateTime? value) => value == null
      ? 'Не выбрано'
      : '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  Future<void> _openStandard(BuildContext context) async {
    final value = await showCalendarMapDatePicker(
      context: context,
      initialDate: _confirmed ?? DateTime.now(),
      firstYear: 1900,
      lastYear: 2100,
      allowTextInput: true,
      restorationId: 'standard_calendar_map',
    );
    if (mounted && value != null) setState(() => _confirmed = value);
  }

  Future<void> _openYesNo(BuildContext context) async {
    var initial = _confirmed ?? DateTime.now();
    while (initial.weekday == DateTime.saturday ||
        initial.weekday == DateTime.sunday) {
      initial = DateTime(initial.year, initial.month, initial.day + 1);
    }
    final value = await showCalendarMapDatePicker(
      context: context,
      initialDate: initial,
      firstYear: 1900,
      lastYear: 2100,
      title: 'Подтвердить дату?',
      confirmText: 'Да',
      cancelText: 'Нет',
      showZoomControls: false,
      selectableDayPredicate: (date) =>
          date.weekday != DateTime.saturday && date.weekday != DateTime.sunday,
    );
    if (mounted && value != null) setState(() => _confirmed = value);
  }

  Future<void> _openImmediateSheet(BuildContext context) async {
    final value = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (sheetContext) => _ImmediatePickerSheet(
        initialDate: _instant ?? DateTime.now(),
        onSelected: (date) => Navigator.of(sheetContext).pop(date),
      ),
    );
    if (mounted && value != null) setState(() => _instant = value);
  }

  Future<void> _openRangeSheet(BuildContext context) async {
    final value = await showCupertinoModalPopup<_PickedRange>(
      context: context,
      builder: (_) => _RangePickerSheet(initialRange: _range),
    );
    if (mounted && value != null) setState(() => _range = value);
  }

  Future<void> _openCalendarOnlyRangeSheet(BuildContext context) async {
    final value = await showCupertinoModalPopup<_PickedRange>(
      context: context,
      builder: (_) => _CalendarOnlyRangeSheet(
        initialRange: _calendarOnlyRange,
      ),
    );
    if (mounted && value != null) {
      setState(() => _calendarOnlyRange = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (_appearance) {
      _Appearance.light => Brightness.light,
      _Appearance.dark => Brightness.dark,
      _Appearance.system => MediaQuery.platformBrightnessOf(context),
    };
    final dark = brightness == Brightness.dark;
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: dark ? _accent : const Color(0xFFCB263A),
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      localizationsDelegates: GlobalCupertinoLocalizations.delegates,
      home: Builder(
        builder: (context) => CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Calendar DatePicker'),
                border: null,
                backgroundColor: CupertinoColors.systemGroupedBackground
                    .resolveFrom(context),
              ),
              SliverSafeArea(
                top: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList.list(
                    children: [
                      _ExampleCard(
                        icon: CupertinoIcons.check_mark_circled,
                        title: 'Обычное подтверждение',
                        description:
                            'Кнопки «Выбрать» и «Отмена», плюс ручной зум.',
                        value: _date(_confirmed),
                        button: 'Открыть диалог',
                        onPressed: () => _openStandard(context),
                      ),
                      const SizedBox(height: 14),
                      _ExampleCard(
                        icon: CupertinoIcons.hand_thumbsup,
                        title: '«Да / Нет» без + / −',
                        description:
                            'Свои подписи действий; выходные недоступны для выбора.',
                        value: _date(_confirmed),
                        button: 'Показать вариант',
                        onPressed: () => _openYesNo(context),
                      ),
                      const SizedBox(height: 14),
                      _ExampleCard(
                        icon: CupertinoIcons.cursor_rays,
                        title: 'Мгновенный выбор',
                        description:
                            'Bottom sheet без действий: тап по дню сразу возвращает дату.',
                        value: _date(_instant),
                        button: 'Открыть bottom sheet',
                        onPressed: () => _openImmediateSheet(context),
                      ),
                      const SizedBox(height: 14),
                      _ExampleCard(
                        icon: CupertinoIcons.calendar_badge_plus,
                        title: 'Диапазон дат',
                        description:
                            'Сначала начало, затем конец. Вторая дата ограничена первой.',
                        value: _range == null
                            ? 'Не выбрано'
                            : '${_date(_range!.start)} — ${_date(_range!.end)}',
                        button: 'Выбрать диапазон',
                        onPressed: () => _openRangeSheet(context),
                      ),
                      const SizedBox(height: 14),
                      _ExampleCard(
                        icon: CupertinoIcons.calendar,
                        title: 'Диапазон — только календарь',
                        description:
                            'Без кнопок «Начало» и «Конец»: два последовательных тапа по датам.',
                        value: _calendarOnlyRange == null
                            ? 'Не выбрано'
                            : '${_date(_calendarOnlyRange!.start)} — ${_date(_calendarOnlyRange!.end)}',
                        button: 'Открыть календарь',
                        onPressed: () => _openCalendarOnlyRangeSheet(context),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'ОФОРМЛЕНИЕ',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontSize: 12,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 9),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CupertinoSlidingSegmentedControl<_Appearance>(
                            groupValue: _appearance,
                            onValueChanged: (value) {
                              if (value != null) {
                                setState(() => _appearance = value);
                              }
                            },
                            children: const {
                              _Appearance.light: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('Светлая'),
                              ),
                              _Appearance.dark: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('Тёмная'),
                              ),
                              _Appearance.system: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('Система'),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.button,
    required this.onPressed,
  });

  final IconData icon;
  final String title, description, value, button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: TextStyle(color: secondary, height: 1.35)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: onPressed,
                borderRadius: BorderRadius.circular(13),
                child: Text(button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(top: false, child: child),
          ),
        ),
      );
}

class _ImmediatePickerSheet extends StatelessWidget {
  const _ImmediatePickerSheet({
    required this.initialDate,
    required this.onSelected,
  });
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => _SheetFrame(
        child: Column(
          children: [
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Нажмите на день',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: CalendarMapDatePicker(
                initialDate: initialDate,
                firstYear: 1900,
                lastYear: 2100,
                showZoomControls: false,
                onDateSelected: onSelected,
              ),
            ),
          ],
        ),
      );
}

class _RangePickerSheet extends StatefulWidget {
  const _RangePickerSheet({this.initialRange});

  final _PickedRange? initialRange;

  @override
  State<_RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<_RangePickerSheet> {
  DateTime? _start;
  DateTime? _end;
  int _step = 0;

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    if (_start != null && _end != null) _step = -1;
  }

  @override
  Widget build(BuildContext context) {
    final initial = _step == 0
        ? (_start ?? DateTime.now())
        : (_end ?? _start ?? DateTime.now());
    return _SheetFrame(
      child: Column(
        children: [
          const _SheetHandle(),
          const Text(
            'Диапазон дат',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _step == 0
                      ? 'Шаг 1 из 2 · Нажмите первый день'
                      : _step == 1
                          ? 'Шаг 2 из 2 · Теперь нажмите последний день'
                          : 'Диапазон сохранён · нажмите любой день, чтобы выбрать новый',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: _RangeStep(
                    number: '1',
                    label: 'Начало',
                    value:
                        _start == null ? 'Выберите дату' : _shortDate(_start!),
                    active: _step == 0,
                    complete: _start != null,
                    onPressed: () => setState(() => _step = 0),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(CupertinoIcons.chevron_right, size: 18),
                ),
                Expanded(
                  child: _RangeStep(
                    number: '2',
                    label: 'Конец',
                    value: _end != null
                        ? _shortDate(_end!)
                        : _start == null
                            ? 'После начала'
                            : 'Выберите дату',
                    active: _step == 1,
                    complete: _end != null,
                    onPressed:
                        _start == null ? null : () => setState(() => _step = 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CalendarMapDatePicker(
              key: ValueKey('$_step-$_start-$_end'),
              initialDate: initial,
              firstYear: 1900,
              lastYear: 2100,
              minDate: _step == 1 ? _start : null,
              rangeStart: _start,
              rangeEnd: _end,
              showZoomControls: false,
              showZoomHint: _start == null,
              onDateSelected: (date) {
                if (_step == -1 || _step == 0) {
                  setState(() {
                    _start = date;
                    _end = null;
                    _step = 1;
                  });
                } else {
                  setState(() {
                    _end = date;
                    _step = -1;
                  });
                }
              },
            ),
          ),
          Visibility(
            visible: _start != null && _end != null,
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_PickedRange(_start!, _end!)),
                  borderRadius: BorderRadius.circular(14),
                  child: const Text('Подтвердить диапазон'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarOnlyRangeSheet extends StatefulWidget {
  const _CalendarOnlyRangeSheet({this.initialRange});

  final _PickedRange? initialRange;

  @override
  State<_CalendarOnlyRangeSheet> createState() =>
      _CalendarOnlyRangeSheetState();
}

class _CalendarOnlyRangeSheetState extends State<_CalendarOnlyRangeSheet> {
  material.DateTimeRange<DateTime>? _range;
  var _selectingEnd = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRange;
    if (initial != null) {
      _range = material.DateTimeRange<DateTime>(
        start: initial.start,
        end: initial.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _range != null;
    final instruction = _selectingEnd
        ? 'Теперь нажмите последний день'
        : complete
            ? 'Нажмите любой день, чтобы выбрать новый диапазон'
            : 'Нажмите первый день диапазона';
    return _SheetFrame(
      child: Column(
        children: [
          const _SheetHandle(),
          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CalendarMapDateRangePicker(
              initialRange: _range,
              firstYear: 1900,
              lastYear: 2100,
              style: CalendarRangePickerStyle.calendarOnly,
              showZoomControls: false,
              onRangeStartChanged: (_) => setState(() => _selectingEnd = true),
              onRangeChanged: (range) => setState(() {
                _range = range;
                _selectingEnd = range == null;
              }),
            ),
          ),
          Visibility(
            visible: complete,
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: complete
                      ? () => Navigator.of(context).pop(
                            _PickedRange(_range!.start, _range!.end),
                          )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: const Text('Подтвердить диапазон'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeStep extends StatelessWidget {
  const _RangeStep({
    required this.number,
    required this.label,
    required this.value,
    required this.active,
    required this.complete,
    required this.onPressed,
  });

  final String number, label, value;
  final bool active, complete;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final border = active || complete
        ? accent
        : CupertinoColors.separator.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: const Cubic(.23, 1, .32, 1),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: .09)
              : CupertinoColors.secondarySystemBackground.resolveFrom(context),
          border: Border.all(color: border, width: active ? 1.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: complete || active ? accent : border,
                shape: BoxShape.circle,
              ),
              child: complete
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      size: 15,
                      color: CupertinoColors.white,
                    )
                  : Text(
                      number,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 38,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey3.resolveFrom(context),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
}
