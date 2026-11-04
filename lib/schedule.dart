part of 'main.dart';

class AppointmentEvent {
  const AppointmentEvent(this.before, this.after, this.actor, this.reason);
  final Appointment? before, after;
  final String actor, reason;
  String get label => after == null
      ? 'Приём отменён'
      : before == null
      ? 'Запись создана'
      : 'Приём перенесён';
}

class AppointmentSchedule extends ChangeNotifier {
  Appointment? _current;
  Appointment? get current => _current;
  final _history = <AppointmentEvent>[];
  final _blocked = <String>{};
  List<AppointmentEvent> get history => List.unmodifiable(_history);
  String slotKey(Appointment a) => '${a.day}/${a.time}/${a.online}';
  bool same(Appointment a, Appointment b) => slotKey(a) == slotKey(b);
  bool blocked(Appointment a) => _blocked.contains(slotKey(a));
  List<String> available(int day, bool online) => _SpecialistScreenState.slots(
    day,
    online,
  ).where((time) => !blocked(Appointment(day, time, online))).toList();
  bool change(
    Appointment? expected,
    Appointment? next, {
    required String actor,
    String reason = '',
  }) {
    if (!identical(current, expected) || (next == null && current == null)) {
      return false;
    }
    if (next != null &&
        (next.day < 0 ||
            next.day > 4 ||
            !available(next.day, next.online).contains(next.time))) {
      return false;
    }
    if (next != null && current != null && same(next, current!)) return false;
    _history.insert(0, AppointmentEvent(current, next, actor, reason));
    _current = next;
    notifyListeners();
    return true;
  }

  bool setBlocked(Appointment slot, bool value) {
    if (slot.day < 0 || slot.day > 4) return false;
    if (!_SpecialistScreenState.slots(
      slot.day,
      slot.online,
    ).contains(slot.time)) {
      return false;
    }
    if (current != null && same(current!, slot)) return false;
    if (value) {
      _blocked.add(slotKey(slot));
    } else {
      _blocked.remove(slotKey(slot));
    }
    notifyListeners();
    return true;
  }
}

extension _ExpertScheduleViews on ExpertWorkspaceState {
  String appointmentText(Appointment a) =>
      '${a.date} · ${a.time} · ${a.format}';
  Widget appointmentSummary() {
    final a = widget.schedule.current!;
    return Surface(
      color: const Color(0xFFDDF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'БЛИЖАЙШИЙ ПРИЁМ',
            style: tx(11, color: C.green, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text('${a.date} · ${a.time}', style: tx(24, weight: FontWeight.w600)),
          Text(
            'Пользователь · ${a.format} · 45 минут',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            key: const ValueKey('expert-open-appointment'),
            onPressed: () {
              updatePatients(() {
                scheduleDay = a.day;
                scheduleTab = 0;
              });
              navigate(4);
            },
            child: const Text('Открыть приём в расписании'),
          ),
        ],
      ),
    );
  }

  Widget schedulePanel() {
    final a = widget.schedule.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Октябрь 2026', style: tx(25, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Иркутск · UTC+8 · приём 45 минут',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in [
                    '21 · Ср',
                    '22 · Чт',
                    '23 · Пт',
                    '24 · Сб',
                    '26 · Пн',
                  ].indexed)
                    ChoiceChip(
                      key: ValueKey('schedule-day-${d.$1}'),
                      label: Text(d.$2),
                      selected: scheduleDay == d.$1,
                      onSelected: (_) =>
                          updatePatients(() => scheduleDay = d.$1),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tab in [
                    'Приёмы',
                    'Доступное время',
                    'История',
                  ].indexed)
                    ChoiceChip(
                      key: ValueKey('schedule-tab-${tab.$1}'),
                      label: Text(tab.$2),
                      selected: scheduleTab == tab.$1,
                      onSelected: (_) =>
                          updatePatients(() => scheduleTab = tab.$1),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (scheduleTab == 0)
          a != null && a.day == scheduleDay
              ? scheduleAppointment(a)
              : Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 38,
                        color: C.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'На этот день приёмов нет',
                        style: tx(23, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Запись появится здесь после подтверждения в личном кабинете.',
                        style: tx(14, color: C.muted),
                      ),
                      const SizedBox(height: 18),
                      if (a != null)
                        OutlinedButton(
                          key: const ValueKey('schedule-next'),
                          onPressed: () =>
                              updatePatients(() => scheduleDay = a.day),
                          child: Text('К записи: ${a.date} · ${a.time}'),
                        ),
                      TextButton(
                        key: const ValueKey('schedule-book-as-user'),
                        onPressed: widget.onPersonalBooking,
                        child: const Text(
                          'Открыть запись со стороны пользователя',
                        ),
                      ),
                    ],
                  ),
                )
        else if (scheduleTab == 1)
          scheduleSlots()
        else
          scheduleHistory(),
        const SizedBox(height: 16),
        Text(
          'Демо-период: 21–26 октября. Изменения сохраняются до обновления страницы. Реальные уведомления и видеозвонки не отправляются.',
          style: tx(12, color: C.muted),
        ),
      ],
    );
  }

  Widget scheduleAppointment(Appointment a) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [const Tag('Подтверждено', green: true), Tag(a.format)],
        ),
        const SizedBox(height: 16),
        Text(a.time, style: tx(32, weight: FontWeight.w600)),
        Text('${a.date} · 45 минут · Иркутск', style: tx(14, color: C.muted)),
        const Divider(height: 32),
        Text('Пользователь', style: tx(23, weight: FontWeight.w600)),
        Text('MNT-DEMO-001 · демо', style: tx(12, color: C.muted)),
        const SizedBox(height: 14),
        Text(
          'Консультация · Анна Волкова\n${a.price}${a.online ? ' · онлайн' : ' · в клинике'}',
          style: tx(15),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          'Открыть карточку пациента',
          () => openPatient(),
          key: const ValueKey('schedule-patient'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('schedule-reschedule'),
          onPressed: () => rescheduleAppointment(a),
          child: const Text('Перенести приём'),
        ),
        TextButton(
          key: const ValueKey('schedule-cancel'),
          onPressed: () => cancelAppointment(a),
          child: const Text('Отменить приём'),
        ),
        const Divider(height: 24),
        Text(
          'Запись не открывает медицинские данные. Доступные вопросы и документы находятся в карточке пациента.',
          style: tx(12, color: C.muted),
        ),
        TextButton(
          key: const ValueKey('schedule-view-user'),
          onPressed: widget.onPersonalBooking,
          child: const Text('Посмотреть запись у пользователя →'),
        ),
      ],
    ),
  );

  Widget scheduleSlots() {
    final times = _SpecialistScreenState.slots(scheduleDay, scheduleOnline);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Время для записи', style: tx(23, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            'Закройте свободный слот или снова откройте его. Уже забронированное время меняется через перенос или отмену приёма.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final online in [true, false])
                ChoiceChip(
                  key: ValueKey('schedule-format-$online'),
                  label: Text(online ? 'Онлайн' : 'В клинике'),
                  selected: scheduleOnline == online,
                  onSelected: (_) =>
                      updatePatients(() => scheduleOnline = online),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (times.isEmpty)
            Text(
              '24 октября — день без приёмов.',
              style: tx(16, color: C.muted),
            ),
          for (final time in times)
            slotRow(Appointment(scheduleDay, time, scheduleOnline)),
        ],
      ),
    );
  }

  Widget slotRow(Appointment slot) {
    final booked =
        widget.schedule.current != null &&
        widget.schedule.same(widget.schedule.current!, slot);
    final closed = widget.schedule.blocked(slot);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        color: C.soft,
        padding: 16,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.time, style: tx(20, weight: FontWeight.w600)),
                  Text(
                    booked
                        ? 'Забронировано'
                        : closed
                        ? 'Закрыто для записи'
                        : 'Свободно',
                    style: tx(12, color: C.muted),
                  ),
                ],
              ),
            ),
            if (booked)
              const Icon(Icons.event_available, color: C.green)
            else
              OutlinedButton(
                key: ValueKey('schedule-slot-${slot.time}'),
                onPressed: () => toggleSlot(slot, !closed),
                child: Text(closed ? 'Открыть' : 'Закрыть'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleSlot(Appointment slot, bool close) async {
    final confirmed = await modal<bool>(
      close ? 'Закрыть время для записи?' : 'Открыть время для записи?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(appointmentText(slot), style: tx(19, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Text(
            close
                ? 'Этот слот исчезнет из выбора времени у пользователя. Существующая запись сохранится.'
                : 'Этот слот снова появится в выборе времени у пользователя.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Подтвердить',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('schedule-confirm-slot'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = widget.schedule.setBlocked(slot, close);
    updatePatients(() {});
    notify(
      success
          ? (close ? 'Время закрыто для записи' : 'Время снова доступно')
          : 'Слот уже занят. Откройте приём.',
    );
  }

  Future<void> rescheduleAppointment(Appointment original) async {
    var day = original.day;
    var online = original.online;
    String? time;
    final draft = await modal<Appointment>(
      'Новое время приёма',
      (ctx) => StatefulBuilder(
        builder: (ctx, local) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Сейчас: ${appointmentText(original)}',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [21, 22, 23, 24, 26].indexed)
                  ChoiceChip(
                    key: ValueKey('move-day-${d.$1}'),
                    label: Text('${d.$2} окт.'),
                    selected: day == d.$1,
                    onSelected: (_) => local(() {
                      day = d.$1;
                      time = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final mode in [true, false])
                  ChoiceChip(
                    key: ValueKey('move-format-$mode'),
                    label: Text(mode ? 'Онлайн' : 'В клинике'),
                    selected: online == mode,
                    onSelected: (_) => local(() {
                      online = mode;
                      time = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (widget.schedule.available(day, online).isEmpty)
              Text(
                'Свободного времени нет. Выберите другой день.',
                style: tx(14, color: C.muted),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in widget.schedule.available(day, online))
                  ChoiceChip(
                    key: ValueKey('move-slot-$slot'),
                    label: Text(slot),
                    selected: time == slot,
                    onSelected: (_) => local(() => time = slot),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Проверить перенос',
              time == null ||
                      widget.schedule.same(
                        original,
                        Appointment(day, time!, online),
                      )
                  ? null
                  : () => Navigator.pop(ctx, Appointment(day, time!, online)),
              key: const ValueKey('schedule-review-move'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Оставить прежнюю запись'),
            ),
          ],
        ),
      ),
    );
    if (draft == null || !mounted) return;
    final confirmed = await modal<bool>(
      'Подтвердить перенос',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Было: ${appointmentText(original)}',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 14),
          Text(
            'Будет: ${appointmentText(draft)}',
            style: tx(20, weight: FontWeight.w600),
          ),
          Text('${draft.price} · 45 минут · Иркутск', style: tx(14)),
          const SizedBox(height: 18),
          Text(
            'Запись обновится в личном кабинете. Это локальная демонстрация, без отправки уведомления.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Подтвердить перенос',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('schedule-confirm-move'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Оставить прежнюю запись'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = widget.schedule.change(
      original,
      draft,
      actor: 'Специалист',
    );
    updatePatients(() {
      if (success) scheduleDay = draft.day;
    });
    notify(
      success
          ? 'Приём перенесён в обеих рабочих средах'
          : 'Запись или слот изменились. Откройте актуальный приём.',
    );
  }

  Future<void> cancelAppointment(Appointment original) async {
    final reason = scheduleCancelReason..clear();
    final confirmed = await modal<bool>(
      'Отменить приём?',
      (ctx) => StatefulBuilder(
        builder: (ctx, local) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              appointmentText(original),
              style: tx(19, weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('schedule-cancel-reason'),
              controller: reason,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              onChanged: (_) => local(() {}),
              decoration: const InputDecoration(
                labelText: 'Причина отмены',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Запись исчезнет из предстоящих приёмов у обоих участников. Причина сохранится в истории специалиста.',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Подтвердить отмену',
              reason.text.trim().length < 3 || reason.text.trim().length > 300
                  ? null
                  : () => Navigator.pop(ctx, true),
              key: const ValueKey('schedule-confirm-cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Оставить приём'),
            ),
          ],
        ),
      ),
    );
    final text = reason.text.trim();
    if (confirmed != true || !mounted) return;
    final success = widget.schedule.change(
      original,
      null,
      actor: 'Специалист',
      reason: text,
    );
    updatePatients(() {});
    notify(
      success
          ? 'Приём отменён. История сохранена.'
          : 'Запись уже изменилась. Проверьте расписание.',
    );
  }

  Widget scheduleHistory() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('История записей', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Все дни демо-периода · последние изменения сверху',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 18),
        if (widget.schedule.history.isEmpty)
          Text(
            'История появится после первой записи.',
            style: tx(15, color: C.muted),
          ),
        for (final event in widget.schedule.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(event.label, style: tx(18, weight: FontWeight.w600)),
                  Text(event.actor, style: tx(12, color: C.green)),
                  const SizedBox(height: 10),
                  if (event.before != null)
                    Text(
                      'Было: ${appointmentText(event.before!)}',
                      style: tx(13, color: C.muted),
                    ),
                  if (event.after != null)
                    Text(
                      'Запись: ${appointmentText(event.after!)}',
                      style: tx(14),
                    ),
                  if (event.reason.isNotEmpty)
                    Text('Причина: ${event.reason}', style: tx(14)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
