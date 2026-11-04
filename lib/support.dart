part of 'main.dart';

class SupportEntry {
  const SupportEntry(this.mood, this.note, this.context);
  final String mood, note, context;
}

class SupportData extends ChangeNotifier {
  static const moods = [
    'Спокойно',
    'Перегружен(а)',
    'Тревожно',
    'Очень тяжело',
  ];
  final entries = <SupportEntry>[];
  final events = <String>[];
  final done = <int>{};
  bool urgent = false, active = false;
  int sessions = 0;
  String? get latestMood => entries.isEmpty ? null : entries.last.mood;
  void record(
    String mood,
    String note, {
    String context = 'Отметка состояния',
  }) {
    entries.add(SupportEntry(mood, note.trim(), context));
    notifyListeners();
  }

  void start() {
    if (urgent || active) return;
    active = true;
    done.clear();
    sessions++;
    events.insert(0, 'Начат план поддержки №$sessions.');
    notifyListeners();
  }

  void mark(int step) {
    if (!active || urgent || !done.add(step)) return;
    events.insert(
      0,
      'План №$sessions · ${['необязательный пункт отложен', 'пауза завершена', 'связь с близким отмечена вами'][step]}.',
    );
    notifyListeners();
  }

  void finish(String result) {
    if (!active || urgent) return;
    events.insert(
      0,
      'План №$sessions завершён. Ваша оценка: $result. Отмечено действий: ${done.length} из 3.',
    );
    active = false;
    notifyListeners();
  }

  void openUrgent() {
    if (urgent) return;
    urgent = true;
    events.insert(
      0,
      'Открыта немедленная помощь. Обычные задания временно скрыты. Обращение в службу не отправлялось.',
    );
    notifyListeners();
  }

  void leaveUrgent() {
    if (!urgent) return;
    urgent = false;
    active = false;
    events.insert(
      0,
      'Вы подтвердили, что сейчас в безопасности. Автоматической оценки состояния нет; предыдущий план поддержки не возобновлён.',
    );
    notifyListeners();
  }
}

class SupportSummary extends StatelessWidget {
  const SupportSummary({required this.data, required this.onOpen, super.key});
  final SupportData data;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.self_improvement_rounded, color: C.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Состояние и поддержка',
                style: tx(21, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          data.latestMood == null
              ? 'Небольшая пауза, чтобы прислушаться к себе.'
              : 'Последняя отметка · ${data.latestMood}',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('open-support'),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
            data.active ? 'Продолжить поддержку' : 'Открыть поддержку',
          ),
        ),
      ],
    ),
  );
}

class SupportPriorityPanel extends StatelessWidget {
  const SupportPriorityPanel({required this.onOpen, super.key});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.support_agent_rounded, size: 36, color: C.green),
        ),
        const SizedBox(height: 20),
        Text(
          'Сейчас на первом месте — поддержка',
          style: tx(28, weight: FontWeight.w600, height: 1.2),
        ),
        const SizedBox(height: 12),
        Text(
          'Вы открыли немедленную помощь. Обычные задания временно скрыты; ваши программы, отметки и история сохранены.',
          style: tx(15, color: C.muted),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'Открыть немедленную помощь',
          onOpen,
          key: const ValueKey('return-urgent-support'),
        ),
      ],
    ),
  );
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({required this.data, required this.onHome, super.key});
  final SupportData data;
  final VoidCallback onHome;
  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> {
  SupportData get data => widget.data;
  int tab = 0;
  final scroll = ScrollController();
  static const gap = SizedBox(height: 20);
  static const steps = [
    'Уберите один необязательный пункт',
    '3 минуты спокойной паузы',
    'Свяжитесь с человеком, которому доверяете',
  ];
  static const stepDetails = [
    'Можно освободить немного места в своём дне.',
    'В своём темпе. Можно остановиться в любой момент.',
    'Подготовьте сообщение или просто побудьте рядом.',
  ];
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void showTab(int value) {
    setState(() => tab = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void urgent() {
    data.openUrgent();
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<T?> popup<T>(
    String title,
    Widget Function(BuildContext) body,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
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
              body(ctx),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> checkIn({bool again = false}) async {
    String? mood;
    var note = '';
    final result = await popup<(String, String)>(
      'Как вы сейчас?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выберите описание, которое вам ближе. Это личная отметка, а не оценка или диагноз.',
              style: tx(14, color: C.muted),
            ),
            gap,
            for (final label in SupportData.moods)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  key: ValueKey(
                    'support-mood-${SupportData.moods.indexOf(label)}',
                  ),
                  label: SizedBox(width: double.infinity, child: Text(label)),
                  selected: mood == label,
                  onSelected: (_) => update(() => mood = label),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('support-note'),
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Заметка для себя · необязательно',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => note = v,
            ),
            gap,
            PrimaryButton(
              'Сохранить состояние',
              mood == null ? null : () => Navigator.pop(ctx, (mood!, note)),
              key: const ValueKey('save-support-mood'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ('urgent', '')),
              child: const Text('Нужна немедленная помощь'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.$1 == 'urgent') {
      urgent();
      return;
    }
    data.record(
      result.$1,
      result.$2,
      context: again ? 'Повторная отметка' : 'Отметка состояния',
    );
    showTab(0);
    if (result.$1 == 'Очень тяжело') await safetyChoice();
  }

  Future<void> safetyChoice() async {
    final safe = await popup<bool>(
      'Какая поддержка нужна сейчас?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Если вы не уверены в своей безопасности, откройте варианты немедленной помощи. Обычный план можно оставить на потом.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Нужна немедленная помощь',
            () => Navigator.pop(ctx, false),
            key: const ValueKey('support-choice-urgent'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('support-choice-safe'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Я в безопасности, хочу обычную поддержку',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted || safe == null) return;
    if (!safe) {
      urgent();
    } else {
      data.start();
      showTab(1);
    }
  }

  void startSupport() {
    if (data.latestMood == 'Очень тяжело' && !data.active) {
      safetyChoice();
      return;
    }
    data.start();
    showTab(1);
  }

  Future<void> lighten() async {
    final accepted = await popup<bool>(
      'Освободите немного места',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите одно необязательное дело, которое может подождать. Не нужно завершать весь список сегодня.',
            style: tx(15, color: C.muted),
          ),
          gap,
          Text(
            'Отметка относится к вашему решению. Записи к врачам, назначения и календарь не изменятся.',
            style: tx(13, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Я отложил(а) одно дело',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('support-lighten-confirm'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) data.mark(0);
  }

  Future<void> breathing() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SupportPauseDialog(),
    );
    if (!mounted) return;
    if (result == 'urgent') {
      urgent();
    } else if (result == 'done') {
      data.mark(1);
    }
  }

  Future<void> trusted({bool immediate = false}) async {
    var draft = immediate
        ? 'Мне сейчас очень тяжело. Пожалуйста, позвони мне или побудь рядом.'
        : 'Привет. Сегодня непростой день. Можем немного поговорить?';
    var copied = false;
    final result = await popup<bool>(
      'Человек, которому вы доверяете',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Можно позвонить близкому или отправить сообщение через привычный мессенджер.',
              style: tx(15, color: C.muted),
            ),
            gap,
            TextFormField(
              key: const ValueKey('support-contact-draft'),
              initialValue: draft,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Текст сообщения',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => update(() {
                draft = v;
                copied = false;
              }),
            ),
            gap,
            PrimaryButton(
              copied ? 'Текст скопирован' : 'Скопировать текст',
              draft.trim().isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: draft.trim()),
                      );
                      if (ctx.mounted) update(() => copied = true);
                    },
              key: const ValueKey('support-copy-contact'),
            ),
            const SizedBox(height: 12),
            Text(
              'Прототип не отправляет сообщения и не связывается с близкими автоматически.',
              style: tx(13, color: C.muted),
            ),
            if (!immediate)
              TextButton(
                key: const ValueKey('support-contact-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Я уже связался(-ась)'),
              ),
          ],
        ),
      ),
    );
    if (result == true && mounted && !immediate) data.mark(2);
  }

  Future<void> finish() async {
    String? feeling;
    final result = await popup<String>(
      'Как прошла эта пауза?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Необязательно выполнять все действия. Можно завершить поддержку без оценки.',
              style: tx(14, color: C.muted),
            ),
            gap,
            for (final label in [
              'Стало немного легче',
              'Без изменений',
              'Стало тяжелее',
              'Не хочу оценивать',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity, child: Text(label)),
                  selected: feeling == label,
                  onSelected: (_) => update(() => feeling = label),
                ),
              ),
            gap,
            PrimaryButton(
              'Завершить поддержку',
              feeling == null ? null : () => Navigator.pop(ctx, feeling),
              key: const ValueKey('support-finish-confirm'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    data.finish(result);
    showTab(1);
    if (result == 'Стало тяжелее') await safetyChoice();
  }

  Future<void> leaveUrgent() async {
    final confirmed = await popup<bool>(
      'Вернуться к обычному экрану?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Возвращайтесь, если сейчас вы в безопасности. Прототип не может оценить ваше состояние или подтвердить, что помощь получена.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Сейчас я в безопасности',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('support-exit-confirm'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Остаться на экране помощи'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      data.leaveUrgent();
      showTab(0);
    }
  }

  Future<void> emergencyDetails() async {
    var russia = true, copied = false;
    await popup<void>(
      'Варианты немедленной помощи',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Для примера выбрана Россия. Геолокация не определяется.',
              style: tx(13, color: C.muted),
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Россия'),
                  selected: russia,
                  onSelected: (_) => update(() {
                    russia = true;
                    copied = false;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Другая страна'),
                  selected: !russia,
                  onSelected: (_) => update(() {
                    russia = false;
                    copied = false;
                  }),
                ),
              ],
            ),
            gap,
            if (russia) ...[
              SelectableText('112', style: tx(48, weight: FontWeight.w600)),
              Text(
                'Единый номер экстренных служб России. При непосредственной угрозе жизни позвоните с телефона.',
                style: tx(15),
              ),
              gap,
              PrimaryButton(
                copied ? 'Номер скопирован' : 'Скопировать номер',
                () async {
                  await Clipboard.setData(const ClipboardData(text: '112'));
                  if (ctx.mounted) update(() => copied = true);
                },
                key: const ValueKey('support-copy-emergency'),
              ),
              const SizedBox(height: 12),
              Text(
                'Источник: МЧС России · проверено 27 октября 2026.',
                style: tx(12, color: C.muted),
              ),
            ] else ...[
              Text(
                'Обратитесь в местную экстренную службу или ближайшее отделение неотложной помощи.',
                style: tx(16, weight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                'В этом прототипе справочник для других стран пока не подключён.',
                style: tx(14, color: C.muted),
              ),
            ],
            gap,
            Text(
              'Звонок не совершается из прототипа. Открытие этого экрана и копирование номера не означают, что служба уведомлена.',
              style: tx(13, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 700;
        return SingleChildScrollView(
          controller: scroll,
          key: const PageStorageKey('support-scroll'),
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
                        key: const ValueKey('support-home'),
                        onPressed: widget.onHome,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('На главную'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.urgent
                          ? 'Немедленная помощь'
                          : 'Состояние и поддержка',
                      style: tx(
                        narrow ? 31 : 40,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.urgent
                          ? 'Сейчас важнее доступ к реальной помощи.'
                          : 'Можно замедлиться. Здесь не нужно ничего доказывать.',
                      style: tx(15, color: C.muted),
                    ),
                    gap,
                    if (data.urgent)
                      urgentView()
                    else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            ChoiceChip(
                              key: ValueKey('support-tab-$i'),
                              label: Text(
                                ['Сейчас', 'Поддержка', 'История'][i],
                              ),
                              selected: tab == i,
                              showCheckmark: false,
                              onSelected: (_) => showTab(i),
                            ),
                          TextButton.icon(
                            key: const ValueKey('support-urgent'),
                            onPressed: urgent,
                            icon: const Icon(
                              Icons.support_agent_rounded,
                              size: 20,
                            ),
                            label: const Text('Нужна немедленная помощь'),
                          ),
                        ],
                      ),
                      gap,
                      if (box.maxWidth >= 1000)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: mainContent()),
                            const SizedBox(width: 24),
                            SizedBox(width: 320, child: sideContent()),
                          ],
                        )
                      else ...[
                        mainContent(),
                        gap,
                        sideContent(),
                      ],
                    ],
                    gap,
                    Text(
                      'Демо · 20 октября 2026 · записи сохраняются до обновления страницы',
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

  Widget mainContent() => switch (tab) {
    1 => plan(),
    2 => history(),
    _ => now(),
  };

  Widget now() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Tag('Личная отметка', green: true),
        ),
        gap,
        Text(
          data.latestMood == null
              ? 'Как вы сейчас?'
              : 'Вы отметили: ${data.latestMood}',
          style: tx(28, weight: FontWeight.w600, height: 1.2),
        ),
        const SizedBox(height: 12),
        Text(
          data.latestMood == null
              ? 'Иногда достаточно назвать своё состояние. Вы можете добавить заметку только для себя.'
              : 'Это ваше ощущение в момент записи. Оно не превращается в диагноз или общий балл здоровья.',
          style: tx(15, color: C.muted),
        ),
        gap,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final label in SupportData.moods) Tag(label)],
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          data.latestMood == null
              ? 'Отметить состояние'
              : 'Отметить состояние снова',
          () => checkIn(again: data.latestMood != null),
          key: const ValueKey('support-check-in'),
        ),
        const SizedBox(height: 10),
        TextButton(
          key: const ValueKey('support-start'),
          onPressed: startSupport,
          child: Text(
            data.active
                ? 'Продолжить план поддержки →'
                : 'Перейти к поддержке без новой отметки →',
          ),
        ),
      ],
    ),
  );

  Widget sideContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: C.dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.spa_outlined, size: 32, color: C.lime),
            gap,
            Text(
              'Ближайшие\n10 минут — для вас',
              style: tx(
                25,
                weight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Один необязательный пункт можно отложить. Сделать паузу. Связаться с близким. Выберите то, что подходит сейчас.',
              style: tx(14, color: const Color(0xFFBDCEC5)),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, color: C.green),
            const SizedBox(height: 12),
            Text(
              'Личное остаётся личным',
              style: tx(19, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Заметки не передаются в ИИ-чат, специалистам или близким. Поддержка не заменяет профессиональную и экстренную помощь.',
              style: tx(14, color: C.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget plan() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(
            data.active
                ? 'В вашем темпе'
                : data.sessions == 0
                ? 'Можно начать с любого шага'
                : 'Пауза завершена',
            green: true,
          ),
        ),
        gap,
        Text(
          data.active || data.sessions == 0
              ? 'Поддержка на ближайшие 10 минут'
              : 'Спасибо, что уделили себе время',
          style: tx(27, weight: FontWeight.w600, height: 1.2),
        ),
        const SizedBox(height: 12),
        Text(
          'Без обязательного порядка и цели выполнить всё. Состояние после паузы может быть любым.',
          style: tx(15, color: C.muted),
        ),
        gap,
        if (!data.active) ...[
          PrimaryButton(
            data.sessions == 0 ? 'Начать поддержку' : 'Начать новую поддержку',
            startSupport,
            key: const ValueKey('support-plan-start'),
          ),
          const SizedBox(height: 12),
        ],
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              key: ValueKey('support-step-$i'),
              onPressed: !data.active || data.done.contains(i)
                  ? null
                  : [lighten, breathing, trusted][i],
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: const BorderSide(color: C.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    data.done.contains(i)
                        ? Icons.check_circle_outline
                        : [
                            Icons.remove_circle_outline,
                            Icons.air_rounded,
                            Icons.chat_bubble_outline_rounded,
                          ][i],
                    size: 24,
                    color: data.done.contains(i) ? C.green : C.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i], style: tx(16, weight: FontWeight.w500)),
                        const SizedBox(height: 5),
                        Text(
                          data.done.contains(i)
                              ? 'Отмечено вами'
                              : stepDetails[i],
                          style: tx(13, color: C.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (data.active) ...[
          gap,
          PrimaryButton(
            'Завершить поддержку',
            finish,
            key: const ValueKey('support-finish'),
          ),
        ],
        TextButton(
          onPressed: () => checkIn(again: true),
          child: const Text('Снова отметить состояние'),
        ),
      ],
    ),
  );

  Widget history() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Личная история', style: tx(26, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Ваши слова и действия. Без автоматических выводов о причинах и динамике.',
          style: tx(14, color: C.muted),
        ),
        gap,
        Text('Отметки состояния', style: tx(19, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (data.entries.isEmpty)
          Text('Отметок пока нет', style: tx(14, color: C.muted)),
        for (final entry in data.entries.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              color: C.soft,
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(entry.mood, style: tx(17, weight: FontWeight.w600)),
                  Text(
                    '${entry.context} · 20 октября',
                    style: tx(12, color: C.muted),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(entry.note, style: tx(14)),
                  ],
                ],
              ),
            ),
          ),
        gap,
        Text('Поддержка и действия', style: tx(19, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (data.events.isEmpty)
          Text('Действий пока нет', style: tx(14, color: C.muted)),
        for (final event in data.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(event, style: tx(14, color: C.muted)),
          ),
      ],
    ),
  );

  Widget urgentView() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Tag('Обычная поддержка приостановлена'),
        ),
        gap,
        Text(
          'Не оставайтесь с этим в одиночку',
          style: tx(28, weight: FontWeight.w600, height: 1.2),
        ),
        const SizedBox(height: 12),
        Text(
          'Если есть непосредственная угроза вашей жизни или безопасности, обратитесь в экстренную службу. По возможности побудьте рядом с человеком, которому доверяете.',
          style: tx(16),
        ),
        gap,
        PrimaryButton(
          'Открыть варианты немедленной помощи',
          emergencyDetails,
          key: const ValueKey('support-emergency-options'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('support-urgent-contact'),
          onPressed: () => trusted(immediate: true),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('Связаться с близким', textAlign: TextAlign.center),
          ),
        ),
        gap,
        Text(
          'MONTAS не отправляет сигнал службам и не подтверждает получение помощи. Открытие экрана не заменяет звонок.',
          style: tx(14, color: C.muted),
        ),
        gap,
        const Divider(),
        TextButton(
          key: const ValueKey('support-exit-urgent'),
          onPressed: leaveUrgent,
          child: const Text(
            'Сейчас я в безопасности — вернуться',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

class SupportPauseDialog extends StatefulWidget {
  const SupportPauseDialog({super.key});
  @override
  State<SupportPauseDialog> createState() => _SupportPauseDialogState();
}

class _SupportPauseDialogState extends State<SupportPauseDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController timer = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 3),
  );
  bool started = false;
  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(context).height - 48,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: timer,
          builder: (context, _) {
            final remainingMs = 180000 - (timer.value * 180000).round();
            final seconds = (remainingMs / 1000).ceil();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Спокойная пауза',
                        style: tx(23, weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Устройтесь удобно. Дышите в привычном, комфортном темпе. Если некомфортно, остановитесь.',
                  style: tx(15, color: C.muted),
                ),
                const SizedBox(height: 28),
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: 1 - timer.value,
                            strokeWidth: 5,
                            backgroundColor: C.line,
                            color: C.green,
                          ),
                        ),
                        Text(
                          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                          key: const ValueKey('support-timer-value'),
                          style: tx(42, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (!timer.isCompleted)
                  PrimaryButton(
                    timer.isAnimating
                        ? 'Пауза'
                        : started
                        ? 'Продолжить'
                        : 'Начать 3 минуты',
                    () => setState(() {
                      started = true;
                      if (timer.isAnimating) {
                        timer.stop();
                      } else {
                        timer.forward();
                      }
                    }),
                    key: const ValueKey('support-timer-toggle'),
                  ),
                if (timer.isCompleted)
                  PrimaryButton(
                    'Пауза завершена',
                    () => Navigator.pop(context, 'done'),
                    key: const ValueKey('support-timer-done'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закончить без отметки'),
                ),
                TextButton(
                  key: const ValueKey('support-timer-urgent'),
                  onPressed: () => Navigator.pop(context, 'urgent'),
                  child: const Text('Нужна немедленная помощь'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
