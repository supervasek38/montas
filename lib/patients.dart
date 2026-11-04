part of 'main.dart';

// The prototype has one personal account. This view projects its existing
// transfers and grants; opening a patient never grants additional access.
extension _ExpertPatientsViews on ExpertWorkspaceState {
  List<DocumentGrant> get patientGrants =>
      widget.data.grants.where((g) => g.recipientId == 'expert-anna').toList();
  bool get hasPatient =>
      requests.isNotEmpty ||
      patientGrants.isNotEmpty ||
      widget.schedule.history.isNotEmpty;
  bool get patientAccessible =>
      requests.any((q) => !q.revoked) || documents.isNotEmpty;
  String get patientStatus => !patientAccessible
      ? (widget.schedule.current != null ? 'Записан на приём' : 'Доступ закрыт')
      : pending.isNotEmpty
      ? 'Требует ответа'
      : 'На связи';

  void openPatient({int tab = 0}) {
    FocusManager.instance.primaryFocus?.unfocus();
    updatePatients(() {
      section = 3;
      patientOpen = true;
      patientTab = tab;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void setPatientTab(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    updatePatients(() => patientTab = value);
  }

  Widget patientMessage(String title, String body, {Widget? action}) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.person_outline, size: 38, color: C.green),
        const SizedBox(height: 16),
        Text(title, style: tx(22, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(body, style: tx(14, color: C.muted)),
        if (action != null) ...[const SizedBox(height: 20), action],
      ],
    ),
  );

  Widget patientsPanel() {
    if (patientOpen && hasPatient) return patientCard();
    final query = patientSearch.text.trim().toLowerCase();
    final match =
        'пользователь демо mnt-demo-001'.contains(query) &&
        switch (patientFilter) {
          'Требуют ответа' => pending.isNotEmpty,
          'Есть документы' => documents.isNotEmpty,
          'Доступ закрыт' => !patientAccessible,
          _ => true,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Мои пациенты',
                      style: tx(24, weight: FontWeight.w600),
                    ),
                  ),
                  Tag(hasPatient ? '1 человек' : '0 человек'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Люди, которые записались на приём, передали вопросы или открыли документы.',
                style: tx(14, color: C.muted),
              ),
              const SizedBox(height: 22),
              TextField(
                key: const ValueKey('patient-search'),
                controller: patientSearch,
                onChanged: (_) => updatePatients(() {}),
                decoration: InputDecoration(
                  labelText: 'Поиск по имени или ID',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить поиск',
                          onPressed: () => updatePatients(patientSearch.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (final option in [
                    'Все',
                    'Требуют ответа',
                    'Есть документы',
                    'Доступ закрыт',
                  ])
                    ChoiceChip(
                      key: ValueKey('patient-filter-$option'),
                      label: Text(option),
                      selected: patientFilter == option,
                      onSelected: (_) =>
                          updatePatients(() => patientFilter = option),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              if (!hasPatient)
                patientMessage(
                  'Пациентов пока нет',
                  'Передайте вопросы из личного кабинета или откройте документ Анне Волковой в «Моих данных». Здесь появится карточка этого пользователя.',
                  action: OutlinedButton(
                    key: const ValueKey('patients-start'),
                    onPressed: widget.onPersonalQuestions,
                    child: const Text('Подготовить вопросы пользователя'),
                  ),
                )
              else if (!match)
                patientMessage(
                  'Ничего не найдено',
                  'Попробуйте другое имя, ID или измените фильтр.',
                  action: TextButton(
                    key: const ValueKey('patients-reset'),
                    onPressed: () => updatePatients(() {
                      patientSearch.clear();
                      patientFilter = 'Все';
                    }),
                    child: const Text('Сбросить поиск и фильтр'),
                  ),
                )
              else
                Material(
                  color: C.soft,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: const ValueKey('patient-open'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => openPatient(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFDDF7E8),
                                foregroundColor: C.green,
                                child: Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Пользователь',
                                      style: tx(20, weight: FontWeight.w600),
                                    ),
                                    Text(
                                      'MNT-DEMO-001 · демо',
                                      style: tx(12, color: C.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Tag(patientStatus, green: patientAccessible),
                              Tag('Без ответа: ${pending.length}'),
                              Tag('Документы: ${documents.length}'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            patientAccessible
                                ? 'Открыть карточку и продолжить работу →'
                                : 'Посмотреть историю доступа →',
                            style: tx(
                              13,
                              color: C.green,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'В этой демо-сессии доступен один личный кабинет. Новая передача вопросов обновляет ту же карточку пациента.',
          style: tx(12, color: C.muted),
        ),
      ],
    );
  }

  Widget patientCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('patient-back'),
                onPressed: () {
                  updatePatients(() => patientOpen = false);
                  if (scroll.hasClients) scroll.jumpTo(0);
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Все пациенты'),
              ),
            ),
            const SizedBox(height: 10),
            Text('Пользователь', style: tx(28, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'MNT-DEMO-001 · личный кабинет прототипа',
              style: tx(12, color: C.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag(patientStatus, green: patientAccessible),
                const Tag('Демо-профиль'),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final item in [
                  'Обзор',
                  'Обращения',
                  'Документы',
                  'Доступы',
                ].indexed)
                  ChoiceChip(
                    key: ValueKey('patient-tab-${item.$1}'),
                    label: Text(item.$2),
                    selected: patientTab == item.$1,
                    onSelected: (_) => setPatientTab(item.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (!patientAccessible) ...[
        Surface(
          color: C.soft,
          padding: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, color: C.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Нет открытых разрешений на данные. Содержимое вопросов, документов и рабочей заметки скрыто. Запись на приём и история разрешений остаются доступными.',
                  style: tx(14, color: C.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
      switch (patientTab) {
        1 => patientRequests(),
        2 => documentsPanel(),
        3 => patientAccess(),
        _ => patientOverview(),
      },
    ],
  );

  Widget patientOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.library.deliveries.isNotEmpty) ...[
        patientLibrarySummary(),
        const SizedBox(height: 18),
      ],
      for (final c in widget.consiliums.cases) caseTile(c),
      if (widget.schedule.current != null) ...[
        appointmentSummary(),
        const SizedBox(height: 18),
      ],
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Сейчас в работе', style: tx(23, weight: FontWeight.w600)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Tag(
                  'Открытые обращения: ${requests.where((q) => !q.revoked).length}',
                ),
                Tag(
                  'Ожидают ответа: ${pending.length}',
                  green: pending.isNotEmpty,
                ),
                Tag('Документы: ${documents.length}'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              pending.isNotEmpty
                  ? 'Пациент передал вопросы. Откройте обращение, чтобы ознакомиться с контекстом и подготовить ответ.'
                  : patientAccessible
                  ? 'Нет обращений, ожидающих ответа. Можно посмотреть разрешённые материалы и историю работы.'
                  : 'Для продолжения пациенту нужно снова передать вопросы или открыть конкретный документ.',
              style: tx(15, color: C.muted),
            ),
            const SizedBox(height: 18),
            if (pending.isNotEmpty)
              PrimaryButton(
                'Ответить на обращение',
                () => openRequest(pending.first, viaPatient: true),
                key: const ValueKey('patient-answer'),
              )
            else
              OutlinedButton(
                onPressed: () => setPatientTab(3),
                child: const Text('Проверить доступы'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Рабочая заметка', style: tx(22, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Видна только специалисту. Пациенту отправляется отдельный подтверждённый ответ.',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 16),
            Text(
              !patientAccessible
                  ? 'Заметка скрыта: доступ к пациенту закрыт.'
                  : patientNote.isEmpty
                  ? 'Зафиксируйте, что уточнить при следующем обращении.'
                  : patientNote,
              key: const ValueKey('patient-saved-note'),
              style: tx(15),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('patient-edit-note'),
              onPressed: patientAccessible ? editPatientNote : null,
              icon: const Icon(Icons.edit_note),
              label: Text(
                patientNote.isEmpty ? 'Добавить заметку' : 'Изменить заметку',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Surface(
        color: C.soft,
        padding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'За пределами текущего доступа',
              style: tx(17, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Радар здоровья, план восстановления, лекарства, семейные профили и личные заметки не переданы специалисту. В карточке отображаются только открытые вопросы и файлы.',
              style: tx(13, color: C.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget patientRequests() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('История обращений', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Каждая передача — отдельное обращение. Ответы и черновики остаются в своих обращениях.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 20),
        if (requests.isEmpty)
          Text('Вопросы пока не переданы.', style: tx(15, color: C.muted)),
        for (final q in requests.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Обращение №${number(q)}',
                    style: tx(18, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Tag(status(q), green: !q.revoked),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.revoked
                        ? 'Содержимое закрыто пользователем.'
                        : q.questions.firstOrNull ?? 'Вопросы пользователя',
                    style: tx(14, color: C.muted),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    key: ValueKey('patient-request-${number(q)}'),
                    onPressed: () => openRequest(q, viaPatient: true),
                    child: Text(
                      q.revoked
                          ? 'Посмотреть статус'
                          : q.specialistReply == null
                          ? 'Открыть и ответить'
                          : 'Посмотреть ответ',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget patientAccess() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Что открыто специалисту', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          'Разрешения выданы Анне Волковой. Дата демо-сценария — 20 октября 2026. Изменить или отозвать доступ может пользователь в личном кабинете.',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 20),
        for (final q in requests.reversed)
          accessRow(
            'Обращение №${number(q)}',
            q.revoked
                ? 'Содержимое вопросов скрыто'
                : 'Только переданный список вопросов',
            q.until,
            q.revoked,
          ),
        for (final g in patientGrants)
          accessRow(
            g.revoked
                ? 'Документ · разрешение №${g.id}'
                : widget.data.document(g.documentId).file.name,
            g.revoked ? 'Название и содержимое скрыты' : g.purpose,
            g.until,
            g.revoked,
          ),
        const Divider(height: 32),
        OutlinedButton(
          key: const ValueKey('patient-manage-access'),
          onPressed: widget.onPersonalData,
          child: const Text('Управлять в личном кабинете'),
        ),
      ],
    ),
  );

  Widget accessRow(
    String title,
    String description,
    String until,
    bool revoked,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Surface(
      color: C.soft,
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: tx(16, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(description, style: tx(13, color: C.muted)),
          const SizedBox(height: 8),
          Text(
            revoked ? 'Доступ отозван' : 'Только просмотр · до $until',
            style: tx(12, color: revoked ? C.muted : C.green),
          ),
        ],
      ),
    ),
  );

  Widget patientContext() => Surface(
    color: const Color(0xFFDDF7E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          patientOpen && hasPatient
              ? 'КОНТЕКСТ ПАЦИЕНТА'
              : 'РАБОТА С ПАЦИЕНТАМИ',
          style: tx(11, color: C.green, weight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text(
          patientOpen && hasPatient ? 'Пользователь' : 'Всё нужное рядом',
          style: tx(22, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          patientOpen && hasPatient
              ? 'MNT-DEMO-001 · демо'
              : 'От первого вопроса до следующей встречи.',
          style: tx(13, color: C.muted),
        ),
        const Divider(height: 32),
        Text('Основание доступа', style: tx(16, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Пациент сам выбирает, какие вопросы и документы передать. Открытие карточки не расширяет разрешения.',
          style: tx(13, color: C.muted),
        ),
        if (patientOpen && hasPatient) ...[
          const SizedBox(height: 18),
          Text(
            'Открытые разрешения: ${requests.where((q) => !q.revoked).length + allowed.length}',
            style: tx(14, weight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => setPatientTab(3),
            child: const Text('Посмотреть доступы →'),
          ),
        ],
        const Divider(height: 32),
        Text('Следующий шаг', style: tx(16, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          hasPatient
              ? 'Откройте обращение из карточки. После ответа можно вернуться к этому же пациенту.'
              : 'Подготовьте вопрос в личном кабинете, затем вернитесь к списку пациентов.',
          style: tx(13, color: C.muted),
        ),
      ],
    ),
  );

  Future<void> editPatientNote() async {
    if (!patientAccessible) return;
    patientNoteDraft.text = patientNote;
    final saved = await modal<String>(
      'Рабочая заметка',
      (ctx) => ListenableBuilder(
        listenable: widget.data,
        builder: (ctx, _) => StatefulBuilder(
          builder: (ctx, local) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Пользователь · MNT-DEMO-001\nТолько для специалиста, до обновления страницы.',
                style: tx(13, color: C.muted),
              ),
              const SizedBox(height: 18),
              if (!patientAccessible)
                Text('Доступ закрыт. Заметка недоступна.', style: tx(15))
              else
                TextField(
                  key: const ValueKey('patient-note-input'),
                  controller: patientNoteDraft,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 2000,
                  onChanged: (_) => local(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Что важно помнить',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 18),
              PrimaryButton(
                'Сохранить заметку',
                !patientAccessible ||
                        patientNoteDraft.text.trim().isEmpty ||
                        patientNoteDraft.text.trim().length > 2000
                    ? null
                    : () => Navigator.pop(ctx, patientNoteDraft.text.trim()),
                key: const ValueKey('patient-note-save'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == null || !mounted) return;
    if (!patientAccessible) {
      notify('Заметка не сохранена: доступ закрыт.');
      return;
    }
    updatePatients(() => patientNote = saved);
    notify('Рабочая заметка сохранена · только для специалиста');
  }
}
