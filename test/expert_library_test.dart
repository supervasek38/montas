import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'expert_test.dart' show k, switchTo;
import 'widget_test.dart' show tapVisible;

Future<ExpertWorkspaceState> libraryStart(WidgetTester t, double width) async {
  t.view.physicalSize = Size(width, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(const MontasApp(seedDemo: true));
  await t.pumpAndSettle();
  await switchTo(t, 'expert');
  return t.state<ExpertWorkspaceState>(find.byType(ExpertWorkspace));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Onest',
    )..addFont(rootBundle.load('assets/Onest.ttf'))).load();
  });
  test(
    'Published deliveries freeze program and material editions; stale writes fail',
    () {
      final lib = ExpertLibrary()..seedDemo();
      addTearDown(lib.dispose);
      final a = lib.item(1)!;
      final p = lib.item(2)!;
      final q = QuestionTransfer(['Question'], 7);
      final old = p.published!;
      final d = lib.offer(p, old, q)!;
      lib.save(
        LibraryKind.article,
        LibraryEdition(
          title: 'Changed article',
          summary: 'Changed summary',
          body: 'Changed body for patient',
        ),
        existing: a,
        expectedRevision: a.revision,
      );
      expect(
        a.published!.edition.title,
        'Подготовка к встрече со специалистом',
      );
      expect(
        lib.save(
          LibraryKind.article,
          a.draft,
          existing: a,
          expectedRevision: 1,
        ),
        isNull,
      );
      lib.publish(a, a.revision);
      expect(
        d.snapshot.materials.single.edition.title,
        'Подготовка к встрече со специалистом',
      );
      lib.save(
        LibraryKind.program,
        p.draft,
        existing: p,
        expectedRevision: p.revision,
      );
      final reviewed = {a.id: a.published!};
      lib.save(
        LibraryKind.article,
        a.draft,
        existing: a,
        expectedRevision: a.revision,
      );
      lib.publish(a, a.revision);
      expect(lib.publish(p, p.revision, reviewedMaterials: reviewed), isFalse);
      expect(lib.publish(p, p.revision - 1), isFalse);
      expect(lib.publish(p, p.revision), isTrue);
      expect(d.snapshot, same(old));
      expect(lib.offer(p, old, q), isNull);
      expect(lib.offer(p, p.published!, q), isNull);
      expect(lib.transition(d, DeliveryStatus.active), isTrue);
      expect(lib.mark(d, 0, true), isTrue);
      expect(lib.transition(d, DeliveryStatus.paused), isTrue);
      expect(lib.mark(d, 1, true), isFalse);
      expect(lib.transition(d, DeliveryStatus.active), isTrue);
      expect(lib.mark(d, 1, true), isTrue);
      expect(d.status, DeliveryStatus.completed);
      expect(lib.mark(d, 1, false), isTrue);
      q.revoked = true;
      expect(lib.mark(d, 1, true), isFalse);
      expect(lib.offer(a, a.published!, q), isNull);
    },
  );
  test(
    'Invalid, archived and declined items cannot start; archive retains existing snapshot',
    () {
      final lib = ExpertLibrary()..seedDemo();
      addTearDown(lib.dispose);
      final p = lib.item(2)!;
      final a = lib.item(1)!;
      final q = QuestionTransfer(['Question'], 7);
      expect(
        lib.save(
          LibraryKind.program,
          LibraryEdition(
            title: 'Valid title',
            summary: 'Valid summary',
            body: '',
            days: 0,
            steps: ['step'],
          ),
        ),
        isNull,
      );
      final d = lib.offer(p, p.published!, q)!;
      lib.transition(d, DeliveryStatus.declined);
      expect(lib.transition(d, DeliveryStatus.active), isFalse);
      final next = lib.offer(p, p.published!, q)!;
      lib.archive(p, true);
      expect(lib.publish(p, p.revision), isFalse);
      expect(lib.transition(next, DeliveryStatus.active), isTrue);
      expect(lib.mark(next, 0, true), isTrue);
      lib.archive(a, true);
      lib.archive(p, false);
      expect(
        lib.save(
          LibraryKind.program,
          p.draft,
          existing: p,
          expectedRevision: p.revision,
        ),
        isNull,
      );
      expect(next.snapshot.materials.single.edition.body, isNotEmpty);
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Program offer, acceptance, pause and progress at $width', (
      t,
    ) async {
      final expert = await libraryStart(t, width);
      await tapVisible(t, k('expert-nav-6'));
      await tapVisible(t, k('library-open-2'));
      await tapVisible(t, k('library-offer'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(expert.widget.library.deliveries, isEmpty);
      await tapVisible(t, k('library-offer'));
      await tapVisible(t, k('library-offer-confirm'));
      final d = expert.widget.library.deliveries.single;
      await tapVisible(t, k('library-view-patient'));
      expect(find.text('От специалиста'), findsOneWidget);
      await tapVisible(t, k('delivery-read-1'));
      expect(find.text(d.snapshot.edition.title), findsWidgets);
      await tapVisible(t, find.byTooltip('Закрыть материал'));
      await tapVisible(t, k('delivery-accept-1'));
      await tapVisible(t, k('delivery-step-1-0'));
      await tapVisible(t, k('delivery-pause-1'));
      expect(d.status, DeliveryStatus.paused);
      expect(
        t.widget<CheckboxListTile>(k('delivery-step-1-1')).onChanged,
        isNull,
      );
      await tapVisible(t, k('delivery-pause-1'));
      await tapVisible(t, k('delivery-step-1-1'));
      expect(d.status, DeliveryStatus.completed);
      await switchTo(t, 'expert');
      expect(find.text('Завершено · версия 1 · выполнено 2/2'), findsOneWidget);
      await tapVisible(t, k('expert-nav-7'));
      await tapVisible(t, k('library-open-1'));
      await tapVisible(t, k('library-edit'));
      await t.enterText(k('library-field-title'), 'Памятка: новая редакция');
      await tapVisible(t, k('library-save'));
      expect(expert.widget.library.item(1)!.published!.version, 1);
      await tapVisible(t, k('library-review'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(expert.widget.library.item(1)!.published!.version, 1);
      await tapVisible(t, k('library-review'));
      await tapVisible(t, k('library-publish'));
      expect(expert.widget.library.item(1)!.published!.version, 2);
      expect(d.snapshot.materials.single.version, 1);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('Create content, link it to new program, validate and archive', (
    t,
  ) async {
    final expert = await libraryStart(t, 390);
    final lib = expert.widget.library;
    await tapVisible(t, k('expert-nav-7'));
    await tapVisible(t, k('library-create-article'));
    await tapVisible(t, k('library-save'));
    expect(lib.items.length, 3);
    await t.enterText(k('library-field-title'), 'Тестовая памятка');
    await t.enterText(k('library-field-summary'), 'Описание тестовой памятки');
    await t.enterText(
      k('library-field-body'),
      'Текст для проверки пользовательского сценария.',
    );
    await tapVisible(t, k('library-save'));
    await tapVisible(t, k('library-review'));
    await tapVisible(t, k('library-publish'));
    await tapVisible(t, k('expert-nav-6'));
    await tapVisible(t, k('library-create-program'));
    await t.enterText(k('library-field-title'), 'Новая программа');
    await t.enterText(k('library-field-summary'), 'Описание новой программы');
    await t.enterText(
      k('library-field-steps'),
      'Прочитать материал\nПодготовить вопросы',
    );
    await tapVisible(t, k('library-link-4'));
    await tapVisible(t, k('library-save'));
    expect(lib.item(5)!.draft.materialIds, [4]);
    await tapVisible(t, k('library-review'));
    await tapVisible(t, k('library-publish'));
    await tapVisible(t, k('library-archive'));
    await tapVisible(t, k('library-archive-confirm'));
    expect(lib.item(5)!.archived, isTrue);
    expect(k('library-offer'), findsNothing);
    await tapVisible(t, k('library-archive'));
    await tapVisible(t, k('library-archive-confirm'));
    expect(lib.item(5)!.archived, isFalse);
    await tapVisible(t, k('library-back'));
    await t.enterText(k('library-search-program'), 'не существует');
    await t.pumpAndSettle();
    expect(k('library-open-5'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('Standalone material can be declined, withdrawn or marked read', (
    t,
  ) async {
    final expert = await libraryStart(t, 390);
    final lib = expert.widget.library;
    await tapVisible(t, k('expert-nav-7'));
    await tapVisible(t, k('library-open-1'));
    await tapVisible(t, k('library-offer'));
    await tapVisible(t, k('library-offer-confirm'));
    await tapVisible(t, k('library-view-patient'));
    await tapVisible(t, k('delivery-decline-1'));
    expect(lib.deliveries.single.status, DeliveryStatus.declined);
    await switchTo(t, 'expert');
    await tapVisible(t, k('library-offer'));
    await tapVisible(t, k('library-offer-confirm'));
    await tapVisible(t, k('library-withdraw-2'));
    await tapVisible(t, k('library-withdraw-confirm'));
    expect(lib.deliveries.last.status, DeliveryStatus.withdrawn);
    await tapVisible(t, k('library-offer'));
    await tapVisible(t, k('library-offer-confirm'));
    await tapVisible(t, k('library-view-patient'));
    await tapVisible(t, k('delivery-accept-3'));
    await tapVisible(t, k('delivery-step-3-0'));
    expect(lib.deliveries.last.status, DeliveryStatus.completed);
    await switchTo(t, 'expert');
    expect(find.text('Завершено · версия 1 · выполнено 1/1'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
