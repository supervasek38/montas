part of 'main.dart';

// Current-state counters only: this demo has no dated analytics event stream.
class ExpertAnalytics {
  ExpertAnalytics({
    required List<QuestionTransfer> requests,
    required AppointmentSchedule schedule,
    required ConsiliumStore consiliums,
    required ExpertLibrary library,
    required bool hasPatient,
  }) {
    patients = hasPatient ? 1 : 0;
    revoked = requests.where((q) => q.revoked).length;
    final visible = requests.where((q) => !q.revoked).toList();
    answered = visible.where((q) => q.specialistReply != null).length;
    inProgress = visible
        .where((q) => q.specialistReply == null && q.inProgress)
        .length;
    newRequests = visible
        .where((q) => q.specialistReply == null && !q.inProgress)
        .length;
    appointments = schedule.current == null ? 0 : 1;
    cancellations = schedule.history.where((e) => e.after == null).length;
    reschedules = schedule.history
        .where((e) => e.before != null && e.after != null)
        .length;
    casesOpen = consiliums.cases
        .where((c) => c.canWork && c.result == null)
        .length;
    casesDone = consiliums.cases
        .where((c) => c.canWork && c.result != null)
        .length;
    casesPending = consiliums.cases
        .where((c) => !c.source.revoked && c.consent == CaseConsent.pending)
        .length;
    publishedPrograms = library.items
        .where(
          (i) =>
              !i.archived &&
              i.kind == LibraryKind.program &&
              i.published != null,
        )
        .length;
    publishedArticles = library.availableMaterials.length;
    drafts = library.items.where((i) => !i.archived && i.dirty).length;
    archived = library.items.where((i) => i.archived).length;
    final deliveries = library.deliveries
        .where((d) => !d.source.revoked)
        .toList();
    final programs = deliveries
        .where((d) => d.snapshot.kind == LibraryKind.program)
        .toList();
    offered = programs.where((d) => d.status == DeliveryStatus.offered).length;
    active = programs.where((d) => d.status == DeliveryStatus.active).length;
    paused = programs.where((d) => d.status == DeliveryStatus.paused).length;
    completed = programs
        .where((d) => d.status == DeliveryStatus.completed)
        .length;
    declined = programs
        .where((d) => d.status == DeliveryStatus.declined)
        .length;
    withdrawn = programs
        .where((d) => d.status == DeliveryStatus.withdrawn)
        .length;
    final accepted = programs
        .where(
          (d) => [
            DeliveryStatus.active,
            DeliveryStatus.paused,
            DeliveryStatus.completed,
          ].contains(d.status),
        )
        .toList();
    stepsDone = accepted.fold(0, (sum, d) => sum + d.done.length);
    stepsTotal = accepted.fold(0, (sum, d) => sum + d.total);
    final materials = deliveries
        .where(
          (d) =>
              d.snapshot.kind == LibraryKind.article &&
              ![
                DeliveryStatus.withdrawn,
                DeliveryStatus.declined,
              ].contains(d.status),
        )
        .toList();
    materialsShared = materials.length;
    materialsRead = materials
        .where((d) => d.status == DeliveryStatus.completed)
        .length;
  }
  late final int patients,
      revoked,
      answered,
      inProgress,
      newRequests,
      appointments,
      cancellations,
      reschedules;
  late final int casesOpen,
      casesDone,
      casesPending,
      publishedPrograms,
      publishedArticles,
      drafts,
      archived;
  late final int offered,
      active,
      paused,
      completed,
      declined,
      withdrawn,
      stepsDone,
      stepsTotal,
      materialsShared,
      materialsRead;
  int get requestsTotal => answered + inProgress + newRequests;
  int get acceptedPrograms => active + paused + completed;
  String ratio(int n, int total) =>
      total == 0 ? '—' : '${(n / total * 100).round()}%';
  Map<String, String> get report => {
    'Период': 'Текущее состояние демо-сеанса · 20 октября 2026',
    'Пациенты в истории': '$patients',
    'Доступные обращения': '$requestsTotal',
    'Ответы': '$answered',
    'Обращения в работе': '$inProgress',
    'Новые обращения': '$newRequests',
    'Отозванные обращения': '$revoked',
    'Актуальные записи на приём': '$appointments',
    'Операции отмены записи': '$cancellations',
    'Операции переноса записи': '$reschedules',
    'Консилиумы в работе': '$casesOpen',
    'Консилиумы с итогом': '$casesDone',
    'Ожидают согласия': '$casesPending',
    'Опубликованные программы': '$publishedPrograms',
    'Опубликованные материалы': '$publishedArticles',
    'Черновики редакций': '$drafts',
    'Объекты в архиве': '$archived',
    'Предложенные программы': '$offered',
    'Активные программы': '$active',
    'Программы на паузе': '$paused',
    'Завершённые программы': '$completed',
    'Отклонённые программы': '$declined',
    'Отозванные предложения программ': '$withdrawn',
    'Принятые программы': '$acceptedPrograms',
    'Выполненные шаги': '$stepsDone',
    'Всего шагов принятых программ': '$stepsTotal',
    'Предложенные отдельно материалы без отзыва и отклонения':
        '$materialsShared',
    'Материалы с отметкой прочтения': '$materialsRead',
  };
  String get csv =>
      '\uFEFFПоказатель;Значение\r\n${report.entries.map((e) => '"${e.key.replaceAll('"', '""')}";"${e.value.replaceAll('"', '""')}"').join('\r\n')}\r\n';
}

extension _ExpertAnalyticsViews on ExpertWorkspaceState {
  ExpertAnalytics get analytics => ExpertAnalytics(
    requests: requests,
    schedule: widget.schedule,
    consiliums: widget.consiliums,
    library: widget.library,
    hasPatient: hasPatient,
  );
  Widget analyticsPanel() {
    final a = analytics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          color: C.dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ТЕКУЩИЙ ДЕМО-СЕАНС',
                style: tx(11, color: C.lime, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Работа в цифрах',
                style: tx(27, color: Colors.white, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Показатели обновляются после ваших действий и отметок пациента. Исторические периоды пока не собираются.',
                style: tx(14, color: const Color(0xFFBDD0C5)),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                'Посмотреть отчёт',
                showAnalyticsReport,
                key: const ValueKey('analytics-report'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in [
              'Обзор',
              'Участие в программах',
              'Библиотека',
            ].indexed)
              ChoiceChip(
                key: ValueKey('analytics-tab-${t.$1}'),
                label: Text(t.$2),
                selected: analyticsTab == t.$1,
                onSelected: (_) => updatePatients(() => analyticsTab = t.$1),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (analyticsTab == 0) ...[
          LayoutBuilder(
            builder: (ctx, box) => Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final m in [
                  (
                    'Пациенты в истории',
                    '${a.patients}',
                    'Один тестовый аккаунт',
                    3,
                    'patients',
                  ),
                  (
                    'Ожидают ответа',
                    '${a.newRequests + a.inProgress}',
                    'Новые и взятые в работу',
                    1,
                    'pending',
                  ),
                  (
                    'Ближайшие приёмы',
                    '${a.appointments}',
                    'Подтверждённая запись',
                    4,
                    'appointments',
                  ),
                  (
                    'Консилиумы в работе',
                    '${a.casesOpen}',
                    'Согласие получено, итога ещё нет',
                    5,
                    'cases',
                  ),
                ])
                  SizedBox(
                    width: box.maxWidth < 480
                        ? box.maxWidth
                        : (box.maxWidth - 14) / 2,
                    child: analyticsMetric(
                      m.$1,
                      m.$2,
                      m.$3,
                      () => analyticsNavigate(m.$4),
                      m.$5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Обращения', style: tx(23, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Ответы: ${a.answered} из ${a.requestsTotal} · ${a.ratio(a.answered, a.requestsTotal)}',
                  key: const ValueKey('analytics-response-rate'),
                  style: tx(15, color: C.green),
                ),
                const SizedBox(height: 18),
                analyticsBar('Новые', a.newRequests, a.requestsTotal),
                analyticsBar('В работе', a.inProgress, a.requestsTotal),
                analyticsBar('С ответом', a.answered, a.requestsTotal),
                if (a.requestsTotal == 0)
                  Text(
                    'Нет доступных обращений для расчёта доли ответов.',
                    style: tx(13, color: C.muted),
                  ),
                Text(
                  'Отозванные: ${a.revoked}. Они исключены из распределения и доли ответов.',
                  style: tx(12, color: C.muted),
                ),
                TextButton(
                  key: const ValueKey('analytics-open-requests'),
                  onPressed: () => analyticsNavigate(1),
                  child: const Text('Перейти к обращениям →'),
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
                  'Приёмы и совместные разборы',
                  style: tx(21, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                analyticsRow('Переносы записей за сеанс', '${a.reschedules}'),
                analyticsRow('Отмены записей за сеанс', '${a.cancellations}'),
                analyticsRow(
                  'Консилиумы с опубликованным итогом',
                  '${a.casesDone}',
                ),
                analyticsRow(
                  'Консилиумы ожидают согласия',
                  '${a.casesPending}',
                ),
                Text(
                  'Перенос и отмена — операции с записью, а не количество пациентов. Проведённые приёмы и оплаты в прототипе не учитываются.',
                  style: tx(12, color: C.muted),
                ),
              ],
            ),
          ),
        ] else if (analyticsTab == 1)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Участие в программах',
                  style: tx(23, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '${a.completed} из ${a.acceptedPrograms} завершено',
                  key: const ValueKey('analytics-completed'),
                  style: tx(25, weight: FontWeight.w600),
                ),
                Text(
                  'Доля завершённых: ${a.ratio(a.completed, a.acceptedPrograms)}. Основа расчёта — принятые программы, включая паузу.',
                  style: tx(13, color: C.muted),
                ),
                const SizedBox(height: 18),
                analyticsBar('Активные', a.active, a.acceptedPrograms),
                analyticsBar('На паузе', a.paused, a.acceptedPrograms),
                analyticsBar('Завершены', a.completed, a.acceptedPrograms),
                const Divider(height: 28),
                analyticsRow('Ещё не приняты', '${a.offered}'),
                analyticsRow('Отклонены', '${a.declined}'),
                analyticsRow('Предложения отозваны', '${a.withdrawn}'),
                const SizedBox(height: 14),
                Text(
                  'Шаги: ${a.stepsDone} из ${a.stepsTotal} · ${a.ratio(a.stepsDone, a.stepsTotal)}',
                  key: const ValueKey('analytics-steps'),
                  style: tx(17, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  a.acceptedPrograms == 0
                      ? 'Пациент ещё не принял программу. Предложите готовую программу из библиотеки.'
                      : 'Расчёт по отметкам пациента. Выполнение шагов не оценивает медицинский результат.',
                  style: tx(13, color: C.muted),
                ),
                TextButton(
                  onPressed: () => analyticsNavigate(6),
                  child: const Text('Открыть программы →'),
                ),
              ],
            ),
          )
        else
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Библиотека и материалы',
                  style: tx(23, weight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                analyticsRow(
                  'Опубликованные программы',
                  '${a.publishedPrograms}',
                ),
                analyticsRow(
                  'Опубликованные материалы',
                  '${a.publishedArticles}',
                ),
                analyticsRow('Черновики редакций', '${a.drafts}'),
                analyticsRow('Объекты в архиве', '${a.archived}'),
                const Divider(height: 28),
                Text(
                  'Чтение отдельных материалов',
                  style: tx(19, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '${a.materialsRead} из ${a.materialsShared} отмечены прочитанными',
                  key: const ValueKey('analytics-read'),
                  style: tx(17),
                ),
                const SizedBox(height: 12),
                analyticsBar('Прочитано', a.materialsRead, a.materialsShared),
                Text(
                  'Учитываются материалы, предложенные отдельно и не отозванные или отклонённые. Просмотр страницы не равен отметке «прочитано». Материалы внутри программы отдельно не отслеживаются.',
                  style: tx(12, color: C.muted),
                ),
                TextButton(
                  onPressed: () => analyticsNavigate(7),
                  child: const Text('Открыть контент →'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void analyticsNavigate(int target) {
    updatePatients(() {
      if (target == 1) {
        selected = null;
        filter = 'Все';
      }
      if (target == 3) {
        patientOpen = false;
        patientFilter = 'Все';
        patientSearch.clear();
      }
      if (target == 5) selectedCase = null;
      if (target == 6) selectedProgram = null;
      if (target == 7) selectedContent = null;
    });
    navigate(target);
  }

  Widget analyticsMetric(
    String label,
    String value,
    String note,
    VoidCallback open,
    String id,
  ) => Surface(
    padding: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: tx(14, weight: FontWeight.w500)),
        const SizedBox(height: 12),
        Text(
          value,
          key: ValueKey('analytics-value-$id'),
          style: tx(34, weight: FontWeight.w600),
        ),
        Text(note, style: tx(12, color: C.muted)),
        TextButton(
          key: ValueKey('analytics-drill-$id'),
          onPressed: open,
          child: const Text('Открыть →'),
        ),
      ],
    ),
  );
  Widget analyticsRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: tx(14))),
        const SizedBox(width: 12),
        Text(value, style: tx(16, weight: FontWeight.w600)),
      ],
    ),
  );
  Widget analyticsBar(String label, int value, int total) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        analyticsRow(label, '$value'),
        Semantics(
          label: '$label: $value из $total',
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : value / total,
            color: C.green,
            backgroundColor: C.soft,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  );
  Future<void> showAnalyticsReport() async {
    final snapshot = analytics;
    await modal<void>(
      'Отчёт текущего сеанса',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Снимок на момент открытия. Только итоговые счётчики, без вопросов и медицинских данных.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 18),
          for (final row in snapshot.report.entries)
            if (row.key == 'Период')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(row.value, style: tx(14)),
              )
            else
              analyticsRow(row.key, row.value),
          const SizedBox(height: 18),
          PrimaryButton('Скачать CSV', () {
            try {
              file_bridge.download(
                'montas-expert-analytics.csv',
                'text/csv;charset=utf-8',
                Uint8List.fromList(utf8.encode(snapshot.csv)),
              );
              notify('Отчёт передан браузеру для скачивания');
            } catch (_) {
              notify('Скачивание доступно в веб-версии');
            }
          }, key: const ValueKey('analytics-download')),
        ],
      ),
    );
  }

  Widget analyticsContext() => Surface(
    color: const Color(0xFFDDF7E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'КАК ЧИТАТЬ ПОКАЗАТЕЛИ',
          style: tx(11, color: C.green, weight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        Text('Данные вашего сеанса', style: tx(22, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(
          'Источник — обращения, расписание, консилиумы и библиотека прототипа. Показатели обновляются автоматически.',
          style: tx(14, color: C.muted),
        ),
        const Divider(height: 28),
        Text('Без выдуманной динамики', style: tx(16, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Сравнения с прошлой неделей и выручка появятся после подключения истории событий и оплат. При отсутствии данных доля показана как «—».',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 12),
        Text(
          'После отзыва доступа участие пациента исключается из расчётов. После перезагрузки восстанавливается тестовый набор.',
          style: tx(12, color: C.muted),
        ),
      ],
    ),
  );
}
