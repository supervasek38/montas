part of 'main.dart';

enum FamilyScope { visits, results, plan, tasks }

String familyScopeLabel(FamilyScope scope) => switch (scope) {
  FamilyScope.visits => 'Записи и статус визитов',
  FamilyScope.results => 'Результаты обследований',
  FamilyScope.plan => 'План · только просмотр',
  FamilyScope.tasks => 'Поручения по заботе',
};

class FamilyAccess {
  FamilyAccess(Set<FamilyScope> scopes, {this.days = 14})
    : scopes = Set.of(scopes);
  final Set<FamilyScope> scopes;
  final int days;
  bool revoked = false;
  static final demoDate = DateTime(2026, 10, 20);
  bool allows(FamilyScope scope) => !revoked && scopes.contains(scope);
  String get until {
    final date = demoDate.add(Duration(days: days));
    return '${date.day} ${date.month == 10 ? 'октября' : 'ноября'} 2026, 23:59 · Иркутск';
  }
}

class FamilyPerson {
  FamilyPerson(this.id, this.name, this.relation, {this.incoming});
  final int id;
  final String name, relation;
  FamilyAccess? incoming, outgoing, pending;
  bool visitConfirmed = false;
  final events = <String>[];
  bool can(FamilyScope scope) => incoming?.allows(scope) ?? false;
  bool get canConfirmVisit => can(FamilyScope.visits) && can(FamilyScope.tasks);
}

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => FamilyScreenState();
}

class FamilyScreenState extends State<FamilyScreen> {
  final people = <FamilyPerson>[
    FamilyPerson(
      1,
      'Елена',
      'Мама',
      incoming: FamilyAccess({FamilyScope.visits, FamilyScope.tasks}),
    ),
    FamilyPerson(2, 'Алексей', 'Сын · 15 лет'),
  ];
  FamilyPerson? selected;
  int tab = 0;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void event(FamilyPerson p, String value) => p.events.insert(0, value);
  void select(FamilyPerson? p) {
    setState(() {
      selected = p;
      tab = 0;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void openAccess(FamilyPerson? person) {
    select(person);
    if (person != null) setState(() => tab = 1);
  }

  Future<T?> modal<T>(
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
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(ctx).height - 64,
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

  Future<void> addPerson() async {
    final name = TextEditingController();
    var relation = 'Родственник';
    final value = await modal<String>(
      'Добавить близкого',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Создадим демонстрационный профиль. Приглашения и сообщения не отправляются.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('relative-name'),
              controller: name,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => update(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: relation,
              decoration: const InputDecoration(
                labelText: 'Кем приходится',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final r in [
                  'Родственник',
                  'Мама',
                  'Папа',
                  'Партнёр',
                  'Ребёнок',
                ])
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => relation = v!,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Добавить профиль',
              name.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, name.text.trim()),
              key: const ValueKey('confirm-relative'),
            ),
          ],
        ),
      ),
    );
    // The dialog's text field is disposed after its closing transition.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    if (value != null && mounted) {
      setState(() {
        people.add(FamilyPerson(people.length + 1, value, relation));
      });
    }
  }

  Future<void> accessForm(FamilyPerson p, {required bool outgoing}) async {
    if (!outgoing && p.pending != null) return;
    final previous = outgoing ? p.outgoing : p.incoming;
    final scopes = <FamilyScope>{
      if (previous != null && !previous.revoked)
        ...previous.scopes
      else ...{
        FamilyScope.visits,
        FamilyScope.tasks,
      },
    };
    var days = 14;
    final access = await modal<FamilyAccess>(
      outgoing ? 'Открыть мои данные' : 'Запросить доступ',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              outgoing ? 'Вы → ${p.name}' : '${p.name} → вы',
              style: tx(21, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              outgoing
                  ? 'Вы разрешаете выбранному человеку видеть только отмеченные разделы ваших данных.'
                  : 'Запрос получит ${p.name}. До решения владельца текущий доступ не меняется.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 14),
            for (final scope in FamilyScope.values)
              CheckboxListTile(
                key: ValueKey('scope-${scope.name}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: scopes.contains(scope),
                title: Text(familyScopeLabel(scope), style: tx(14)),
                onChanged: (v) => update(() {
                  if (v == true) {
                    scopes.add(scope);
                  } else {
                    scopes.remove(scope);
                  }
                }),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const ValueKey('family-duration'),
              initialValue: days,
              decoration: const InputDecoration(
                labelText: 'Срок доступа',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final d in [7, 14, 30])
                  DropdownMenuItem(value: d, child: Text('$d дней')),
              ],
              onChanged: (v) => update(() => days = v!),
            ),
            const SizedBox(height: 14),
            Text(
              'Цель: помощь с организацией заботы.\nДо ${FamilyAccess(scopes, days: days).until}.\nДемо-дата: 20 октября 2026.',
              style: tx(12, color: C.muted),
            ),
            const SizedBox(height: 12),
            Text(
              'Изменять лечение и назначения нельзя. Родство само по себе не открывает медицинскую карту.',
              style: tx(13),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Проверить разрешение',
              scopes.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, FamilyAccess(scopes, days: days)),
              key: const ValueKey('review-family-access'),
            ),
          ],
        ),
      ),
    );
    if (access == null || !mounted) return;
    final accepted = await modal<bool>(
      outgoing ? 'Подтвердить доступ?' : 'Отправить запрос?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            outgoing
                ? 'Получатель: ${p.name}\nВладелец данных: вы'
                : 'Получатель запроса и владелец данных: ${p.name}',
            style: tx(16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (final s in access.scopes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• ${familyScopeLabel(s)}', style: tx(14)),
            ),
          const SizedBox(height: 12),
          Text('До ${access.until}', style: tx(13, color: C.muted)),
          const SizedBox(height: 12),
          Text(
            outgoing
                ? 'Будет действовать именно этот набор разрешений. Предыдущее разрешение этому человеку заменится.'
                : 'Это запрос, а не выдача доступа. После согласия владельца этот набор и срок заменят прежнее разрешение. До ответа доступ не меняется.',
            style: tx(14),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            outgoing ? 'Подтвердить и открыть' : 'Отправить запрос',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-family-access'),
          ),
          const SizedBox(height: 10),
          Text(
            'Локальная демонстрация · внешней передачи данных нет.',
            style: tx(12, color: C.muted),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        if (outgoing) {
          p.outgoing = access;
          event(
            p,
            'Вы открыли свои данные: ${access.scopes.map(familyScopeLabel).join(', ')}. До ${access.until}.',
          );
        } else {
          p.pending = access;
          event(
            p,
            'Отправлен запрос владельцу. Текущие разрешения не изменились.',
          );
        }
        tab = 1;
      });
    }
  }

  Future<void> demoDecision(FamilyPerson p) async {
    final request = p.pending;
    if (request == null) return;
    final result = await modal<bool>(
      'Демо: ответ владельца',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'В реальном приложении решение принимает ${p.name} в своём аккаунте. Здесь можно проверить оба исхода.',
            style: tx(14),
          ),
          const SizedBox(height: 16),
          for (final s in request.scopes)
            Text('• ${familyScopeLabel(s)}', style: tx(14)),
          const SizedBox(height: 16),
          PrimaryButton(
            'Смоделировать согласие',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('owner-approve'),
          ),
          TextButton(
            key: const ValueKey('owner-decline'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Смоделировать отказ'),
          ),
        ],
      ),
    );
    if (result != null && mounted && p.pending == request) {
      setState(() {
        if (result) {
          p.incoming = FamilyAccess(request.scopes, days: request.days);
          event(
            p,
            'Демо: ${p.name} подтвердил(а) запрос. Доступ открыт до ${p.incoming!.until}.',
          );
        } else {
          event(
            p,
            'Демо: ${p.name} отклонил(а) запрос. Доступ остался прежним.',
          );
        }
        p.pending = null;
      });
    }
  }

  Future<void> revoke(FamilyPerson p, {required bool outgoing}) async {
    final access = outgoing ? p.outgoing : p.incoming;
    if (access == null || access.revoked) return;
    final accepted = await modal<bool>(
      outgoing ? 'Отозвать доступ к моим данным?' : 'Прекратить мой доступ?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            outgoing
                ? '${p.name} больше не сможет просматривать ваши данные и выполнять поручения по этому разрешению.'
                : 'Вы перестанете видеть открытые данные ${p.name} и выполнять связанные поручения.',
            style: tx(15),
          ),
          const SizedBox(height: 14),
          Text(
            'Профиль, история действий и запись на приём сохранятся. Уже просмотренную или сохранённую информацию нельзя забрать обратно.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            outgoing ? 'Да, отозвать доступ' : 'Да, прекратить доступ',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-family-revoke'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        access.revoked = true;
        if (!outgoing) {
          p.pending = null;
        }
        event(
          p,
          outgoing
              ? 'Вы отозвали доступ ${p.name} к своим данным.'
              : 'Вы прекратили свой доступ. Связанные поручения недоступны; ожидавший запрос отменён.',
        );
      });
    }
  }

  Future<void> visit(FamilyPerson p) async {
    if (!p.canConfirmVisit) {
      setState(() => tab = 1);
      return;
    }
    final accepted = await modal<bool>(
      'Подтвердить время визита',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${p.name} · кардиолог', style: tx(21, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('28 октября · 11:30\nДемонстрационная клиника', style: tx(16)),
          const SizedBox(height: 14),
          Text(
            'Вы подтверждаете только время. Медицинские решения и план остаются у владельца данных и специалиста.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Подтвердить время',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-family-visit'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted && p.canConfirmVisit) {
      setState(() {
        p.visitConfirmed = true;
        event(
          p,
          'Время визита подтверждено в пределах разрешённого поручения.',
        );
      });
    }
  }

  Widget avatar(String text, {double size = 52}) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFEAFBD9),
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: Text(
      text.characters.first.toUpperCase(),
      style: tx(size * .42, color: C.dark, weight: FontWeight.w600),
    ),
  );

  Widget heading(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('БЛИЗКИЕ И ЗАБОТА', style: tx(11, color: C.muted)),
      const SizedBox(height: 10),
      Text(title, style: tx(32, weight: FontWeight.w600, height: 1.15)),
      const SizedBox(height: 12),
      Text(description, style: tx(15, color: C.muted)),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      controller: scroll,
      padding: EdgeInsets.all(box.maxWidth < 600 ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selected == null) ...[
                heading(
                  'Семья и доступы',
                  'Быть рядом с близкими — помогать с их согласия и в понятных границах.',
                ),
                const SizedBox(height: 24),
                overview(box.maxWidth),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('family-back'),
                    onPressed: () => select(null),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Все близкие'),
                  ),
                ),
                const SizedBox(height: 12),
                heading(
                  selected!.name,
                  '${selected!.relation} · отдельный профиль MONTAS',
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ChoiceChip(
                        key: ValueKey('family-tab-$i'),
                        label: Text(['Обзор', 'Доступы', 'История'][i]),
                        selected: tab == i,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => tab = i),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (tab == 0)
                  profile(selected!, box.maxWidth)
                else if (tab == 1)
                  accessPanel(selected!, box.maxWidth)
                else
                  historyPanel(selected!),
              ],
              const SizedBox(height: 24),
              Text(
                'Демо-профили и разрешения. Данные остаются в браузере до перезагрузки. Реальных приглашений и передачи информации нет.',
                style: tx(12, color: C.muted),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );

  Widget overview(double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: C.dark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite_border, color: C.lime, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Забота начинается с доверия',
                    style: tx(23, weight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Каждый человек управляет своими данными. Выберите близкого, чтобы увидеть доступные задачи или запросить разрешение.',
                    style: tx(14, color: const Color(0xFFBCD5C8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Мои близкие · ${people.length}',
            style: tx(22, weight: FontWeight.w600),
          ),
          OutlinedButton.icon(
            key: const ValueKey('add-relative'),
            onPressed: addPerson,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Добавить близкого'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, b) {
          final cardWidth = b.maxWidth >= 700
              ? (b.maxWidth - 20) / 2
              : b.maxWidth;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final p in people)
                SizedBox(width: cardWidth, child: personCard(p)),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Кто видит мои данные',
              style: tx(21, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Откройте профиль близкого → «Доступы» → «Я делюсь». Вы выбираете разделы, цель и срок. Разрешение можно отозвать.',
              style: tx(14, color: C.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget personCard(FamilyPerson p) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            avatar(p.name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: tx(22, weight: FontWeight.w600)),
                  Text(p.relation, style: tx(13, color: C.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Tag(
              p.incoming != null && !p.incoming!.revoked
                  ? 'Есть доступ'
                  : 'Данные закрыты',
              green: p.incoming != null && !p.incoming!.revoked,
            ),
            if (p.pending != null) const Tag('Запрос ожидает ответа'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          p.canConfirmVisit
              ? (p.visitConfirmed
                    ? 'Поручение выполнено · время визита подтверждено'
                    : 'Поручение · подтвердить время визита')
              : 'Можно запросить доступ или поделиться своими данными.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Открыть профиль',
          () => select(p),
          key: ValueKey('family-person-${p.id}'),
        ),
      ],
    ),
  );

  Widget columns(Widget left, Widget right, double width) => width >= 900
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: left),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: right),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 20), right],
        );

  Widget profile(FamilyPerson p, double width) => columns(
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Задачи заботы', style: tx(23, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (p.id == 1 && p.canConfirmVisit) ...[
            Tag(
              p.visitConfirmed ? 'Выполнено' : 'Нужно ваше действие',
              green: p.visitConfirmed,
            ),
            const SizedBox(height: 18),
            Text(
              p.visitConfirmed
                  ? 'Время визита подтверждено'
                  : 'Подтвердить время визита',
              style: tx(21, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Кардиолог · 28 октября, 11:30\nДемонстрационная клиника',
              style: tx(15),
            ),
            const SizedBox(height: 16),
            Text(
              'Елена поручила вам согласовать время. Запись и статус визита доступны по её разрешению.',
              style: tx(13, color: C.muted),
            ),
            if (!p.visitConfirmed) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                'Посмотреть поручение',
                () => visit(p),
                key: const ValueKey('family-visit'),
              ),
            ],
          ] else ...[
            Icon(
              p.canConfirmVisit ? Icons.task_alt : Icons.lock_outline,
              size: 36,
              color: C.muted,
            ),
            const SizedBox(height: 14),
            Text(
              p.canConfirmVisit
                  ? 'Активных поручений пока нет'
                  : 'Поручения недоступны',
              style: tx(19, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              p.canConfirmVisit
                  ? 'Владелец ещё не назначил вам задачу.'
                  : 'Для помощи с визитом нужны разрешения на записи и поручения. Закрытые детали не показываются.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => tab = 1),
              child: const Text('Посмотреть доступы'),
            ),
          ],
        ],
      ),
    ),
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Доступные данные', style: tx(21, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          for (final s in [
            FamilyScope.visits,
            FamilyScope.results,
            FamilyScope.plan,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                key: ValueKey('family-data-${s.name}'),
                onPressed: () => openData(p, s),
                icon: Icon(
                  p.can(s) ? Icons.folder_open_outlined : Icons.lock_outline,
                  size: 20,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(familyScopeLabel(s)),
                ),
              ),
            ),
          Text(
            'Владелец данных: ${p.name}. Изменение лечения не входит в разрешения.',
            style: tx(12, color: C.muted),
          ),
        ],
      ),
    ),
    width,
  );

  void openData(FamilyPerson p, FamilyScope scope) {
    if (!p.can(scope)) {
      modal<void>(
        'Раздел закрыт',
        (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${familyScopeLabel(scope)} доступны только после разрешения ${p.name}.',
              style: tx(15),
            ),
            const SizedBox(height: 20),
            PrimaryButton('Перейти к доступам', () {
              Navigator.pop(ctx);
              setState(() => tab = 1);
            }),
          ],
        ),
      );
      return;
    }
    modal<void>(
      familyScopeLabel(scope),
      (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${p.name} · только разрешённый раздел',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 16),
          Text(
            scope == FamilyScope.visits && p.id == 1
                ? 'Кардиолог · 28 октября, 11:30\n${p.visitConfirmed ? 'Время подтверждено' : 'Ожидает подтверждения времени'}'
                : scope == FamilyScope.results
                ? 'В этом демо нет загруженных результатов обследований.'
                : scope == FamilyScope.plan
                ? 'В этом демо нет опубликованного плана близкого.'
                : 'Записей пока нет.',
            style: tx(16),
          ),
        ],
      ),
    );
  }

  Widget accessPanel(FamilyPerson p, double width) => columns(
    accessCard(p, outgoing: false),
    accessCard(p, outgoing: true),
    width,
  );

  Widget accessCard(FamilyPerson p, {required bool outgoing}) {
    final access = outgoing ? p.outgoing : p.incoming;
    final active = access != null && !access.revoked;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            outgoing ? 'Я делюсь' : 'Мне открыто',
            style: tx(23, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            outgoing ? 'Мои данные → ${p.name}' : '${p.name} → я',
            style: tx(15, color: C.muted),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Tag(
              active
                  ? 'Доступ действует'
                  : access?.revoked == true
                  ? 'Доступ прекращён'
                  : 'Нет разрешения',
              green: active,
            ),
          ),
          const SizedBox(height: 18),
          for (final s in FamilyScope.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    active && access.allows(s)
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                    color: active && access.allows(s) ? C.green : C.muted,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(familyScopeLabel(s), style: tx(14))),
                ],
              ),
            ),
          if (active)
            Text(
              'До ${access.until}\nЦель: помощь с организацией заботы.',
              style: tx(12, color: C.muted),
            ),
          const SizedBox(height: 20),
          if (outgoing)
            PrimaryButton(
              active ? 'Изменить разрешение' : 'Открыть мои данные',
              () => accessForm(p, outgoing: true),
              key: const ValueKey('grant-family'),
            )
          else if (p.pending == null)
            PrimaryButton(
              'Запросить доступ',
              () => accessForm(p, outgoing: false),
              key: const ValueKey('request-family'),
            )
          else ...[
            Text(
              'Ожидаем решения ${p.name}',
              style: tx(16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Запрошено: ${p.pending!.scopes.map(familyScopeLabel).join(', ')}. Действующие разрешения пока не меняются.',
              style: tx(13, color: C.muted),
            ),
            TextButton(
              key: const ValueKey('simulate-family-owner'),
              onPressed: () => demoDecision(p),
              child: const Text('Демо: проверить ответ владельца'),
            ),
            TextButton(
              key: const ValueKey('cancel-family-request'),
              onPressed: () => setState(() {
                p.pending = null;
                event(p, 'Вы отменили ожидающий запрос доступа.');
              }),
              child: const Text('Отменить запрос'),
            ),
          ],
          if (active)
            TextButton(
              key: ValueKey(
                outgoing ? 'revoke-family-outgoing' : 'revoke-family-incoming',
              ),
              onPressed: () => revoke(p, outgoing: outgoing),
              child: Text(
                outgoing ? 'Отозвать доступ' : 'Прекратить мой доступ',
              ),
            ),
          const SizedBox(height: 10),
          Text(
            outgoing
                ? 'Вы управляете доступом к своим данным.'
                : 'Разрешение выдаёт владелец данных. Семейная связь его не заменяет.',
            style: tx(12, color: C.muted),
          ),
        ],
      ),
    );
  }

  Widget historyPanel(FamilyPerson p) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'История доступа и действий',
          style: tx(23, weight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'События сохраняются после отзыва разрешения. Содержимое закрытых разделов здесь не показывается.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        for (final e in p.events)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: C.green),
            title: Text(e, style: tx(14)),
            subtitle: Text(
              '20 октября · демо-сеанс',
              style: tx(11, color: C.muted),
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text('Профиль добавлен в семью', style: tx(14)),
          subtitle: Text(
            p.id == 1
                ? 'Начальное демо-разрешение: записи и поручения · 14 дней'
                : 'Доступ к данным автоматически не предоставлен',
            style: tx(12, color: C.muted),
          ),
        ),
      ],
    ),
  );
}
