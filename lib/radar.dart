part of 'main.dart';

class RadarObservation {
  const RadarObservation(this.domain, this.value, this.day, this.note);
  final int domain, value, day;
  final String note;
}

class RadarData extends ChangeNotifier {
  static const domains = [
    'Энергия',
    'Разум',
    'Иммунитет',
    'Восстановление',
    'Обмен',
    'Сердце',
  ];
  final observations = <RadarObservation>[
    const RadarObservation(0, 5, 19, 'Исходная демо-отметка'),
  ];
  bool sleepJoined = false, sleepPaused = false;
  final completed = <String>{};
  RadarObservation? latest(int domain) {
    final items = observations.where((o) => o.domain == domain);
    return items.isEmpty ? null : items.last;
  }

  int? get todayEnergy => observations
      .where((o) => o.domain == 0 && o.day == 20)
      .firstOrNull
      ?.value;
  int get coverage => observations.map((o) => o.domain).toSet().length;
  void record(int domain, int value, {String note = ''}) {
    observations.removeWhere((o) => o.domain == domain && o.day == 20);
    observations.add(RadarObservation(domain, value, 20, note));
    notifyListeners();
  }

  void joinSleep() {
    sleepJoined = true;
    notifyListeners();
  }

  void toggleSleepPause() {
    sleepPaused = !sleepPaused;
    notifyListeners();
  }

  void toggleTask(String id) {
    if (!completed.add(id)) completed.remove(id);
    notifyListeners();
  }
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({
    required this.data,
    required this.programs,
    required this.walkDone,
    required this.recoveryPaused,
    required this.onPlan,
    required this.onSpecialist,
    required this.onPauseRecovery,
    required this.onSupport,
    required this.onSleep,
    this.supportUrgent = false,
    this.expertLibrary,
    super.key,
  });
  final RadarData data;
  final bool programs, walkDone, recoveryPaused;
  final VoidCallback onPlan, onSpecialist, onPauseRecovery;
  final VoidCallback onSupport;
  final VoidCallback onSleep;
  final bool supportUrgent;
  final ExpertLibrary? expertLibrary;
  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  void openLibrary() {
    setState(() {
      program = null;
      activeOnly = false;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  int? domain, program;
  int overviewTab = 0;
  bool activeOnly = false;
  RadarData get data => widget.data;
  static const mint = Color(0xFFBDEFE0);
  static const field = Color(0xFF061312);
  static const domainIcons = [
    Icons.bolt_outlined,
    Icons.psychology_outlined,
    Icons.shield_outlined,
    Icons.spa_outlined,
    Icons.sync_rounded,
    Icons.favorite_border_rounded,
  ];
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void showView(VoidCallback change) {
    setState(change);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void openDomain(int index) => showView(() {
    domain = index;
    program = null;
  });
  void openProgram(int index) => showView(() => program = index);

  Future<T?> modal<T>(
    String title,
    Widget Function(BuildContext) builder,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
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
                    child: Text(title, style: tx(24, weight: FontWeight.w600)),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> record(int d) async {
    final saved = await modal<int>(
      d == 0 ? 'Сколько у вас энергии?' : 'Как вы восстановились?',
      (ctx) => ObservationForm(
        initial: data.latest(d)?.value ?? 5,
        onSave: (v) => Navigator.pop(ctx, v),
      ),
    );
    if (saved != null && mounted) data.record(d, saved);
  }

  void sources(int d) => modal<void>(
    'Откуда эти данные',
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.latest(d) == null
              ? 'Для этой области наблюдений пока нет.'
              : 'Источник — личная отметка по шкале 0–10. Устройства и лаборатории не подключены.',
          style: tx(15),
        ),
        const SizedBox(height: 16),
        Text(
          'Цвет и форма поля показывают связи областей, а не общий балл здоровья. Выполнение программы не меняет показатель автоматически.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 16),
        Text(
          'Сценарий зафиксирован на 20 октября 2026. Исходная отметка за 19 октября — демонстрационная. Новые отметки хранятся до обновления страницы.',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 24),
        PrimaryButton('Понятно', () => Navigator.pop(ctx)),
      ],
    ),
  );

  Future<void> joinProgram() async {
    final confirm = await modal<bool>(
      'Добавить программу?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Спокойный вечер', style: tx(23, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            '7 дней наблюдений за вечерним ритмом и ощущением восстановления. Два небольших действия в день.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          detailRow('Время на день', 'Около 10 минут'),
          detailRow('Связанные области', 'Энергия, восстановление'),
          const SizedBox(height: 18),
          Text(
            'Это демонстрационная программа. Подключение не изменит вашу текущую программу восстановления.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Добавить в мои программы',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-program'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) data.joinSleep();
  }

  Future<void> task(String id, String title, String body) async {
    final done = data.completed.contains(id);
    final result = await modal<bool>(
      title,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(body, style: tx(15, color: C.muted)),
          const SizedBox(height: 24),
          PrimaryButton(
            done ? 'Снять отметку выполнения' : 'Отметить выполненным',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-task'),
          ),
        ],
      ),
    );
    if (result == true && mounted) data.toggleTask(id);
  }

  Future<void> pauseSleep() async {
    final result = await modal<bool>(
      data.sleepPaused
          ? 'Продолжить программу?'
          : 'Поставить программу на паузу?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Все отметки сохранятся. Вы сможете продолжить в удобном ритме.',
            style: tx(15, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            data.sleepPaused ? 'Продолжить' : 'Поставить на паузу',
            () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result == true && mounted) data.toggleSleepPause();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final narrow = box.maxWidth < 700;
      return SingleChildScrollView(
        controller: scroll,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                narrow ? 16 : 36,
                26,
                narrow ? 16 : 36,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (program != null || domain != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('radar-back'),
                        onPressed: () => showView(() {
                          if (program != null) {
                            program = null;
                          } else {
                            domain = null;
                          }
                        }),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(
                          program != null
                              ? (domain != null
                                    ? 'К показателю'
                                    : 'К программам')
                              : 'К радару',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.supportUrgent &&
                      (program != null || widget.programs))
                    SupportPriorityPanel(onOpen: widget.onSupport)
                  else if (program != null)
                    programDetail(program!, box.maxWidth >= 1000)
                  else if (domain != null)
                    domainDetail(domain!, box.maxWidth >= 1000)
                  else if (widget.programs)
                    programList()
                  else
                    overview(box.maxWidth >= 1000),
                  const SizedBox(height: 28),
                  Text(
                    'Демо · наблюдения и программы для тестирования интерфейса · 20 октября 2026',
                    style: tx(11, color: C.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget heading(String eyebrow, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: tx(11, color: C.muted, weight: FontWeight.w500),
      ),
      const SizedBox(height: 10),
      Text(title, style: tx(32, weight: FontWeight.w600, height: 1.15)),
      const SizedBox(height: 12),
      Text(subtitle, style: tx(15, color: C.muted)),
    ],
  );

  Widget columns(Widget left, Widget right, bool wide) => wide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: left),
            const SizedBox(width: 24),
            Expanded(child: right),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 20), right],
        );

  Widget overview(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        'МОЁ ЗДОРОВЬЕ',
        'Радар здоровья',
        'Ваши наблюдения, их контекст и следующие шаги.',
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < 2; i++)
            ChoiceChip(
              label: Text(['Состояние', 'Дневник энергии'][i]),
              selected: overviewTab == i,
              onSelected: (_) => setState(() => overviewTab = i),
              showCheckmark: false,
            ),
        ],
      ),
      const SizedBox(height: 22),
      if (overviewTab == 0) ...[
        Container(
          padding: EdgeInsets.all(wide ? 30 : 18),
          decoration: BoxDecoration(
            color: field,
            borderRadius: BorderRadius.circular(30),
          ),
          child: columns(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Каждая область — часть общей картины',
                  style: tx(16, color: mint),
                ),
                const SizedBox(height: 20),
                LivingRadar(data: data, onDomain: openDomain),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/radar/dot.png', width: 5, height: 5),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${data.coverage} из 6 областей · остальные без данных',
                        style: tx(12, color: mint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ВАША ЦЕЛЬ', style: tx(11, color: C.lime)),
                const SizedBox(height: 12),
                Text(
                  'Больше энергии',
                  style: tx(28, weight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  'Начинаем с ваших наблюдений. Следующий шаг — в вашем плане.',
                  style: tx(15, color: mint),
                ),
                const SizedBox(height: 22),
                Surface(
                  color: const Color(0xFF0C2924),
                  padding: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Картина пока неполная',
                        style: tx(
                          18,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${data.coverage} из 6',
                        style: tx(
                          38,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'областей с наблюдениями',
                        style: tx(13, color: mint),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Это личные отметки. Для выводов о причинах и динамике нужно больше контекста.',
                        style: tx(13, color: mint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  'Сделать отметку энергии',
                  () => record(0),
                  key: const ValueKey('record-energy'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onPlan,
                  style: TextButton.styleFrom(foregroundColor: mint),
                  child: const Text('Посмотреть мой план →'),
                ),
              ],
            ),
            wide,
          ),
        ),
        const SizedBox(height: 30),
        Text('Ваши показатели', style: tx(25, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Откройте область, чтобы увидеть источник данных и связанные действия.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (ctx, b) {
            final count = b.maxWidth > 900
                ? 3
                : b.maxWidth > 560
                ? 2
                : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: (b.maxWidth - (count - 1) * 16) / count,
                  child: domainCard(i),
                ),
              ),
            );
          },
        ),
      ] else
        diary(0),
      const SizedBox(height: 28),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'От наблюдения — к действию',
              style: tx(24, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Программы помогают выстроить ритм. Изменения самочувствия отслеживаются отдельно.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 18),
            programTile(0),
          ],
        ),
      ),
    ],
  );

  Widget domainCard(int d) {
    final o = data.latest(d);
    return Semantics(
      button: true,
      child: InkWell(
        key: ValueKey('domain-$d'),
        onTap: () => openDomain(d),
        borderRadius: BorderRadius.circular(26),
        child: Surface(
          padding: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(domainIcons[d], color: C.green, size: 23),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      RadarData.domains[d],
                      style: tx(18, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.north_east, size: 17, color: C.muted),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                o == null ? 'Нет данных' : '${o.value} / 10',
                style: tx(o == null ? 23 : 32, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                o == null
                    ? 'Наблюдения ещё не добавлены'
                    : 'Самооценка · ${o.day} октября',
                style: tx(12, color: C.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget domainDetail(int d, bool wide) {
    final o = data.latest(d);
    final trackable = d == 0 || d == 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(
          'РАДАР / ПОКАЗАТЕЛЬ',
          RadarData.domains[d],
          trackable
              ? 'Личные наблюдения и действия, связанные с этой областью.'
              : 'Здесь появятся наблюдения с понятным источником и датой.',
        ),
        const SizedBox(height: 24),
        columns(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                color: C.dark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(domainIcons[d], color: C.lime, size: 30),
                    const SizedBox(height: 20),
                    Text(
                      o == null ? 'Пока нет наблюдений' : '${o.value} / 10',
                      style: tx(
                        o == null ? 28 : 54,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      o == null
                          ? 'Отсутствие данных не означает низкий показатель.'
                          : 'Последняя самооценка · ${o.day} октября',
                      style: tx(14, color: mint),
                    ),
                    const SizedBox(height: 24),
                    if (trackable)
                      PrimaryButton(
                        o == null
                            ? 'Добавить наблюдение'
                            : 'Обновить наблюдение',
                        () => record(d),
                      )
                    else
                      OutlinedButton(
                        onPressed: widget.onSpecialist,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.lime,
                        ),
                        child: const Text('Обсудить со специалистом'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              diary(d),
              if (d == 3) ...[
                const SizedBox(height: 20),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Устройства и сон',
                        style: tx(21, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Длительность сна, ваша отметка и качество источника. Показания устройства не заменяют самооценку.',
                        style: tx(14, color: C.muted),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        'Открыть сон',
                        widget.onSleep,
                        key: const ValueKey('radar-open-sleep'),
                      ),
                    ],
                  ),
                ),
              ],
              if (d == 1) ...[
                const SizedBox(height: 20),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Эмоциональное состояние',
                        style: tx(21, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Можно описать, как вы сейчас, и выбрать поддержку. Личная отметка не превращается в балл радара.',
                        style: tx(14, color: C.muted),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        'Открыть поддержку',
                        widget.onSupport,
                        key: const ValueKey('radar-open-support'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что известно',
                      style: tx(21, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      o == null
                          ? 'Для этой области нет подключённого источника. Общий балл не рассчитывается.'
                          : 'Значение отражает ваше ощущение в момент отметки. Оно не объясняет причину самочувствия.',
                      style: tx(14, color: C.muted),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => sources(d),
                      child: const Text('Источник и ограничения →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      trackable ? 'Связанные программы' : 'Следующий шаг',
                      style: tx(21, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (trackable) ...[
                      programTile(0),
                      const SizedBox(height: 12),
                      programTile(1),
                    ] else ...[
                      Text(
                        'Можно начать с обсуждения того, какие данные будут полезны именно вам.',
                        style: tx(14, color: C.muted),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: widget.onSpecialist,
                        child: const Text('Открыть профиль врача'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          wide,
        ),
      ],
    );
  }

  Widget diary(int d) {
    final entries = data.observations.where((o) => o.domain == d).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final difference = entries.length > 1
        ? entries.last.value - entries.first.value
        : 0;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                d == 0 ? 'Дневник энергии' : 'История наблюдений',
                style: tx(23, weight: FontWeight.w600),
              ),
              const Tag('Последние 7 дней'),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty) ...[
            const Icon(Icons.timeline_rounded, size: 46, color: C.muted),
            const SizedBox(height: 14),
            Text(
              'История начнётся с первой отметки',
              style: tx(17, weight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Наблюдения появятся здесь после сохранения.',
              style: tx(14, color: C.muted),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              entries.length < 2
                  ? 'Пока одна отметка — динамику ещё не определить.'
                  : 'Изменение между отметками: ${difference > 0 ? '+' : ''}$difference. Для устойчивой тенденции данных пока мало.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final day = 14 + i;
                  final match = entries.where((o) => o.day == day).firstOrNull;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          match == null ? '—' : '${match.value}',
                          style: tx(
                            12,
                            color: match == null ? C.muted : C.green,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 20,
                          height: match == null ? 3 : 4 + match.value * 8.0,
                          decoration: BoxDecoration(
                            color: match == null ? C.line : C.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text('$day', style: tx(11, color: C.muted)),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Октябрь · шкала 0–10 · «—» означает нет данных',
              style: tx(11, color: C.muted),
            ),
            const Divider(height: 32),
            for (final o in entries.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${o.day} октября',
                            style: tx(14, weight: FontWeight.w500),
                          ),
                          Text(
                            o.day == 19
                                ? 'Исходная демо-отметка'
                                : 'Ваша отметка · этот сеанс',
                            style: tx(11, color: C.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${o.value} / 10',
                      style: tx(18, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
          if (d == 0 || d == 3) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => record(d),
              child: const Text('Добавить отметку'),
            ),
          ],
        ],
      ),
    );
  }

  String programName(int p) =>
      p == 0 ? 'Программа восстановления' : 'Спокойный вечер';
  bool programPaused(int p) =>
      p == 0 ? widget.recoveryPaused : data.sleepPaused;
  int progress(int p) => p == 0
      ? (widget.walkDone ? 1 : 0) +
            (data.todayEnergy != null ? 1 : 0) +
            (data.completed.contains('recovery-reflect') ? 1 : 0)
      : (data.completed.contains('sleep-ritual') ? 1 : 0) +
            (data.latest(3)?.day == 20 ? 1 : 0);
  int total(int p) => p == 0 ? 3 : 2;

  Widget programTile(int p) => InkWell(
    key: ValueKey('program-$p'),
    onTap: () => openProgram(p),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            p == 0 ? Icons.spa_outlined : Icons.nights_stay_outlined,
            color: C.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(programName(p), style: tx(15, weight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(
                  p == 0 || data.sleepJoined
                      ? (programPaused(p)
                            ? 'На паузе'
                            : 'Сегодня: ${progress(p)} из ${total(p)}')
                      : '7 дней · можно начать',
                  style: tx(12, color: C.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: C.muted),
        ],
      ),
    ),
  );

  Widget programList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        'МОИ ДЕЙСТВИЯ',
        'Программы',
        'Небольшие шаги для вашей цели. Выполнение и самочувствие — рядом.',
      ),
      const SizedBox(height: 24),
      if (widget.expertLibrary != null &&
          widget.expertLibrary!.deliveries.isNotEmpty) ...[
        PatientLibraryPanel(library: widget.expertLibrary!),
        const SizedBox(height: 24),
      ],
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Все программы'),
            selected: !activeOnly,
            onSelected: (_) => setState(() => activeOnly = false),
          ),
          ChoiceChip(
            label: Text('Мои (${data.sleepJoined ? 2 : 1})'),
            selected: activeOnly,
            onSelected: (_) => setState(() => activeOnly = true),
          ),
        ],
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (ctx, b) {
          final wide = b.maxWidth > 740;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final p in [0, 1])
                if (!activeOnly || p == 0 || data.sleepJoined)
                  SizedBox(
                    width: wide ? (b.maxWidth - 20) / 2 : b.maxWidth,
                    child: Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                p == 0
                                    ? Icons.spa_outlined
                                    : Icons.nights_stay_outlined,
                                color: C.green,
                                size: 32,
                              ),
                              const Spacer(),
                              Tag(
                                p == 0 || data.sleepJoined
                                    ? (programPaused(p)
                                          ? 'На паузе'
                                          : 'В моём плане')
                                    : 'Для вашей цели',
                                green: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Text(
                            programName(p),
                            style: tx(26, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p == 0
                                ? 'Вернуться к ежедневной активности в комфортном темпе.'
                                : 'Наблюдать за вечерним ритмом и ощущением восстановления.',
                            style: tx(15, color: C.muted),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Tag(p == 0 ? '8 недель' : '7 дней'),
                              Tag(
                                p == 0 ? '10–20 мин / день' : '≈10 мин / день',
                              ),
                              const Tag('Энергия'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (p == 0 || data.sleepJoined) ...[
                            LinearProgressIndicator(
                              value: progress(p) / total(p),
                              backgroundColor: C.soft,
                              color: C.green,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Сегодня выполнено ${progress(p)} из ${total(p)}',
                              style: tx(13, color: C.muted),
                            ),
                            const SizedBox(height: 16),
                          ],
                          PrimaryButton(
                            'Открыть программу',
                            () => openProgram(p),
                            key: ValueKey('open-program-$p'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    ],
  );

  Widget programDetail(int p, bool wide) {
    final joined = p == 0 || data.sleepJoined;
    final isPaused = programPaused(p);
    final count = progress(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(
          'ПРОГРАММА / ЭНЕРГИЯ И ВОССТАНОВЛЕНИЕ',
          programName(p),
          p == 0
              ? 'Движение, наблюдение и бережное возвращение к своему ритму.'
              : 'Небольшая вечерняя пауза и внимание к тому, как вы восстановились.',
        ),
        if (p == 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('program-open-sleep'),
              onPressed: widget.onSleep,
              icon: const Icon(Icons.bedtime_outlined, size: 18),
              label: const Text('Мой сон и устройства →'),
            ),
          ),
        const SizedBox(height: 24),
        columns(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                color: C.dark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Tag(
                          joined
                              ? (isPaused ? 'На паузе' : 'Активна')
                              : 'Можно начать',
                          green: true,
                        ),
                        Tag(p == 0 ? 'Неделя 2 из 8' : '7 дней'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      joined
                          ? 'Сегодня достаточно небольшого шага'
                          : 'Создайте пространство для отдыха',
                      style: tx(
                        28,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Результат программы — ваши наблюдения во времени. Отметки выполнения сами по себе не повышают показатели радара.',
                      style: tx(14, color: mint),
                    ),
                    const SizedBox(height: 24),
                    if (joined) ...[
                      Text(
                        '$count из ${total(p)} действий сегодня',
                        style: tx(
                          19,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: count / total(p),
                        minHeight: 8,
                        color: C.lime,
                        backgroundColor: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: p == 0 ? widget.onPauseRecovery : pauseSleep,
                        style: TextButton.styleFrom(foregroundColor: C.lime),
                        child: Text(
                          isPaused ? 'Продолжить программу' : 'Пауза программы',
                        ),
                      ),
                    ] else
                      PrimaryButton(
                        'Начать программу',
                        joinProgram,
                        key: const ValueKey('join-program'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      joined
                          ? 'Ваши действия на сегодня'
                          : 'Что входит в программу',
                      style: tx(23, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      joined
                          ? (isPaused
                                ? 'Программа на паузе. Отметки сохранены.'
                                : '20 октября · отмечайте действия по мере выполнения')
                          : 'После добавления можно выполнять шаги и сохранять наблюдения.',
                      style: tx(13, color: C.muted),
                    ),
                    const SizedBox(height: 20),
                    if (p == 0) ...[
                      taskRow(
                        'energy',
                        'Отметить энергию',
                        'Самооценка 0–10 · 1 мин',
                        data.todayEnergy != null,
                        () => record(0),
                        enabled: !isPaused,
                      ),
                      taskRow(
                        'walk',
                        'Спокойная прогулка',
                        'Текущий шаг в плане восстановления',
                        widget.walkDone,
                        widget.onPlan,
                        enabled: !isPaused,
                      ),
                      taskRow(
                        'reflect',
                        'Подвести итог дня',
                        'Заметьте, что сегодня помогло',
                        data.completed.contains('recovery-reflect'),
                        () => task(
                          'recovery-reflect',
                          'Итог дня',
                          'Вспомните один момент, после которого вы чувствовали себя лучше. Здесь можно отметить, что вы уделили этому внимание.',
                        ),
                        enabled: !isPaused,
                      ),
                    ] else ...[
                      taskRow(
                        'ritual',
                        'Вечерняя пауза',
                        '10 минут без текущих дел',
                        data.completed.contains('sleep-ritual'),
                        () => task(
                          'sleep-ritual',
                          'Вечерняя пауза',
                          'Выделите немного времени на привычное спокойное занятие. Отметьте выполнение, когда закончите.',
                        ),
                        enabled: joined && !isPaused,
                      ),
                      taskRow(
                        'rest',
                        'Отметить восстановление',
                        'Личное ощущение · 1 мин',
                        data.latest(3)?.day == 20,
                        () => record(3),
                        enabled: joined && !isPaused,
                      ),
                    ],
                    if (joined && count == total(p)) ...[
                      const SizedBox(height: 18),
                      const Tag('На сегодня всё выполнено ✓', green: true),
                      const SizedBox(height: 10),
                      Text(
                        'Хорошая точка для паузы. Оценить изменения можно по следующим наблюдениям.',
                        style: tx(14, color: C.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'С чем связана программа',
                      style: tx(21, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    for (final d in [0, 3])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton.icon(
                          onPressed: () => openDomain(d),
                          icon: Icon(domainIcons[d], size: 19),
                          label: Text(RadarData.domains[d]),
                        ),
                      ),
                    Text(
                      'Сравниваем наблюдения, а не количество галочек.',
                      style: tx(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Нужна помощь?',
                      style: tx(22, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const DoctorMini(),
                    const SizedBox(height: 14),
                    Text(
                      'Обсудите самочувствие и вопросы о следующем шаге.',
                      style: tx(13, color: C.muted),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: widget.onSpecialist,
                      child: const Text('Открыть профиль врача'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          wide,
        ),
      ],
    );
  }

  Widget taskRow(
    String id,
    String title,
    String subtitle,
    bool done,
    VoidCallback onTap, {
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton(
      key: ValueKey('task-$id'),
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide(color: done ? const Color(0xFFB4DBBC) : C.line),
        backgroundColor: done ? const Color(0xFFF0FAEC) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 24,
            color: done ? C.green : C.muted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tx(
                    15,
                    weight: FontWeight.w500,
                    color: enabled ? C.ink : C.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: tx(12, color: C.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: C.muted),
        ],
      ),
    ),
  );
}

class ObservationForm extends StatefulWidget {
  const ObservationForm({
    required this.initial,
    required this.onSave,
    super.key,
  });
  final int initial;
  final ValueChanged<int> onSave;
  @override
  State<ObservationForm> createState() => _ObservationFormState();
}

class _ObservationFormState extends State<ObservationForm> {
  late int rating = widget.initial;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Оцените своё ощущение сейчас. 0 — совсем нет сил, 10 — максимум. Это самооценка, а не медицинский показатель.',
        style: tx(14, color: C.muted),
      ),
      const SizedBox(height: 22),
      Text(
        '$rating / 10',
        textAlign: TextAlign.center,
        style: tx(40, weight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 5,
        runSpacing: 5,
        alignment: WrapAlignment.center,
        children: List.generate(
          11,
          (i) => ChoiceChip(
            key: ValueKey('rating-$i'),
            label: Text('$i'),
            selected: rating == i,
            showCheckmark: false,
            onSelected: (_) => setState(() => rating = i),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Сохраняется одна отметка за день. Повторная запись обновит сегодняшнее значение.',
        style: tx(12, color: C.muted),
      ),
      const SizedBox(height: 22),
      PrimaryButton(
        'Сохранить наблюдение',
        () => widget.onSave(rating),
        key: const ValueKey('save-observation'),
      ),
    ],
  );
}

class LivingRadar extends StatelessWidget {
  const LivingRadar({required this.data, required this.onDomain, super.key});
  final RadarData data;
  final ValueChanged<int> onDomain;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, b) {
      // The exported decorative layers keep the geometry of Figma node 3186:179.
      // Labels are interactive widgets; the field is not a quantitative polygon.
      return SizedBox(
        height: b.maxWidth * 501.6 / 644.3,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 644.3,
            height: 501.6,
            child: Stack(
              children: [
                Positioned(
                  left: 107.65,
                  top: 36.3,
                  width: 429,
                  height: 429,
                  child: Image.asset('assets/radar/living-field.png'),
                ),
                Positioned(
                  left: 114.25,
                  top: 49.5,
                  width: 415.8,
                  height: 415.8,
                  child: Image.asset('assets/radar/ambient.png'),
                ),
                Positioned(
                  left: 173.08,
                  top: 90.1,
                  width: 298.14,
                  height: 324.7,
                  child: Image.asset('assets/radar/relationships.png'),
                ),
                Positioned(
                  left: 307.96,
                  top: 79.2,
                  width: 28.38,
                  height: 100.65,
                  child: Image.asset('assets/radar/signal.png'),
                ),
                Positioned(
                  left: 300.7,
                  top: 69.3,
                  width: 42.9,
                  height: 42.9,
                  child: Image.asset('assets/radar/observed.png'),
                ),
                for (final pos in [
                  const Offset(465.7, 168.3),
                  const Offset(465.7, 328.35),
                  const Offset(317.2, 409.2),
                  const Offset(168.7, 328.35),
                  const Offset(168.7, 168.3),
                ])
                  Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    width: 9.9,
                    height: 9.9,
                    child: Image.asset('assets/radar/empty.png'),
                  ),
                for (final item in [
                  (0, 223.15, 0.0, 198.0),
                  (1, 488.8, 128.7, 115.5),
                  (2, 482.2, 308.55, 158.0),
                  (3, 223.15, 427.35, 198.0),
                  (4, 40.0, 308.55, 115.5),
                  (5, 40.0, 128.7, 115.5),
                ])
                  Positioned(
                    left: item.$2,
                    top: item.$3,
                    width: item.$4,
                    child: Semantics(
                      button: true,
                      label:
                          '${RadarData.domains[item.$1]}: ${data.latest(item.$1)?.value.toString() ?? "нет данных"}',
                      child: InkWell(
                        onTap: () => onDomain(item.$1),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Text(
                              RadarData.domains[item.$1],
                              style: tx(
                                b.maxWidth < 500 ? 24 : 18.15,
                                height: 1.2,
                                color: const Color(0xFFBDEFE0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              data.latest(item.$1) == null
                                  ? '—'
                                  : '${data.latest(item.$1)!.value} / 10',
                              style: tx(
                                item.$1 == 0 ? 34.65 : 29.7,
                                color: Colors.white,
                                weight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
