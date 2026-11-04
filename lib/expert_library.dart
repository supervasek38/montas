part of 'main.dart';

enum LibraryKind { program, article }

enum DeliveryStatus { offered, active, paused, completed, declined, withdrawn }

class LibraryEdition {
  LibraryEdition({
    required this.title,
    required this.summary,
    required this.body,
    this.days = 7,
    List<String> steps = const [],
    List<int> materialIds = const [],
  }) : steps = List.unmodifiable(steps),
       materialIds = List.unmodifiable(materialIds);
  final String title, summary, body;
  final int days;
  final List<String> steps;
  final List<int> materialIds;
}

class PublishedLibraryItem {
  PublishedLibraryItem(
    this.itemId,
    this.kind,
    this.version,
    this.edition,
    List<PublishedLibraryItem> materials,
  ) : materials = List.unmodifiable(materials);
  final int itemId, version;
  final LibraryKind kind;
  final LibraryEdition edition;
  final List<PublishedLibraryItem> materials;
}

class LibraryItem {
  LibraryItem(this.id, this.kind, this.draft);
  final int id;
  final LibraryKind kind;
  LibraryEdition draft;
  int revision = 1;
  int publishedRevision = 0;
  bool archived = false;
  PublishedLibraryItem? published;
  bool get dirty => publishedRevision != revision;
  String get status => archived
      ? 'В архиве'
      : published == null
      ? 'Черновик'
      : dirty
      ? 'Изменения в черновике'
      : 'Опубликовано';
}

class LibraryDelivery {
  LibraryDelivery(this.id, this.snapshot, this.source);
  final int id;
  final PublishedLibraryItem snapshot;
  final QuestionTransfer source;
  DeliveryStatus status = DeliveryStatus.offered;
  final _done = <int>{};
  Set<int> get done => Set.unmodifiable(_done);
  int get total =>
      snapshot.kind == LibraryKind.article ? 1 : snapshot.edition.steps.length;
  bool get canAct =>
      !source.revoked &&
      status != DeliveryStatus.withdrawn &&
      status != DeliveryStatus.declined;
  String get label => switch (status) {
    DeliveryStatus.offered => 'Предложено',
    DeliveryStatus.active => 'В работе',
    DeliveryStatus.paused => 'На паузе',
    DeliveryStatus.completed => 'Завершено',
    DeliveryStatus.declined => 'Отклонено',
    DeliveryStatus.withdrawn => 'Предложение отозвано',
  };
}

class ExpertLibrary extends ChangeNotifier {
  final _items = <LibraryItem>[];
  final _deliveries = <LibraryDelivery>[];
  List<LibraryItem> get items => List.unmodifiable(_items);
  List<LibraryDelivery> get deliveries => List.unmodifiable(_deliveries);
  LibraryItem? item(int id) => _items.where((i) => i.id == id).firstOrNull;
  List<LibraryItem> get availableMaterials => _items
      .where(
        (i) =>
            i.kind == LibraryKind.article && !i.archived && i.published != null,
      )
      .toList();
  String? validate(LibraryKind kind, LibraryEdition e) {
    if (e.title.trim().length < 3 || e.title.length > 100) {
      return 'Название: от 3 до 100 символов';
    }
    if (e.summary.trim().length < 10 || e.summary.length > 500) {
      return 'Описание: от 10 до 500 символов';
    }
    if (e.body.length > 6000) return 'Текст: не больше 6000 символов';
    if (kind == LibraryKind.article && e.body.trim().length < 10) {
      return 'Добавьте текст материала (от 10 символов)';
    }
    if (kind == LibraryKind.program &&
        (e.days < 1 ||
            e.days > 90 ||
            e.steps.isEmpty ||
            e.steps.length > 10 ||
            e.steps.any((s) => s.trim().length < 3 || s.length > 200))) {
      return 'Укажите 1–90 дней и от 1 до 10 шагов (3–200 символов каждый)';
    }
    if (kind == LibraryKind.program &&
        e.materialIds.any((id) => !availableMaterials.any((m) => m.id == id))) {
      return 'Один из материалов недоступен. Обновите список материалов';
    }
    return null;
  }

  LibraryItem? save(
    LibraryKind kind,
    LibraryEdition edition, {
    LibraryItem? existing,
    int? expectedRevision,
  }) {
    if (validate(kind, edition) != null) return null;
    if (existing != null) {
      if (!_items.contains(existing) ||
          existing.archived ||
          existing.kind != kind ||
          existing.revision != expectedRevision) {
        return null;
      }
      existing.draft = edition;
      existing.revision++;
    } else {
      existing = LibraryItem(_items.length + 1, kind, edition);
      _items.add(existing);
    }
    notifyListeners();
    return existing;
  }

  bool publish(
    LibraryItem i,
    int revision, {
    Map<int, PublishedLibraryItem>? reviewedMaterials,
  }) {
    if (reviewedMaterials != null &&
        reviewedMaterials.entries.any(
          (e) => !identical(item(e.key)?.published, e.value),
        )) {
      return false;
    }
    if (!_items.contains(i) ||
        i.archived ||
        !i.dirty ||
        i.revision != revision ||
        validate(i.kind, i.draft) != null) {
      return false;
    }
    i.published = PublishedLibraryItem(
      i.id,
      i.kind,
      (i.published?.version ?? 0) + 1,
      i.draft,
      i.kind == LibraryKind.program
          ? [for (final id in i.draft.materialIds) item(id)!.published!]
          : [],
    );
    i.publishedRevision = revision;
    notifyListeners();
    return true;
  }

  bool archive(LibraryItem i, bool archived) {
    if (!_items.contains(i) || i.archived == archived) return false;
    i.archived = archived;
    i.revision++;
    // Archiving/restoring does not alter the published edition or create a draft.
    if (i.publishedRevision == i.revision - 1) i.publishedRevision = i.revision;
    notifyListeners();
    return true;
  }

  LibraryDelivery? offer(
    LibraryItem i,
    PublishedLibraryItem reviewed,
    QuestionTransfer source,
  ) {
    if (!_items.contains(i) ||
        i.archived ||
        source.revoked ||
        !identical(i.published, reviewed)) {
      return null;
    }
    if (_deliveries.any(
      (d) =>
          d.snapshot.itemId == i.id &&
          !d.source.revoked &&
          d.status != DeliveryStatus.declined &&
          d.status != DeliveryStatus.withdrawn,
    )) {
      return null;
    }
    final d = LibraryDelivery(_deliveries.length + 1, reviewed, source);
    _deliveries.add(d);
    notifyListeners();
    return d;
  }

  bool transition(LibraryDelivery d, DeliveryStatus next) {
    if (!_deliveries.contains(d) || !d.canAct) return false;
    final valid = switch (d.status) {
      DeliveryStatus.offered => [
        DeliveryStatus.active,
        DeliveryStatus.declined,
        DeliveryStatus.withdrawn,
      ].contains(next),
      DeliveryStatus.active => next == DeliveryStatus.paused,
      DeliveryStatus.paused => next == DeliveryStatus.active,
      _ => false,
    };
    if (!valid) return false;
    d.status = next;
    notifyListeners();
    return true;
  }

  bool mark(LibraryDelivery d, int step, bool done) {
    if (!_deliveries.contains(d) ||
        !d.canAct ||
        ![DeliveryStatus.active, DeliveryStatus.completed].contains(d.status) ||
        step < 0 ||
        step >= d.total) {
      return false;
    }
    if (done) {
      d._done.add(step);
    } else {
      d._done.remove(step);
    }
    d.status = d.done.length == d.total
        ? DeliveryStatus.completed
        : DeliveryStatus.active;
    notifyListeners();
    return true;
  }

  void seedDemo() {
    if (_items.isNotEmpty) return;
    final a = save(
      LibraryKind.article,
      LibraryEdition(
        title: 'Подготовка к встрече со специалистом',
        summary:
            'Короткая памятка: как собрать вопросы и ничего не забыть на встрече.',
        body:
            'Запишите, что вы хотели бы обсудить и какого результата ждёте от встречи.\n\nВыберите два-три главных вопроса. Если у вас есть записи наблюдений, подготовьте их для обсуждения.\n\nВ конце встречи уточните, как связаться со специалистом, если появятся дополнительные вопросы.\n\nДемонстрационный информационный материал.',
      ),
    )!;
    publish(a, a.revision);
    final p = save(
      LibraryKind.program,
      LibraryEdition(
        title: 'Подготовка к консультации',
        summary:
            'За три дня собрать вопросы и подготовить контекст для спокойной беседы.',
        body:
            'Организационная программа от Анны Волковой. Пройдите шаги в удобном темпе перед запланированной встречей.',
        days: 3,
        steps: [
          'Прочитать памятку о подготовке к встрече',
          'Записать два вопроса, которые хочется обсудить',
        ],
        materialIds: [a.id],
      ),
    )!;
    publish(p, p.revision);
    save(
      LibraryKind.article,
      LibraryEdition(
        title: 'После консультации',
        summary: 'Черновик памятки о том, как сохранить итоги разговора.',
        body:
            'Запишите, какие вопросы удалось обсудить и что хотите уточнить на следующей встрече.',
      ),
    );
  }
}
