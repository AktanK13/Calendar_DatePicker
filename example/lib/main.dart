import 'package:flutter/cupertino.dart';
// Compatibility services for the unchanged picker, not example UI controls.
import 'package:flutter/material.dart' as material
    show Theme, ThemeData, ColorScheme, DefaultMaterialLocalizations;
import 'package:calendar_date_picker/calendar_date_picker.dart';

void main() => runApp(const CalendarExample());

enum _Appearance { light, dark, system }

class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});
  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  _Appearance _appearance = _Appearance.system;
  DateTime? _selected;
  static const _accent = Color(0xFFFF454A);

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
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground),
      localizationsDelegates: const [
        material.DefaultMaterialLocalizations.delegate
      ],
      builder: (context, child) => material.Theme(
          data: material.ThemeData(
              brightness: brightness,
              useMaterial3: true,
              colorScheme: material.ColorScheme.fromSeed(
                  seedColor: dark ? _accent : const Color(0xFFCB263A),
                  brightness: brightness)),
          child: child!),
      home: Builder(builder: (context) {
        final accent = CupertinoTheme.of(context).primaryColor;
        final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
        final date = _selected;
        final dateText = date == null
            ? 'Дата пока не выбрана'
            : 'Выбрано: ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        Future<void> openPicker() async {
          final picked = await showCalendarMapDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstYear: 1900,
              lastYear: 2100);
          if (picked != null && mounted) setState(() => _selected = picked);
        }

        return CupertinoPageScaffold(
            child: SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverNavigationBar(
                        largeTitle: const Text('Календарь'),
                        border: null,
                        backgroundColor: CupertinoColors.systemGroupedBackground
                            .resolveFrom(context)),
                    SliverToBoxAdapter(
                        child: Center(
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 20, 20, 32),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: CupertinoColors
                                                      .secondarySystemGroupedBackground
                                                      .resolveFrom(context),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          26)),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(24),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(children: [
                                                          DecoratedBox(
                                                              decoration: BoxDecoration(
                                                                  color: accent
                                                                      .withValues(
                                                                          alpha:
                                                                              .10),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              14)),
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          12),
                                                                  child: Icon(
                                                                      CupertinoIcons
                                                                          .calendar,
                                                                      color:
                                                                          accent,
                                                                      size:
                                                                          26))),
                                                          const SizedBox(
                                                              width: 14),
                                                          Expanded(
                                                              child: Text(
                                                                  'Дата события',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color:
                                                                          secondary))),
                                                        ]),
                                                        const SizedBox(
                                                            height: 24),
                                                        Text(
                                                            date == null
                                                                ? 'Выберите\nсвой день'
                                                                : '${date.day} ${CalendarMapLabels.ru.months[date.month - 1].toLowerCase()}',
                                                            style: const TextStyle(
                                                                fontSize: 34,
                                                                height: 1.1,
                                                                letterSpacing:
                                                                    -1.1,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                        const SizedBox(
                                                            height: 12),
                                                        Text(dateText,
                                                            key: const ValueKey(
                                                                'selected-date'),
                                                            style: TextStyle(
                                                                fontSize: 15,
                                                                height: 1.4,
                                                                color:
                                                                    secondary)),
                                                        const SizedBox(
                                                            height: 28),
                                                        SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child: CupertinoButton.filled(
                                                                key: const ValueKey(
                                                                    'open-datepicker'),
                                                                onPressed:
                                                                    openPicker,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            14),
                                                                child: const Text(
                                                                    'Выбрать дату',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600)))),
                                                      ]))),
                                          const SizedBox(height: 30),
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 14, bottom: 10),
                                              child: Text('ОФОРМЛЕНИЕ',
                                                  style: TextStyle(
                                                      color: secondary,
                                                      fontSize: 12,
                                                      letterSpacing: .7))),
                                          DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: CupertinoColors
                                                      .secondarySystemGroupedBackground
                                                      .resolveFrom(context),
                                                  borderRadius: BorderRadius
                                                      .circular(18)),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child:
                                                      CupertinoSlidingSegmentedControl<
                                                              _Appearance>(
                                                          groupValue:
                                                              _appearance,
                                                          onValueChanged:
                                                              (value) {
                                                            if (value != null)
                                                              setState(() =>
                                                                  _appearance =
                                                                      value);
                                                          },
                                                          children: const {
                                                        _Appearance.light: Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                            child: Text(
                                                                'Светлая')),
                                                        _Appearance.dark: Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                            child:
                                                                Text('Тёмная')),
                                                        _Appearance.system: Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                            child: Text(
                                                                'Система')),
                                                      }))),
                                          const SizedBox(height: 12),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14),
                                              child: Text(
                                                  'Системная тема меняется вместе с оформлением iPhone.',
                                                  style: TextStyle(
                                                      color: secondary,
                                                      fontSize: 13,
                                                      height: 1.4))),
                                          SizedBox(
                                              height:
                                                  MediaQuery.paddingOf(context)
                                                      .bottom),
                                        ]))))),
                  ],
                )));
      }),
    );
  }
}
