part of 'main.dart';

enum SleepQuality { available, calibration, partial }

class SleepReport {
  const SleepReport(this.feeling, this.minutes, this.note);
  final String feeling, note;
  final int? minutes;
}

class SleepData extends ChangeNotifier {
  // Fictional, date-keyed samples. Sync merges by date; missing nights stay missing.
  static const fixture = {15: 430, 16: 385, 18: 360, 19: 374, 20: 371};
  final nights = Map<int, int>.from(fixture);
  bool authorized = true, online = true;
  SleepQuality quality = SleepQuality.available;
  String lastSync = '20 октября · 07:42';
  SleepReport? report;
  String? comparisonNote;
  final history = <String>[
    'Демо-источник Ring X добавлен. Загружены 5 ночей; 17 октября — пропуск.',
  ];
  int get average =>
      (nights.values.reduce((a, b) => a + b) / nights.length).round();
  bool get mismatch =>
      report?.minutes != null &&
      nights[20] != null &&
      (report!.minutes! - nights[20]!).abs() > 60;
  String get status => !authorized
      ? 'Отключено вами'
      : !online
      ? 'Нет связи'
      : switch (quality) {
          SleepQuality.available => 'Данные доступны',
          SleepQuality.calibration => 'Калибровка',
          SleepQuality.partial => 'HRV неполный',
        };
  static String duration(int minutes) =>
      '${minutes ~/ 60} ч ${minutes % 60} мин';
  void saveReport(SleepReport value) {
    report = value;
    comparisonNote = null;
    history.insert(
      0,
      '20 октября · личная отметка: ${value.feeling}; ${value.minutes == null ? 'без длительности' : duration(value.minutes!)}. ${value.note}',
    );
    notifyListeners();
  }

  void compare(String note) {
    comparisonNote = note;
    history.insert(0, 'Расхождение рассмотрено: $note. Обе записи сохранены.');
    notifyListeners();
  }

  void scenario(int selected) {
    if (!authorized) return;
    if (selected == 3) {
      online = false;
    } else {
      online = true;
      quality = SleepQuality.values[selected];
    }
    history.insert(
      0,
      'Демо-сценарий: $status. История сна и самооценки сохранена.',
    );
    notifyListeners();
  }

  int sync() {
    if (!authorized || !online) return -1;
    final before = nights.length;
    nights.addAll(fixture);
    lastSync = '20 октября · 09:12';
    final added = nights.length - before;
    history.insert(
      0,
      'Демо-синхронизация 09:12: новых ночей $added; всего ${nights.length}. 17 октября остаётся без данных.',
    );
    notifyListeners();
    return added;
  }

  void connect() {
    authorized = true;
    online = true;
    history.insert(
      0,
      'Демо-доступ к Ring X подтверждён. Источник восстановлен без создания копии.',
    );
    notifyListeners();
  }

  void disconnect() {
    authorized = false;
    online = false;
    history.insert(
      0,
      'Вы отключили демо-доступ к Ring X. Новые данные не поступают, сохранённая история осталась.',
    );
    notifyListeners();
  }
}

class SleepSummary extends StatelessWidget {
  const SleepSummary({required this.data, required this.onOpen, super.key});
  final SleepData data;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.bedtime_outlined, color: C.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Устройства и сон',
                style: tx(21, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Последняя ночь · ${SleepData.duration(data.nights[20]!)}',
          style: tx(17, weight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text('Ring X · демо · ${data.status}', style: tx(13, color: C.muted)),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('open-sleep'),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Посмотреть сон'),
        ),
      ],
    ),
  );
}

class SleepScreen extends StatefulWidget {
  const SleepScreen({
    required this.data,
    required this.radar,
    required this.onRadar,
    required this.onProgram,
    super.key,
  });
  final SleepData data;
  final RadarData radar;
  final VoidCallback onRadar, onProgram;
  @override
  State<SleepScreen> createState() => SleepScreenState();
}

class SleepScreenState extends State<SleepScreen> {
  SleepData get data => widget.data;
  int tab = 0;
  bool syncing = false;
  String? syncMessage;
  final scroll = ScrollController();
  static const gap = SizedBox(height: 20);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void showTab(int value) {
    setState(() => tab = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<T?> popup<T>(
    String title,
    Widget Function(BuildContext) content,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(ctx).height - 48,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: tx(23, weight: FontWeight.w600)),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              gap,
              content(ctx),
            ],
          ),
        ),
      ),
    ),
  );
  Widget detail(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: tx(17, weight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(body, style: tx(14, color: C.muted)),
    ],
  );

  Future<void> record() async {
    final form = GlobalKey<FormState>();
    String? feeling = data.report?.feeling;
    var duration = data.report?.minutes == null
        ? ''
        : '${data.report!.minutes! ~/ 60}:${(data.report!.minutes! % 60).toString().padLeft(2, '0')}';
    var note = data.report?.note ?? '';
    int? recovery;
    final result = await popup<(SleepReport, int?)>(
      'Как прошла ночь?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ночь на 20 октября · ваша оценка хранится отдельно от показаний Ring X.',
                style: tx(14, color: C.muted),
              ),
              gap,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in ['Выспался(-ась)', 'Средне', 'Плохо'])
                    ChoiceChip(
                      label: Text(f),
                      selected: feeling == f,
                      onSelected: (_) => update(() => feeling = f),
                    ),
                ],
              ),
              gap,
              TextFormField(
                key: const ValueKey('sleep-duration'),
                initialValue: duration,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Сколько спали · необязательно',
                  hintText: 'Например, 5:30',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => duration = v.trim(),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return null;
                  return RegExp(
                        r'^([01]?\d|2[0-3]):[0-5]\d$|^24:00$',
                      ).hasMatch(s)
                      ? null
                      : 'Введите длительность от 0:00 до 24:00';
                },
              ),
              gap,
              TextFormField(
                key: const ValueKey('sleep-note'),
                initialValue: note,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Контекст · необязательно',
                  hintText: 'Например, часто просыпался',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => note = v,
              ),
              Text(
                'Добавить самооценку восстановления в радар',
                style: tx(15, weight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Необязательно. Это та же отметка, что в программе «Спокойный вечер».',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (int i = 0; i <= 10; i++)
                    ChoiceChip(
                      key: ValueKey('sleep-recovery-$i'),
                      label: Text('$i'),
                      selected: recovery == i,
                      showCheckmark: false,
                      onSelected: (v) => update(() => recovery = v ? i : null),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '0 — совсем не восстановился(-ась), 10 — полностью',
                style: tx(12, color: C.muted),
              ),
              if (recovery != null && widget.radar.latest(3)?.day == 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Заменит сегодняшнюю самооценку ${widget.radar.latest(3)!.value}/10.',
                    style: tx(13, color: C.muted),
                  ),
                ),
              gap,
              PrimaryButton(
                'Сохранить отметку сна',
                feeling == null
                    ? null
                    : () {
                        if (!form.currentState!.validate()) return;
                        final parts = duration.isEmpty
                            ? null
                            : duration.split(':');
                        Navigator.pop(ctx, (
                          SleepReport(
                            feeling!,
                            parts == null
                                ? null
                                : int.parse(parts[0]) * 60 +
                                      int.parse(parts[1]),
                            note.trim(),
                          ),
                          recovery,
                        ));
                      },
                key: const ValueKey('save-sleep-report'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    data.saveReport(result.$1);
    if (result.$2 != null) {
      widget.radar.record(3, result.$2!, note: 'Самооценка после сна');
    }
  }

  Future<void> compare() async {
    var reason = data.comparisonNote ?? 'Причина пока неизвестна';
    final result = await popup<String>(
      'Два источника — две записи',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            detail('Ring X · демо', SleepData.duration(data.nights[20]!)),
            gap,
            detail(
              'Ваша отметка',
              data.report?.minutes == null
                  ? 'Длительность не указана'
                  : SleepData.duration(data.report!.minutes!),
            ),
            gap,
            Text(
              'Длительность отличается больше чем на час. Это сравнение записей, а не оценка здоровья. Не усредняем значения и не выбираем «правильное» автоматически.',
              style: tx(14, color: C.muted),
            ),
            gap,
            for (final r in [
              'Причина пока неизвестна',
              'Устройство снималось ночью',
              'Я помню периоды бодрствования',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity, child: Text(r)),
                  selected: reason == r,
                  onSelected: (_) => update(() => reason = r),
                ),
              ),
            gap,
            PrimaryButton(
              'Сохранить контекст',
              () => Navigator.pop(ctx, reason),
              key: const ValueKey('save-sleep-comparison'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) data.compare(result);
  }

  Future<void> connect() async {
    var consent = false;
    final result = await popup<bool>(
      'Подключить Ring X',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Tag('Демонстрационный источник'),
            gap,
            detail(
              'Какие данные доступны',
              'Длительность сна, HRV, пульс покоя, время синхронизации и качество сигнала. Только чтение.',
            ),
            gap,
            Text(
              'Bluetooth и аккаунт производителя не подключаются. Прототип использует тестовые записи и сохраняет текущую историю.',
              style: tx(14, color: C.muted),
            ),
            gap,
            CheckboxListTile(
              key: const ValueKey('sleep-connect-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('Разрешаю подключить демо-источник', style: tx(14)),
              value: consent,
              onChanged: (v) => update(() => consent = v ?? false),
            ),
            gap,
            PrimaryButton(
              'Подтвердить подключение',
              consent ? () => Navigator.pop(ctx, true) : null,
              key: const ValueKey('confirm-sleep-connect'),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      data.connect();
      setState(
        () => syncMessage =
            'Демо-источник восстановлен. Можно выполнить синхронизацию.',
      );
    }
  }

  Future<void> disconnect() async {
    final result = await popup<bool>(
      'Отключить источник?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Новые данные Ring X перестанут поступать. Сохранённые ночи, личные отметки и программа сна останутся доступны.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Отключить Ring X',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-sleep-disconnect'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      data.disconnect();
      setState(() => syncMessage = null);
    }
  }

  Future<void> sync() async {
    if (syncing || !data.authorized) return;
    setState(() {
      syncing = true;
      syncMessage = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final added = data.sync();
    setState(() {
      syncing = false;
      syncMessage = added < 0
          ? 'Не удалось синхронизировать: источник недоступен. Сохранённые данные не изменены.'
          : 'Демо-синхронизация завершена. Новых ночей: $added. Дубликатов нет; пропуск 17 октября сохранён.';
    });
  }

  Future<void> scenarios() async {
    var selected = !data.online ? 3 : data.quality.index;
    final result = await popup<int>(
      'Демо: состояние источника',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Переключатель для тестирования интерфейса. Личные отметки и сохранённые ночи не меняются.',
              style: tx(14, color: C.muted),
            ),
            gap,
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  key: ValueKey('sleep-scenario-$i'),
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      [
                        'Данные доступны',
                        'Калибровка',
                        'Неполный HRV',
                        'Нет связи',
                      ][i],
                    ),
                  ),
                  selected: selected == i,
                  onSelected: (_) => update(() => selected = i),
                ),
              ),
            gap,
            PrimaryButton(
              'Применить сценарий',
              () => Navigator.pop(ctx, selected),
              key: const ValueKey('apply-sleep-scenario'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      data.scenario(result);
      setState(() => syncMessage = null);
    }
  }

  Future<void> night(int day) => popup<void>(
    'Ночь на $day октября',
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        detail(
          data.nights.containsKey(day)
              ? SleepData.duration(data.nights[day]!)
              : 'Нет данных',
          data.nights.containsKey(day)
              ? 'Источник: Ring X · демонстрационная запись. Это длительность сна без оценки стадий и причин.'
              : 'У источника нет записи за эту ночь. Пробел не заменяем нулём и не заполняем средним.',
        ),
        gap,
        Text(
          data.authorized && data.online
              ? 'Последняя синхронизация: ${data.lastSync}'
              : 'Сохранённая история · ${data.status}',
          style: tx(14, color: C.muted),
        ),
        gap,
        PrimaryButton('Понятно', () => Navigator.pop(ctx)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([data, widget.radar]),
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 700;
        return SingleChildScrollView(
          key: const PageStorageKey('sleep-scroll'),
          controller: scroll,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  narrow ? 18 : 36,
                  20,
                  narrow ? 18 : 36,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('sleep-back-radar'),
                        onPressed: widget.onRadar,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Радар здоровья'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Устройства и сон',
                      style: tx(
                        narrow ? 32 : 40,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ваша ночь — с контекстом, источником и личной отметкой.',
                      style: tx(15, color: C.muted),
                    ),
                    gap,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < 3; i++)
                          ChoiceChip(
                            key: ValueKey('sleep-tab-$i'),
                            label: Text(['Сон', 'Устройство', 'История'][i]),
                            selected: tab == i,
                            showCheckmark: false,
                            onSelected: (_) => showTab(i),
                          ),
                      ],
                    ),
                    gap,
                    if (box.maxWidth >= 1000)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: tab == 0
                                ? sleepView()
                                : tab == 1
                                ? sourceView()
                                : historyView(),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(width: 320, child: side()),
                        ],
                      )
                    else ...[
                      tab == 0
                          ? sleepView()
                          : tab == 1
                          ? sourceView()
                          : historyView(),
                      gap,
                      side(),
                    ],
                    gap,
                    Text(
                      'Демо · 20 октября 2026 · Ring X — вымышленный источник · данные до обновления страницы',
                      style: tx(11, color: C.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget sleepView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Tag('Ночь на 20 октября'),
                Tag(
                  data.authorized && data.online
                      ? 'Ring X · демо'
                      : 'Сохранённые данные',
                ),
              ],
            ),
            gap,
            Text(
              SleepData.duration(data.nights[20]!),
              style: tx(40, weight: FontWeight.w600, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              'Длительность сна по данным устройства',
              style: tx(14, color: C.muted),
            ),
            gap,
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                stat('В СРЕДНЕМ · 5 НОЧЕЙ', SleepData.duration(data.average)),
                stat('ПРОПУСКИ', '1 ночь'),
              ],
            ),
            gap,
            Text('15–20 октября', style: tx(13, color: C.muted)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int day = 15; day <= 20; day++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        key: ValueKey('sleep-night-$day'),
                        onTap: () => night(day),
                        borderRadius: BorderRadius.circular(10),
                        child: Semantics(
                          button: true,
                          label:
                              '$day октября: ${data.nights[day] == null ? 'нет данных' : SleepData.duration(data.nights[day]!)}',
                          child: Column(
                            children: [
                              SizedBox(
                                height: 110,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 46,
                                    height: data.nights[day] == null
                                        ? 4
                                        : data.nights[day]! / 480 * 110,
                                    decoration: BoxDecoration(
                                      color: data.nights[day] == null
                                          ? C.line
                                          : day == 20
                                          ? C.green
                                          : const Color(0xFFB5DCC7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('$day', style: tx(12, color: C.muted)),
                              Text(
                                data.nights[day] == null
                                    ? '—'
                                    : '${data.nights[day]! ~/ 60}:${(data.nights[day]! % 60).toString().padLeft(2, '0')}',
                                style: tx(11, weight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Нажмите на ночь, чтобы увидеть источник. 17 октября — нет данных.',
              style: tx(12, color: C.muted),
            ),
            if (data.quality == SleepQuality.calibration) ...[
              gap,
              detail(
                'Накопление личной истории · ${data.nights.length}/7 ночей',
                'Пока недостаточно данных для личного диапазона. Пропуск не считается собранной ночью.',
              ),
            ],
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('А как ощущался сон?', style: tx(23, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              data.report == null
                  ? 'Устройство не знает, как вы себя чувствуете. Можно добавить собственную отметку.'
                  : '${data.report!.feeling}${data.report!.minutes == null ? '' : ' · ${SleepData.duration(data.report!.minutes!)}'}',
              style: tx(15, color: C.muted),
            ),
            if (data.report?.note.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(data.report!.note, style: tx(14)),
              ),
            if (widget.radar.latest(3) != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Восстановление: ${widget.radar.latest(3)!.value}/10 · ваша отметка ${widget.radar.latest(3)!.day} октября',
                  key: const ValueKey('sleep-shared-recovery'),
                  style: tx(14, color: C.green),
                ),
              ),
            gap,
            PrimaryButton(
              data.report == null ? 'Отметить сон' : 'Изменить отметку',
              record,
              key: const ValueKey('sleep-record'),
            ),
          ],
        ),
      ),
      if (data.mismatch) ...[
        gap,
        Surface(
          color: const Color(0xFFFFF3D8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Длительность отличается',
                style: tx(21, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Ring X: ${SleepData.duration(data.nights[20]!)}. Ваша оценка: ${SleepData.duration(data.report!.minutes!)}.',
                style: tx(14),
              ),
              const SizedBox(height: 8),
              Text(
                data.comparisonNote ??
                    'Разница больше часа. Можно уточнить контекст или оставить причину неизвестной.',
                style: tx(14, color: C.muted),
              ),
              TextButton(
                key: const ValueKey('sleep-compare'),
                onPressed: compare,
                child: const Text('Разобрать расхождение →'),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: tx(10, color: C.muted)),
      const SizedBox(height: 6),
      Text(value, style: tx(21, weight: FontWeight.w600)),
    ],
  );

  Widget sourceView() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: C.soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.watch_outlined, size: 32, color: C.green),
            ),
            const SizedBox(width: 14),
            Expanded(child: detail('Ring X', 'Демонстрационное устройство')),
          ],
        ),
        gap,
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(data.status, green: data.authorized && data.online),
        ),
        gap,
        detail('Последняя синхронизация', data.lastSync),
        gap,
        detail(
          'Доступ к данным',
          data.authorized
              ? 'Разрешено чтение сна, HRV, пульса покоя и качества сигнала в демо-режиме.'
              : 'Доступ отключён. Видна только сохранённая история.',
        ),
        gap,
        Surface(
          padding: 18,
          color: C.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              detail(
                'Сон',
                '${data.nights.length} ночей · 1 пропуск · без заполнения средним',
              ),
              gap,
              detail(
                'HRV',
                data.quality == SleepQuality.partial
                    ? 'Неполный сигнал. Текущее числовое значение не показываем.'
                    : '${!data.authorized || !data.online ? 'Последнее сохранённое: ' : ''}48 мс · демо-измерение',
              ),
              gap,
              detail(
                'Пульс покоя',
                '${!data.authorized || !data.online ? 'Последнее сохранённое: ' : ''}59 уд/мин · демо-измерение',
              ),
            ],
          ),
        ),
        gap,
        if (data.quality == SleepQuality.calibration) ...[
          detail(
            'Калибровка · ${data.nights.length} из 7 ночей',
            'В примере идёт накопление личной истории. Само подключение не завершает калибровку.',
          ),
          gap,
        ],
        if (data.quality == SleepQuality.partial) ...[
          detail(
            'Почему нет значения HRV',
            'В выбранном демо-сценарии данных недостаточно. Сон и личные отметки доступны, программа не блокируется.',
          ),
          gap,
        ],
        if (syncMessage != null) ...[
          Text(
            syncMessage!,
            key: const ValueKey('sleep-sync-message'),
            style: tx(14, color: C.muted),
          ),
          gap,
        ],
        if (data.authorized) ...[
          PrimaryButton(
            syncing ? 'Синхронизация…' : 'Синхронизировать · демо',
            syncing ? null : sync,
            key: const ValueKey('sleep-sync'),
          ),
          if (!data.online) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              key: const ValueKey('sleep-reconnect'),
              onPressed: syncing ? null : connect,
              child: const Text('Переподключить'),
            ),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                key: const ValueKey('sleep-scenarios'),
                onPressed: syncing ? null : scenarios,
                child: const Text('Демо: проверить состояния'),
              ),
              TextButton(
                key: const ValueKey('sleep-disconnect'),
                onPressed: syncing ? null : disconnect,
                child: const Text('Отключить источник'),
              ),
            ],
          ),
        ] else
          PrimaryButton(
            'Подключить демо-устройство',
            connect,
            key: const ValueKey('sleep-connect'),
          ),
        TextButton(
          key: const ValueKey('sleep-without-device'),
          onPressed: () => showTab(0),
          child: const Text('Продолжить без устройства'),
        ),
      ],
    ),
  );

  Widget side() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: C.dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.sensors_rounded, color: C.lime, size: 30),
            ),
            gap,
            Text(
              'Источник имеет значение',
              style: tx(
                24,
                weight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ring X · ${data.status}\n${data.lastSync}',
              style: tx(14, color: const Color(0xFFBDCEC5)),
            ),
            const SizedBox(height: 14),
            TextButton(
              key: const ValueKey('sleep-open-source'),
              onPressed: () => showTab(1),
              style: TextButton.styleFrom(foregroundColor: C.lime),
              child: const Text('Источник и качество →'),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Сон и энергия', style: tx(21, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Энергия: ${widget.radar.latest(0)!.value}/10 · ваша отметка ${widget.radar.latest(0)!.day} октября',
              style: tx(14),
            ),
            const SizedBox(height: 10),
            Text(
              'Для сопоставления во времени нужны ваши отметки за те же дни. По этим данным причину самочувствия не определяем.',
              style: tx(14, color: C.muted),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Спокойный вечер', style: tx(21, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              widget.radar.sleepJoined
                  ? widget.radar.sleepPaused
                        ? 'Программа на паузе. Отметки сохранены.'
                        : 'Программа в вашем плане.'
                  : 'Вечерняя пауза и наблюдение за восстановлением. Работает и без устройства.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('sleep-open-program'),
              onPressed: widget.onProgram,
              child: const Text('Открыть программу'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget historyView() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'История источника и отметок',
          style: tx(25, weight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'Все события относятся к демонстрационному сценарию. Отключение не удаляет сохранённые записи.',
          style: tx(14, color: C.muted),
        ),
        gap,
        for (final event in data.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: 16,
              color: C.soft,
              child: Text(event, style: tx(14)),
            ),
          ),
      ],
    ),
  );
}
