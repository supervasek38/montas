part of 'main.dart';

enum CaseConsent { pending, approved, declined, revoked }

enum OpinionStance { support, partial, needsInfo, abstain }

extension OpinionLabel on OpinionStance {
  String get label => switch (this) {
    OpinionStance.support => 'Поддерживаю',
    OpinionStance.partial => 'Частично',
    OpinionStance.needsInfo => 'Нужны данные',
    OpinionStance.abstain => 'Воздерживаюсь',
  };
  Color get color => switch (this) {
    OpinionStance.support => const Color(0xFFEAFBD9),
    OpinionStance.partial => const Color(0xFFFFF4D8),
    OpinionStance.needsInfo => const Color(0xFFE4F6FC),
    OpinionStance.abstain => C.soft,
  };
}

class CaseOpinion {
  const CaseOpinion(this.stance, this.text);
  final OpinionStance stance;
  final String text;
}

class ConsiliumCase {
  ConsiliumCase(this.id, this.source);
  final int id;
  final QuestionTransfer source;
  static const participants = [
    'Анна Волкова · координатор',
    'Илья Соколов · специалист по сну',
  ];
  final _opinions = <int, CaseOpinion>{};
  final _history = <String>[
    'Кейс создан · состав вопросов зафиксирован, версия 1',
  ];
  Map<int, CaseOpinion> get opinions => Map.unmodifiable(_opinions);
  List<String> get history => List.unmodifiable(_history);
  CaseConsent _consent = CaseConsent.pending;
  CaseConsent get consent => _consent;
  int revision = 0;
  String? _result;
  String? get result => _result;
  bool get canWork => consent == CaseConsent.approved && !source.revoked;
  bool get ready =>
      canWork &&
      result == null &&
      opinions.length == 2 &&
      opinions.values.every(
        (o) =>
            o.stance == OpinionStance.support ||
            o.stance == OpinionStance.partial,
      );
  bool get disagreement =>
      opinions.values.any((o) => o.stance == OpinionStance.partial);
  String get status => source.revoked || consent == CaseConsent.revoked
      ? 'Доступ отозван'
      : consent == CaseConsent.declined
      ? 'Участие отклонено'
      : consent == CaseConsent.pending
      ? 'Ожидает согласия'
      : result != null
      ? 'Итог опубликован'
      : opinions.values.any((o) => o.stance == OpinionStance.needsInfo)
      ? 'Нужны данные'
      : opinions.values.any((o) => o.stance == OpinionStance.abstain)
      ? 'Есть воздержавшийся'
      : ready
      ? 'Готов к подведению итога'
      : 'Ожидает мнения';
}

class ConsiliumStore extends ChangeNotifier {
  final _cases = <ConsiliumCase>[];
  List<ConsiliumCase> get cases => List.unmodifiable(_cases);
  ConsiliumCase? create(QuestionTransfer source) {
    if (source.revoked) return null;
    for (final c in _cases) {
      if (identical(c.source, source)) return c;
    }
    final c = ConsiliumCase(_cases.length + 1, source);
    _cases.add(c);
    notifyListeners();
    return c;
  }

  bool setConsent(ConsiliumCase c, CaseConsent next) {
    if (!_cases.contains(c) || c.source.revoked) return false;
    final valid =
        c.consent == CaseConsent.pending &&
            (next == CaseConsent.approved || next == CaseConsent.declined) ||
        c.consent == CaseConsent.approved && next == CaseConsent.revoked;
    if (!valid) return false;
    c._consent = next;
    c.revision++;
    c._history.add(switch (next) {
      CaseConsent.approved =>
        'Пациент разрешил разбор двум указанным участникам',
      CaseConsent.declined => 'Пациент отклонил участие',
      _ => 'Пациент отозвал доступ к консилиуму',
    });
    notifyListeners();
    return true;
  }

  bool opinion(ConsiliumCase c, int author, OpinionStance stance, String text) {
    if (!_cases.contains(c) ||
        !c.canWork ||
        c.result != null ||
        author < 0 ||
        author > 1 ||
        text.trim().isEmpty ||
        text.trim().length > 2000) {
      return false;
    }
    c._opinions[author] = CaseOpinion(stance, text.trim());
    c.revision++;
    c._history.add(
      '${ConsiliumCase.participants[author]}: ${stance.label} · вопросы версии 1',
    );
    notifyListeners();
    return true;
  }

  bool publish(ConsiliumCase c, int expectedRevision, String text) {
    if (!_cases.contains(c) ||
        !c.ready ||
        c.revision != expectedRevision ||
        text.trim().isEmpty ||
        text.trim().length > 3000) {
      return false;
    }
    c._result = text.trim();
    c.revision++;
    c._history.add('Координатор опубликовал итог в личном кабинете');
    notifyListeners();
    return true;
  }
}

extension _ExpertConsiliumViews on ExpertWorkspaceState {
  void openCase(ConsiliumCase c) {
    updatePatients(() {
      selectedCase = c;
    });
    navigate(5);
  }

  Future<void> prepareConsilium(QuestionTransfer q) async {
    final existing = widget.consiliums.cases
        .where((c) => identical(c.source, q))
        .firstOrNull;
    if (existing != null) {
      openCase(existing);
      return;
    }
    final accepted = await modal<bool>(
      'Создать консилиум',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Совместная подготовка к консультации',
            style: tx(20, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Участники:\n${ConsiliumCase.participants.join('\n')}\n\nБудут включены только вопросы этого обращения. Документы, заметки и план не передаются. Сначала пациенту нужно подтвердить участие в личном кабинете.',
            style: tx(14),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Запросить согласие',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('case-create-confirm'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      final c = widget.consiliums.create(q);
      if (c != null) openCase(c);
    }
  }

  Widget caseTile(ConsiliumCase c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Surface(
      color: const Color(0xFFF0F4F2),
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Консилиум №${c.id} · подготовка к консультации',
            style: tx(17, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Пользователь · демо · MNT-DEMO-001',
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(c.status),
              if (c.canWork) Tag('Мнения ${c.opinions.length}/2'),
            ],
          ),
          TextButton(
            onPressed: () => openCase(c),
            key: ValueKey('case-open-${c.id}'),
            child: const Text('Открыть кейс →'),
          ),
        ],
      ),
    ),
  );

  Widget consiliumPanel() {
    final c = selectedCase;
    if (c == null) {
      return Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Совместные разборы', style: tx(24, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              'Один кейс, независимые мнения и проверенный координатором итог.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 20),
            if (widget.consiliums.cases.isEmpty)
              Text(
                'Пока нет консилиумов. Откройте обращение пациента, чтобы начать разбор.',
                style: tx(15),
              ),
            for (final c in widget.consiliums.cases.reversed) caseTile(c),
            OutlinedButton(
              onPressed: () => navigate(1),
              child: const Text('К обращениям пациентов'),
            ),
          ],
        ),
      );
    }
    final controller = caseDrafts.putIfAbsent(c, () => TextEditingController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => updatePatients(() => selectedCase = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Все консилиумы'),
          ),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Tag('СОВМЕСТНЫЙ РАЗБОР · ДЕМО', green: true),
              const SizedBox(height: 16),
              Text(
                'Подготовка к консультации',
                style: tx(25, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Кейс №${c.id} · MNT-DEMO-001 · вопросы версии 1',
                style: tx(12, color: C.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [Tag(c.status), const Tag('2 участника')],
              ),
              TextButton(
                onPressed: () => openPatient(),
                child: const Text('Карточка пациента →'),
              ),
              if (!c.canWork) ...[
                const SizedBox(height: 12),
                Text(
                  'Содержимое кейса доступно только при действующем согласии пациента на этот консилиум и исходное обращение.',
                  style: tx(14, color: C.muted),
                ),
                OutlinedButton(
                  onPressed: widget.onPersonalQuestions,
                  child: const Text('Открыть согласие в личном кабинете'),
                ),
              ] else ...[
                const Divider(height: 28),
                for (final q in c.source.questions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(q, style: tx(15)),
                  ),
                Text(
                  'Основание: вопросы пациента. Файлы и личные заметки не включены в кейс. Доступ — до ${c.source.until}',
                  style: tx(12, color: C.muted),
                ),
              ],
            ],
          ),
        ),
        if (c.canWork) ...[
          const SizedBox(height: 22),
          Text('Независимые мнения', style: tx(23, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Разногласия остаются видимыми. Координатор формулирует итог после получения мнений.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 2; i++) opinionCard(c, i),
          Surface(
            color: const Color(0xFFF0F4F2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  c.result != null ? 'Итог разбора' : 'Решение координатора',
                  style: tx(22, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (c.disagreement) ...[
                  const Tag('Есть разногласия'),
                  const SizedBox(height: 12),
                ],
                if (c.result != null) ...[
                  Text(c.result!, style: tx(15)),
                  const SizedBox(height: 12),
                  Text(
                    'Опубликовано в личном кабинете. План пациента не изменён.',
                    style: tx(12, color: C.green),
                  ),
                ] else ...[
                  if (!c.ready)
                    Text(
                      'Для итогового решения нужны два мнения «Поддерживаю» или «Частично». При запросе данных или воздержании разбор остаётся открытым.',
                      style: tx(14, color: C.muted),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('case-result-draft'),
                    controller: controller,
                    minLines: 3,
                    maxLines: 7,
                    maxLength: 3000,
                    decoration: const InputDecoration(
                      labelText: 'Итог для пациента',
                      hintText:
                          'Что обсудили, в чём согласны и какие вопросы остались',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  PrimaryButton(
                    'Проверить итог',
                    c.ready ? () => reviewCase(c, controller.text) : null,
                    key: const ValueKey('case-review'),
                  ),
                ],
                TextButton(
                  onPressed: widget.onPersonalQuestions,
                  key: const ValueKey('case-view-patient'),
                  child: const Text('Посмотреть со стороны пациента →'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Surface(
            padding: 12,
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                title: const Text('История разбора'),
                children: [
                  for (final event in c.history)
                    ListTile(title: Text(event, style: tx(12))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget opinionCard(ConsiliumCase c, int author) {
    final o = c.opinions[author];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Surface(
        color: o?.stance.color ?? C.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ConsiliumCase.participants[author],
              style: tx(16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              o?.stance.label ?? 'Мнение ещё не добавлено',
              style: tx(14, weight: FontWeight.w600),
            ),
            if (o != null) ...[
              const SizedBox(height: 10),
              Text(o.text, style: tx(14)),
              const SizedBox(height: 8),
              Text(
                'Основание: вопросы пациента · версия 1',
                style: tx(11, color: C.muted),
              ),
            ],
            if (c.result == null)
              TextButton(
                onPressed: () => editCaseOpinion(c, author),
                key: ValueKey('case-opinion-$author'),
                child: Text(
                  author == 0
                      ? (o == null
                            ? 'Добавить своё мнение'
                            : 'Изменить своё мнение')
                      : 'Демо: мнение второго участника',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> editCaseOpinion(ConsiliumCase c, int author) async {
    final previous = c.opinions[author];
    final input = TextEditingController(text: previous?.text ?? '');
    var stance = previous?.stance ?? OpinionStance.support;
    String? error;
    await modal<void>(
      author == 0 ? 'Ваше мнение' : 'Демо: мнение участника',
      (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ConsiliumCase.participants[author],
              style: tx(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (author == 1)
              Text(
                'Вы моделируете ответ второго участника. Реальные приглашения не отправляются.',
                style: tx(12, color: C.muted),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in OpinionStance.values)
                  ChoiceChip(
                    key: ValueKey('stance-${s.name}'),
                    label: Text(s.label),
                    selected: stance == s,
                    onSelected: (_) => refresh(() => stance = s),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('case-opinion-text'),
              controller: input,
              minLines: 3,
              maxLines: 7,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Мнение и его основание',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton('Сохранить мнение', () {
              if (widget.consiliums.opinion(c, author, stance, input.text)) {
                Navigator.pop(ctx);
              } else {
                refresh(
                  () => error = !c.canWork
                      ? 'Доступ к кейсу закрыт'
                      : 'Введите мнение (до 2000 символов)',
                );
              }
            }, key: const ValueKey('case-opinion-save')),
          ],
        ),
      ),
    );
    // Dialog transitions can still use the controller for one frame.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Future<void> reviewCase(ConsiliumCase c, String draft) async {
    final text = draft.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала заполните итог для пациента')),
      );
      return;
    }
    final revision = c.revision;
    await modal<void>(
      'Проверка итога',
      (ctx) => ListenableBuilder(
        listenable: widget.consiliums,
        builder: (ctx, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Получатель: Пользователь · демо\nКейс №${c.id} · вопросы версии 1',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 16),
            if (!c.canWork)
              Text('Доступ отозван. Публикация недоступна.', style: tx(15))
            else ...[
              if (c.disagreement)
                const Tag('Есть разногласия — они будут видны пациенту'),
              const SizedBox(height: 12),
              Text(text, style: tx(15)),
              const SizedBox(height: 16),
              Text(
                'Пациент увидит итог и оба мнения. Назначения и план автоматически не меняются.',
                style: tx(13, color: C.muted),
              ),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              'Опубликовать итог',
              c.ready && c.revision == revision
                  ? () {
                      if (widget.consiliums.publish(c, revision, text)) {
                        Navigator.pop(ctx);
                      }
                    }
                  : null,
              key: const ValueKey('case-publish'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsiliumPatientPanel extends StatelessWidget {
  const ConsiliumPatientPanel({required this.store, super.key});
  final ConsiliumStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in store.cases)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Консилиум №${c.id}',
                    style: tx(23, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text('Совместная подготовка к консультации', style: tx(16)),
                  const SizedBox(height: 12),
                  Text(
                    'Участники:\n${ConsiliumCase.participants.join('\n')}',
                    style: tx(14),
                  ),
                  const SizedBox(height: 12),
                  Tag(c.status),
                  const SizedBox(height: 12),
                  Text(
                    'Доступ только к переданным вопросам до ${c.source.until}. Файлы, заметки и план не включены.',
                    style: tx(12, color: C.muted),
                  ),
                  if (c.consent == CaseConsent.pending &&
                      !c.source.revoked) ...[
                    const SizedBox(height: 12),
                    for (final q in c.source.questions)
                      Text('• $q', style: tx(14)),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      'Разрешить разбор этим участникам',
                      () => store.setConsent(c, CaseConsent.approved),
                      key: ValueKey('case-consent-${c.id}'),
                    ),
                    TextButton(
                      onPressed: () =>
                          store.setConsent(c, CaseConsent.declined),
                      key: ValueKey('case-decline-${c.id}'),
                      child: const Text('Отклонить'),
                    ),
                  ],
                  if (c.result != null) ...[
                    const Divider(height: 28),
                    Text(
                      'Итог от Анны Волковой',
                      style: tx(19, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (c.disagreement) const Tag('Есть разногласия'),
                    Text(c.result!, style: tx(15)),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: ExpansionTile(
                        title: const Text('Мнения участников'),
                        children: [
                          for (final e in c.opinions.entries)
                            ListTile(
                              title: Text(ConsiliumCase.participants[e.key]),
                              subtitle: Text(
                                '${e.value.stance.label}\n${e.value.text}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Итог сохранён для вас. Ваш план не изменён.',
                      style: tx(12, color: C.green),
                    ),
                  ],
                  if (c.canWork)
                    TextButton(
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Отозвать доступ?'),
                            content: const Text(
                              'Участники больше не смогут просматривать кейс и добавлять мнения. Уже полученный итог останется у вас.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Назад'),
                              ),
                              TextButton(
                                key: const ValueKey('case-revoke-confirm'),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Отозвать'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) {
                          store.setConsent(c, CaseConsent.revoked);
                        }
                      },
                      key: ValueKey('case-revoke-${c.id}'),
                      child: const Text('Отозвать доступ к консилиуму'),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
