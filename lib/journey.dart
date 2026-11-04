part of 'main.dart';

enum StepStatus { ready, active, scheduled, done }

class JourneyWorkspace extends StatefulWidget {
  const JourneyWorkspace({
    this.initialPage = 0,
    this.seedDemo = false,
    super.key,
  });
  final int initialPage;
  final bool seedDemo;
  @override
  State<JourneyWorkspace> createState() => _JourneyWorkspaceState();
}

class _JourneyWorkspaceState extends State<JourneyWorkspace> {
  late int page = widget.initialPage;
  bool showDirectory = false;
  final savedSpecialists = <String>{};
  final publicProfileKey = GlobalKey<_SpecialistScreenState>();
  int selectedDay = 1, planTab = 0, minutes = 20, version = 2;
  final radar = RadarData();
  final medication = MedicationData();
  final support = SupportData();
  final sleep = SleepData();
  late final travel = TravelData(medication);
  final programsKey = GlobalKey<_RadarScreenState>();
  final askKey = GlobalKey<AskScreenState>();
  final familyKey = GlobalKey<FamilyScreenState>();
  final myDataKey = GlobalKey<MyDataScreenState>();
  final myData = MyDataStore();
  final appointments = AppointmentSchedule();
  final consiliums = ConsiliumStore();
  final library = ExpertLibrary();
  final workProfile = ExpertWorkProfile();
  WorkspaceMode workspace = WorkspaceMode.personal;
  final expertKey = GlobalKey<ExpertWorkspaceState>();
  bool get isExpert => workspace == WorkspaceMode.expert;
  void switchWorkspace(WorkspaceMode value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => workspace = value);
  }

  void personalQuestions() {
    switchWorkspace(WorkspaceMode.personal);
    askSpecialist();
  }

  void refreshConversations() {
    askKey.currentState?.refreshReplies();
    refreshRadar();
  }

  int? get energy => radar.todayEnergy;
  static const navOrder = [0, 3, 1, 4, 2];
  static const navLabels = [
    'Главная',
    'Мой план',
    'Специалисты',
    'Радар',
    'Программы',
    'Спросить',
    'Семья',
    'Лекарства',
    'Поддержка',
    'Устройства и сон',
    'Процедуры и поездки',
    'Мои данные',
    'Мероприятия',
    'Маркетплейс',
  ];
  @override
  void initState() {
    super.initState();
    radar.addListener(refreshRadar);
    medication.addListener(refreshRadar);
    support.addListener(refreshRadar);
    sleep.addListener(refreshRadar);
    travel.addListener(refreshRadar);
    myData.addListener(refreshRadar);
    appointments.addListener(refreshRadar);
    consiliums.addListener(refreshConversations);
    library.addListener(refreshRadar);
    workProfile.addListener(refreshConversations);
    if (widget.seedDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) => seedExpertDemo());
    }
  }

  void seedExpertDemo() {
    if (!mounted) return;
    library.seedDemo();
    final ask = askKey.currentState!;
    final question = QuestionTransfer([
      'Как подготовиться к консультации по режиму сна и самочувствию?',
      'Какие наблюдения записать перед встречей?',
    ], 7)..inProgress = true;
    ask.transfers.add(question);
    ask.saved = List.of(question.questions);
    ask.editing = false;
    ask.history.add('Тестовый набор: вопросы переданы Анне Волковой');
    for (var i = 0; i < ask.questions.length; i++) {
      ask.questions[i].text = i < question.questions.length
          ? question.questions[i]
          : '';
    }
    myData.grant(
      myData.documents.firstWhere((d) => d.demo),
      'Анна Волкова',
      'Подготовка к консультации · демо',
      7,
      recipientId: 'expert-anna',
    );
    appointments.change(
      null,
      const Appointment(1, '18:30', true),
      actor: 'Тестовый набор',
    );
    final c = consiliums.create(question)!;
    consiliums.setConsent(c, CaseConsent.approved);
    consiliums.opinion(
      c,
      1,
      OpinionStance.support,
      'Предлагаю перед встречей собрать вопросы о привычном режиме сна. Это пример обсуждения, без назначений.',
    );
    expertKey.currentState?.patientNote =
        'Демо: на встрече уточнить ожидания пациента и обсудить подготовленные вопросы.';
    refreshConversations();
  }

  void refreshRadar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    workProfile.removeListener(refreshConversations);
    workProfile.dispose();
    library.removeListener(refreshRadar);
    library.dispose();
    consiliums.removeListener(refreshConversations);
    consiliums.dispose();
    appointments.removeListener(refreshRadar);
    appointments.dispose();
    myData.removeListener(refreshRadar);
    myData.dispose();
    radar.removeListener(refreshRadar);
    radar.dispose();
    travel.removeListener(refreshRadar);
    travel.dispose();
    medication.removeListener(refreshRadar);
    medication.dispose();
    support.removeListener(refreshRadar);
    support.dispose();
    sleep.removeListener(refreshRadar);
    sleep.dispose();
    super.dispose();
  }

  bool paused = false, recovered = false;
  String scheduledFor = 'Сегодня · после обеда';
  StepStatus status = StepStatus.ready;
  Appointment? get appointment => appointments.current;
  final history = <String>[
    'Версия 2 · 19 октября\nПрогулка перенесена на дневное время. Нагрузка снижена до 20 минут.',
    'Версия 1 · 12 октября\nВыбрана цель «Больше энергии». Начали наблюдать за самочувствием.',
  ];
  String get stepTitle => '$minutes минут спокойной прогулки';
  String get statusText => paused
      ? 'План на паузе'
      : switch (status) {
          StepStatus.ready => 'Можно начать',
          StepStatus.active => 'Прогулка начата',
          StepStatus.scheduled => 'Шаг перенесён',
          StepStatus.done => 'Шаг выполнен',
        };
  void navigate(int value) => setState(() {
    page = value;
    if (value == 2) showDirectory = false;
  });
  void navigateSection(int value) => setState(() {
    page = value;
    if (value == 2) showDirectory = true;
  });
  void saveSpecialist(String id, bool saved) => setState(() {
    if (saved) {
      savedSpecialists.add(id);
    } else {
      savedSpecialists.remove(id);
    }
  });
  void askSpecialist() {
    navigate(5);
    askKey.currentState?.openSpecialist();
  }

  Future<T?> dialog<T>(
    String title,
    Widget Function(BuildContext) content,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(ctx).height - 60,
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
              const SizedBox(height: 16),
              content(ctx),
            ],
          ),
        ),
      ),
    ),
  );

  void info(String title, String body) => dialog<void>(
    title,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(body, style: tx(15, color: C.muted)),
        const SizedBox(height: 24),
        PrimaryButton('Понятно', () => Navigator.pop(ctx)),
      ],
    ),
  );

  Future<void> startStep() async {
    if (paused) {
      await togglePause();
      return;
    }
    if (status == StepStatus.done) {
      await checkIn();
      return;
    }
    if (status == StepStatus.active) {
      await completeStep();
      return;
    }
    final accepted = await dialog<bool>(
      'Небольшая пауза для себя',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.directions_walk_rounded, size: 58, color: C.green),
          const SizedBox(height: 16),
          Text(stepTitle, style: tx(21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Выберите знакомый маршрут и комфортный темп. Здесь вы сможете отметить завершение, когда вернётесь.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Начать шаг',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('start-step'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        status = StepStatus.active;
        scheduledFor = 'Сегодня · в процессе';
        selectedDay = 1;
      });
    }
  }

  Future<void> completeStep() async {
    final accepted = await dialog<bool>(
      'Завершить прогулку?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Отметим сегодняшний шаг выполненным. Позже можно записать, как изменилось самочувствие.',
            style: tx(15, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Да, шаг выполнен',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('complete-step'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        status = StepStatus.done;
        selectedDay = 1;
        scheduledFor = 'Сегодня · выполнено';
      });
    }
  }

  Future<void> checkIn() async {
    int rating = energy ?? 5;
    final result = await dialog<int>(
      'Как вы себя чувствуете?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Оцените энергию сейчас. Это ваша личная отметка, а не медицинская оценка.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: List.generate(
                11,
                (i) => ChoiceChip(
                  label: Text('$i'),
                  selected: rating == i,
                  showCheckmark: false,
                  onSelected: (_) => update(() => rating = i),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Мало сил', style: tx(12, color: C.muted)),
                Text('Много энергии', style: tx(12, color: C.muted)),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              'Сохранить самочувствие',
              () => Navigator.pop(ctx, rating),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) radar.record(0, result);
  }

  Future<void> reschedule() async {
    String choice = 'Сегодня · 18:00';
    final result = await dialog<String>(
      'Когда будет удобнее?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Перенос — часть плана. Выберите время для этого шага.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 16),
            for (final option in [
              'Сегодня · 18:00',
              'Завтра · 09:00',
              'Завтра · 13:00',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity, child: Text(option)),
                  selected: choice == option,
                  onSelected: (_) => update(() => choice = option),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Подтвердить перенос',
              () => Navigator.pop(ctx, choice),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        scheduledFor = result;
        status = StepStatus.scheduled;
        selectedDay = result.startsWith('Завтра') ? 2 : 1;
      });
    }
  }

  Future<void> adapt({bool afterMiss = false}) async {
    String reason = afterMiss
        ? 'Возвращаюсь после пропуска'
        : 'Сегодня мало сил';
    final result = await dialog<String>(
      afterMiss ? 'Вернёмся в комфортном темпе' : 'Подстроим шаг под ваш день',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              afterMiss
                  ? 'Вчера не получилось — ничего догонять не нужно. Цель и история останутся с вами.'
                  : 'Что мешает сегодня? Изменения применятся только после вашего подтверждения.',
              style: tx(14, color: C.muted),
            ),
            if (!afterMiss) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final r in ['Сегодня мало сил', 'Мало времени'])
                    ChoiceChip(
                      label: Text(r),
                      selected: reason == r,
                      onSelected: (_) => update(() => reason = r),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Surface(
              color: const Color(0xFFEAFBD9),
              padding: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ПРЕДЛОЖЕНИЕ',
                    style: tx(10, color: C.green, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10 минут прогулки сегодня',
                    style: tx(20, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Меньше нагрузка · та же цель',
                    style: tx(13, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              'Принять облегчённый шаг',
              () => Navigator.pop(ctx, reason),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        minutes = 10;
        version++;
        recovered = true;
        status = StepStatus.ready;
        scheduledFor = 'Сегодня · в удобное время';
        selectedDay = 1;
        history.insert(
          0,
          'Версия $version · 20 октября\n$result. Вы выбрали 10 минут прогулки. Цель сохранена.',
        );
      });
    }
  }

  Future<void> togglePause() async {
    final result = await dialog<bool>(
      paused ? 'Продолжить план?' : 'Поставить план на паузу?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            paused
                ? 'Вернёмся к текущему шагу. Его состояние и предыдущие отметки сохранены.'
                : 'Текущий шаг и история сохранятся. Продолжить можно в любой момент.',
            style: tx(15, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            paused ? 'Продолжить план' : 'Подтвердить паузу',
            () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result == true && mounted) setState(() => paused = !paused);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile = box.maxWidth < 1050;
      final topSections = [
        ...navOrder,
        if (box.maxWidth >= 1300) ...[12, 13],
        5,
        6,
        if (box.maxWidth >= 2100) ...[7, 8, 9, 10, 11],
      ];
      final moreSections = [
        for (var i = 0; i < navLabels.length; i++)
          if (!topSections.contains(i)) i,
      ];
      return Scaffold(
        bottomNavigationBar: !isExpert && mobile && page < 5
            ? NavigationBar(
                selectedIndex: navOrder.indexOf(page),
                onDestinationSelected: (i) => navigateSection(navOrder[i]),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFEAFBD9),
                destinations: [
                  for (final i in navOrder)
                    NavigationDestination(
                      key: ValueKey('mobile-nav-$i'),
                      icon: Icon(
                        [
                          Icons.home_outlined,
                          Icons.route_outlined,
                          Icons.person_outline_rounded,
                          Icons.radar_rounded,
                          Icons.view_agenda_outlined,
                        ][i],
                      ),
                      label: i == 2 ? 'Врачи' : navLabels[i],
                    ),
                ],
              )
            : null,
        body: Column(
          children: [
            WorkspaceHeader(
              mode: workspace,
              onChanged: switchWorkspace,
              onHome: () {
                if (isExpert) {
                  expertKey.currentState?.openToday();
                } else {
                  navigate(0);
                }
              },
            ),
            if (!isExpert)
              Container(
                height: 58,
                padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: C.line)),
                ),
                child: Row(
                  children: [
                    if (mobile)
                      Expanded(
                        child: Text(
                          navLabels[page],
                          overflow: TextOverflow.ellipsis,
                          style: tx(14, weight: FontWeight.w600),
                        ),
                      )
                    else
                      const Spacer(),
                    if (!mobile) ...[
                      for (final i in topSections)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TextButton(
                            key: ValueKey('nav-$i'),
                            onPressed: () => navigateSection(i),
                            style: TextButton.styleFrom(
                              backgroundColor: page == i
                                  ? C.soft
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 18,
                              ),
                            ),
                            child: Text(navLabels[i]),
                          ),
                        ),
                      if (moreSections.isNotEmpty)
                        PopupMenuButton<int>(
                          tooltip: 'Другие разделы',
                          onSelected: navigateSection,
                          itemBuilder: (_) => [
                            for (final i in moreSections)
                              PopupMenuItem(
                                value: i,
                                child: Text(navLabels[i]),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              moreSections.contains(page)
                                  ? (page == 9
                                        ? 'Сон'
                                        : page == 10
                                        ? 'Поездки'
                                        : navLabels[page])
                                  : 'Ещё',
                              style: tx(14),
                            ),
                          ),
                        ),
                      const Spacer(),
                    ],
                    if (mobile)
                      IconButton(
                        key: const ValueKey('mobile-nav-6'),
                        onPressed: () => navigate(6),
                        icon: const Icon(Icons.people_outline, size: 20),
                        tooltip: 'Семья',
                      ),
                    if (mobile)
                      IconButton(
                        key: const ValueKey('mobile-nav-5'),
                        tooltip: page == 5 ? 'На главную' : 'Спросить MONTAS',
                        onPressed: () => navigate(page == 5 ? 0 : 5),
                        icon: Icon(
                          page == 5 ? Icons.close : Icons.forum_outlined,
                        ),
                      ),
                    if (mobile)
                      PopupMenuButton<int>(
                        tooltip: 'Все разделы',
                        onSelected: navigateSection,
                        icon: const Icon(Icons.menu_rounded),
                        itemBuilder: (_) => [
                          for (var i = 0; i < navLabels.length; i++)
                            PopupMenuItem(value: i, child: Text(navLabels[i])),
                        ],
                      ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: isExpert ? 14 : page,
                children: [
                  dashboard(false),
                  dashboard(true),
                  IndexedStack(
                    index: showDirectory ? 1 : 0,
                    children: [
                      SpecialistScreen(
                        key: publicProfileKey,
                        workProfile: workProfile,
                        embedded: true,
                        schedule: appointments,
                        onAsk: askSpecialist,
                        onDirectory: () => navigateSection(2),
                        isFavorite: savedSpecialists.contains('anna'),
                        onFavoriteChanged: (value) =>
                            saveSpecialist('anna', value),
                      ),
                      SpecialistsDirectory(
                        profile: workProfile,
                        schedule: appointments,
                        favorites: savedSpecialists,
                        onFavorite: saveSpecialist,
                        onOpenAnna: (online) {
                          navigate(2);
                          if (online != null) {
                            publicProfileKey.currentState?.selectFormat(online);
                          }
                        },
                      ),
                    ],
                  ),
                  radarScreen(false),
                  radarScreen(true),
                  AskScreen(
                    key: askKey,
                    workProfile: workProfile,
                    consiliums: consiliums,
                    energy: radar.latest(0)!.value,
                    energyDay: radar.latest(0)!.day,
                    planStatus: statusText,
                    appointment: appointment,
                    onPlan: () => navigate(1),
                    onRadar: () => navigate(3),
                    onSpecialist: () => navigate(2),
                    onData: () {
                      navigate(11);
                      myDataKey.currentState?.openTab(0);
                    },
                    onConversationChanged: refreshRadar,
                  ),
                  FamilyScreen(key: familyKey),
                  MedicationScreen(data: medication, onPlan: () => navigate(1)),
                  SupportScreen(data: support, onHome: () => navigate(0)),
                  SleepScreen(
                    data: sleep,
                    radar: radar,
                    onRadar: () => navigate(3),
                    onProgram: () {
                      navigate(4);
                      programsKey.currentState?.openProgram(1);
                    },
                  ),
                  TravelScreen(
                    data: travel,
                    onPlan: () => navigate(1),
                    onAsk: askSpecialist,
                    onMedication: () => navigate(7),
                  ),
                  MyDataScreen(
                    key: myDataKey,
                    data: myData,
                    people: () => familyKey.currentState?.people ?? [],
                    transfers: () => askKey.currentState?.transfers ?? [],
                    onFamily: (person) {
                      navigate(6);
                      familyKey.currentState?.openAccess(person);
                    },
                    onQuestions: askSpecialist,
                  ),
                  const EventsScreen(),
                  const MarketplaceScreen(),
                  ExpertWorkspace(
                    key: expertKey,
                    workProfile: workProfile,
                    library: library,
                    onPersonalPrograms: () {
                      switchWorkspace(WorkspaceMode.personal);
                      navigate(4);
                      programsKey.currentState?.openLibrary();
                    },
                    consiliums: consiliums,
                    schedule: appointments,
                    onPersonalBooking: () {
                      switchWorkspace(WorkspaceMode.personal);
                      navigate(2);
                    },
                    transfers: () => askKey.currentState?.transfers ?? [],
                    data: myData,
                    onChanged: refreshConversations,
                    onPersonalQuestions: personalQuestions,
                    onPersonalData: () {
                      switchWorkspace(WorkspaceMode.personal);
                      navigate(11);
                      myDataKey.currentState?.openTab(0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget radarScreen(bool programs) => RadarScreen(
    key: programs ? programsKey : const ValueKey('radar-screen'),
    data: radar,
    programs: programs,
    expertLibrary: library,
    walkDone: status == StepStatus.done,
    recoveryPaused: paused,
    onPlan: () => navigate(1),
    onSpecialist: () => navigate(2),
    onPauseRecovery: togglePause,
    onSupport: () => navigate(8),
    supportUrgent: support.urgent,
    onSleep: () => navigate(9),
  );

  Widget dashboard(bool plan) => LayoutBuilder(
    builder: (context, box) {
      if (support.urgent) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SupportPriorityPanel(onOpen: () => navigate(8)),
            ),
          ),
        );
      }
      final narrow = box.maxWidth < 700;
      final wide = box.maxWidth >= 1000;
      final mainColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: plan
            ? [
                planHero(),
                const SizedBox(height: 24),
                week(),
                const SizedBox(height: 24),
                if (planTab == 0) actionCard() else historyCard(),
                const SizedBox(height: 24),
                MedicationSummary(data: medication, onOpen: () => navigate(7)),
                const SizedBox(height: 24),
                SupportSummary(data: support, onOpen: () => navigate(8)),
                const SizedBox(height: 24),
                SleepSummary(data: sleep, onOpen: () => navigate(9)),
                const SizedBox(height: 24),
                TravelSummary(data: travel, onOpen: () => navigate(10)),
              ]
            : [
                welcome(narrow),
                const SizedBox(height: 24),
                actionCard(),
                const SizedBox(height: 24),
                MedicationSummary(data: medication, onOpen: () => navigate(7)),
                const SizedBox(height: 24),
                SupportSummary(data: support, onOpen: () => navigate(8)),
                const SizedBox(height: 24),
                SleepSummary(data: sleep, onOpen: () => navigate(9)),
                const SizedBox(height: 24),
                TravelSummary(data: travel, onOpen: () => navigate(10)),
                const SizedBox(height: 24),
                recoveryCard(),
              ],
      );
      final sideColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyDataSummary(data: myData, onOpen: () => navigate(11)),
          const SizedBox(height: 20),
          if (!plan) ...[
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Радар здоровья',
                    style: tx(21, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Энергия · ${radar.latest(0)!.value} / 10',
                    style: tx(17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${radar.coverage} из 6 областей с наблюдениями',
                    style: tx(13, color: C.muted),
                  ),
                  TextButton(
                    onPressed: () => navigate(3),
                    child: const Text('Посмотреть показатели →'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            progressCard(),
            const SizedBox(height: 20),
          ],
          wellbeingCard(),
          const SizedBox(height: 20),
          doctorCard(),
          if (plan) ...[
            const SizedBox(height: 20),
            Surface(
              color: C.dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: C.lime),
                  const SizedBox(height: 14),
                  Text(
                    'В вашем ритме',
                    style: tx(21, weight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'План учитывает ваш день. Пропуск можно оставить в прошлом и продолжить с посильного шага.',
                    style: tx(14, color: const Color(0xFFBDCEC5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
      return SingleChildScrollView(
        key: PageStorageKey(plan ? 'plan-scroll' : 'home-scroll'),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                narrow ? 18 : 36,
                narrow ? 24 : 32,
                narrow ? 18 : 36,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        plan
                            ? 'МОЙ ПЛАН / ВОССТАНОВЛЕНИЕ'
                            : 'ВТОРНИК, 20 ОКТЯБРЯ',
                        style: tx(11, color: C.muted, weight: FontWeight.w500),
                      ),
                      const Tag('Неделя 2 из 8', green: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (plan) ...[
                    Text(
                      'План восстановления',
                      style: tx(
                        narrow ? 30 : 38,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Маленькие действия. Больше внимания к себе.',
                      style: tx(15, color: C.muted),
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainColumn),
                        const SizedBox(width: 26),
                        SizedBox(width: 330, child: sideColumn),
                      ],
                    )
                  else ...[
                    mainColumn,
                    const SizedBox(height: 24),
                    sideColumn,
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Демо-сценарий · 20 октября 2026 · данные для тестирования интерфейса',
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

  Widget welcome(bool narrow) => Container(
    padding: EdgeInsets.all(narrow ? 24 : 32),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFFE9F5DD), Color(0xFFD3EADC)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 21, color: C.green),
            const SizedBox(width: 8),
            Text('Добрый день!', style: tx(14, weight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Больше энергии.\nВ вашем ритме.',
          style: tx(narrow ? 32 : 44, weight: FontWeight.w600, height: 1.12),
        ),
        const SizedBox(height: 18),
        Text(
          'Сегодня достаточно одного посильного шага.\nНачнём с небольшой прогулки?',
          style: tx(15, color: C.muted),
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Tag('✓ Контекст учтён'),
            Tag('● Ежедневная активность'),
          ],
        ),
      ],
    ),
  );

  Widget actionCard() {
    final done = status == StepStatus.done;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: C.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ВАШ ШАГ',
                  style: tx(11, weight: FontWeight.w600, color: C.muted),
                ),
              ),
              Tag(statusText, green: !paused),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            done ? 'Вы сделали шаг к своей цели' : stepTitle,
            style: tx(26, weight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            done
                ? 'Теперь можно отдохнуть. Отметьте самочувствие через 60–90 минут, когда будете готовы.'
                : 'Спокойный темп и знакомый маршрут. Если день тяжёлый — шаг можно сделать короче.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag('≈ $minutes мин'),
              const Tag('Низкая нагрузка'),
              Tag(scheduledFor),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            paused
                ? 'Продолжить план'
                : done
                ? (energy == null
                      ? 'Отметить самочувствие'
                      : 'Обновить самочувствие')
                : status == StepStatus.active
                ? 'Завершить прогулку'
                : 'Начать прогулку',
            startStep,
            key: ValueKey(page == 0 ? 'home-action' : 'plan-action'),
          ),
          if (!paused && !done) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              children: [
                TextButton(
                  onPressed: reschedule,
                  child: const Text('Перенести'),
                ),
                TextButton(
                  onPressed: () => adapt(),
                  child: const Text('Не подходит'),
                ),
              ],
            ),
          ],
          const Divider(height: 28),
          InkWell(
            onTap: () => info(
              'Почему этот шаг',
              'В демонстрационном плане энергия снижается к вечеру. Поэтому прогулка запланирована на день, с невысокой нагрузкой. Проверка самочувствия поможет обсудить следующий шаг.',
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: C.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Почему этот шаг',
                      style: tx(13, color: C.muted),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: C.muted, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget recoveryCard() => Surface(
    color: C.dark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          recovered ? Icons.check_circle_outline : Icons.spa_outlined,
          color: C.lime,
          size: 28,
        ),
        const SizedBox(height: 14),
        Text(
          recovered
              ? 'Вы вернулись к своему ритму'
              : 'Вчера не получилось? Всё в порядке.',
          style: tx(22, weight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          recovered
              ? 'Облегчённый шаг уже в плане. История сохранена, цель остаётся прежней.'
              : 'Ничего догонять не нужно. Можно продолжить с 10 минут прогулки сегодня.',
          style: tx(14, color: const Color(0xFFBDCEC5)),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () {
            if (recovered || status == StepStatus.done) {
              navigate(1);
            } else {
              adapt(afterMiss: true);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: C.lime,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            recovered || status == StepStatus.done
                ? 'Посмотреть мой план →'
                : 'Вернуться мягко →',
          ),
        ),
      ],
    ),
  );

  Widget progressCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Ваш путь', style: tx(21, weight: FontWeight.w600)),
            ),
            const Icon(Icons.route_outlined, color: C.green),
          ],
        ),
        const SizedBox(height: 22),
        Text('Больше энергии', style: tx(17, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(
          'Неделя 2 из 8 · ежедневная активность',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const LinearProgressIndicator(
            value: 2 / 8,
            minHeight: 7,
            color: C.green,
            backgroundColor: C.soft,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          status == StepStatus.done
              ? 'Сегодняшний шаг выполнен ✓'
              : 'Следующая проверка — через 5 дней',
          style: tx(13),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => navigate(1),
          child: const Text('Открыть план'),
        ),
      ],
    ),
  );

  Widget wellbeingCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_outlined, color: C.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Как вы сегодня?',
                style: tx(20, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          energy == null
              ? 'Прислушайтесь к себе'
              : '$energy из 10 · ваша энергия',
          style: tx(18, weight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          energy == null
              ? 'Короткая отметка поможет сохранить картину дня.'
              : 'Отметка сохранена на сегодня. Вы можете изменить её.',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: checkIn,
          child: Text(
            energy == null ? 'Отметить состояние →' : 'Изменить отметку →',
          ),
        ),
      ],
    ),
  );

  Widget doctorCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          appointment == null
              ? 'Рядом, когда нужна помощь'
              : 'Ваша ближайшая запись',
          style: tx(17, weight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        DoctorMini(details: workProfile.published),
        const SizedBox(height: 16),
        Text(
          appointment == null
              ? 'Разберите вопросы о самочувствии вместе со специалистом.'
              : '${appointment!.date} · ${appointment!.time}\n${appointment!.format} · 45 минут',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => navigate(2),
          child: Text(
            appointment == null ? 'Открыть профиль' : 'Открыть запись',
          ),
        ),
        TextButton(
          key: ValueKey('ask-from-${page == 1 ? 'plan' : 'home'}'),
          onPressed: askSpecialist,
          child: const Text('Задать вопрос специалисту →'),
        ),
      ],
    ),
  );

  Widget planHero() => Surface(
    color: C.dark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            Tag(paused ? 'На паузе' : 'Активный план', green: true),
            Tag('Версия $version'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Цель — больше энергии',
          style: tx(
            28,
            weight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Сейчас фокус на ежедневной активности. Проверим самочувствие и обсудим, что подходит именно вам.',
          style: tx(14, color: const Color(0xFFBDCEC5)),
        ),
        const SizedBox(height: 24),
        const JourneyStages(),
        const SizedBox(height: 18),
        TextButton(
          onPressed: togglePause,
          style: TextButton.styleFrom(
            foregroundColor: C.lime,
            padding: EdgeInsets.zero,
          ),
          child: Text(paused ? 'Продолжить план →' : 'Поставить на паузу'),
        ),
      ],
    ),
  );

  Widget week() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 10,
          runSpacing: 8,
          children: [
            Text('19–25 октября', style: tx(20, weight: FontWeight.w600)),
            Text('Текущая неделя', style: tx(12, color: C.muted)),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) => Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    button: true,
                    selected: selectedDay == i,
                    label: '${19 + i} октября',
                    child: InkWell(
                      key: ValueKey('week-$i'),
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => setState(() => selectedDay = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: selectedDay == i ? C.dark : C.soft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i],
                              style: tx(
                                10,
                                color: selectedDay == i
                                    ? Colors.white70
                                    : C.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${19 + i}',
                              style: tx(
                                box.maxWidth < 300 ? 15 : 18,
                                weight: FontWeight.w600,
                                color: selectedDay == i ? Colors.white : C.ink,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Icon(
                              i == 0
                                  ? Icons.remove_rounded
                                  : i == 1 && status == StepStatus.done
                                  ? Icons.check_circle_rounded
                                  : Icons.circle,
                              size: i == 1 && status == StepStatus.done
                                  ? 12
                                  : 6,
                              color: selectedDay == i ? C.lime : C.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (selectedDay != 1) ...[
          Text(
            selectedDay == 0
                ? 'Понедельник · шаг пропущен'
                : '${19 + selectedDay} октября · ${selectedDay == 6 ? "проверка недели" : "спокойная прогулка"}',
            style: tx(15, weight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            selectedDay == 0
                ? 'История сохранена. Продолжайте в удобном темпе.'
                : (status == StepStatus.scheduled &&
                      selectedDay == 2 &&
                      scheduledFor.startsWith('Завтра'))
                ? 'Сюда перенесён ваш шаг: $scheduledFor. Дополнительной прогулки нет.'
                : 'Плановый шаг. Уточним нагрузку по самочувствию в этот день.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => selectedDay = 1),
            child: const Text('Вернуться к сегодняшнему шагу'),
          ),
          const Divider(),
        ],
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => planTab = 0),
                style: TextButton.styleFrom(
                  backgroundColor: planTab == 0 ? C.soft : null,
                ),
                child: const Text('Сегодня'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => planTab = 1),
                style: TextButton.styleFrom(
                  backgroundColor: planTab == 1 ? C.soft : null,
                ),
                child: const Text('История плана'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget historyCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Как менялся ваш план', style: tx(24, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Изменения сохраняют цель и предыдущие шаги.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        for (final item in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: C.green,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item, style: tx(14))),
              ],
            ),
          ),
      ],
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {this.green = false, super.key});
  final String text;
  final bool green;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: green ? const Color(0xFFEAFBD9) : C.soft,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: tx(11, color: green ? C.green : C.muted, weight: FontWeight.w500),
    ),
  );
}

class JourneyStages extends StatelessWidget {
  const JourneyStages({super.key});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < 3; i++)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    i == 0
                        ? Icons.check_circle
                        : i == 1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: i < 2 ? C.lime : Colors.white38,
                    size: 20,
                  ),
                  if (i < 2)
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ['Контекст', 'Действие', 'Эффект'][i],
                style: tx(12, color: i == 1 ? Colors.white : Colors.white60),
              ),
              const SizedBox(height: 4),
              Text(
                ['Учтён', 'Сегодня', 'Через 5 дней'][i],
                style: tx(10, color: Colors.white54),
              ),
            ],
          ),
        ),
    ],
  );
}
