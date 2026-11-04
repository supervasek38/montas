part of 'main.dart';

class EventTicket {
  const EventTicket(
    this.id,
    this.name,
    this.price,
    this.online,
    this.includes, {
    this.capacity = 100,
    this.cancelUntil = 'До начала события',
  });
  final String id, name, includes, cancelUntil;
  final int price, capacity;
  final bool online;
}

class MontasEvent {
  const MontasEvent({
    required this.id,
    required this.title,
    required this.day,
    required this.time,
    required this.category,
    required this.description,
    required this.speakers,
    required this.agenda,
    required this.tickets,
    required this.venue,
    required this.icon,
  });
  final String id, title, time, category, description, speakers, venue;
  final int day;
  final IconData icon;
  final List<String> agenda;
  final List<EventTicket> tickets;
  String get date => '$day октября · $time';
  String get format => tickets.any((t) => t.online)
      ? tickets.any((t) => !t.online)
            ? 'Москва + онлайн'
            : 'Онлайн'
      : 'Москва';
  int get price => tickets.map((t) => t.price).reduce((a, b) => a < b ? a : b);
}

const montasEvents = [
  MontasEvent(
    id: 'sleep-lab',
    title: 'Sleep & Longevity Lab',
    day: 23,
    time: '18:00–22:00',
    category: 'Лекция и практика',
    description:
        'Вечер о сне, привычках и восстановлении. Обсудите вопросы '
        'с экспертами, разберите примеры и соберите личный список наблюдений.',
    speakers:
        'Анна Волкова · терапевт\nСергей Крук · приглашённый эксперт\n'
        'Мария Левина · ведущая практики',
    venue: 'MONTAS Hub · Москва\nДемо-площадка, зал «Свет» · доступный вход',
    icon: Icons.nightlight_round,
    agenda: [
      '18:00 · Что мы знаем о сне',
      '18:40 · Разбор примеров',
      '19:30 · Sleep Lab: практическая часть',
      '20:30 · Вопросы экспертам',
    ],
    tickets: [
      EventTicket(
        'standard',
        'Standard · в зале',
        4900,
        false,
        'Основная программа и запись на 14 дней',
        capacity: 82,
        cancelUntil: 'До 22 октября, 18:00',
      ),
      EventTicket(
        'lab',
        'Lab · зал + практика',
        8900,
        false,
        'Основная программа, практикум и запись на 14 дней',
        capacity: 24,
        cancelUntil: 'До 22 октября, 18:00',
      ),
      EventTicket(
        'live',
        'Live · трансляция',
        2900,
        true,
        'Онлайн-эфир и запись на 14 дней',
        capacity: 1000,
      ),
    ],
  ),
  MontasEvent(
    id: 'analysis',
    title: 'Разбор анализов без тревоги',
    day: 24,
    time: '19:00–20:00',
    category: 'Открытая встреча',
    description:
        'Какие вопросы стоит задать врачу об анализах и как '
        'подготовиться к обсуждению результатов. На встрече разбираем общие '
        'примеры, без персональных назначений.',
    speakers: 'Анна Волкова · терапевт',
    venue: 'Онлайн · в MONTAS',
    icon: Icons.forum_outlined,
    agenda: [
      '19:00 · Как читать структуру отчёта',
      '19:25 · Подготовка вопросов к консультации',
      '19:45 · Общие вопросы',
    ],
    tickets: [
      EventTicket(
        'online',
        'Онлайн-участие',
        0,
        true,
        'Прямой эфир и памятка для подготовки к консультации',
      ),
    ],
  ),
  MontasEvent(
    id: 'recovery',
    title: 'Практика восстановления',
    day: 29,
    time: '11:00–13:00',
    category: 'Клубная практика',
    description:
        'Небольшая встреча, чтобы замедлиться и попробовать '
        'спокойные повседневные практики. Комфортный темп, паузы и время '
        'на разговор с ведущей.',
    speakers: 'Мария Левина · ведущая практики',
    venue: 'MONTAS Hub · Москва\nДемо-площадка, студия «Тишина»',
    icon: Icons.spa_outlined,
    agenda: [
      '11:00 · Знакомство и настрой',
      '11:20 · Спокойная практика',
      '12:20 · Обсуждение и личные заметки',
    ],
    tickets: [
      EventTicket(
        'practice',
        'Участие в студии',
        2500,
        false,
        'Двухчасовая практика в небольшой группе',
        capacity: 12,
        cancelUntil: 'До 28 октября, 11:00',
      ),
    ],
  ),
];

class EventRegistration {
  EventRegistration(this.id, this.event, this.ticket);
  final String id;
  final MontasEvent event;
  final EventTicket ticket;
  bool cancelled = false;
}

class EventsStore extends ChangeNotifier {
  final saved = <String>{};
  final _registrations = <EventRegistration>[];
  List<EventRegistration> get registrations =>
      List.unmodifiable(_registrations);
  EventRegistration? active(String eventId) {
    for (final r in _registrations.reversed) {
      if (r.event.id == eventId && !r.cancelled) return r;
    }
    return null;
  }

  int remaining(MontasEvent event, EventTicket ticket) =>
      ticket.capacity -
      _registrations
          .where(
            (r) =>
                !r.cancelled &&
                r.event.id == event.id &&
                r.ticket.id == ticket.id,
          )
          .length;
  void toggleSaved(String id) {
    if (!saved.remove(id)) saved.add(id);
    notifyListeners();
  }

  EventRegistration? register(MontasEvent event, EventTicket ticket) {
    if (!montasEvents.contains(event) ||
        !event.tickets.contains(ticket) ||
        active(event.id) != null ||
        remaining(event, ticket) <= 0) {
      return null;
    }
    final r = EventRegistration(
      'EV-${(_registrations.length + 1).toString().padLeft(3, '0')}',
      event,
      ticket,
    );
    _registrations.add(r);
    notifyListeners();
    return r;
  }

  bool cancel(EventRegistration registration) {
    if (!_registrations.contains(registration) || registration.cancelled) {
      return false;
    }
    registration.cancelled = true;
    notifyListeners();
    return true;
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => EventsScreenState();
}

class EventsScreenState extends State<EventsScreen> {
  final store = EventsStore();
  final search = TextEditingController();
  int tab = 0;
  String format = 'Все форматы';
  bool freeOnly = false;
  MontasEvent? selected;
  @override
  void dispose() {
    store.dispose();
    search.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    search.clear();
    format = 'Все форматы';
    freeOnly = false;
    tab = 0;
  });
  void open(MontasEvent event) => setState(() => selected = event);

  Future<void> register(MontasEvent event) async {
    var ticket = event.tickets.first;
    var review = false, accepted = false;
    String? error;
    await discoveryDialog<void>(
      context,
      'Участие в событии',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(event.title, style: tx(18, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(event.date, style: tx(13, color: C.muted)),
            const SizedBox(height: 20),
            if (!review) ...[
              Text(
                '1. Выберите формат',
                style: tx(16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final option in event.tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    key: ValueKey('event-ticket-${option.id}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: ticket == option ? C.soft : Colors.white,
                      side: BorderSide(
                        color: ticket == option ? C.green : C.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => update(() => ticket = option),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ticket == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20,
                          color: C.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                style: tx(15, weight: FontWeight.w600),
                              ),
                              Text(
                                discoveryMoney(option.price),
                                style: tx(16, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.includes,
                                style: tx(13, color: C.muted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Доступных мест: ${store.remaining(event, option)} · демо',
                                style: tx(12, color: C.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                'Продолжить',
                () => update(() => review = true),
                key: const ValueKey('event-continue'),
              ),
            ] else ...[
              Text(
                '2. Проверьте регистрацию',
                style: tx(16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Surface(
                color: C.soft,
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.name, style: tx(16, weight: FontWeight.w600)),
                    Text(ticket.includes, style: tx(13)),
                    const SizedBox(height: 12),
                    Text('1 участник · ваш демо-профиль', style: tx(14)),
                    Text(
                      'Стоимость по макету: ${discoveryMoney(ticket.price)}',
                      style: tx(14),
                    ),
                    Text(
                      'Отмена: ${ticket.cancelUntil}',
                      style: tx(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Создадим тестовую запись в «Моих мероприятиях». '
                'Оплата и отправка данных организатору не выполняются.',
                style: tx(13, color: C.muted),
              ),
              CheckboxListTile(
                key: const ValueKey('event-consent'),
                contentPadding: EdgeInsets.zero,
                value: accepted,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => update(() => accepted = v ?? false),
                title: Text('Формат и условия проверены', style: tx(13)),
              ),
              if (error != null)
                Text(error!, style: tx(13, color: Colors.red.shade700)),
              PrimaryButton(
                'Подтвердить демо-регистрацию',
                accepted
                    ? () {
                        final result = store.register(event, ticket);
                        if (result == null) {
                          update(
                            () => error =
                                'Регистрация уже есть или формат недоступен. Закройте окно и проверьте событие.',
                          );
                        } else {
                          Navigator.pop(ctx);
                        }
                      }
                    : null,
                key: const ValueKey('event-confirm'),
              ),
              TextButton(
                onPressed: () => update(() {
                  review = false;
                  accepted = false;
                }),
                child: const Text('Изменить формат'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> cancel(EventRegistration r) async {
    final yes = await discoveryDialog<bool>(
      context,
      'Отменить участие?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${r.event.title}\n${r.ticket.name}\n${r.event.date}',
            style: tx(15),
          ),
          const SizedBox(height: 16),
          Text(
            'Запись останется в истории со статусом «Отменено». '
            'Денежных операций в демо нет.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            'Отменить демо-регистрацию',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('event-cancel-confirm'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Сохранить участие'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) store.cancel(r);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => selected == null ? catalog() : detail(selected!),
  );

  Widget catalog() {
    final query = search.text.toLowerCase().trim();
    final events = montasEvents
        .where(
          (e) =>
              '${e.title} ${e.category} ${e.speakers}'.toLowerCase().contains(
                query,
              ) &&
              (format == 'Все форматы' ||
                  e.tickets.any((t) => t.online == (format == 'Онлайн'))) &&
              (!freeOnly || e.price == 0) &&
              (tab != 1 || store.saved.contains(e.id)),
        )
        .toList();
    return DiscoveryLayout(
      id: 'events-list',
      children: [
        const DiscoveryHeading(
          'MONTAS EVENTS',
          'События и встречи',
          'Знакомьтесь с экспертами, задавайте вопросы и пробуйте новое.',
        ),
        DiscoveryTabs(
          id: 'events',
          labels: [
            'Афиша',
            'Сохранённые (${store.saved.length})',
            'Мои мероприятия (${store.registrations.where((r) => !r.cancelled).length})',
          ],
          selected: tab,
          onSelect: (i) => setState(() => tab = i),
        ),
        if (tab == 2) ...[
          if (store.registrations.isEmpty)
            DiscoveryEmpty(
              'Вы пока никуда не записаны',
              'Выберите встречу и подходящий формат участия.',
              'Посмотреть афишу',
              reset,
            ),
          for (final r in store.registrations.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Surface(
                key: ValueKey('registration-${r.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Tag(
                          r.cancelled ? 'Отменено' : 'Демо-регистрация',
                          green: !r.cancelled,
                        ),
                        Tag(r.id),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(r.event.title, style: tx(22, weight: FontWeight.w600)),
                    Text(
                      '${r.event.date}\n${r.ticket.name} · ${discoveryMoney(r.ticket.price)}',
                      style: tx(14, color: C.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: () => open(r.event),
                          child: const Text('Открыть событие'),
                        ),
                        if (!r.cancelled)
                          TextButton(
                            onPressed: () => cancel(r),
                            child: const Text('Отменить участие'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          Surface(
            padding: 18,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('events-search'),
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Название, тема или эксперт',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in ['Все форматы', 'Онлайн', 'В Москве'])
                        ChoiceChip(
                          key: ValueKey('event-filter-$value'),
                          label: Text(value),
                          selected: format == value,
                          onSelected: (_) => setState(() => format = value),
                        ),
                      FilterChip(
                        label: const Text('Бесплатно'),
                        selected: freeOnly,
                        onSelected: (v) => setState(() => freeOnly = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Октябрь 2026 · найдено ${events.length}',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            DiscoveryEmpty(
              'Подходящих событий нет',
              'Попробуйте изменить фильтры или посмотрите всю афишу.',
              'Сбросить фильтры',
              reset,
            )
          else
            DiscoveryGrid(children: events.map(eventCard).toList()),
        ],
      ],
    );
  }

  Widget eventCard(MontasEvent event) => Surface(
    padding: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        eventImage(event),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(event.category, style: tx(12, color: C.green)),
            ),
            IconButton(
              key: ValueKey('event-save-${event.id}'),
              tooltip: store.saved.contains(event.id)
                  ? 'Убрать событие из сохранённых'
                  : 'Сохранить событие',
              onPressed: () => store.toggleSaved(event.id),
              icon: Icon(
                store.saved.contains(event.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: C.green,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 62,
          child: Text(
            event.title,
            style: tx(22, weight: FontWeight.w600, height: 1.25),
          ),
        ),
        discoveryFact(Icons.schedule, event.date),
        discoveryFact(Icons.location_on_outlined, event.format),
        const Divider(height: 24),
        Text(
          event.price == 0 ? 'Бесплатно' : 'от ${discoveryMoney(event.price)}',
          style: tx(20, weight: FontWeight.w600),
        ),
        Text(
          store.active(event.id) == null
              ? '${event.tickets.length} ${event.tickets.length == 1 ? 'формат' : 'формата'} участия'
              : 'Вы уже записаны · демо',
          style: tx(12, color: C.muted),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          'Подробнее',
          () => open(event),
          key: ValueKey('event-open-${event.id}'),
        ),
      ],
    ),
  );

  Widget eventImage(MontasEvent event) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: Image.asset(
        'assets/events/${event.id}-v1.png',
        fit: BoxFit.cover,
        semanticLabel: 'Анонс «${event.title}» · ИИ-иллюстрация',
      ),
    ),
  );

  Widget detail(MontasEvent event) {
    final registration = store.active(event.id);
    return DiscoveryLayout(
      id: 'event-detail-${event.id}',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('event-back'),
            onPressed: () => setState(() => selected = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('К мероприятиям'),
          ),
        ),
        const SizedBox(height: 16),
        DiscoveryHeading(
          'MONTAS EVENTS · ${event.category.toUpperCase()}',
          event.title,
          event.description,
        ),
        DiscoveryColumns(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              eventImage(event),
              const SizedBox(height: 20),
              Surface(
                color: C.dark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(event.icon, size: 42, color: C.lime),
                    const SizedBox(height: 24),
                    Text(
                      event.date,
                      style: tx(
                        26,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.venue,
                      style: tx(15, color: const Color(0xFFD4E6DC)),
                    ),
                    const SizedBox(height: 20),
                    Tag(event.format, green: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Программа встречи',
                      style: tx(22, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    for (final item in event.agenda)
                      discoveryFact(Icons.circle_outlined, item),
                    const Divider(height: 32),
                    Text(
                      'Кто проводит',
                      style: tx(18, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(event.speakers, style: tx(14, height: 1.8)),
                  ],
                ),
              ),
            ],
          ),
          aside: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (registration != null) ...[
                  const Tag('Вы записаны · демо', green: true),
                  const SizedBox(height: 18),
                  Text(
                    registration.ticket.name,
                    style: tx(22, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(registration.ticket.includes, style: tx(14)),
                  const SizedBox(height: 14),
                  Text(
                    'Запись ${registration.id}\n1 участник · ${discoveryMoney(registration.ticket.price)}',
                    style: tx(14, color: C.muted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Тестовая регистрация сохранена. Реальный билет, оплата и ссылка на трансляцию не создаются.',
                    style: tx(13, color: C.muted),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    'Мои мероприятия',
                    () => setState(() {
                      selected = null;
                      tab = 2;
                    }),
                    key: const ValueKey('event-my'),
                  ),
                  TextButton(
                    key: const ValueKey('event-cancel'),
                    onPressed: () => cancel(registration),
                    child: const Text('Отменить участие'),
                  ),
                ] else ...[
                  Text(
                    event.price == 0
                        ? 'Бесплатное участие'
                        : 'от ${discoveryMoney(event.price)}',
                    style: tx(26, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Выберите подходящий формат. Условия и состав билета покажем перед подтверждением.',
                    style: tx(14, color: C.muted),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    'Выбрать формат',
                    () => register(event),
                    key: const ValueKey('event-register'),
                  ),
                ],
                const Divider(height: 32),
                Text('Перед встречей', style: tx(16, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Подготовьте 2–3 вопроса. Если идёте в зал, приходите за 15 минут до начала.',
                  style: tx(13, color: C.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => store.toggleSaved(event.id),
                  icon: Icon(
                    store.saved.contains(event.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(
                    store.saved.contains(event.id)
                        ? 'Сохранено'
                        : 'Сохранить событие',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
