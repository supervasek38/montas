part of 'main.dart';

class DataDocument {
  DataDocument(this.id, this.file, {this.demo = false});
  final int id;
  final LocalFile file;
  final bool demo;
  String category = 'Без категории';
}

class DataNote {
  DataNote(this.id, this.title, this.body, this.documentId);
  final int id;
  String title, body;
  int? documentId;
  final versions = <({String title, String body, int? documentId})>[];
}

class DocumentGrant {
  DocumentGrant(
    this.id,
    this.documentId,
    this.recipient,
    this.purpose,
    this.days, {
    this.recipientId,
  });
  final int id, documentId, days;
  final String recipient, purpose;
  final String? recipientId;
  bool revoked = false;
  String get until =>
      dataDate(DateTime(2026, 10, 20).add(Duration(days: days)));
}

String dataDate(DateTime date) =>
    '${date.day} ${date.month == 10 ? 'октября' : 'ноября'} 2026, 23:59 · Иркутск';

class DataExport {
  DataExport(this.id, DataDocument document)
    : documentId = document.id,
      file = LocalFile(
        document.file.name,
        document.file.mime,
        document.file.bytes,
      ),
      category = document.category,
      demo = document.demo;
  final int id, documentId;
  final LocalFile file;
  final String category;
  final bool demo;
  bool handedToBrowser = false;

  Uint8List archiveBytes() {
    final safeName = file.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9а-яА-ЯёЁ._ -]'),
      '_',
    );
    final metadata = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'prototype': 'MONTAS · локальная выгрузка',
        'snapshotId': id,
        'sourceDocumentId': documentId,
        'filename': file.name,
        'category': category,
        'demoDocument': demo,
        'scenarioDate': '2026-10-20',
        'includes': ['Исходный файл', 'Это описание'],
        'excludes': [
          'Заметки',
          'Семейные данные',
          'Чаты',
          'Разрешения доступа',
        ],
      }),
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile('document/$safeName', file.bytes.length, file.bytes),
      )
      ..addFile(ArchiveFile('metadata.json', metadata.length, metadata));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }
}

class MyDataStore extends ChangeNotifier {
  MyDataStore() {
    addFile(exampleFile(), demo: true);
  }
  static LocalFile exampleFile() => LocalFile(
    'Подготовка к консультации.txt',
    'text/plain',
    Uint8List.fromList(
      utf8.encode(
        'MONTAS · ДЕМОНСТРАЦИОННЫЙ ДОКУМЕНТ\n\n'
        'Подготовка к консультации\n20 октября 2026\n\n'
        'Цель встречи: обсудить самочувствие и план восстановления.\n'
        'Вопросы для обсуждения:\n'
        '1. Какие наблюдения стоит записывать до следующей встречи?\n'
        '2. Как оценить комфортную нагрузку в течение дня?\n\n'
        'Это вымышленный пример для проверки интерфейса.\n'
        'Медицинских назначений и результатов обследований здесь нет.',
      ),
    ),
  );
  int _nextId = 1;
  final _documents = <DataDocument>[];
  final _notes = <DataNote>[];
  final _grants = <DocumentGrant>[];
  final _exports = <DataExport>[];
  List<DataDocument> get documents => List.unmodifiable(_documents);
  List<DataNote> get notes => List.unmodifiable(_notes);
  List<DocumentGrant> get grants => List.unmodifiable(_grants);
  List<DataExport> get exports => List.unmodifiable(_exports);
  DataDocument document(int id) => _documents.firstWhere((d) => d.id == id);
  DataDocument addFile(LocalFile file, {bool demo = false}) {
    file.validate();
    for (final existing in _documents) {
      if (existing.file.name == file.name &&
          existing.file.bytes.length == file.bytes.length &&
          file.bytes.indexed.every((p) => existing.file.bytes[p.$1] == p.$2)) {
        return existing;
      }
    }
    final value = DataDocument(_nextId++, file, demo: demo);
    _documents.insert(0, value);
    notifyListeners();
    return value;
  }

  void classify(DataDocument document, String category) {
    document.category = category;
    notifyListeners();
  }

  void saveNote({
    DataNote? note,
    required String title,
    required String body,
    int? documentId,
  }) {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('Заполните заметку');
    }
    if (documentId != null) document(documentId);
    if (note == null) {
      _notes.insert(
        0,
        DataNote(_nextId++, title.trim(), body.trim(), documentId),
      );
    } else {
      note.versions.insert(0, (
        title: note.title,
        body: note.body,
        documentId: note.documentId,
      ));
      note.title = title.trim();
      note.body = body.trim();
      note.documentId = documentId;
    }
    notifyListeners();
  }

  DocumentGrant grant(
    DataDocument doc,
    String recipient,
    String purpose,
    int days, {
    String? recipientId,
  }) {
    document(doc.id);
    final value = DocumentGrant(
      _nextId++,
      doc.id,
      recipient,
      purpose,
      days,
      recipientId: recipientId,
    );
    _grants.insert(0, value);
    notifyListeners();
    return value;
  }

  void revoke(DocumentGrant grant) {
    grant.revoked = true;
    notifyListeners();
  }

  DataExport export(DataDocument document) {
    final value = DataExport(_nextId++, document);
    _exports.insert(0, value);
    notifyListeners();
    return value;
  }

  void downloaded(DataExport export) {
    export.handedToBrowser = true;
    notifyListeners();
  }
}

class MyDataSummary extends StatelessWidget {
  const MyDataSummary({required this.data, required this.onOpen, super.key});
  final MyDataStore data;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.folder_open_rounded, color: C.green, size: 30),
        const SizedBox(height: 12),
        Text('Мои данные', style: tx(23, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Документы, личные заметки и контроль доступа — в одном месте.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 12),
        Text(
          'Документы: ${data.documents.length} · Заметки: ${data.notes.length}',
          style: tx(12, color: C.muted),
        ),
        TextButton(
          onPressed: onOpen,
          key: const ValueKey('open-my-data'),
          child: const Text('Открыть мои данные →'),
        ),
      ],
    ),
  );
}

class MyDataScreen extends StatefulWidget {
  const MyDataScreen({
    required this.data,
    required this.people,
    required this.transfers,
    required this.onFamily,
    required this.onQuestions,
    super.key,
  });
  final MyDataStore data;
  final List<FamilyPerson> Function() people;
  final List<QuestionTransfer> Function() transfers;
  final ValueChanged<FamilyPerson?> onFamily;
  final VoidCallback onQuestions;
  @override
  State<MyDataScreen> createState() => MyDataScreenState();
}

class MyDataScreenState extends State<MyDataScreen> {
  static const categories = [
    'Без категории',
    'Анализы и результаты',
    'Заключение',
    'Назначение',
    'Другой документ',
  ];
  static const tabs = ['Документы', 'Заметки', 'Доступы', 'Выгрузки'];
  final scroll = ScrollController();
  final search = TextEditingController();
  int tab = 0;
  String category = 'Все';
  bool picking = false;
  String? fileError;
  MyDataStore get data => widget.data;
  @override
  void dispose() {
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  void openTab(int value) {
    setState(() => tab = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<T?> modal<T>(
    String title,
    Widget Function(BuildContext, StateSetter) body,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
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
                      child: Text(
                        title,
                        style: tx(23, weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                body(ctx, update),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> addDocument() async {
    if (picking) return;
    setState(() {
      picking = true;
      fileError = null;
    });
    LocalFile? file;
    try {
      file = await file_bridge.pick();
    } catch (error) {
      if (mounted) {
        setState(
          () => fileError = error is FormatException
              ? error.message
              : 'Не удалось прочитать файл. Попробуйте выбрать его ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
    if (file == null || !mounted) return;
    await confirmFile(file);
  }

  Future<void> confirmFile(LocalFile file, {bool demo = false}) async {
    bool consent = false;
    String selected = 'Без категории';
    final result = await modal<String>(
      'Добавить документ',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fileLabel(
            file.name,
            '${_size(file.bytes.length)} · ${demo ? 'Демо-файл' : 'Локальный файл'}',
          ),
          const SizedBox(height: 20),
          Text(
            'Файл появится в этой сессии прототипа. После обновления страницы добавленные данные исчезнут.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Категория',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => update(() => selected = v!),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('data-file-consent'),
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: (v) => update(() => consent = v!),
            title: Text(
              demo
                  ? 'Добавить демонстрационный файл'
                  : 'Это мой документ, и я хочу добавить его в прототип',
              style: tx(14),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Добавить в мои данные',
            consent ? () => Navigator.pop(ctx, selected) : null,
            key: const ValueKey('data-save-file'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final count = data.documents.length;
    try {
      final doc = data.addFile(file, demo: demo);
      if (data.documents.length != count) data.classify(doc, result);
      message(
        data.documents.length == count
            ? 'Такой файл уже добавлен. Открыт существующий документ.'
            : 'Документ добавлен в текущую сессию',
      );
      await viewDocument(doc);
    } catch (_) {
      if (mounted) {
        setState(
          () => fileError = 'Не удалось добавить файл. Выберите его повторно.',
        );
      }
    }
  }

  Future<void> viewDocument(DataDocument doc) async {
    final action = await modal<String>(
      'Документ',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fileLabel(
            doc.file.name,
            '${doc.category} · ${_size(doc.file.bytes.length)}',
          ),
          const SizedBox(height: 12),
          Text(
            doc.demo
                ? 'Вымышленный пример · владелец: вы'
                : 'Локальный файл · владелец: вы',
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 18),
          if (doc.file.mime == 'text/plain')
            Surface(
              color: C.soft,
              padding: 18,
              child: SelectableText(_previewText(doc.file), style: tx(14)),
            )
          else if (doc.file.mime.startsWith('image/'))
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                doc.file.bytes,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'Предпросмотр изображения недоступен. Исходный файл можно скачать.',
                ),
              ),
            )
          else
            Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: C.green,
                  ),
                  const SizedBox(height: 12),
                  const Text('PDF откроется в отдельной вкладке браузера.'),
                  TextButton(
                    onPressed: () {
                      try {
                        file_bridge.preview(doc.file);
                      } catch (_) {
                        message(
                          'Не удалось открыть PDF. Попробуйте скачать файл.',
                        );
                      }
                    },
                    child: const Text('Открыть PDF'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Связанные заметки: ${data.notes.where((n) => n.documentId == doc.id).length} · '
            'Активные демо-доступы: ${data.grants.where((g) => g.documentId == doc.id && !g.revoked).length}',
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pair in [
                ('category', 'Изменить категорию'),
                ('note', 'Добавить заметку'),
                ('access', 'Предоставить доступ'),
                ('export', 'Выгрузить'),
              ])
                OutlinedButton(
                  key: ValueKey('data-doc-${pair.$1}'),
                  onPressed: () => Navigator.pop(ctx, pair.$1),
                  child: Text(pair.$2),
                ),
              TextButton(
                onPressed: () => downloadOriginal(doc),
                child: const Text('Скачать исходный файл'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'category':
        await classify(doc);
      case 'note':
        await editNote(documentId: doc.id);
      case 'access':
        await grantAccess(doc);
      case 'export':
        await prepareExport(doc);
    }
  }

  void downloadOriginal(DataDocument doc) {
    try {
      file_bridge.download(doc.file.name, doc.file.mime, doc.file.bytes);
      message('Файл передан браузеру для скачивания');
    } catch (_) {
      message('Не удалось начать скачивание. Попробуйте ещё раз.');
    }
  }

  Future<void> classify(DataDocument doc) async {
    var selected = doc.category;
    final result = await modal<String>(
      'Категория документа',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Категория помогает найти файл. Содержимое документа остаётся прежним.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 16),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: c == selected,
                onSelected: (_) => update(() => selected = c),
              ),
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Сохранить категорию',
            () => Navigator.pop(ctx, selected),
          ),
        ],
      ),
    );
    if (result != null && mounted) data.classify(doc, result);
  }

  Future<void> editNote({DataNote? note, int? documentId}) async {
    final title = TextEditingController(text: note?.title ?? '');
    final body = TextEditingController(text: note?.body ?? '');
    var linked = note?.documentId ?? documentId;
    var invalid = false;
    final saved = await modal<bool>(
      note == null ? 'Новая заметка' : 'Редактировать заметку',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Личная запись. Доступ к документу не открывает эту заметку.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('data-note-title'),
            controller: title,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Заголовок',
              border: const OutlineInputBorder(),
              errorText: invalid && title.text.trim().isEmpty
                  ? 'Введите заголовок'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('data-note-body'),
            controller: body,
            minLines: 4,
            maxLines: 8,
            maxLength: 4000,
            decoration: InputDecoration(
              labelText: 'Текст заметки',
              border: const OutlineInputBorder(),
              errorText: invalid && body.text.trim().isEmpty
                  ? 'Добавьте текст'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: linked ?? -1,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Связанный документ',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: -1, child: Text('Без документа')),
              for (final d in data.documents)
                DropdownMenuItem(
                  value: d.id,
                  child: Text(d.file.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => linked = v == -1 ? null : v,
          ),
          const SizedBox(height: 20),
          PrimaryButton('Сохранить заметку', () {
            if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
              update(() => invalid = true);
              return;
            }
            Navigator.pop(ctx, true);
          }, key: const ValueKey('data-save-note')),
        ],
      ),
    );
    if (saved == true && mounted) {
      data.saveNote(
        note: note,
        title: title.text,
        body: body.text,
        documentId: linked,
      );
      openTab(1);
    }
    // The dialog route can still be animating after its result is returned.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    title.dispose();
    body.dispose();
  }

  Future<void> noteHistory(DataNote note) => modal<void>(
    'История заметки',
    (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Текущая версия ${note.versions.length + 1}',
          style: tx(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(note.body, style: tx(14)),
        for (final version in note.versions.indexed) ...[
          const Divider(height: 32),
          Text(
            'Версия ${note.versions.length - version.$1} · ${version.$2.title}',
            style: tx(16, weight: FontWeight.w600),
          ),
          Text(version.$2.body, style: tx(14)),
          if (version.$2.documentId != null)
            Text(
              'Документ: ${data.document(version.$2.documentId!).file.name}',
              style: tx(12, color: C.muted),
            ),
        ],
      ],
    ),
  );

  Future<void> grantAccess(DataDocument doc) async {
    var recipient = 'Анна · специалист (демо)';
    var purpose = 'Подготовка к консультации';
    var days = 7;
    var consent = false;
    final recipients = [
      'Анна · специалист (демо)',
      for (final p in widget.people())
        '${p.name} · ${p.relation} (демо, №${p.id})',
    ];
    final accepted = await modal<bool>(
      'Доступ к одному документу',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fileLabel(doc.file.name, 'Только просмотр выбранного файла'),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: recipient,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Кому',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final r in recipients)
                DropdownMenuItem(
                  value: r,
                  child: Text(r, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => update(() => recipient = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: purpose,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Для чего',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final p in [
                'Подготовка к консультации',
                'Обсуждение документа',
                'Помощь близкого',
              ])
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => update(() => purpose = v!),
          ),
          const SizedBox(height: 16),
          Text('Срок доступа', style: tx(14, weight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: [
              for (final d in [1, 7, 30])
                ChoiceChip(
                  label: Text('$d ${d == 1 ? 'день' : 'дней'}'),
                  selected: days == d,
                  onSelected: (_) => update(() => days = d),
                ),
            ],
          ),
          Text(
            'До ${dataDate(DateTime(2026, 10, 20).add(Duration(days: days)))}',
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 16),
          Text(
            'Демо-разрешение: реальная отправка не выполняется. Заметки, другие файлы и семейные данные не включены.',
            style: tx(14, color: C.muted),
          ),
          CheckboxListTile(
            key: const ValueKey('data-access-consent'),
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: (v) => update(() => consent = v!),
            title: Text(
              'Подтверждаю получателя, документ, цель и срок',
              style: tx(14),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Создать демо-доступ',
            consent ? () => Navigator.pop(ctx, true) : null,
            key: const ValueKey('data-confirm-access'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      data.grant(
        doc,
        recipient,
        purpose,
        days,
        recipientId: recipient == recipients.first ? 'expert-anna' : null,
      );
      openTab(2);
    }
  }

  Future<void> revoke(DocumentGrant grant) async {
    final accepted = await modal<bool>(
      'Отозвать доступ?',
      (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${grant.recipient}\n${data.document(grant.documentId).file.name}',
            style: tx(16),
          ),
          const SizedBox(height: 14),
          Text(
            'Это разрешение перестанет действовать в демо-сценарии. Другие выданные разрешения сохранятся.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Отозвать этот доступ',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('data-confirm-revoke'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) data.revoke(grant);
  }

  Future<void> prepareExport(DataDocument doc) async {
    var consent = false;
    final accepted = await modal<bool>(
      'Проверить состав выгрузки',
      (ctx, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fileLabel(
            doc.file.name,
            '${doc.category} · ${_size(doc.file.bytes.length)}',
          ),
          const SizedBox(height: 20),
          Text(
            'ZIP-архив: исходный файл и описание с категорией на момент создания.',
            style: tx(16, weight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Заметки, чаты, семейные данные и разрешения не входят в архив. Выгрузка не предоставляет доступ. Поздние изменения категории не изменят этот снимок.',
            style: tx(14, color: C.muted),
          ),
          CheckboxListTile(
            key: const ValueKey('data-export-consent'),
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: (v) => update(() => consent = v!),
            title: Text('Состав проверен, создать мою копию', style: tx(14)),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Подготовить выгрузку',
            consent ? () => Navigator.pop(ctx, true) : null,
            key: const ValueKey('data-confirm-export'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      data.export(doc);
      openTab(3);
    }
  }

  void downloadExport(DataExport export) {
    try {
      final bytes = export.archiveBytes();
      file_bridge.download(
        'montas-document-${export.id}.zip',
        'application/zip',
        bytes,
      );
      data.downloaded(export);
      message('Архив передан браузеру. Проверьте список загрузок.');
    } catch (_) {
      message(
        'Не удалось скачать архив. Выгрузка сохранена в сессии — попробуйте ещё раз.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final mobile = box.maxWidth < 700;
        final body = switch (tab) {
          0 => documents(),
          1 => notes(),
          2 => accesses(),
          _ => exports(),
        };
        return SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.all(mobile ? 18 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ЛИЧНОЕ ПРОСТРАНСТВО / МОИ ДАННЫЕ',
                    style: tx(11, color: C.muted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Всё важное. Под вашим контролем.',
                    style: tx(
                      mobile ? 30 : 38,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Собирайте документы, сохраняйте мысли и выбирайте, чем делиться.',
                    style: tx(15, color: C.muted),
                  ),
                  const SizedBox(height: 24),
                  Surface(
                    color: C.dark,
                    padding: mobile ? 20 : 28,
                    child: Wrap(
                      spacing: 36,
                      runSpacing: 20,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_copy_outlined,
                          color: C.lime,
                          size: 36,
                        ),
                        for (final stat in [
                          ('${data.documents.length}', 'Документы'),
                          ('${data.notes.length}', 'Личные заметки'),
                          (
                            '${data.grants.where((g) => !g.revoked).length}',
                            'Доступы к файлам',
                          ),
                        ])
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.$1,
                                style: tx(
                                  28,
                                  color: Colors.white,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                stat.$2,
                                style: tx(12, color: const Color(0xFFBDD0C5)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        ChoiceChip(
                          key: ValueKey('data-tab-$i'),
                          label: Text(tabs[i]),
                          selected: tab == i,
                          showCheckmark: false,
                          onSelected: (_) => openTab(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (box.maxWidth >= 1000)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: body),
                        const SizedBox(width: 24),
                        SizedBox(width: 285, child: privacyCard()),
                      ],
                    )
                  else ...[
                    body,
                    const SizedBox(height: 20),
                    privacyCard(),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Демо-сценарий · 20 октября 2026 · файлы и изменения живут до обновления страницы',
                    style: tx(11, color: C.muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget privacyCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined, color: C.green, size: 28),
        const SizedBox(height: 16),
        Text(
          'Вы выбираете, что открыть',
          style: tx(21, weight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Каждое разрешение связано с получателем, целью и сроком. Его можно отозвать.',
          style: tx(14, color: C.muted),
        ),
        const Divider(height: 32),
        Text(
          'Сейчас — локальный прототип',
          style: tx(14, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Добавленные файлы остаются в памяти этой вкладки. После обновления страницы они исчезнут. Скачайте нужную копию заранее.',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 8),
        Text(
          'Демо-доступы не отправляют файлы людям или ИИ.',
          style: tx(13, color: C.muted),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => widget.onFamily(null),
          child: const Text('Семья и близкие →'),
        ),
        TextButton(
          onPressed: widget.onQuestions,
          child: const Text('Вопросы специалисту →'),
        ),
      ],
    ),
  );

  Widget documents() {
    final filtered = data.documents
        .where(
          (d) =>
              (category == 'Все' || d.category == category) &&
              d.file.name.toLowerCase().contains(
                search.text.toLowerCase().trim(),
              ),
        )
        .toList();
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Документы', 'Оригиналы и результаты, которые вы добавили.'),
          const SizedBox(height: 18),
          PrimaryButton(
            picking ? 'Выберите файл в окне браузера…' : 'Добавить документ',
            picking ? null : addDocument,
            key: const ValueKey('data-add-file'),
          ),
          Text(
            'PDF, PNG, JPG, TXT · до 10 МБ',
            textAlign: TextAlign.center,
            style: tx(11, color: C.muted),
          ),
          if (fileError != null) ...[
            const SizedBox(height: 12),
            Text(fileError!, style: tx(14, color: Colors.red.shade800)),
            TextButton(
              onPressed: addDocument,
              child: const Text('Выбрать файл повторно'),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('data-search'),
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Найти документ',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () => setState(() => search.clear()),
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Показать',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in ['Все', ...categories])
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            _empty(
              Icons.search_off,
              'Ничего не найдено',
              'Измените запрос или выберите другую категорию.',
            ),
          for (final d in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: C.soft,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: ValueKey('data-file-${d.id}'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => viewDocument(d),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fileLabel(
                          d.file.name,
                          '${d.category} · ${_size(d.file.bytes.length)}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Tag(d.demo ? 'Демо-файл' : 'Мой файл'),
                            const Tag('Только эта сессия'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Открыть документ →',
                          style: tx(
                            13,
                            color: C.green,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          TextButton(
            key: const ValueKey('data-demo-file'),
            onPressed: () => confirmFile(MyDataStore.exampleFile(), demo: true),
            child: const Text('Попробовать на демо-файле'),
          ),
        ],
      ),
    );
  }

  Widget notes() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Личные заметки',
          'Мысли и вопросы, к которым хочется вернуться.',
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Создать заметку',
          () => editNote(),
          key: const ValueKey('data-new-note'),
        ),
        const SizedBox(height: 20),
        if (data.notes.isEmpty)
          _empty(
            Icons.edit_note_rounded,
            'Здесь будут ваши заметки',
            'Запишите вопрос перед консультацией или добавьте комментарий к документу.',
          ),
        for (final note in data.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(note.title, style: tx(19, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(note.body, style: tx(14)),
                  const SizedBox(height: 12),
                  Text(
                    'Только вы · версия ${note.versions.length + 1}',
                    style: tx(12, color: C.muted),
                  ),
                  if (note.documentId != null)
                    TextButton(
                      onPressed: () =>
                          viewDocument(data.document(note.documentId!)),
                      child: Text(
                        'Документ: ${data.document(note.documentId!).file.name}',
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        key: ValueKey('data-edit-note-${note.id}'),
                        onPressed: () => editNote(note: note),
                        child: const Text('Редактировать'),
                      ),
                      TextButton(
                        onPressed: () => noteHistory(note),
                        child: const Text('История версий'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget accesses() {
    final people = widget.people();
    final transfers = widget.transfers();
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Доступы', 'Кто видит данные и на каких условиях.'),
          const SizedBox(height: 20),
          Text('Документы · я делюсь', style: tx(18, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (data.grants.isEmpty)
            Text(
              'Доступ к файлам пока не выдавался. Откройте документ и выберите «Предоставить доступ».',
              style: tx(14, color: C.muted),
            ),
          for (final grant in data.grants)
            _accessCard(
              grant.recipient,
              '${data.document(grant.documentId).file.name}\n${grant.purpose}\nТолько просмотр · до ${grant.until}',
              grant.revoked ? 'Отозван' : 'Действует · демо',
              grant.revoked ? null : () => revoke(grant),
              'Отозвать',
              key: ValueKey('data-revoke-${grant.id}'),
            ),
          TextButton(
            onPressed: () => openTab(0),
            child: const Text('Выбрать документ →'),
          ),
          const Divider(height: 32),
          Text(
            'Семья · общие разрешения',
            style: tx(18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь отражаются текущие разрешения из раздела «Семья». Доступ к отдельному файлу управляется выше.',
            style: tx(13, color: C.muted),
          ),
          for (final person in people) ...[
            if (person.incoming != null)
              _accessCard(
                '${person.name} → мне',
                _familyDetail(person.incoming!),
                person.incoming!.revoked ? 'Отозван' : 'Действует · демо',
                () => widget.onFamily(person),
                'Управлять в «Семье»',
              ),
            if (person.outgoing != null)
              _accessCard(
                'Я → ${person.name}',
                _familyDetail(person.outgoing!),
                person.outgoing!.revoked ? 'Отозван' : 'Действует · демо',
                () => widget.onFamily(person),
                'Управлять в «Семье»',
              ),
            if (person.pending != null)
              _accessCard(
                'Запрос к ${person.name}',
                _familyDetail(person.pending!),
                'Ожидает решения',
                () => widget.onFamily(person),
                'Открыть запрос',
              ),
          ],
          const Divider(height: 32),
          Text('Вопросы специалисту', style: tx(18, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (transfers.isEmpty)
            Text(
              'Переданных вопросов пока нет.',
              style: tx(14, color: C.muted),
            ),
          for (final transfer in transfers.reversed)
            _accessCard(
              'Я → Анна · специалист',
              'Вопросов: ${transfer.questions.length} · без документов и заметок\nДо ${transfer.until}',
              transfer.revoked ? 'Отозван' : 'Действует · демо',
              widget.onQuestions,
              'Открыть передачу вопросов',
            ),
          TextButton(
            onPressed: widget.onQuestions,
            child: const Text('Перейти в «Спросить» →'),
          ),
        ],
      ),
    );
  }

  String _familyDetail(FamilyAccess access) =>
      '${access.scopes.map(familyScopeLabel).join(' · ')}\nДо ${access.until}';
  Widget _accessCard(
    String title,
    String body,
    String status,
    VoidCallback? action,
    String label, {
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Surface(
      color: C.soft,
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tx(16, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: tx(13, color: C.muted)),
          const SizedBox(height: 12),
          Tag(status, green: status.startsWith('Действует')),
          if (action != null)
            TextButton(key: key, onPressed: action, child: Text(label)),
        ],
      ),
    ),
  );

  Widget exports() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Мои выгрузки',
          'Отдельная копия выбранного документа и его описания.',
        ),
        const SizedBox(height: 20),
        if (data.exports.isEmpty)
          _empty(
            Icons.download_outlined,
            'Выгрузок пока нет',
            'Откройте документ, выберите «Выгрузить» и проверьте состав копии.',
          ),
        for (final export in data.exports)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              color: C.soft,
              padding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fileLabel(
                    export.file.name,
                    'Снимок №${export.id} · ${export.category}',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ZIP · исходный файл + metadata.json',
                    style: tx(13, color: C.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    export.handedToBrowser
                        ? 'Передан браузеру для скачивания'
                        : 'Готов к скачиванию',
                    style: tx(13, color: C.green),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    export.handedToBrowser
                        ? 'Скачать ZIP повторно'
                        : 'Скачать ZIP',
                    () => downloadExport(export),
                    key: ValueKey('data-download-${export.id}'),
                  ),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: () => openTab(0),
          child: const Text('Выбрать документ для выгрузки →'),
        ),
      ],
    ),
  );
  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: tx(24, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(subtitle, style: tx(14, color: C.muted)),
    ],
  );
  Widget _empty(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, size: 42, color: C.green),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tx(19, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: tx(14, color: C.muted),
        ),
      ],
    ),
  );
  Widget _fileLabel(String name, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.description_outlined, color: C.green, size: 30),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: tx(16, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle, style: tx(12, color: C.muted)),
          ],
        ),
      ),
    ],
  );
  String _size(int length) => length < 1024
      ? '$length Б'
      : length < 1024 * 1024
      ? '${(length / 1024).toStringAsFixed(1)} КБ'
      : '${(length / (1024 * 1024)).toStringAsFixed(1)} МБ';
  String _previewText(LocalFile file) {
    final value = utf8.decode(file.bytes, allowMalformed: true);
    return value.length <= 20000
        ? value
        : '${value.substring(0, 20000)}\n\nПоказано начало файла. Полная версия доступна при скачивании.';
  }
}
