part of 'main.dart';

/// Calendar-only demo. These fixtures are not clinical clearance or live slots.
class TravelData extends ChangeNotifier {
  TravelData(this.medication) : medicationVersion = medication.version {
    medication.addListener(_medicationChanged);
  }
  final MedicationData medication;
  static final today = DateTime(2026, 10, 20);
  DateTime procedure = DateTime(2026, 10, 24);
  DateTime departure = DateTime(2026, 10, 26);
  DateTime returning = DateTime(2026, 10, 30);
  String destination = 'Иркутск → Москва';
  int recoveryDays = 5, sourceVersion = 1, contextVersion = 1;
  int medicationVersion;
  int? selectedVersion;
  bool needsReview = false, reviewRequested = false;
  final history = <String>[
    '20 октября · демо-план создан: процедура 24 октября, поездка 26–30 октября. Условия v1: период 3–5 дней; для календаря используем 5 дней.',
  ];
  DateTime endFor(DateTime day) => day.add(Duration(days: recoveryDays));
  bool conflicts(DateTime day) =>
      !day.isAfter(returning) && !endFor(day).isBefore(departure);
  bool get selected => selectedVersion != null;
  bool get current => selectedVersion == contextVersion && !needsReview;
  bool get conflict => conflicts(procedure);
  String get status => needsReview
      ? 'Нужна проверка условий'
      : selected && !current
      ? 'Перепроверьте выбранную дату'
      : conflict
      ? 'Даты пересекаются'
      : current
      ? 'Окно выбрано · без записи'
      : 'По датам пересечения нет';
  // Offer a day before the trip only when it has not passed in the demo clock.
  List<DateTime> get options {
    final before = departure.subtract(Duration(days: recoveryDays + 1));
    return [
      if (!before.isBefore(today)) before,
      returning.add(const Duration(days: 1)),
      returning.add(const Duration(days: 3)),
    ];
  }

  static String date(DateTime d) =>
      '${d.day} ${const ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'][d.month - 1]}';
  void choose(DateTime day) {
    if (needsReview || conflicts(day) || day.isBefore(today)) return;
    procedure = day;
    selectedVersion = contextVersion;
    history.insert(
      0,
      '20 октября · выбрано окно ${date(day)} → ${date(endFor(day))}. Условия v$sourceVersion, назначение v$medicationVersion, контекст v$contextVersion. Запись не создана.',
    );
    notifyListeners();
  }

  void editTrip(String route, DateTime start, DateTime end) {
    if (route.trim().isEmpty || start.isBefore(today) || end.isBefore(start)) {
      return;
    }
    if (destination == route.trim() && departure == start && returning == end) {
      return;
    }
    final old = '$destination · ${date(departure)}–${date(returning)}';
    destination = route.trim();
    departure = start;
    returning = end;
    contextVersion++;
    reviewRequested = false;
    history.insert(
      0,
      '20 октября · поездка изменена вами: $old → $destination · ${date(start)}–${date(end)}. ${selected ? 'Прежняя дата процедуры сохранена как черновик; нужен повторный выбор.' : 'Календарь пересчитан.'}',
    );
    notifyListeners();
  }

  void _medicationChanged() {
    if (medicationVersion == medication.version) return;
    medicationVersion = medication.version;
    invalidate('Принята новая версия назначения v$medicationVersion');
  }

  void invalidate(String reason) {
    contextVersion++;
    needsReview = true;
    reviewRequested = false;
    history.insert(
      0,
      '20 октября · $reason. Дата ${date(procedure)} сохранена; требуется проверка специалиста.',
    );
    notifyListeners();
  }

  void requestReview() {
    if (!needsReview || reviewRequested) return;
    reviewRequested = true;
    history.insert(
      0,
      '20 октября · запрос проверки смоделирован для специалиста по процедуре. Контекст v$contextVersion, назначение v$medicationVersion. Внешней отправки нет.',
    );
    notifyListeners();
  }

  void demoReviewResult() {
    if (!reviewRequested || !needsReview) return;
    recoveryDays = 7;
    sourceVersion++;
    contextVersion++;
    needsReview = false;
    reviewRequested = false;
    history.insert(
      0,
      '20 октября · принят демонстрационный ответ: условия v$sourceVersion, календарный период 7 дней. Предыдущая дата не заменена. Выберите окно заново.',
    );
    notifyListeners();
  }

  void clearSelection() {
    if (!selected) return;
    selectedVersion = null;
    history.insert(
      0,
      '20 октября · выбор окна снят вами. Дата ${date(procedure)} осталась в черновике; отмены записи в клинику нет.',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    medication.removeListener(_medicationChanged);
    super.dispose();
  }
}

class TravelSummary extends StatelessWidget {
  const TravelSummary({required this.data, required this.onOpen, super.key});
  final TravelData data;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.flight_takeoff, color: C.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Процедуры и поездки',
                style: tx(21, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(data.status, style: tx(17, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          'Процедура ${TravelData.date(data.procedure)} · поездка ${TravelData.date(data.departure)}',
          style: tx(13, color: C.muted),
        ),
        TextButton.icon(
          key: const ValueKey('open-travel'),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Открыть календарь'),
        ),
      ],
    ),
  );
}

class TravelScreen extends StatefulWidget {
  const TravelScreen({
    required this.data,
    required this.onPlan,
    required this.onAsk,
    required this.onMedication,
    super.key,
  });
  final TravelData data;
  final VoidCallback onPlan, onAsk, onMedication;
  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  TravelData get data => widget.data;
  int tab = 0;
  final scroll = ScrollController();
  final routeController = TextEditingController();
  static const gap = SizedBox(height: 20);
  @override
  void dispose() {
    scroll.dispose();
    routeController.dispose();
    super.dispose();
  }

  void showTab(int value) {
    setState(() => tab = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Widget textBlock(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: tx(18, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(body, style: tx(14, color: C.muted)),
    ],
  );
  Future<T?> popup<T>(
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
          maxWidth: 540,
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
              content(ctx),
            ],
          ),
        ),
      ),
    ),
  );
  Future<void> procedureDetail() => popup<void>(
    'Процедура и условия',
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        textBlock(
          'Лазерная процедура · пример из макета',
          'Черновик на ${TravelData.date(data.procedure)}. Клиника, специалист, стоимость и время приёма не выбраны.',
        ),
        gap,
        textBlock(
          'Источник · условия v${data.sourceVersion}',
          'Демонстрационная карточка специалиста по процедуре, 20 октября 2026. ${data.sourceVersion == 1 ? 'В макете указан диапазон 3–5 дней. Для примера календаря взята верхняя граница — 5 дней.' : 'В демонстрационном ответе указан период 7 дней.'} Это вымышленные условия сценария, не рекомендация для реальной процедуры.',
        ),
        gap,
        textBlock(
          'Как сравниваются даты',
          'Период заканчивается ${TravelData.date(data.endFor(data.procedure))}. День окончания также оставляем свободным от поездки. Проверка учитывает весь промежуток поездки; медицинскую допустимость подтверждает специалист.',
        ),
        gap,
        OutlinedButton(
          key: const ValueKey('travel-medication'),
          onPressed: () {
            Navigator.pop(ctx);
            widget.onMedication();
          },
          child: Text('Лекарства · версия ${data.medicationVersion}'),
        ),
        PrimaryButton('Понятно', () => Navigator.pop(ctx)),
      ],
    ),
  );

  Future<void> editTrip() async {
    final route = routeController..text = data.destination;
    var start = data.departure, end = data.returning;
    String? error;
    final accepted = await popup<bool>(
      'Ваша поездка',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Измените черновик поездки. Билеты и внешние календари не меняются.',
              style: tx(14, color: C.muted),
            ),
            gap,
            TextField(
              key: const ValueKey('travel-route'),
              controller: route,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Маршрут или название',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
            gap,
            OutlinedButton.icon(
              key: const ValueKey('travel-departure'),
              icon: const Icon(Icons.flight_takeoff),
              label: Text('Выезд · ${TravelData.date(start)}'),
              onPressed: () async {
                final value = await showDatePicker(
                  context: ctx,
                  initialDate: start,
                  currentDate: TravelData.today,
                  firstDate: TravelData.today,
                  lastDate: DateTime(2026, 12, 31),
                  helpText: 'Дата выезда · 2026',
                  cancelText: 'Отмена',
                  confirmText: 'Выбрать',
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                );
                if (value != null && ctx.mounted) {
                  update(() {
                    start = value;
                  });
                }
              },
            ),
            OutlinedButton.icon(
              key: const ValueKey('travel-return'),
              icon: const Icon(Icons.flight_land),
              label: Text('Возвращение · ${TravelData.date(end)}'),
              onPressed: () async {
                final value = await showDatePicker(
                  context: ctx,
                  initialDate: end.isBefore(start) ? start : end,
                  currentDate: TravelData.today,
                  firstDate: start,
                  lastDate: DateTime(2026, 12, 31),
                  helpText: 'Дата возвращения · 2026',
                  cancelText: 'Отмена',
                  confirmText: 'Выбрать',
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                );
                if (value != null && ctx.mounted) {
                  update(() {
                    end = value;
                  });
                }
              },
            ),
            gap,
            if (end.isBefore(start))
              Text(
                'Возвращение раньше выезда. Выберите новую дату возвращения.',
                key: const ValueKey('travel-date-error'),
                style: tx(14, color: Colors.brown),
              ),
            if (data.selected)
              Text(
                'После изменения поездки прежний выбор окна станет черновиком. Дата процедуры сохранится.',
                style: tx(13, color: C.muted),
              ),
            gap,
            PrimaryButton(
              'Сохранить поездку',
              end.isBefore(start)
                  ? null
                  : () {
                      if (route.text.trim().isEmpty) {
                        update(() => error = 'Укажите маршрут или название');
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
              key: const ValueKey('save-travel-trip'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) data.editTrip(route.text, start, end);
  }

  Future<void> choose(DateTime day) async {
    final revision = data.contextVersion;
    final accepted = await popup<bool>(
      'Выбрать это окно?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textBlock(
            'Процедура · ${TravelData.date(day)}',
            'Период в календаре: ${TravelData.date(day)} → ${TravelData.date(data.endFor(day))}. Поездка: ${TravelData.date(data.departure)} → ${TravelData.date(data.returning)}.',
          ),
          gap,
          textBlock(
            'Только выбор даты',
            'Окно сохранится в текущем прототипе. Это не медицинский допуск и не запись в клинику. Доступность времени нужно уточнить отдельно.',
          ),
          gap,
          PrimaryButton(
            'Выбрать окно',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-travel-window'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Вернуться к датам'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      if (revision != data.contextVersion) {
        showTab(0);
        return;
      }
      data.choose(day);
      showTab(0);
    }
  }

  Future<void> clearSelection() async {
    final accepted = await popup<bool>(
      'Снять выбор окна?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Дата останется в черновике и истории. Записи в клинику в этом сценарии не было.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Снять выбор',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-clear-travel'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) data.clearSelection();
  }

  Future<void> simulateChange() async {
    final accepted = await popup<bool>(
      'Демо: условия изменились',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Смоделируем новую информацию от специалиста. Текущее окно станет черновиком до проверки; дата и история останутся прежними.',
            style: tx(15, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Смоделировать изменение',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-travel-change'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      data.invalidate('Условия процедуры изменились · демо');
    }
  }

  Future<void> requestReview() async {
    final accepted = await popup<bool>(
      'Проверка условий · демо',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textBlock(
            'Специалисту по процедуре',
            'В сводке: дата ${TravelData.date(data.procedure)}, поездка $routeLabel, условия v${data.sourceVersion}, назначение v${data.medicationVersion}.',
          ),
          gap,
          Text(
            'Следующее действие только покажет ожидание ответа. Внешней передачи и реальной заявки нет.',
            style: tx(14, color: C.muted),
          ),
          gap,
          PrimaryButton(
            'Смоделировать запрос',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-travel-review'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) data.requestReview();
  }

  Future<void> reviewResult() async {
    final accepted = await popup<bool>(
      'Демо-ответ специалиста',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textBlock(
            'Новые условия · 7 дней',
            'Вымышленный ответ для теста: календарный период увеличен до 7 дней. Назначение лекарств не меняется. После принятия нужно заново выбрать окно.',
          ),
          gap,
          PrimaryButton(
            'Принять демо-условия',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('accept-travel-review'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) data.demoReviewResult();
  }

  String get routeLabel =>
      '${data.destination} · ${TravelData.date(data.departure)}–${TravelData.date(data.returning)}';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 700;
        final content = tab == 0
            ? overview()
            : tab == 1
            ? windows()
            : historyView();
        return SingleChildScrollView(
          key: const PageStorageKey('travel-scroll'),
          controller: scroll,
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
                        key: const ValueKey('travel-back-plan'),
                        onPressed: widget.onPlan,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Мой план'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Процедуры и поездки',
                      style: tx(
                        narrow ? 32 : 40,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Оставьте время на восстановление — и место для своих планов.',
                      style: tx(15, color: C.muted),
                    ),
                    gap,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < 3; i++)
                          ChoiceChip(
                            key: ValueKey('travel-tab-$i'),
                            label: Text(['Обзор', 'Подбор дат', 'История'][i]),
                            selected: tab == i,
                            showCheckmark: false,
                            onSelected: (_) => showTab(i),
                          ),
                      ],
                    ),
                    gap,
                    if (box.maxWidth >= 1000)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: content),
                          const SizedBox(width: 24),
                          SizedBox(width: 320, child: side()),
                        ],
                      )
                    else ...[
                      content,
                      gap,
                      side(),
                    ],
                    gap,
                    Text(
                      'Демо · 20 октября 2026 · вымышленные условия и даты · данные до обновления страницы',
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

  Widget overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: data.current ? const Color(0xFFEAFBD9) : const Color(0xFFFFF3D8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Tag(
                data.current ? 'Выбрано локально' : 'Проверка календаря',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.status,
              key: const ValueKey('travel-status'),
              style: tx(28, weight: FontWeight.w600, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              data.needsReview
                  ? 'Исходные условия изменились. Сохранили дату и остановили выбор нового окна до проверки специалиста.'
                  : data.selected && !data.current
                  ? 'Контекст поездки или условия обновились. Прежняя дата сохранена; проверьте календарь и подтвердите выбор заново.'
                  : data.conflict
                  ? 'Поездка пересекается с периодом восстановления. Можно подобрать другую дату процедуры.'
                  : 'Период восстановления не пересекается с поездкой по условиям демо. Медицинскую допустимость и запись нужно уточнить у специалиста.',
              style: tx(15),
            ),
            gap,
            if (data.needsReview) ...[
              if (data.reviewRequested) ...[
                textBlock(
                  'Ожидает проверки · демо',
                  'Реальный запрос не отправлен. Для продолжения теста можно открыть пример ответа.',
                ),
                gap,
                PrimaryButton(
                  'Показать демо-ответ',
                  reviewResult,
                  key: const ValueKey('travel-review-result'),
                ),
              ] else
                PrimaryButton(
                  'Запросить проверку · демо',
                  requestReview,
                  key: const ValueKey('travel-request-review'),
                ),
            ] else
              PrimaryButton(
                data.current
                    ? 'Изменить выбранное окно'
                    : 'Посмотреть подходящие даты',
                () => showTab(1),
                key: const ValueKey('travel-find-dates'),
              ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Всё на одной линии', style: tx(23, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Даты сценария · октябрь–ноябрь 2026',
              style: tx(13, color: C.muted),
            ),
            gap,
            timeline(
              Icons.spa_outlined,
              'Процедура',
              '${TravelData.date(data.procedure)} · лазерная процедура',
              'Черновик · время и клиника не выбраны',
              C.green,
            ),
            timeline(
              Icons.self_improvement,
              'Период восстановления',
              '${TravelData.date(data.procedure)} → ${TravelData.date(data.endFor(data.procedure))}',
              '${data.recoveryDays} дней · условия v${data.sourceVersion}${data.needsReview ? ' · требуют проверки' : ''}',
              C.green,
            ),
            timeline(
              Icons.flight_takeoff,
              'Поездка',
              '${TravelData.date(data.departure)} → ${TravelData.date(data.returning)}',
              data.destination,
              data.conflict ? Colors.brown : C.green,
            ),
            OutlinedButton(
              key: const ValueKey('travel-edit-trip'),
              onPressed: editTrip,
              child: const Text('Изменить поездку'),
            ),
            TextButton(
              key: const ValueKey('travel-procedure'),
              onPressed: procedureDetail,
              child: const Text('Процедура, источник и условия →'),
            ),
          ],
        ),
      ),
      if (data.selected) ...[
        gap,
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textBlock(
                data.current
                    ? 'Следующий шаг — обсудить со специалистом'
                    : 'Выбранная дата сохранена в черновике',
                'Выбор окна не создаёт бронь или оплату. Доступность клиники не проверялась.',
              ),
              gap,
              OutlinedButton(
                key: const ValueKey('travel-return-plan'),
                onPressed: widget.onPlan,
                child: const Text('Вернуться в мой план'),
              ),
              TextButton(
                key: const ValueKey('travel-clear'),
                onPressed: clearSelection,
                child: const Text('Снять выбор окна'),
              ),
            ],
          ),
        ),
      ],
    ],
  );
  Widget timeline(
    IconData icon,
    String title,
    String value,
    String note,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tx(12, color: C.muted)),
              Text(value, style: tx(17, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(note, style: tx(13, color: C.muted)),
            ],
          ),
        ),
      ],
    ),
  );
  Widget windows() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            textBlock(
              'Когда можно запланировать',
              'Сравниваем календарные периоды с вашей поездкой. Даты ниже — варианты демо, а не свободные слоты клиники.',
            ),
            gap,
            if (data.needsReview) ...[
              textBlock(
                'Сначала проверка условий',
                'До ответа специалиста новое окно выбрать нельзя. Прежняя дата осталась в черновике.',
              ),
              gap,
              PrimaryButton('Перейти к проверке', () => showTab(0)),
            ] else ...[
              if (data.options.first.isAfter(data.returning)) ...[
                Text(
                  'До поездки полного периода уже не остаётся. Показываем варианты после возвращения.',
                  style: tx(14, color: C.muted),
                ),
                gap,
              ],
              for (final (i, day) in data.options.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Surface(
                    padding: 18,
                    color: C.soft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          day.isBefore(data.departure)
                              ? 'ДО ПОЕЗДКИ'
                              : 'ПОСЛЕ ВОЗВРАЩЕНИЯ',
                          style: tx(
                            10,
                            color: C.green,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          TravelData.date(day),
                          style: tx(26, weight: FontWeight.w600),
                        ),
                        Text(
                          'Период до ${TravelData.date(data.endFor(day))} включительно',
                          style: tx(14, color: C.muted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: ValueKey('travel-option-$i'),
                          onPressed: () => choose(day),
                          child: Text(
                            data.current && data.procedure == day
                                ? 'Выбрано · посмотреть'
                                : 'Посмотреть и выбрать',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            TextButton(
              onPressed: editTrip,
              child: const Text('Изменить даты поездки'),
            ),
          ],
        ),
      ),
    ],
  );
  Widget historyView() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        textBlock(
          'История решений',
          'Сохраняем выбор, исходные условия и изменения в текущем сеансе.',
        ),
        gap,
        for (final event in data.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              color: C.soft,
              padding: 16,
              child: Text(event, style: tx(14)),
            ),
          ),
      ],
    ),
  );
  Widget side() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: C.dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.event_available_outlined,
                color: C.lime,
                size: 28,
              ),
            ),
            gap,
            Text(
              'Сначала — время на восстановление',
              style: tx(
                24,
                color: Colors.white,
                weight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            gap,
            Text(
              'Дата под ваши планы. Клиника и стоимость — отдельный следующий шаг.',
              style: tx(15, color: const Color(0xFFC8D5CD)),
            ),
            TextButton(
              onPressed: procedureDetail,
              child: Text(
                'Откуда взяты условия →',
                style: tx(14, color: C.lime),
              ),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            textBlock(
              'Есть вопрос о процедуре?',
              'Подготовьте вопросы специалисту в разделе «Спросить». Данные поездки автоматически туда не передаются.',
            ),
            gap,
            OutlinedButton(
              key: const ValueKey('travel-ask'),
              onPressed: widget.onAsk,
              child: const Text('Открыть вопросы специалисту'),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            textBlock(
              'Проверить сценарий',
              'Изменение условий или новая версия назначения требуют повторной проверки окна.',
            ),
            TextButton(
              key: const ValueKey('travel-change'),
              onPressed: data.needsReview ? null : simulateChange,
              child: const Text('Демо: условия изменились'),
            ),
          ],
        ),
      ),
    ],
  );
}
