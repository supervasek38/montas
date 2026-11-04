part of 'main.dart';

enum WorkspaceMode { personal, expert }

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    required this.mode,
    required this.onChanged,
    required this.onHome,
    super.key,
  });
  final WorkspaceMode mode;
  final ValueChanged<WorkspaceMode> onChanged;
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 650;
      return Container(
        height: 76,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: C.line)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onHome,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: C.dark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: C.lime, size: 23),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Text('MONTAS', style: tx(20, weight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<WorkspaceMode>(
                  key: const ValueKey('workspace-switcher'),
                  tooltip: 'Сменить рабочую среду',
                  initialValue: mode,
                  onSelected: onChanged,
                  itemBuilder: (_) => [
                    const PopupMenuItem<WorkspaceMode>(
                      enabled: false,
                      child: Text('ДЕМО · РАБОЧАЯ СРЕДА'),
                    ),
                    for (final entry in [
                      (
                        WorkspaceMode.personal,
                        'Личный кабинет',
                        Icons.person_outline,
                      ),
                      (
                        WorkspaceMode.expert,
                        'Кабинет специалиста',
                        Icons.medical_services_outlined,
                      ),
                    ])
                      PopupMenuItem(
                        value: entry.$1,
                        key: ValueKey('workspace-${entry.$1.name}'),
                        child: Row(
                          children: [
                            Icon(entry.$3, size: 20, color: C.green),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.$2)),
                            if (mode == entry.$1)
                              const Icon(Icons.check, size: 18, color: C.green),
                          ],
                        ),
                      ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: C.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'РАБОЧАЯ СРЕДА · ДЕМО',
                                style: tx(
                                  9,
                                  color: C.muted,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                mode == WorkspaceMode.personal
                                    ? 'Личный кабинет'
                                    : 'Кабинет специалиста',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tx(
                                  compact ? 13 : 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!compact) ...[
              Text(
                mode == WorkspaceMode.expert
                    ? 'Анна Волкова · специалист'
                    : 'Ваше личное пространство',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(width: 16),
              const Tag('Демо-сессия'),
            ],
          ],
        ),
      );
    },
  );
}

class ExpertWorkspace extends StatefulWidget {
  const ExpertWorkspace({
    required this.transfers,
    required this.data,
    required this.onChanged,
    required this.onPersonalQuestions,
    required this.onPersonalData,
    required this.schedule,
    required this.onPersonalBooking,
    required this.consiliums,
    required this.library,
    required this.onPersonalPrograms,
    required this.workProfile,
    super.key,
  });
  final List<QuestionTransfer> Function() transfers;
  final MyDataStore data;
  final AppointmentSchedule schedule;
  final ConsiliumStore consiliums;
  final ExpertLibrary library;
  final ExpertWorkProfile workProfile;
  final VoidCallback onPersonalPrograms;
  final VoidCallback onPersonalBooking;
  final VoidCallback onChanged, onPersonalQuestions, onPersonalData;
  @override
  State<ExpertWorkspace> createState() => ExpertWorkspaceState();
}

class ExpertWorkspaceState extends State<ExpertWorkspace> {
  static const labels = [
    'Сегодня',
    'Запросы',
    'Доступные документы',
    'Пациенты',
    'Расписание',
    'Консилиумы',
    'Программы',
    'Контент',
    'Аналитика',
    'Рабочий профиль',
  ];
  static const icons = [
    Icons.today_outlined,
    Icons.forum_outlined,
    Icons.folder_open_outlined,
    Icons.people_outline,
    Icons.calendar_month_outlined,
    Icons.groups_outlined,
    Icons.route_outlined,
    Icons.auto_stories_outlined,
    Icons.bar_chart_outlined,
    Icons.badge_outlined,
  ];
  int section = 0;
  String filter = 'Все';
  QuestionTransfer? selected;
  final scroll = ScrollController();
  final drafts = <QuestionTransfer, TextEditingController>{};
  final patientSearch = TextEditingController();
  final patientNoteDraft = TextEditingController();
  String patientFilter = 'Все', patientNote = '';
  bool patientOpen = false, fromPatient = false;
  int patientTab = 0;
  int scheduleDay = 1, scheduleTab = 0;
  bool scheduleOnline = true;
  final scheduleCancelReason = TextEditingController();
  ConsiliumCase? selectedCase;
  final caseDrafts = <ConsiliumCase, TextEditingController>{};
  LibraryItem? selectedProgram, selectedContent;
  final librarySearch = [TextEditingController(), TextEditingController()];
  final libraryFilters = ['Все', 'Все'];
  int analyticsTab = 0, workProfileTab = 0;
  void updatePatients(VoidCallback change) => setState(change);
  List<QuestionTransfer> get requests => widget.transfers();
  List<QuestionTransfer> get pending =>
      requests.where((q) => !q.revoked && q.specialistReply == null).toList();
  List<DocumentGrant> get allowed => widget.data.grants
      .where((g) => g.recipientId == 'expert-anna' && !g.revoked)
      .toList();
  List<DataDocument> get documents => widget.data.documents
      .where((d) => allowed.any((g) => g.documentId == d.id))
      .toList();
  bool canRead(DataDocument document) =>
      allowed.any((g) => g.documentId == document.id);
  String number(QuestionTransfer q) => '${requests.indexOf(q) + 1}';
  String status(QuestionTransfer q) => q.revoked
      ? 'Доступ отозван'
      : q.specialistReply != null
      ? 'Ответ добавлен'
      : q.inProgress
      ? 'В работе'
      : 'Новое';
  @override
  void dispose() {
    for (final controller in drafts.values) {
      controller.dispose();
    }
    scroll.dispose();
    patientSearch.dispose();
    patientNoteDraft.dispose();
    scheduleCancelReason.dispose();
    for (final input in librarySearch) {
      input.dispose();
    }
    for (final draft in caseDrafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void openToday() => navigate(0);
  void navigate(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      section = value;
      fromPatient = false;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void openRequest(QuestionTransfer value, {bool viaPatient = false}) {
    setState(() {
      section = 1;
      selected = value;
      filter = 'Все';
      fromPatient = viaPatient;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void notify(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<T?> modal<T>(
    String title,
    Widget Function(BuildContext) body,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
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
              const SizedBox(height: 18),
              body(ctx),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> reviewReply(QuestionTransfer request) async {
    if (request.revoked || request.specialistReply != null) return;
    final text = request.replyDraft.trim();
    if (text.isEmpty || text.length > 3000) {
      notify('Напишите ответ: от 1 до 3000 символов.');
      return;
    }
    final accepted = await modal<bool>(
      'Проверить ответ',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Кому: пользователь демо-кабинета\nОбращение №${number(request)}\nОт: Анна Волкова',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          Surface(
            color: C.soft,
            padding: 18,
            child: Text(text, style: tx(15)),
          ),
          const SizedBox(height: 18),
          Text(
            'Ответ появится в личном кабинете → «Спросить». Это локальная демонстрация, без отправки реальным людям. План пользователя автоматически не изменится.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Добавить ответ пользователю',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('expert-confirm-reply'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Вернуться к черновику'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    // Re-check the same request after review; a revoked or answered request cannot be changed.
    if (!requests.contains(request) || !request.publishReply(text)) {
      setState(() {});
      notify(
        'Ответ не добавлен: доступ закрыт или обращение уже обработано. Черновик сохранён.',
      );
      return;
    }
    drafts[request]?.clear();
    widget.onChanged();
    setState(() {});
    notify('Ответ доступен в личном кабинете · демо');
  }

  Future<void> viewDocument(DataDocument document) async {
    if (!canRead(document)) {
      notify('Доступ к документу закрыт.');
      return;
    }
    await modal<void>(
      'Документ пользователя',
      (ctx) => ListenableBuilder(
        listenable: widget.data,
        builder: (_, _) {
          if (!canRead(document)) {
            return Text(
              'Доступ отозван. Содержимое больше недоступно.',
              style: tx(16),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(document.file.name, style: tx(18, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '${document.category} · только просмотр',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 18),
              if (document.file.mime == 'text/plain')
                Surface(
                  color: C.soft,
                  padding: 18,
                  child: SelectableText(
                    previewText(document.file),
                    style: tx(14),
                  ),
                )
              else if (document.file.mime.startsWith('image/'))
                Image.memory(
                  document.file.bytes,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Text('Предпросмотр изображения недоступен.'),
                )
              else
                OutlinedButton(
                  onPressed: () {
                    if (!canRead(document)) {
                      Navigator.pop(ctx);
                      return;
                    }
                    try {
                      file_bridge.preview(document.file);
                    } catch (_) {
                      notify('Не удалось открыть PDF в браузере.');
                    }
                  },
                  child: const Text('Открыть PDF в браузере'),
                ),
              const SizedBox(height: 16),
              Text(
                'Разрешение относится только к этому файлу. Личные заметки и другие документы сюда не передаются.',
                style: tx(12, color: C.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  String previewText(LocalFile file) {
    final text = utf8.decode(file.bytes, allowMalformed: true);
    return text.length > 20000
        ? '${text.substring(0, 20000)}\n\nПоказаны первые 20 000 символов.'
        : text;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.data,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final mobile = box.maxWidth < 800;
        final wide = box.maxWidth >= 1200;
        final main = section == 0
            ? today()
            : section == 1
            ? requestPanel()
            : section == 2
            ? documentsPanel()
            : section == 3
            ? patientsPanel()
            : section == 4
            ? schedulePanel()
            : section == 5
            ? consiliumPanel()
            : section < 8
            ? libraryPanel(section == 6)
            : section == 8
            ? analyticsPanel()
            : workProfilePanel();
        final work = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            main,
            if (!wide) ...[const SizedBox(height: 20), contextPanel()],
          ],
        );
        return SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.all(mobile ? 18 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Tag('КАБИНЕТ СПЕЦИАЛИСТА', green: true),
                      Text(
                        '20 октября 2026 · демо',
                        style: tx(12, color: C.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    section == 0
                        ? 'Сегодня, Анна'
                        : section == 3 && patientOpen
                        ? 'Карточка пациента'
                        : labels[section],
                    style: tx(
                      mobile ? 29 : 36,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    section == 3
                        ? 'Вопросы, документы и история работы — вокруг одного человека.'
                        : section == 8
                        ? 'Обращения, участие и материалы — по данным текущего демо-сеанса.'
                        : section == 9
                        ? 'Профессиональная информация и организация вашего рабочего дня.'
                        : section >= 6
                        ? (section == 6
                              ? 'Пошаговые программы, материалы и участие пациента.'
                              : 'Ваши материалы: от первого черновика до готовой публикации.')
                        : section == 4
                        ? 'Приёмы и доступное время. Один календарь для вас и пациента.'
                        : 'Обращения, которым нужно ваше внимание. Контекст — рядом с решением.',
                    style: tx(15, color: C.muted),
                  ),
                  const SizedBox(height: 26),
                  if (mobile) ...[
                    navigation(true),
                    const SizedBox(height: 20),
                    work,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 205, child: navigation(false)),
                        const SizedBox(width: 22),
                        Expanded(child: work),
                        if (wide) ...[
                          const SizedBox(width: 22),
                          SizedBox(width: 280, child: contextPanel()),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Демонстрационная рабочая среда · изменения сохраняются в этой вкладке до обновления страницы',
                    style: tx(11, color: C.muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget navigation(bool mobile) {
    final buttons = [
      for (final i in [0, 4, 3, 1, 5, 6, 7, 8, 9, 2])
        TextButton.icon(
          key: ValueKey('expert-nav-$i'),
          onPressed: () => navigate(i),
          style: TextButton.styleFrom(
            backgroundColor: section == i
                ? const Color(0xFFE7FBD5)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            alignment: Alignment.centerLeft,
          ),
          icon: Icon(icons[i], size: 19),
          label: Text(
            labels[i],
            style: tx(
              13,
              weight: section == i ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
    ];
    if (mobile) return Wrap(spacing: 6, runSpacing: 6, children: buttons);
    return Surface(
      color: C.soft,
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'РАБОЧИЙ ДЕНЬ',
              style: tx(10, color: C.muted, weight: FontWeight.w600),
            ),
          ),
          ...buttons,
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Анна Волкова\nСпециалист · демо-профиль',
              style: tx(12, color: C.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget today() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.schedule.current != null) ...[
        appointmentSummary(),
        const SizedBox(height: 20),
      ],
      Surface(
        color: C.dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ВАШ ФОКУС',
              style: tx(11, color: C.lime, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              pending.isNotEmpty
                  ? 'Есть обращения без ответа'
                  : widget.consiliums.cases.any(
                      (c) => c.canWork && c.result == null,
                    )
                  ? 'Продолжим совместный разбор'
                  : 'Всё спокойно',
              style: tx(27, color: Colors.white, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Ожидают ответа: ${pending.length}\nДоступные документы: ${documents.length}',
              style: tx(14, color: const Color(0xFFBDD0C5)),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 22),
              PrimaryButton(
                'Открыть ближайшее обращение',
                () => openRequest(pending.first),
                key: const ValueKey('expert-next-request'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Что требует внимания',
              style: tx(23, weight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            if (pending.isEmpty) ...[
              Text(
                'Новых обращений пока нет. Они появятся после передачи вопросов из личного кабинета.',
                style: tx(15, color: C.muted),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                key: const ValueKey('expert-start-demo'),
                onPressed: widget.onPersonalQuestions,
                child: const Text('Подготовить вопрос в личном кабинете'),
              ),
            ] else
              for (final q in pending) requestTile(q),
            for (final c in widget.consiliums.cases.where(
              (c) => c.canWork && c.result == null,
            ))
              caseTile(c),
            if (documents.isNotEmpty) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => navigate(2),
                child: const Text('Посмотреть открытые документы'),
              ),
            ],
            if (requests.any((q) => q.specialistReply != null)) ...[
              const Divider(height: 32),
              Text(
                'Ответы добавлены: ${requests.where((q) => q.specialistReply != null).length}',
                style: tx(14, color: C.green),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    section = 1;
                    filter = 'С ответом';
                    selected = null;
                  });
                },
                child: const Text('Посмотреть обработанные обращения →'),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget requestTile(QuestionTransfer q) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: selected == q && section == 1 ? const Color(0xFFE7FBD5) : C.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('expert-request-${number(q)}'),
        onTap: () => openRequest(q),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Обращение №${number(q)}',
                      style: tx(16, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              if (!q.revoked)
                Text(
                  q.questions.firstOrNull ?? 'Вопросы пользователя',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tx(13, color: C.muted),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Tag(status(q), green: !q.revoked),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget requestPanel() {
    final visible = requests.reversed
        .where(
          (q) => switch (filter) {
            'Без ответа' => !q.revoked && q.specialistReply == null,
            'С ответом' => !q.revoked && q.specialistReply != null,
            'Отозванные' => q.revoked,
            _ => true,
          },
        )
        .toList();
    if (selected != null) return requestDetail(selected!);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Обращения пользователей',
            style: tx(23, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Здесь только вопросы, переданные Анне Волковой.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in [
                'Все',
                'Без ответа',
                'С ответом',
                'Отозванные',
              ])
                ChoiceChip(
                  label: Text(option),
                  selected: filter == option,
                  onSelected: (_) => setState(() => filter = option),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty) ...[
            Text(
              'В этом списке пока нет обращений.',
              style: tx(15, color: C.muted),
            ),
            TextButton(
              onPressed: widget.onPersonalQuestions,
              child: const Text('Открыть личный кабинет →'),
            ),
          ],
          for (final q in visible) requestTile(q),
        ],
      ),
    );
  }

  Widget requestDetail(QuestionTransfer q) {
    final controller = drafts.putIfAbsent(
      q,
      () => TextEditingController(text: q.replyDraft),
    );
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('expert-back-requests'),
              onPressed: () => setState(() => selected = null),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Все обращения'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('expert-request-patient'),
            onPressed: () => openPatient(tab: 1),
            icon: const Icon(Icons.person_outline, size: 18),
            label: Text(
              fromPatient ? 'К карточке пациента' : 'Карточка пациента',
            ),
          ),
          Text(
            'Обращение №${number(q)}',
            style: tx(25, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(status(q), green: !q.revoked),
              const Tag('Пользователь · демо'),
            ],
          ),
          const SizedBox(height: 20),
          if (q.revoked) ...[
            const Icon(Icons.lock_outline, size: 40, color: C.muted),
            const SizedBox(height: 16),
            Text(
              'Пользователь отозвал доступ',
              style: tx(21, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Вопросы и рабочий черновик закрыты для просмотра. Добавить ответ по этому разрешению нельзя. Новая передача будет отдельным обращением.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: widget.onPersonalQuestions,
              child: const Text('Перейти в личный кабинет'),
            ),
          ] else ...[
            OutlinedButton.icon(
              key: const ValueKey('create-consilium'),
              onPressed: () => prepareConsilium(q),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Обсудить на консилиуме'),
            ),
            Text(
              'ВОПРОСЫ ПОЛЬЗОВАТЕЛЯ',
              style: tx(11, color: C.green, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            for (final question in q.questions.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  '${question.$1 + 1}. ${question.$2}',
                  style: tx(16),
                ),
              ),
            Text(
              'Просмотр разрешён до ${q.until}',
              style: tx(12, color: C.muted),
            ),
            const Divider(height: 36),
            if (q.specialistReply != null) ...[
              Text('Ваш ответ', style: tx(21, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              Surface(
                color: C.soft,
                padding: 18,
                child: SelectableText(q.specialistReply!, style: tx(15)),
              ),
              const SizedBox(height: 16),
              Text(
                'Ответ добавлен в личный кабинет. Обращение сохранено в истории.',
                style: tx(13, color: C.green),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                'Посмотреть со стороны пользователя',
                widget.onPersonalQuestions,
                key: const ValueKey('expert-view-as-user'),
              ),
            ] else ...[
              if (!q.inProgress)
                OutlinedButton(
                  key: const ValueKey('expert-take-request'),
                  onPressed: () {
                    if (q.revoked) return;
                    setState(() => q.inProgress = true);
                    widget.onChanged();
                  },
                  child: const Text('Взять в работу'),
                ),
              const SizedBox(height: 14),
              Text(
                'Ответ пользователю',
                style: tx(21, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Черновик виден только в кабинете специалиста.',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('expert-reply-draft'),
                controller: controller,
                minLines: 5,
                maxLines: 12,
                maxLength: 3000,
                onChanged: (value) => setState(() => q.replyDraft = value),
                decoration: const InputDecoration(
                  hintText: 'Напишите ответ и следующий шаг для пользователя…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                q.replyDraft.isEmpty
                    ? 'Текст пока не добавлен'
                    : 'Черновик сохранён в этой сессии',
                style: tx(12, color: C.muted),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                'Проверить и добавить ответ',
                q.replyDraft.trim().isEmpty || q.replyDraft.trim().length > 3000
                    ? null
                    : () => reviewReply(q),
                key: const ValueKey('expert-review-reply'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget documentsPanel() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Открыто пользователем', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Документы с отдельным действующим разрешением для Анны Волковой.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        if (documents.isEmpty) ...[
          const Icon(Icons.folder_off_outlined, size: 42, color: C.muted),
          const SizedBox(height: 16),
          Text(
            'Доступных документов пока нет',
            style: tx(19, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Вопрос или запись на приём не открывают файлы автоматически. Пользователь выбирает документ, получателя и срок в «Моих данных».',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: widget.onPersonalData,
            child: const Text('Открыть «Мои данные» пользователя'),
          ),
        ],
        for (final doc in documents)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(doc.file.name, style: tx(17, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(doc.category, style: tx(13, color: C.muted)),
                  for (final grant in allowed.where(
                    (g) => g.documentId == doc.id,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${grant.purpose}\nДо ${grant.until}',
                        style: tx(12, color: C.muted),
                      ),
                    ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    key: ValueKey('expert-document-${doc.id}'),
                    onPressed: () => viewDocument(doc),
                    child: const Text('Открыть для просмотра'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget contextPanel() => section == 8
      ? analyticsContext()
      : section == 9
      ? workProfileContext()
      : section >= 6
      ? libraryContext()
      : section == 3
      ? patientContext()
      : Surface(
          color: const Color(0xFFDDF7E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'КОНТЕКСТ РАБОТЫ',
                style: tx(11, color: C.green, weight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Text('Анна Волкова', style: tx(21, weight: FontWeight.w600)),
              Text('Специалист · демо-профиль', style: tx(13, color: C.muted)),
              const Divider(height: 32),
              if (section == 1 && selected != null) ...[
                Text(
                  'Обращение №${number(selected!)}',
                  style: tx(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(status(selected!), style: tx(14)),
                const SizedBox(height: 16),
              ],
              Text('Доступный объём', style: tx(15, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Переданные вопросы и отдельно открытые файлы. Личные заметки, семейные данные и чат с ИИ остаются в личном кабинете.',
                style: tx(13, color: C.muted),
              ),
              const Divider(height: 32),
              Text(
                'Проверка полного пути',
                style: tx(15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Переключайтесь между участниками через меню «Рабочая среда». Экран и черновик каждой среды сохраняются.',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onPersonalQuestions,
                child: const Text('Вопросы в личном кабинете →'),
              ),
            ],
          ),
        );
}
