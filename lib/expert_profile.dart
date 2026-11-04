part of 'main.dart';

class ProfessionalDetails {
  const ProfessionalDetails({
    this.specialty = 'Терапевт',
    this.years = 12,
    this.headline = 'Помогу увидеть общую картину',
    this.about =
        '«Важно не только посмотреть на цифры в анализах, но и услышать, как вы себя чувствуете. На приёме мы спокойно разберём ваши вопросы и составим понятный план дальнейших действий».',
    this.topics =
        'Усталость и энергия\nРазбор анализов\nСон и восстановление\nПрофилактика',
    this.education =
        '2014 · Лечебное дело\n2016 · Ординатура по терапии\n2024 · Повышение квалификации: профилактика и персональный подход',
    this.city = 'Иркутск',
    this.languages = '',
  });
  final String specialty, headline, about, topics, education, city, languages;
  final int years;
  List<String> get topicList => topics
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  Map<String, bool> get sections => {
    'Специализация': specialty.trim().length >= 3,
    'Стаж': years >= 0 && years <= 70,
    'Заголовок карточки': headline.trim().length >= 3,
    'О себе': about.trim().length >= 20,
    'Темы консультаций': topicList.isNotEmpty,
    'Образование': education.trim().length >= 10,
    'Город': city.trim().isNotEmpty,
    'Языки': languages.trim().isNotEmpty,
  };
  int get filled => sections.values.where((v) => v).length;
  int get completeness => (filled / sections.length * 100).round();
}

class ExpertWorkProfile extends ChangeNotifier {
  ProfessionalDetails _draft = const ProfessionalDetails();
  ProfessionalDetails _published = const ProfessionalDetails();
  ProfessionalDetails get draft => _draft;
  ProfessionalDetails get published => _published;
  int revision = 1, publishedRevision = 1, version = 1;
  bool get dirty => revision != publishedRevision;
  bool _acceptingRequests = true;
  int _responseDays = 2;
  bool get acceptingRequests => _acceptingRequests;
  int get responseDays => _responseDays;
  final _history = <String>['Версия 1 · исходная демонстрационная карточка'];
  List<String> get history => List.unmodifiable(_history);
  String? validate(ProfessionalDetails p, {bool publishing = false}) {
    if (p.specialty.trim().length < 3 || p.specialty.length > 60) {
      return 'Специализация: от 3 до 60 символов';
    }
    if (p.years < 0 || p.years > 70) return 'Стаж: целое число от 0 до 70';
    if (p.headline.trim().length < 3 || p.headline.length > 100) {
      return 'Заголовок: от 3 до 100 символов';
    }
    if (p.about.length > 2000 ||
        p.education.length > 2000 ||
        p.topics.length > 1000 ||
        p.city.length > 80 ||
        p.languages.length > 100) {
      return 'Сократите текст до указанного ограничения';
    }
    if (p.topicList.length > 8 || p.topicList.any((s) => s.length > 80)) {
      return 'Не более 8 тем, до 80 символов каждая';
    }
    if (publishing &&
        (p.about.trim().length < 20 ||
            p.education.trim().length < 10 ||
            p.topicList.isEmpty)) {
      return 'Перед публикацией заполните описание, темы и образование';
    }
    return null;
  }

  bool save(ProfessionalDetails p, int expectedRevision) {
    if (revision != expectedRevision || validate(p) != null) return false;
    _draft = p;
    revision++;
    notifyListeners();
    return true;
  }

  bool publish(int expectedRevision) {
    if (!dirty ||
        revision != expectedRevision ||
        validate(draft, publishing: true) != null) {
      return false;
    }
    _published = draft;
    publishedRevision = revision;
    version++;
    _history.insert(0, 'Версия $version · карточка обновлена в демо-каталоге');
    notifyListeners();
    return true;
  }

  bool discard(int expectedRevision) {
    if (!dirty || revision != expectedRevision) return false;
    _draft = published;
    revision++;
    publishedRevision = revision;
    notifyListeners();
    return true;
  }

  bool configure({required bool accepting, required int days}) {
    if (days < 1 || days > 7) return false;
    _acceptingRequests = accepting;
    _responseDays = days;
    notifyListeners();
    return true;
  }
}

extension _ExpertWorkProfileViews on ExpertWorkspaceState {
  Widget workProfilePanel() {
    final p = widget.workProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          color: const Color(0xFFDDF7E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/anna-demo.png',
                      width: 64,
                      height: 76,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Анна Волкова',
                          style: tx(25, weight: FontWeight.w600),
                        ),
                        Text(
                          'EXPERT-ANNA · демо-профиль',
                          style: tx(12, color: C.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Заполнение профиля · ${p.draft.completeness}%',
                style: tx(18, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: p.draft.filled / p.draft.sections.length,
                backgroundColor: Colors.white,
                color: C.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 10),
              Text(
                '${p.draft.filled} из ${p.draft.sections.length} разделов заполнено. Это полнота информации, а не проверка квалификации.',
                style: tx(12, color: C.muted),
              ),
              if (p.draft.filled < p.draft.sections.length)
                TextButton(
                  onPressed: editWorkProfile,
                  child: Text(
                    'Следующий шаг: ${p.draft.sections.entries.firstWhere((e) => !e.value).key.toLowerCase()} →',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tab in [
              'Карточка специалиста',
              'Организация работы',
            ].indexed)
              ChoiceChip(
                key: ValueKey('profile-tab-${tab.$1}'),
                label: Text(tab.$2),
                selected: workProfileTab == tab.$1,
                onSelected: (_) =>
                    updatePatients(() => workProfileTab = tab.$1),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (workProfileTab == 0)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tag(
                      p.dirty
                          ? 'Есть изменения в черновике'
                          : 'Карточка опубликована',
                      green: !p.dirty,
                    ),
                    Tag('Публичная версия ${p.version}'),
                  ],
                ),
                const SizedBox(height: 18),
                ProfessionalPreview(details: p.draft),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  key: const ValueKey('work-profile-edit'),
                  onPressed: editWorkProfile,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Редактировать профиль'),
                ),
                if (p.dirty) ...[
                  const SizedBox(height: 12),
                  PrimaryButton(
                    'Проверить изменения',
                    reviewWorkProfile,
                    key: const ValueKey('work-profile-review'),
                  ),
                  TextButton(
                    key: const ValueKey('work-profile-discard'),
                    onPressed: () async {
                      final revision = p.revision;
                      final yes = await modal<bool>(
                        'Отменить изменения черновика?',
                        (ctx) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Восстановится опубликованная карточка специалиста.',
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              'Восстановить карточку',
                              () => Navigator.pop(ctx, true),
                              key: const ValueKey(
                                'work-profile-discard-confirm',
                              ),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) p.discard(revision);
                    },
                    child: const Text('Отменить изменения черновика'),
                  ),
                ],
                TextButton(
                  key: const ValueKey('work-profile-public'),
                  onPressed: widget.onPersonalBooking,
                  child: const Text('Открыть опубликованную карточку →'),
                ),
                const Divider(height: 28),
                Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    key: const ValueKey('work-profile-history'),
                    title: const Text('История публикаций'),
                    children: [
                      for (final h in p.history)
                        ListTile(title: Text(h, style: tx(13))),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          workSettings(),
      ],
    );
  }

  Future<void> editWorkProfile() => modal<void>(
    'Профессиональная информация',
    (ctx) => WorkProfileEditor(
      profile: widget.workProfile,
      onSaved: () {
        Navigator.pop(ctx);
        notify('Черновик профиля сохранён');
      },
    ),
  );

  Future<void> reviewWorkProfile() async {
    final p = widget.workProfile;
    final error = p.validate(p.draft, publishing: true);
    if (error != null) {
      notify(error);
      return;
    }
    final revision = p.revision;
    final yes = await modal<bool>(
      'Проверка карточки специалиста',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfessionalPreview(details: p.draft),
          const SizedBox(height: 20),
          Text(
            'Эта информация заменит карточку Анны Волковой в демо-каталоге. Расписание, стоимость и уже созданные записи сохранятся.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Опубликовать карточку',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('work-profile-publish'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      notify(
        p.publish(revision)
            ? 'Карточка специалиста обновлена'
            : 'Черновик изменился. Повторите проверку',
      );
    }
  }

  Widget workSettings() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Новые обращения', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Tag(
          widget.workProfile.acceptingRequests
              ? 'Принимаю запросы'
              : 'Новые запросы на паузе',
          green: widget.workProfile.acceptingRequests,
        ),
        const SizedBox(height: 12),
        Text(
          'Ориентир ответа: ${widget.workProfile.responseDays} дн.\nНастройки видны пациенту при подготовке вопроса. Точный срок согласуется отдельно.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          key: const ValueKey('work-settings-edit'),
          onPressed: editWorkSettings,
          child: const Text('Настроить приём запросов'),
        ),
        const Divider(height: 32),
        Text(
          'Приёмы и доступное время',
          style: tx(20, weight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'Иркутск · UTC+8\nОнлайн и в клинике · 45 минут\nОнлайн — 3 000 ₽, в клинике — 4 200 ₽',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => navigate(4),
          child: const Text('Открыть расписание'),
        ),
        Text(
          'Пауза новых запросов не отменяет приёмы и работу с уже полученными обращениями.',
          style: tx(12, color: C.muted),
        ),
      ],
    ),
  );

  Future<void> editWorkSettings() async {
    final p = widget.workProfile;
    var accepting = p.acceptingRequests;
    var days = p.responseDays;
    final yes = await modal<bool>(
      'Приём запросов',
      (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const ValueKey('work-accepting'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Принимать новые запросы'),
                value: accepting,
                onChanged: (v) => refresh(() => accepting = v),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ориентир ответа', style: tx(16, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [1, 2, 3, 7])
                  ChoiceChip(
                    key: ValueKey('work-response-$d'),
                    label: Text('$d дн.'),
                    selected: days == d,
                    onSelected: (_) => refresh(() => days = d),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Сохранение изменит возможность передавать новые вопросы в личном кабинете. Уже переданные вопросы останутся доступны.',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Сохранить настройки',
              () => Navigator.pop(ctx, true),
              key: const ValueKey('work-settings-save'),
            ),
          ],
        ),
      ),
    );
    if (yes == true) p.configure(accepting: accepting, days: days);
  }

  Widget workProfileContext() => Surface(
    color: const Color(0xFFDDF7E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ВИДИМОСТЬ ИНФОРМАЦИИ',
          style: tx(11, color: C.green, weight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text('Сначала проверка', style: tx(22, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(
          'Черновик виден вам. Пациент увидит профессиональную информацию после публикации карточки.',
          style: tx(14, color: C.muted),
        ),
        const Divider(height: 28),
        Text(
          'Демонстрационный профиль',
          style: tx(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Имя и фото закреплены за тестовой Анной Волковой. Проверка квалификации и подключение реальных документов пока не реализованы.',
          style: tx(13, color: C.muted),
        ),
        TextButton(
          onPressed: widget.onPersonalBooking,
          child: const Text('Посмотреть со стороны пациента →'),
        ),
      ],
    ),
  );
}

class ProfessionalPreview extends StatelessWidget {
  const ProfessionalPreview({required this.details, super.key});
  final ProfessionalDetails details;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${details.specialty} · стаж ${details.years} лет',
        style: tx(20, weight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        [
          details.city,
          details.languages,
        ].where((s) => s.isNotEmpty).join(' · '),
        style: tx(13, color: C.muted),
      ),
      const SizedBox(height: 20),
      Text(details.headline, style: tx(22, weight: FontWeight.w600)),
      const SizedBox(height: 12),
      Text(
        details.about.isEmpty ? 'Описание ещё не заполнено' : details.about,
        style: tx(14, color: C.muted),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final t in details.topicList) Tag(t)],
      ),
      const Divider(height: 28),
      Text('Образование и практика', style: tx(17, weight: FontWeight.w600)),
      const SizedBox(height: 10),
      Text(
        details.education.isEmpty
            ? 'Добавьте сведения об образовании'
            : details.education,
        style: tx(14),
      ),
    ],
  );
}

class WorkProfileEditor extends StatefulWidget {
  const WorkProfileEditor({
    required this.profile,
    required this.onSaved,
    super.key,
  });
  final ExpertWorkProfile profile;
  final VoidCallback onSaved;
  @override
  State<WorkProfileEditor> createState() => _WorkProfileEditorState();
}

class _WorkProfileEditorState extends State<WorkProfileEditor> {
  late final revision = widget.profile.revision;
  late final p = widget.profile.draft;
  late final inputs = [
    p.specialty,
    '${p.years}',
    p.headline,
    p.about,
    p.topics,
    p.education,
    p.city,
    p.languages,
  ].map((s) => TextEditingController(text: s)).toList();
  String? error;
  @override
  void dispose() {
    for (final c in inputs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Анна Волкова · редактирование черновика',
        style: tx(13, color: C.muted),
      ),
      const SizedBox(height: 16),
      for (final f in [
        'Специализация',
        'Стаж, лет',
        'Заголовок карточки',
        'О себе',
        'Темы — каждая с новой строки',
        'Образование и практика',
        'Город',
        'Языки консультаций',
      ].indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            key: ValueKey('profile-field-${f.$1}'),
            controller: inputs[f.$1],
            minLines: f.$1 >= 3 && f.$1 <= 5 ? 3 : 1,
            maxLines: f.$1 >= 3 && f.$1 <= 5 ? 7 : 2,
            maxLength: [60, 2, 100, 2000, 1000, 2000, 80, 100][f.$1],
            decoration: InputDecoration(
              labelText: f.$2,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      if (error != null)
        Text(error!, style: tx(13, color: Colors.red.shade800)),
      const SizedBox(height: 16),
      PrimaryButton('Сохранить черновик', () {
        final value = ProfessionalDetails(
          specialty: inputs[0].text.trim(),
          years: int.tryParse(inputs[1].text) ?? -1,
          headline: inputs[2].text.trim(),
          about: inputs[3].text.trim(),
          topics: inputs[4].text.trim(),
          education: inputs[5].text.trim(),
          city: inputs[6].text.trim(),
          languages: inputs[7].text.trim(),
        );
        final validation = widget.profile.validate(value);
        if (validation != null) {
          setState(() => error = validation);
          return;
        }
        if (!widget.profile.save(value, revision)) {
          setState(
            () => error = 'Черновик изменился. Откройте редактор заново.',
          );
          return;
        }
        widget.onSaved();
      }, key: const ValueKey('work-profile-save')),
    ],
  );
}
