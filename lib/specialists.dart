part of 'main.dart';

/// Catalog examples share Anna's published profile and live demo schedule.
/// Other providers never use Anna's booking or patient-data permissions.
class SpecialistOption {
  const SpecialistOption({
    required this.id,
    required this.name,
    required this.specialty,
    required this.topics,
    required this.years,
    required this.city,
    required this.about,
    required this.onlinePrice,
    this.clinicPrice,
  });
  final String id, name, specialty, city, about;
  final List<String> topics;
  final int years, onlinePrice;
  final int? clinicPrice;
  int price(String format) =>
      format == 'В клинике' ? (clinicPrice ?? onlinePrice) : onlinePrice;
  String get formats => clinicPrice == null ? 'Онлайн' : 'Онлайн · в клинике';
}

class SpecialistsDirectory extends StatefulWidget {
  const SpecialistsDirectory({
    required this.profile,
    required this.schedule,
    required this.favorites,
    required this.onFavorite,
    required this.onOpenAnna,
    super.key,
  });
  final ExpertWorkProfile profile;
  final AppointmentSchedule schedule;
  final Set<String> favorites;
  final void Function(String, bool) onFavorite;
  final ValueChanged<bool?> onOpenAnna;
  @override
  State<SpecialistsDirectory> createState() => _SpecialistsDirectoryState();
}

class _SpecialistsDirectoryState extends State<SpecialistsDirectory> {
  final search = TextEditingController();
  String format = 'Любой формат', sort = 'По имени';
  int maxPrice = 0, minYears = 0;
  bool onlySaved = false, availableOnly = false;
  final compared = <String>{};
  List<SpecialistOption> get options {
    final p = widget.profile.published;
    return [
      SpecialistOption(
        id: 'anna',
        name: 'Анна Волкова',
        specialty: p.specialty,
        topics: p.topicList,
        years: p.years,
        city: p.city,
        about: p.headline,
        onlinePrice: 3000,
        clinicPrice: 4200,
      ),
      const SpecialistOption(
        id: 'ilya',
        name: 'Илья Миронов',
        specialty: 'Терапевт · сомнология',
        topics: ['Сон', 'Режим дня', 'Восстановление'],
        years: 10,
        city: 'Москва',
        onlinePrice: 3500,
        about: 'Обсудить сон и привычный режим дня',
      ),
    ];
  }

  Appointment? nextSlot(SpecialistOption option) {
    if (option.id != 'anna') return null;
    final online = format != 'В клинике';
    for (var day = 0; day < 5; day++) {
      for (final time in widget.schedule.available(day, online)) {
        final slot = Appointment(day, time, online);
        final current = widget.schedule.current;
        if (current == null || !widget.schedule.same(current, slot)) {
          return slot;
        }
      }
    }
    return null;
  }

  String availability(SpecialistOption option) {
    if (option.id != 'anna') return 'Расписание не подключено';
    final slot = nextSlot(option);
    return slot == null
        ? 'Нет доступного времени'
        : '${slot.date} · ${slot.time}';
  }

  String money(int n) =>
      '${n ~/ 1000} ${(n % 1000).toString().padLeft(3, '0')} ₽';
  List<SpecialistOption> get results {
    final words = search.text
        .toLowerCase()
        .replaceAll('ё', 'е')
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty);
    final found = options.where((p) {
      final haystack =
          '${p.name} ${p.specialty} ${p.topics.join(' ')} ${p.city}'
              .toLowerCase()
              .replaceAll('ё', 'е');
      return words.every(haystack.contains) &&
          (format != 'В клинике' || p.clinicPrice != null) &&
          (maxPrice == 0 || p.price(format) <= maxPrice) &&
          p.years >= minYears &&
          (!onlySaved || widget.favorites.contains(p.id)) &&
          (!availableOnly || nextSlot(p) != null);
    }).toList();
    found.sort(
      (a, b) => switch (sort) {
        'Сначала дешевле' => a.price(format).compareTo(b.price(format)),
        'По опыту' => b.years.compareTo(a.years),
        _ => a.name.compareTo(b.name),
      },
    );
    return found;
  }

  void reset() => setState(() {
    search.clear();
    format = 'Любой формат';
    maxPrice = 0;
    minYears = 0;
    availableOnly = false;
    onlySaved = false;
  });
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> panel(
    String title,
    Widget Function(BuildContext, StateSetter) content,
  ) => showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => Dialog(
        backgroundColor: C.canvas,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(ctx).height - 48,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: tx(24, weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                content(ctx, update),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void openOption(SpecialistOption p) {
    if (p.id == 'anna') {
      widget.onOpenAnna(format == 'Любой формат' ? null : format == 'Онлайн');
      return;
    }
    panel(
      p.name,
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.specialty, style: tx(16, color: C.green)),
          const SizedBox(height: 16),
          Text('Демонстрационный профиль', style: tx(12, color: C.muted)),
          const SizedBox(height: 8),
          Text(p.about, style: tx(22, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.topics.map((t) => Tag(t)).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Опыт: ${p.years} лет\nГород: ${p.city}\nФормат: ${p.formats}\nКонсультация: ${money(p.onlinePrice)}',
            style: tx(15),
          ),
          const SizedBox(height: 20),
          Surface(
            color: const Color(0xFFEAF2EC),
            padding: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расписание пока не подключено',
                  style: tx(17, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Сохраните профиль, чтобы вернуться к нему. Запись в этом прототипе доступна у Анны Волковой.',
                  style: tx(14, color: C.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            widget.favorites.contains(p.id)
                ? 'Убрать из избранного'
                : 'Сохранить специалиста',
            () {
              widget.onFavorite(p.id, !widget.favorites.contains(p.id));
              update(() {});
            },
            key: const ValueKey('directory-detail-save'),
          ),
        ],
      ),
    );
  }

  void compare() => panel('Сравнение специалистов', (ctx, update) {
    final selected = options.where((p) => compared.contains(p.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Сопоставьте темы и условия консультации. Все данные — примеры для тестирования.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            final cards = selected
                .map(
                  (p) => Surface(
                    padding: 18,
                    key: ValueKey('comparison-${p.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(p.name, style: tx(21, weight: FontWeight.w600)),
                        const SizedBox(height: 18),
                        compareField('Специализация', p.specialty),
                        compareField('Темы', p.topics.join(' · ')),
                        compareField('Опыт', '${p.years} лет'),
                        compareField('Город', p.city),
                        compareField('Формат', p.formats),
                        compareField('Онлайн', money(p.onlinePrice)),
                        compareField(
                          'В клинике',
                          p.clinicPrice == null
                              ? 'Недоступно'
                              : money(p.clinicPrice!),
                        ),
                        compareField(
                          'Ближайшее время · ${format == 'В клинике' ? 'в клинике' : 'онлайн'}',
                          availability(p),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton('Открыть профиль', () {
                          Navigator.pop(ctx);
                          openOption(p);
                        }),
                      ],
                    ),
                  ),
                )
                .toList();
            return box.maxWidth >= 580
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards.first),
                      const SizedBox(width: 16),
                      Expanded(child: cards.last),
                    ],
                  )
                : Column(
                    children: [
                      for (final c in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: c,
                        ),
                    ],
                  );
          },
        ),
      ],
    );
  });
  Widget compareField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tx(11, color: C.muted)),
        const SizedBox(height: 3),
        Text(value, style: tx(14)),
      ],
    ),
  );

  Widget select<T>(
    String label,
    String key,
    T value,
    Map<T, String> values,
    ValueChanged<T> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$key-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: C.canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      style: tx(13),
      items: values.entries
          .map(
            (e) => DropdownMenuItem<T>(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) changed(v);
      },
    ),
  );
  Widget filters(void Function(VoidCallback) change) => Material(
    color: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Фильтры', style: tx(20, weight: FontWeight.w600)),
        const SizedBox(height: 20),
        select('Формат', 'directory-format', format, {
          'Любой формат': 'Любой формат',
          'Онлайн': 'Онлайн',
          'В клинике': 'В клинике',
        }, (v) => change(() => format = v)),
        select('Стоимость', 'directory-price', maxPrice, {
          0: 'Любая стоимость',
          3000: 'До 3 000 ₽',
          4000: 'До 4 000 ₽',
          5000: 'До 5 000 ₽',
        }, (v) => change(() => maxPrice = v)),
        select('Опыт работы', 'directory-years', minYears, {
          0: 'Любой опыт',
          5: 'От 5 лет',
          10: 'От 10 лет',
          15: 'От 15 лет',
        }, (v) => change(() => minYears = v)),
        CheckboxListTile(
          key: const ValueKey('directory-available'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text('Есть время для записи', style: tx(13)),
          value: availableOnly,
          onChanged: (v) => change(() => availableOnly = v!),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => change(() {
            format = 'Любой формат';
            maxPrice = 0;
            minYears = 0;
            availableOnly = false;
          }),
          child: const Text('Сбросить фильтры'),
        ),
      ],
    ),
  );
  void mobileFilters() => panel(
    'Условия консультации',
    (ctx, update) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters((fn) {
          setState(fn);
          update(() {});
        }),
        const SizedBox(height: 16),
        PrimaryButton(
          'Показать результаты · ${results.length}',
          () => Navigator.pop(ctx),
          key: const ValueKey('directory-apply-filters'),
        ),
      ],
    ),
  );

  Widget card(SpecialistOption p, bool narrow) => Surface(
    key: ValueKey('directory-card-${p.id}'),
    padding: narrow ? 18 : 24,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: narrow ? 64 : 92,
                height: narrow ? 80 : 112,
                child: p.id == 'anna'
                    ? Image.asset(
                        'assets/anna-demo.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : ColoredBox(
                        color: const Color(0xFFDDE8E1),
                        child: Center(
                          child: Text(
                            'ИМ',
                            style: tx(
                              narrow ? 22 : 30,
                              color: C.dark,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(width: narrow ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: tx(narrow ? 19 : 24, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(p.specialty, style: tx(14, color: C.green)),
                  const SizedBox(height: 8),
                  Text(
                    '${p.years} лет опыта · ${p.city}',
                    style: tx(12, color: C.muted),
                  ),
                  if (!narrow) ...[
                    const SizedBox(height: 8),
                    Text(p.formats, style: tx(12)),
                  ],
                ],
              ),
            ),
            IconButton(
              key: ValueKey('directory-save-${p.id}'),
              tooltip: widget.favorites.contains(p.id)
                  ? 'Убрать ${p.name} из избранного'
                  : 'Сохранить ${p.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              onPressed: () =>
                  widget.onFavorite(p.id, !widget.favorites.contains(p.id)),
              icon: Icon(
                widget.favorites.contains(p.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 21,
                color: widget.favorites.contains(p.id) ? C.green : C.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.canvas,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'С ЧЕМ МОЖНО ОБРАТИТЬСЯ',
                style: tx(10, weight: FontWeight.w600, color: C.muted),
              ),
              const SizedBox(height: 6),
              Text(p.topics.join(' · '), style: tx(14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.id == 'anna' ? 'Ближайшее время · Иркутск' : 'Доступность',
                  style: tx(11, color: C.muted),
                ),
                Text(availability(p), style: tx(14, weight: FontWeight.w500)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format == 'В клинике' ? 'В клинике' : 'Онлайн',
                  style: tx(11, color: C.muted),
                ),
                Text(
                  money(p.price(format)),
                  style: tx(19, weight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: narrow ? double.infinity : 220,
              child: PrimaryButton(
                'Открыть профиль',
                () => openOption(p),
                key: ValueKey('directory-open-${p.id}'),
              ),
            ),
            FilterChip(
              key: ValueKey('directory-compare-${p.id}'),
              label: Text(compared.contains(p.id) ? 'В сравнении' : 'Сравнить'),
              selected: compared.contains(p.id),
              onSelected: (v) => setState(() {
                if (v) {
                  compared.add(p.id);
                } else {
                  compared.remove(p.id);
                }
              }),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final narrow = box.maxWidth < 700, desktop = box.maxWidth >= 1000;
      final found = results;
      return Material(
        color: C.canvas,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('specialists-scroll'),
                padding: EdgeInsets.fromLTRB(
                  narrow ? 18 : 36,
                  24,
                  narrow ? 18 : 36,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1128),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Surface(
                          color: C.dark,
                          padding: narrow ? 24 : 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ЛЮДИ, КОТОРЫМ МОЖНО ЗАДАТЬ ВОПРОС',
                                style: tx(
                                  10,
                                  color: C.lime,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Специалисты',
                                style: tx(
                                  narrow ? 32 : 42,
                                  color: Colors.white,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Найдите специалиста под свой запрос.\nСравните темы, опыт и условия консультации.',
                                style: tx(15, color: const Color(0xFFCEDCD4)),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Демо-каталог · 2 профиля · расписание октября 2026',
                                style: tx(11, color: const Color(0xFFCEDCD4)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          key: const ValueKey('directory-search'),
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: narrow
                                ? 'Имя, тема или город'
                                : 'Имя специалиста, тема консультации или город',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Очистить поиск',
                                    onPressed: () => setState(search.clear),
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: C.line),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Все специалисты'),
                              selected: !onlySaved,
                              onSelected: (_) =>
                                  setState(() => onlySaved = false),
                            ),
                            ChoiceChip(
                              key: const ValueKey('directory-saved'),
                              label: Text(
                                'Избранное · ${widget.favorites.length}',
                              ),
                              selected: onlySaved,
                              onSelected: (_) =>
                                  setState(() => onlySaved = true),
                            ),
                            if (!desktop)
                              ActionChip(
                                key: const ValueKey('directory-filters'),
                                avatar: const Icon(Icons.tune, size: 17),
                                label: const Text('Фильтры'),
                                onPressed: mobileFilters,
                              ),
                          ],
                        ),
                        if (!desktop &&
                            (format != 'Любой формат' ||
                                maxPrice != 0 ||
                                minYears != 0 ||
                                availableOnly))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              [
                                format,
                                if (maxPrice != 0) 'до ${money(maxPrice)}',
                                if (minYears != 0) 'от $minYears лет',
                                if (availableOnly) 'есть время',
                              ].join(' · '),
                              style: tx(12, color: C.green),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (desktop) ...[
                              SizedBox(
                                width: 240,
                                child: Surface(
                                  padding: 20,
                                  child: filters(setState),
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Найдено: ${found.length}',
                                        key: const ValueKey('directory-count'),
                                        style: tx(17, weight: FontWeight.w600),
                                      ),
                                      DropdownButton<String>(
                                        key: const ValueKey('directory-sort'),
                                        value: sort,
                                        underline: const SizedBox.shrink(),
                                        style: tx(12, color: C.muted),
                                        items:
                                            [
                                                  'По имени',
                                                  'Сначала дешевле',
                                                  'По опыту',
                                                ]
                                                .map(
                                                  (s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(s),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (s) =>
                                            setState(() => sort = s!),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (found.isEmpty)
                                    Surface(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Icon(
                                            Icons.search_off_rounded,
                                            size: 44,
                                            color: C.green,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Подходящих специалистов нет',
                                            style: tx(
                                              23,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            onlySaved &&
                                                    widget.favorites.isEmpty
                                                ? 'Сохраните интересные профили с помощью сердечка.'
                                                : 'Попробуйте другую тему или расширьте условия поиска.',
                                            style: tx(14, color: C.muted),
                                          ),
                                          const SizedBox(height: 20),
                                          PrimaryButton(
                                            'Показать всех специалистов',
                                            reset,
                                            key: const ValueKey(
                                              'directory-reset',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  for (final p in found)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: card(p, narrow),
                                    ),
                                  Text(
                                    'Профили и цены приведены для тестирования. Избранное и выбранные условия сохраняются до перезагрузки страницы.',
                                    style: tx(11, color: C.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (compared.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 18 : 36,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: C.line)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1128),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'В сравнении: ${compared.length} из 2',
                          style: tx(14, weight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () => setState(compared.clear),
                          child: const Text('Очистить'),
                        ),
                        SizedBox(
                          width: narrow ? double.infinity : 250,
                          child: PrimaryButton(
                            compared.length == 2
                                ? 'Сравнить специалистов'
                                : 'Выберите ещё специалиста',
                            compared.length == 2 ? compare : null,
                            key: const ValueKey('directory-compare-open'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
