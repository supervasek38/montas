part of 'main.dart';

enum MedicationReview { none, ready, waiting, decision, accepted }

/// Local demo state. A self-report never changes the prescription.
class MedicationData extends ChangeNotifier {
  String? takenAt;
  int version = 1;
  String changeKind = '', changeText = '';
  MedicationReview review = MedicationReview.none;
  final intakeHistory = <String>[];
  final reviewHistory = <String>[];
  final versions = <String>[
    'Версия 1 · 14 августа 2026\nЭндокринолог · исходное демо-назначение.\n50 мкг · 08:00 · натощак.',
  ];
  String get intakeLabel =>
      takenAt == null ? 'Приём ещё не отмечен' : 'Приём отмечен · $takenAt';
  String get reviewLabel => switch (review) {
    MedicationReview.none => 'Изменений нет',
    MedicationReview.ready => 'Сводка готова',
    MedicationReview.waiting => 'Ожидает проверки · демо',
    MedicationReview.decision => 'Есть решение · демо',
    MedicationReview.accepted => 'Решение принято · демо',
  };
  void logIntake(String time) {
    intakeHistory.insert(
      0,
      '20 октября · $time\n${takenAt == null ? 'Приём отмечен' : 'Время исправлено с $takenAt'} · 50 мкг. Источник: ваша отметка.',
    );
    takenAt = time;
    notifyListeners();
  }

  void undoIntake() {
    if (takenAt == null) return;
    intakeHistory.insert(
      0,
      '20 октября · отметка $takenAt отменена вами. Назначение сохранено.',
    );
    takenAt = null;
    notifyListeners();
  }

  void prepare(String kind, String text) {
    if (review == MedicationReview.waiting ||
        review == MedicationReview.decision) {
      return;
    }
    changeKind = kind;
    changeText = text.trim();
    review = MedicationReview.ready;
    reviewHistory.insert(
      0,
      '20 октября · сводка подготовлена\n$kind: $changeText\nВерсия назначения: $version. Внешней передачи нет.',
    );
    notifyListeners();
  }

  void simulateSend() {
    if (review != MedicationReview.ready) return;
    review = MedicationReview.waiting;
    reviewHistory.insert(
      0,
      '20 октября · передача смоделирована\nПолучатель: эндокринолог (демо). Канал: кабинет специалиста (демо). Срок ответа не установлен.\nСостав: назначение v$version, $changeKind: $changeText; $intakeLabel.',
    );
    notifyListeners();
  }

  void simulateDecision() {
    if (review != MedicationReview.waiting) return;
    review = MedicationReview.decision;
    reviewHistory.insert(
      0,
      '20 октября · демонстрационное решение эндокринолога\nПредложена версия ${version + 1}: 50 мкг · 08:00 · натощак. Причина: повторное подтверждение текущей схемы.',
    );
    notifyListeners();
  }

  void acceptDecision() {
    if (review != MedicationReview.decision) return;
    version++;
    review = MedicationReview.accepted;
    versions.insert(
      0,
      'Версия $version · 20 октября 2026\nЭндокринолог · демонстрационное решение.\n50 мкг · 08:00 · натощак. Причина: повторное подтверждение текущей схемы. Принято вами.',
    );
    reviewHistory.insert(
      0,
      '20 октября · вы приняли версию $version. Предыдущая версия сохранена.',
    );
    notifyListeners();
  }
}

class MedicationSummary extends StatelessWidget {
  const MedicationSummary({
    required this.data,
    required this.onOpen,
    super.key,
  });
  final MedicationData data;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.medication_outlined, color: C.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Лекарства', style: tx(21, weight: FontWeight.w600)),
            ),
            const Tag('Сегодня'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Левотироксин · 50 мкг', style: tx(17, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          data.intakeLabel,
          key: const ValueKey('medication-summary-status'),
          style: tx(14, color: data.takenAt == null ? C.muted : C.green),
        ),
        if (data.review != MedicationReview.none) ...[
          const SizedBox(height: 8),
          Text(data.reviewLabel, style: tx(13, color: C.muted)),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          key: const ValueKey('open-medications'),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Открыть лекарства'),
        ),
      ],
    ),
  );
}

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({required this.data, required this.onPlan, super.key});
  final MedicationData data;
  final VoidCallback onPlan;
  @override
  State<MedicationScreen> createState() => MedicationScreenState();
}

class MedicationScreenState extends State<MedicationScreen> {
  int tab = 0;
  MedicationData get data => widget.data;
  static const gap = SizedBox(height: 20);

  Future<T?> popup<T>(
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

  Future<void> intake() async {
    final form = GlobalKey<FormState>();
    var time = data.takenAt ?? '08:03';
    final result = await popup<String>(
      data.takenAt == null ? 'Отметить приём' : 'Исправить время',
      (ctx) => Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Tag('20 октября · демо-дата'),
            gap,
            Text(
              'Левотироксин · 50 мкг',
              style: tx(19, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Отметка описывает уже состоявшийся приём. Назначение останется прежним.',
              style: tx(14, color: C.muted),
            ),
            gap,
            TextFormField(
              key: const ValueKey('med-time'),
              initialValue: time,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Время приёма',
                hintText: '08:03',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => time = v.trim(),
              validator: (v) =>
                  RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Введите время от 00:00 до 23:59',
            ),
            gap,
            PrimaryButton('Сохранить отметку', () {
              if (form.currentState!.validate()) Navigator.pop(ctx, time);
            }, key: const ValueKey('confirm-med-intake')),
          ],
        ),
      ),
    );
    if (result != null && mounted) data.logIntake(result);
  }

  Future<void> undo() async {
    final confirmed = await popup<bool>(
      'Отменить отметку?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Уберём отметку приёма за сегодня. Исправление останется в журнале, назначение не изменится.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Да, отменить отметку',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-med-undo'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) data.undoIntake();
  }

  Future<void> change() async {
    final editing = data.review == MedicationReview.ready;
    var kind = editing ? data.changeKind : 'Самочувствие';
    var note = editing ? data.changeText : '';
    final form = GlobalKey<FormState>();
    final result = await popup<(String, String)>(
      'Что изменилось?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Текущее назначение: 50 мкг. Опишите наблюдение или сведения от врача, чтобы подготовить сводку.',
                style: tx(14, color: C.muted),
              ),
              gap,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in [
                    'Самочувствие',
                    'Назначение врача',
                    'Другой препарат',
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: kind == label,
                      onSelected: (_) => update(() => kind = label),
                    ),
                ],
              ),
              gap,
              TextFormField(
                key: const ValueKey('med-change-text'),
                initialValue: note,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Что и когда произошло',
                  alignLabelWithHint: true,
                  hintText: 'Например, врач уточнил схему на приёме…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => note = v,
                validator: (v) => (v?.trim().length ?? 0) < 5
                    ? 'Добавьте описание (не менее 5 символов)'
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Сохраним сводку для просмотра. Получатель и передача подтверждаются отдельно.',
                style: tx(13, color: C.muted),
              ),
              gap,
              PrimaryButton('Подготовить для врача', () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, (kind, note));
                }
              }, key: const ValueKey('prepare-med-review')),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      data.prepare(result.$1, result.$2);
      setState(() => tab = 1);
    }
  }

  Future<void> send() async {
    var consent = false;
    final result = await popup<bool>(
      'Проверить передачу',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Tag('Демонстрация · без отправки'),
            gap,
            Text('Эндокринолог', style: tx(20, weight: FontWeight.w600)),
            Text(
              'Тестовый получатель · кабинет специалиста',
              style: tx(13, color: C.muted),
            ),
            gap,
            detail(
              'Что входит',
              'Назначение v${data.version}, ваша сводка «${data.changeKind}» и сегодняшняя отметка приёма.',
            ),
            const SizedBox(height: 12),
            Text(data.changeText, style: tx(14)),
            gap,
            CheckboxListTile(
              key: const ValueKey('med-transfer-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: consent,
              onChanged: (v) => update(() => consent = v ?? false),
              title: Text(
                'Подтверждаю состав сводки и тестового получателя',
                style: tx(14),
              ),
            ),
            gap,
            PrimaryButton(
              'Смоделировать передачу',
              consent ? () => Navigator.pop(ctx, true) : null,
              key: const ValueKey('confirm-med-send'),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) data.simulateSend();
  }

  Future<void> decision() async {
    final confirmed = await popup<bool>(
      'Демо: решение врача',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Это заранее заданный ответ для проверки интерфейса. Он не основан на вашем описании и не является реальной консультацией.',
            style: tx(14, color: C.muted),
          ),
          gap,
          detail(
            'Автор · эндокринолог (демо)',
            'Повторно подтверждена прежняя схема: 50 мкг · 08:00 · натощак. Доза не увеличена.',
          ),
          gap,
          PrimaryButton(
            'Показать демо-решение',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-med-decision'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) data.simulateDecision();
  }

  Future<void> accept() async {
    final confirmed = await popup<bool>(
      'Принять новую версию?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Версия ${data.version} → ${data.version + 1}',
            style: tx(21, weight: FontWeight.w600),
          ),
          gap,
          detail(
            'Что изменилось',
            'Обновлено подтверждение эндокринолога. Доза 50 мкг, время 08:00 и условие «натощак» сохранены.',
          ),
          gap,
          Text(
            'Предыдущая версия и журнал приёма останутся в истории. Решение демонстрационное.',
            style: tx(14, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Принять версию ${data.version + 1}',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-med-accept'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) data.acceptDecision();
  }

  Widget detail(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: tx(14, weight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(body, style: tx(14, color: C.muted)),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 700;
        final wide = box.maxWidth >= 1000;
        final primary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tab == 0) ...[todayCard(narrow), gap, prescriptionCard()],
            if (tab == 1) reviewCard(),
            if (tab == 2) historyCard(),
          ],
        );
        final secondary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Surface(
              color: C.dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: C.lime,
                    size: 28,
                  ),
                  gap,
                  Text(
                    'Назначение —\nпод контролем врача',
                    style: tx(
                      23,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Вы отмечаете приём и сообщаете об изменениях. Новая версия появляется после отдельного решения специалиста.',
                    style: tx(14, color: const Color(0xFFBDCEC5)),
                  ),
                ],
              ),
            ),
            gap,
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Проверка изменений',
                    style: tx(19, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(data.reviewLabel, style: tx(14, color: C.green)),
                  const SizedBox(height: 8),
                  Text(
                    data.review == MedicationReview.none
                        ? 'Новый симптом, другое лекарство или уточнение назначения можно собрать в сводку.'
                        : 'Сводка и ход проверки доступны в разделе «Изменения».',
                    style: tx(14, color: C.muted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => tab = 1),
                    child: const Text('Открыть изменения →'),
                  ),
                ],
              ),
            ),
            gap,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: detail(
                'Пример из Figma',
                'Демонстрационное назначение и события за 20 октября 2026. Данные живут до обновления страницы.',
              ),
            ),
          ],
        );
        return SingleChildScrollView(
          key: const PageStorageKey('medication-scroll'),
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
                        key: const ValueKey('med-back-plan'),
                        onPressed: widget.onPlan,
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Мой план'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Лекарства',
                          style: tx(
                            narrow ? 32 : 40,
                            weight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                        const Tag('1 назначение', green: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ваш режим, отметки и решения — в одном месте.',
                      style: tx(15, color: C.muted),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < 3; i++)
                          ChoiceChip(
                            key: ValueKey('med-tab-$i'),
                            label: Text(['Сегодня', 'Изменения', 'История'][i]),
                            selected: tab == i,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => tab = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: primary),
                          const SizedBox(width: 24),
                          SizedBox(width: 320, child: secondary),
                        ],
                      )
                    else ...[
                      primary,
                      gap,
                      secondary,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget todayCard(bool narrow) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Tag('Сегодня · 20 октября'),
            Tag(
              data.takenAt == null ? 'Ожидает отметки' : 'Приём отмечен',
              green: data.takenAt != null,
            ),
          ],
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBD9),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 29,
                color: C.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Левотироксин',
                    style: tx(narrow ? 22 : 28, weight: FontWeight.w600),
                  ),
                  Text(
                    'Текущий режим · версия ${data.version}',
                    style: tx(13, color: C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        gap,
        Surface(
          padding: 20,
          color: C.soft,
          child: Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              doseFact('ВРЕМЯ', '08:00'),
              doseFact('ДОЗА', '50 мкг'),
              doseFact('УСЛОВИЕ', 'Натощак'),
            ],
          ),
        ),
        gap,
        if (data.takenAt == null) ...[
          Text('Пока без отметки', style: tx(17, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'После приёма сохраните время в личном журнале.',
            style: tx(14, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Отметить приём',
            intake,
            key: const ValueKey('med-log'),
          ),
        ] else ...[
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: C.green, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Принято в ${data.takenAt} · 50 мкг',
                  style: tx(18, weight: FontWeight.w600, color: C.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Следующий приём по демо-схеме — завтра, 08:00.',
            style: tx(14, color: C.muted),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                key: const ValueKey('med-edit-time'),
                onPressed: intake,
                child: const Text('Исправить время'),
              ),
              TextButton(
                key: const ValueKey('med-undo'),
                onPressed: undo,
                child: const Text('Отменить отметку'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('med-change'),
          onPressed: () {
            if (data.review == MedicationReview.waiting ||
                data.review == MedicationReview.decision) {
              setState(() => tab = 1);
            } else {
              change();
            }
          },
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
          child: Text(
            data.review == MedicationReview.waiting ||
                    data.review == MedicationReview.decision
                ? 'Посмотреть проверку'
                : 'Что-то изменилось',
          ),
        ),
      ],
    ),
  );

  Widget doseFact(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: tx(10, color: C.muted, weight: FontWeight.w500),
      ),
      const SizedBox(height: 5),
      Text(value, style: tx(22, weight: FontWeight.w600)),
    ],
  );

  Widget prescriptionCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Источник назначения', style: tx(21, weight: FontWeight.w600)),
        gap,
        detail(
          'Эндокринолог · демо',
          'Версия ${data.version} · подтверждение ${data.version == 1 ? '14 августа' : '20 октября'} 2026',
        ),
        const SizedBox(height: 14),
        Text(
          'Отметка приёма и ваше сообщение не меняют дозировку.',
          style: tx(14, color: C.muted),
        ),
        TextButton(
          onPressed: () => setState(() => tab = 2),
          child: const Text('Назначения и история версий →'),
        ),
      ],
    ),
  );

  Widget reviewCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(
            data.reviewLabel,
            green: data.review == MedicationReview.accepted,
          ),
        ),
        gap,
        Text(switch (data.review) {
          MedicationReview.none => 'Что-то изменилось?',
          MedicationReview.ready => 'Сводка готова к передаче',
          MedicationReview.waiting => 'Ожидаем решение специалиста',
          MedicationReview.decision => 'Решение готово к просмотру',
          MedicationReview.accepted => 'Новая версия сохранена',
        }, style: tx(25, weight: FontWeight.w600)),
        gap,
        if (data.review == MedicationReview.none) ...[
          Text(
            'Запишите, что произошло: изменение самочувствия, новое назначение или другой препарат. Сначала вы увидите подготовленную сводку.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Сообщить об изменении',
            change,
            key: const ValueKey('med-new-change'),
          ),
        ] else ...[
          detail('Ваше сообщение · ${data.changeKind}', data.changeText),
          gap,
          Surface(
            padding: 18,
            color: C.soft,
            child: detail(
              'Текущее назначение · v${data.version}',
              'Левотироксин · 50 мкг · 08:00 · натощак.',
            ),
          ),
          gap,
          if (data.review == MedicationReview.ready) ...[
            detail(
              'Передача не подтверждена',
              'Получатель и канал ещё не подтверждены. Срок ответа не установлен.',
            ),
            gap,
            PrimaryButton(
              'Проверить передачу',
              send,
              key: const ValueKey('med-send'),
            ),
            TextButton(
              key: const ValueKey('med-edit-change'),
              onPressed: change,
              child: const Text('Редактировать сводку'),
            ),
          ],
          if (data.review == MedicationReview.waiting) ...[
            detail(
              'Эндокринолог · тестовый получатель',
              'Кабинет специалиста · передача смоделирована. Реальной отправки нет, срок ответа не установлен.',
            ),
            gap,
            OutlinedButton(
              key: const ValueKey('med-simulate-decision'),
              onPressed: decision,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Демо: получить решение'),
              ),
            ),
          ],
          if (data.review == MedicationReview.decision) ...[
            Surface(
              padding: 18,
              color: const Color(0xFFEAFBD9),
              child: detail(
                'Версия ${data.version + 1} · эндокринолог (демо)',
                'Доза, время и условие сохранены. Причина: повторное подтверждение текущей схемы. Предыдущая версия остаётся действующей до вашего подтверждения.',
              ),
            ),
            gap,
            PrimaryButton(
              'Открыть новую версию',
              accept,
              key: const ValueKey('med-accept'),
            ),
          ],
          if (data.review == MedicationReview.accepted) ...[
            detail(
              'Версия ${data.version} принята вами',
              'Демонстрационное подтверждение от 20 октября. Предыдущая версия и отметки сохранены.',
            ),
            gap,
            PrimaryButton(
              'К сегодняшнему приёму',
              () => setState(() => tab = 0),
            ),
            TextButton(
              key: const ValueKey('med-new-change'),
              onPressed: change,
              child: const Text('Сообщить о новом изменении'),
            ),
          ],
        ],
      ],
    ),
  );

  Widget historyCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('История', style: tx(25, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Назначения, ваши отметки и проверка изменений хранятся раздельно.',
          style: tx(14, color: C.muted),
        ),
        gap,
        historyGroup('Версии назначения', data.versions),
        gap,
        historyGroup('Журнал приёма', data.intakeHistory),
        gap,
        historyGroup('Изменения и решения', data.reviewHistory),
      ],
    ),
  );

  Widget historyGroup(String title, List<String> entries) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: tx(18, weight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        Text('Пока нет событий', style: tx(14, color: C.muted)),
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Surface(
            padding: 16,
            color: C.soft,
            child: Text(entry, style: tx(14)),
          ),
        ),
    ],
  );
}
