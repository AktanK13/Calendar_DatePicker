import 'package:calendar_date_picker/calendar_date_picker.dart';
import 'package:flutter/cupertino.dart';
// Compatibility services required by the picker; the example UI is Cupertino.
import 'package:flutter/material.dart' as material
    show ColorScheme, DefaultMaterialLocalizations, Theme, ThemeData;

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

  String _date(DateTime? value) => value == null
      ? 'Не выбрано'
      : '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  Future<void> _openStandard(BuildContext context) async {
    final value = await showCalendarMapDatePicker(
      context: context,
      initialDate: _confirmed ?? DateTime.now(),
      firstYear: 1900,
      lastYear: 2100,
    );
    if (mounted && value != null) setState(() => _confirmed = value);
  }

  Future<void> _openYesNo(BuildContext context) async {
    final value = await showCalendarMapDatePicker(
      context: context,
      initialDate: _confirmed ?? DateTime.now(),
      firstYear: 1900,
      lastYear: 2100,
      title: 'Подтвердить дату?',
      confirmText: 'Да',
      cancelText: 'Нет',
      showZoomControls: false,
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
      builder: (_) => const _RangePickerSheet(),
    );
    if (mounted && value != null) setState(() => _range = value);
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
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: dark ? _accent : const Color(0xFFCB263A),
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      localizationsDelegates: const [
        material.DefaultMaterialLocalizations.delegate,
      ],
      builder: (context, child) => material.Theme(
        data: material.ThemeData(
          brightness: brightness,
          useMaterial3: true,
          colorScheme: material.ColorScheme.fromSeed(
            seedColor: dark ? _accent : const Color(0xFFCB263A),
            brightness: brightness,
          ),
        ),
        child: child!,
      ),
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
                            'Свои подписи действий; масштаб меняется жестом.',
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
  const _RangePickerSheet();

  @override
  State<_RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<_RangePickerSheet> {
  DateTime? _start;

  @override
  Widget build(BuildContext context) {
    final initial = _start ?? DateTime.now();
    return _SheetFrame(
      child: Column(
        children: [
          const _SheetHandle(),
          Text(
            _start == null
                ? 'Выберите начало диапазона'
                : 'Начало: ${_start!.day}.${_start!.month}.${_start!.year} · выберите конец',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CalendarMapDatePicker(
              key: ValueKey(_start),
              initialDate: initial,
              firstYear: 1900,
              lastYear: 2100,
              minDate: _start,
              showZoomControls: false,
              showZoomHint: _start == null,
              onDateSelected: (date) {
                if (_start == null) {
                  setState(() => _start = date);
                } else {
                  Navigator.of(context).pop(_PickedRange(_start!, date));
                }
              },
            ),
          ),
        ],
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
