part of 'main.dart';

extension _ExpertLibraryViews on ExpertWorkspaceState {
  void openLibraryItem(LibraryItem i) {
    updatePatients(() {
      if (i.kind == LibraryKind.program) {
        selectedProgram = i;
      } else {
        selectedContent = i;
      }
    });
    navigate(i.kind == LibraryKind.program ? 6 : 7);
  }

  Future<void> editLibrary(LibraryKind kind, [LibraryItem? item]) async {
    final saved = await modal<LibraryItem>(
      item == null
          ? (kind == LibraryKind.program ? 'Новая программа' : 'Новый материал')
          : 'Редактирование',
      (ctx) => LibraryEditor(
        library: widget.library,
        kind: kind,
        item: item,
        onSaved: (i) => Navigator.pop(ctx, i),
      ),
    );
    if (saved != null && mounted) {
      openLibraryItem(saved);
      notify('Черновик сохранён');
    }
  }

  Widget libraryPanel(bool programs) {
    final kind = programs ? LibraryKind.program : LibraryKind.article;
    final selected = programs ? selectedProgram : selectedContent;
    if (selected != null) return libraryDetail(selected);
    final index = programs ? 0 : 1;
    final all = widget.library.items.where((i) => i.kind == kind).toList();
    final filtered = all.where((i) {
      final matches = '${i.draft.title} ${i.draft.summary}'
          .toLowerCase()
          .contains(librarySearch[index].text.trim().toLowerCase());
      return matches &&
          switch (libraryFilters[index]) {
            'Черновики' => !i.archived && i.dirty,
            'Опубликованные' => !i.archived && i.published != null,
            'Архив' => i.archived,
            _ => !i.archived,
          };
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          color: const Color(0xFFDDF7E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                programs
                    ? 'От цели к понятным шагам'
                    : 'Знания, к которым можно вернуться',
                style: tx(25, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                programs
                    ? 'Соберите шаги и материалы, проверьте программу и предложите её пациенту.'
                    : 'Готовьте памятки и статьи. Опубликованные материалы можно включать в программы или предлагать отдельно.',
                style: tx(14, color: C.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(
                    'Готовые: ${all.where((i) => i.published != null && !i.archived).length}',
                  ),
                  Tag(
                    'Черновики: ${all.where((i) => i.dirty && !i.archived).length}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                programs ? 'Создать программу' : 'Создать материал',
                () => editLibrary(kind),
                key: ValueKey('library-create-${kind.name}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: ValueKey('library-search-${kind.name}'),
                controller: librarySearch[index],
                onChanged: (_) => updatePatients(() {}),
                decoration: InputDecoration(
                  labelText: programs ? 'Поиск программ' : 'Поиск материалов',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in [
                    'Все',
                    'Черновики',
                    'Опубликованные',
                    'Архив',
                  ])
                    ChoiceChip(
                      label: Text(f),
                      selected: libraryFilters[index] == f,
                      onSelected: (_) =>
                          updatePatients(() => libraryFilters[index] = f),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                Text(
                  'Ничего не найдено. Измените поиск или создайте новый ${programs ? 'шаблон программы' : 'материал'}.',
                  style: tx(14, color: C.muted),
                ),
              for (final i in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Surface(
                    color: C.soft,
                    padding: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              programs
                                  ? Icons.route_outlined
                                  : Icons.description_outlined,
                              color: C.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                i.draft.title,
                                style: tx(19, weight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(i.draft.summary, style: tx(13, color: C.muted)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Tag(
                              i.status,
                              green: i.published != null && !i.archived,
                            ),
                            if (programs)
                              Tag(
                                '${i.draft.days} дн. · ${i.draft.steps.length} шага',
                              ),
                            if (i.published != null)
                              Tag('Версия ${i.published!.version}'),
                          ],
                        ),
                        TextButton(
                          key: ValueKey('library-open-${i.id}'),
                          onPressed: () => openLibraryItem(i),
                          child: Text(
                            programs
                                ? 'Открыть программу →'
                                : 'Открыть материал →',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget libraryDetail(LibraryItem i) {
    final programs = i.kind == LibraryKind.program;
    final related = widget.library.deliveries
        .where((d) => d.snapshot.itemId == i.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('library-back'),
            onPressed: () => updatePatients(() {
              if (programs) {
                selectedProgram = null;
              } else {
                selectedContent = null;
              }
            }),
            icon: const Icon(Icons.arrow_back),
            label: Text(programs ? 'Все программы' : 'Все материалы'),
          ),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(i.status, green: i.published != null && !i.archived),
                  const Tag('Анна Волкова · демо'),
                ],
              ),
              const SizedBox(height: 16),
              LibraryPreview(
                kind: i.kind,
                edition: i.draft,
                materials: [
                  for (final id in i.draft.materialIds)
                    if (widget.library.item(id)?.published != null)
                      widget.library.item(id)!.published!,
                ],
              ),
              if (i.dirty && i.published != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Это новая редакция. Пациентам доступна ранее отправленная версия ${i.published!.version}.',
                    style: tx(13, color: C.green),
                  ),
                ),
              const SizedBox(height: 20),
              if (!i.archived) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('library-edit'),
                      onPressed: () => editLibrary(i.kind, i),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Редактировать'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('library-preview'),
                      onPressed: () => modal<void>(
                        'Предпросмотр',
                        (_) => LibraryPreview(
                          kind: i.kind,
                          edition: i.draft,
                          materials: [
                            for (final id in i.draft.materialIds)
                              if (widget.library.item(id)?.published != null)
                                widget.library.item(id)!.published!,
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Предпросмотр'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (i.dirty)
                  PrimaryButton(
                    'Проверить и опубликовать',
                    () => reviewLibraryPublication(i),
                    key: const ValueKey('library-review'),
                  ),
                if (i.published != null) ...[
                  const SizedBox(height: 14),
                  PrimaryButton(
                    'Предложить пациенту · версия ${i.published!.version}',
                    () => offerLibrary(i),
                    key: const ValueKey('library-offer'),
                  ),
                ],
              ],
              TextButton(
                key: const ValueKey('library-archive'),
                onPressed: () => archiveLibrary(i),
                child: Text(i.archived ? 'Вернуть из архива' : 'В архив'),
              ),
            ],
          ),
        ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 20),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  programs ? 'Участие пациента' : 'Материал у пациента',
                  style: tx(22, weight: FontWeight.w600),
                ),
                for (final d in related) deliverySummary(d),
                TextButton(
                  onPressed: widget.onPersonalPrograms,
                  key: const ValueKey('library-view-patient'),
                  child: const Text('Открыть у пациента →'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> reviewLibraryPublication(LibraryItem i) async {
    final revision = i.revision;
    final error = widget.library.validate(i.kind, i.draft);
    if (error != null) {
      notify(error);
      return;
    }
    final reviewedMaterials = {
      for (final id in i.draft.materialIds)
        id: widget.library.item(id)!.published!,
    };
    final yes = await modal<bool>(
      'Проверка публикации',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LibraryPreview(
            kind: i.kind,
            edition: i.draft,
            materials: [
              for (final id in i.draft.materialIds)
                widget.library.item(id)!.published!,
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Версия ${(i.published?.version ?? 0) + 1} появится в вашей библиотеке. Предложить её пациенту можно отдельным действием. Уже отправленные версии сохранятся.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Опубликовать в библиотеке',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('library-publish'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      notify(
        widget.library.publish(
              i,
              revision,
              reviewedMaterials: reviewedMaterials,
            )
            ? 'Новая версия опубликована'
            : 'Данные изменились. Повторите проверку',
      );
    }
  }

  Future<void> archiveLibrary(LibraryItem i) async {
    final archived = !i.archived;
    final yes = await modal<bool>(
      archived ? 'Перенести в архив?' : 'Вернуть из архива?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i.draft.title, style: tx(20, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            archived
                ? 'Новые предложения будут недоступны. Уже переданные пациенту версии останутся у него.'
                : 'Материал снова появится в основной библиотеке.',
            style: tx(14),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Подтвердить',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('library-archive-confirm'),
          ),
        ],
      ),
    );
    if (yes == true) widget.library.archive(i, archived);
  }

  Future<void> offerLibrary(LibraryItem i) async {
    final source = requests.where((q) => !q.revoked).firstOrNull;
    if (source == null) {
      notify('Для предложения нужен действующий запрос пациента');
      return;
    }
    final snapshot = i.published!;
    final yes = await modal<bool>(
      'Предложить пациенту',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Tag('Пользователь · демо · MNT-DEMO-001'),
          const SizedBox(height: 16),
          LibraryPreview(
            kind: snapshot.kind,
            edition: snapshot.edition,
            materials: snapshot.materials,
          ),
          const SizedBox(height: 16),
          Text(
            'Версия ${snapshot.version} появится в личном кабинете → Программы → От специалиста. Пациент сам решит, начать ли её. Текущий план не изменится.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Подтвердить предложение',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('library-offer-confirm'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      final delivery = widget.library.offer(i, snapshot, source);
      notify(
        delivery == null
            ? 'Предложение уже существует или данные изменились'
            : 'Предложение добавлено в личный кабинет',
      );
    }
  }

  Widget deliverySummary(LibraryDelivery d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Пользователь · демо', style: tx(15, weight: FontWeight.w600)),
        if (d.source.revoked)
          Text('Доступ к участию закрыт', style: tx(13, color: C.muted))
        else ...[
          Text(
            '${d.label} · версия ${d.snapshot.version} · выполнено ${d.done.length}/${d.total}',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: d.done.length / d.total,
            color: C.green,
            backgroundColor: C.soft,
          ),
          if (d.status == DeliveryStatus.offered)
            TextButton(
              key: ValueKey('library-withdraw-${d.id}'),
              onPressed: () async {
                final yes = await modal<bool>(
                  'Отозвать предложение?',
                  (ctx) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(d.snapshot.edition.title),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        'Отозвать',
                        () => Navigator.pop(ctx, true),
                        key: const ValueKey('library-withdraw-confirm'),
                      ),
                    ],
                  ),
                );
                if (yes == true) {
                  widget.library.transition(d, DeliveryStatus.withdrawn);
                }
              },
              child: const Text('Отозвать предложение'),
            ),
        ],
      ],
    ),
  );

  Widget patientLibrarySummary() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Программы и материалы', style: tx(22, weight: FontWeight.w600)),
        for (final d in widget.library.deliveries) ...[
          const SizedBox(height: 12),
          Text(
            d.snapshot.edition.title,
            style: tx(16, weight: FontWeight.w500),
          ),
          deliverySummary(d),
        ],
        OutlinedButton(
          onPressed: () => navigate(6),
          child: const Text('Открыть библиотеку программ'),
        ),
      ],
    ),
  );

  Widget libraryContext() => Surface(
    color: const Color(0xFFDDF7E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'РАБОТА С БИБЛИОТЕКОЙ',
          style: tx(11, color: C.green, weight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text(
          section == 6 ? 'Шаги и материалы' : 'От черновика к публикации',
          style: tx(22, weight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Text(
          section == 6
              ? 'Включайте опубликованные материалы из раздела «Контент». Для пациента фиксируется версия программы и её материалов.'
              : 'Редактирование сохраняет черновик. После проверки публикуется новая версия, готовая для использования в программах.',
          style: tx(14, color: C.muted),
        ),
        const Divider(height: 32),
        Text(
          'Участие по выбору пациента',
          style: tx(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Предложение появляется в личном кабинете. Выполнение отражается здесь после отметок пациента.',
          style: tx(13, color: C.muted),
        ),
        TextButton(
          onPressed: widget.onPersonalPrograms,
          child: const Text('Программы у пациента →'),
        ),
        Text(
          'Демо-библиотека · изменения до перезагрузки',
          style: tx(11, color: C.muted),
        ),
      ],
    ),
  );
}

class LibraryPreview extends StatelessWidget {
  const LibraryPreview({
    required this.kind,
    required this.edition,
    this.materials = const [],
    super.key,
  });
  final LibraryKind kind;
  final LibraryEdition edition;
  final List<PublishedLibraryItem> materials;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(edition.title, style: tx(24, weight: FontWeight.w600)),
      const SizedBox(height: 12),
      Text(edition.summary, style: tx(15, color: C.muted)),
      if (kind == LibraryKind.program) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Tag('${edition.days} дней'),
            Tag('${edition.steps.length} шага'),
            Tag('Материалы: ${materials.length}'),
          ],
        ),
      ],
      if (edition.body.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(edition.body, style: tx(15)),
      ],
      for (final step in edition.steps.indexed)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.$1 + 1}.',
                style: tx(15, color: C.green, weight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(step.$2, style: tx(15))),
            ],
          ),
        ),
      if (materials.isNotEmpty) ...[
        const Divider(height: 30),
        Text('Материалы программы', style: tx(17, weight: FontWeight.w600)),
        for (final m in materials)
          TextButton.icon(
            onPressed: () => showLibraryReading(context, m),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text('${m.edition.title} · v${m.version}'),
          ),
      ],
    ],
  );
}

Future<void> showLibraryReading(
  BuildContext context,
  PublishedLibraryItem item,
) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(ctx).height - 48,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Закрыть материал',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ),
            Text(
              'Анна Волкова · версия ${item.version}',
              style: tx(12, color: C.muted),
            ),
            const SizedBox(height: 12),
            LibraryPreview(
              kind: item.kind,
              edition: item.edition,
              materials: item.materials,
            ),
          ],
        ),
      ),
    ),
  ),
);

class LibraryEditor extends StatefulWidget {
  const LibraryEditor({
    required this.library,
    required this.kind,
    required this.onSaved,
    this.item,
    super.key,
  });
  final ExpertLibrary library;
  final LibraryKind kind;
  final LibraryItem? item;
  final ValueChanged<LibraryItem> onSaved;
  @override
  State<LibraryEditor> createState() => _LibraryEditorState();
}

class _LibraryEditorState extends State<LibraryEditor> {
  late final title = TextEditingController(text: widget.item?.draft.title);
  late final summary = TextEditingController(text: widget.item?.draft.summary);
  late final body = TextEditingController(text: widget.item?.draft.body);
  late final steps = TextEditingController(
    text: widget.item?.draft.steps.join('\n'),
  );
  late final days = TextEditingController(
    text: '${widget.item?.draft.days ?? 7}',
  );
  late final materialIds = {...?widget.item?.draft.materialIds};
  late final revision = widget.item?.revision;
  String? error;
  @override
  void dispose() {
    for (final c in [title, summary, body, steps, days]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String id,
    String label,
    TextEditingController c, {
    int lines = 1,
    int max = 100,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      key: ValueKey('library-field-$id'),
      controller: c,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 4,
      maxLength: max,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Tag('ЧЕРНОВИК · виден только вам'),
      const SizedBox(height: 20),
      field('title', 'Название', title),
      field('summary', 'Краткое описание', summary, lines: 2, max: 500),
      field(
        'body',
        widget.kind == LibraryKind.program
            ? 'Введение для пациента'
            : 'Текст материала',
        body,
        lines: 4,
        max: 6000,
      ),
      if (widget.kind == LibraryKind.program) ...[
        field('days', 'Продолжительность в днях (1–90)', days, max: 2),
        field(
          'steps',
          'Шаги — каждый с новой строки',
          steps,
          lines: 3,
          max: 2000,
        ),
        Text('Материалы из библиотеки', style: tx(18, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (widget.library.availableMaterials.isEmpty)
          Text(
            'Сначала опубликуйте материал в разделе «Контент». Программу можно сохранить и без материалов.',
            style: tx(13, color: C.muted),
          ),
        for (final m in widget.library.availableMaterials)
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: ValueKey('library-link-${m.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(m.published!.edition.title, style: tx(14)),
              subtitle: Text('Версия ${m.published!.version}'),
              value: materialIds.contains(m.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  materialIds.add(m.id);
                } else {
                  materialIds.remove(m.id);
                }
              }),
            ),
          ),
        for (final id
            in materialIds
                .where(
                  (id) =>
                      !widget.library.availableMaterials.any((m) => m.id == id),
                )
                .toList())
          TextButton(
            onPressed: () => setState(() => materialIds.remove(id)),
            child: Text('Удалить недоступный материал №$id'),
          ),
      ],
      if (error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(error!, style: tx(13, color: Colors.red.shade800)),
        ),
      const SizedBox(height: 16),
      PrimaryButton('Сохранить черновик', () {
        final e = LibraryEdition(
          title: title.text.trim(),
          summary: summary.text.trim(),
          body: body.text.trim(),
          days: int.tryParse(days.text) ?? 0,
          steps: widget.kind == LibraryKind.program
              ? steps.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
              : [],
          materialIds: materialIds.toList(),
        );
        final validation = widget.library.validate(widget.kind, e);
        if (validation != null) {
          setState(() => error = validation);
          return;
        }
        final i = widget.library.save(
          widget.kind,
          e,
          existing: widget.item,
          expectedRevision: revision,
        );
        if (i == null) {
          setState(
            () => error =
                'Данные изменились. Закройте редактор и откройте снова.',
          );
          return;
        }
        widget.onSaved(i);
      }, key: const ValueKey('library-save')),
    ],
  );
}

class PatientLibraryPanel extends StatelessWidget {
  const PatientLibraryPanel({required this.library, super.key});
  final ExpertLibrary library;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('От специалиста', style: tx(25, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Программы и материалы, которые предложила Анна Волкова.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 16),
        for (final d in library.deliveries.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Tag(d.label, green: d.status == DeliveryStatus.completed),
                      Tag('Версия ${d.snapshot.version}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    d.snapshot.edition.title,
                    style: tx(22, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    d.snapshot.edition.summary,
                    style: tx(14, color: C.muted),
                  ),
                  if (!d.canAct) ...[
                    const SizedBox(height: 12),
                    Text(
                      d.source.revoked
                          ? 'Доступ по обращению отозван. Для продолжения свяжитесь со специалистом.'
                          : 'Это предложение больше не активно.',
                      style: tx(13, color: C.muted),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextButton(
                      key: ValueKey('delivery-read-${d.id}'),
                      onPressed: () => showLibraryReading(context, d.snapshot),
                      child: const Text('Посмотреть содержание'),
                    ),
                    if (d.status == DeliveryStatus.offered) ...[
                      PrimaryButton(
                        d.snapshot.kind == LibraryKind.program
                            ? 'Принять программу'
                            : 'Добавить материал',
                        () => library.transition(d, DeliveryStatus.active),
                        key: ValueKey('delivery-accept-${d.id}'),
                      ),
                      TextButton(
                        key: ValueKey('delivery-decline-${d.id}'),
                        onPressed: () =>
                            library.transition(d, DeliveryStatus.declined),
                        child: const Text('Отклонить предложение'),
                      ),
                    ] else ...[
                      Text(
                        'Выполнено ${d.done.length} из ${d.total}',
                        style: tx(14, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: d.done.length / d.total,
                        color: C.green,
                        backgroundColor: C.soft,
                      ),
                      const SizedBox(height: 14),
                      for (var j = 0; j < d.total; j++)
                        Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            key: ValueKey('delivery-step-${d.id}-$j'),
                            value: d.done.contains(j),
                            onChanged: d.status == DeliveryStatus.paused
                                ? null
                                : (v) => library.mark(d, j, v == true),
                            title: Text(
                              d.snapshot.kind == LibraryKind.article
                                  ? 'Материал прочитан'
                                  : d.snapshot.edition.steps[j],
                              style: tx(14),
                            ),
                          ),
                        ),
                      for (final m in d.snapshot.materials)
                        TextButton(
                          onPressed: () => showLibraryReading(context, m),
                          child: Text('Читать: ${m.edition.title}'),
                        ),
                      if (d.status == DeliveryStatus.active ||
                          d.status == DeliveryStatus.paused)
                        TextButton(
                          key: ValueKey('delivery-pause-${d.id}'),
                          onPressed: () => library.transition(
                            d,
                            d.status == DeliveryStatus.paused
                                ? DeliveryStatus.active
                                : DeliveryStatus.paused,
                          ),
                          child: Text(
                            d.status == DeliveryStatus.paused
                                ? 'Продолжить программу'
                                : 'Поставить на паузу',
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
