import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'package:montas_prototype/local_file.dart';
import 'widget_test.dart' show tapVisible;

Finder k(String value) => find.byKey(ValueKey(value));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });

  test(
    'Files validate, deduplicate, preserve originals and export an isolated snapshot',
    () {
      final data = MyDataStore();
      addTearDown(data.dispose);
      final doc = data.documents.single;
      expect(data.addFile(MyDataStore.exampleFile()), same(doc));
      expect(data.documents.length, 1);
      expect(
        () => data.addFile(
          LocalFile(
            'bad.pdf',
            'application/pdf',
            Uint8List.fromList([1, 2, 3]),
          ),
        ),
        throwsFormatException,
      );
      expect(data.documents.single, same(doc));
      data.classify(doc, 'Заключение');
      final snapshot = data.export(doc);
      data.classify(doc, 'Другой документ');
      data.saveNote(
        title: 'private title',
        body: 'PRIVATE NOTE MUST NOT LEAK',
        documentId: doc.id,
      );
      final grant = data.grant(doc, 'Анна', 'Подготовка', 30);
      final other = data.grant(doc, 'Елена', 'Помощь', 7);
      data.revoke(grant);
      expect(grant.until, contains('19 ноября 2026'));
      expect(other.revoked, isFalse);
      expect(snapshot.category, 'Заключение');
      final zip = ZipDecoder().decodeBytes(
        snapshot.archiveBytes(),
        verify: true,
      );
      expect(zip.files.length, 2);
      expect(zip.files.first.content, orderedEquals(doc.file.bytes));
      final metadata =
          jsonDecode(
                utf8.decode(
                  zip.findFile('metadata.json')!.content as List<int>,
                ),
              )
              as Map;
      expect(metadata['category'], 'Заключение');
      expect(metadata['sourceDocumentId'], doc.id);
      expect(metadata.toString(), isNot(contains('PRIVATE NOTE')));
      expect(data.notes.single.body, 'PRIVATE NOTE MUST NOT LEAK');
      expect(
        data.documents.single.file.bytes,
        orderedEquals(MyDataStore.exampleFile().bytes),
      );
    },
  );

  test('Imported byte buffers cannot mutate stored document or export', () {
    final data = MyDataStore();
    addTearDown(data.dispose);
    final bytes = Uint8List.fromList(utf8.encode('original'));
    final doc = data.addFile(LocalFile('example.txt', 'text/plain', bytes));
    final snapshot = data.export(doc);
    bytes[0] = 0;
    expect(utf8.decode(doc.file.bytes), 'original');
    expect(utf8.decode(snapshot.file.bytes), 'original');
    expect(() => doc.file.bytes[0] = 0, throwsUnsupportedError);
    expect(
      () => LocalFile('empty.txt', 'text/plain', Uint8List(0)).validate(),
      throwsFormatException,
    );
    expect(() => LocalFile.mimeFor('script.html'), throwsFormatException);
  });

  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0, 1750.0]) {
    testWidgets('My data documents, notes, consent and export fit $width', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MontasApp(initialPage: 11));
      await t.pumpAndSettle();
      final screen = t.widget<MyDataScreen>(find.byType(MyDataScreen));
      final data = screen.data;
      final doc = data.documents.single;
      expect(t.takeException(), isNull);
      await t.enterText(k('data-search'), 'не существует');
      await t.pumpAndSettle();
      expect(find.text('Ничего не найдено'), findsOneWidget);
      await tapVisible(t, find.byTooltip('Очистить поиск'));
      await tapVisible(t, k('data-demo-file'));
      expect(t.widget<PrimaryButton>(k('data-save-file')).onPressed, isNull);
      await tapVisible(t, k('data-file-consent'));
      await tapVisible(t, k('data-save-file'));
      expect(data.documents.length, 1);
      expect(find.textContaining('Вопросы для обсуждения:'), findsOneWidget);
      await tapVisible(t, k('data-doc-note'));
      await tapVisible(t, k('data-save-note'));
      expect(find.text('Введите заголовок'), findsOneWidget);
      await t.enterText(k('data-note-title'), 'К консультации');
      await t.enterText(k('data-note-body'), 'Что обсудить на встрече?');
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.notes, isEmpty);
      await tapVisible(t, k('data-file-${doc.id}'));
      await tapVisible(t, k('data-doc-note'));
      await t.enterText(k('data-note-title'), 'К консультации');
      await t.enterText(k('data-note-body'), 'Что обсудить на встрече?');
      await tapVisible(t, k('data-save-note'));
      expect(data.notes.single.documentId, doc.id);
      final note = data.notes.single;
      await tapVisible(t, k('data-edit-note-${note.id}'));
      await t.enterText(k('data-note-body'), 'Уточнить план восстановления');
      await tapVisible(t, k('data-save-note'));
      expect(note.versions.single.body, 'Что обсудить на встрече?');
      await tapVisible(t, k('data-tab-0'));
      await tapVisible(t, k('data-file-${doc.id}'));
      await tapVisible(t, k('data-doc-access'));
      expect(
        t.widget<PrimaryButton>(k('data-confirm-access')).onPressed,
        isNull,
      );
      await tapVisible(t, k('data-access-consent'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.grants, isEmpty);
      await tapVisible(t, k('data-file-${doc.id}'));
      await tapVisible(t, k('data-doc-access'));
      await tapVisible(t, k('data-access-consent'));
      await tapVisible(t, k('data-confirm-access'));
      expect(data.grants.single.documentId, doc.id);
      await tapVisible(t, k('data-revoke-${data.grants.single.id}'));
      await tapVisible(t, k('data-confirm-revoke'));
      expect(data.grants.single.revoked, isTrue);
      expect(note.body, 'Уточнить план восстановления');
      await tapVisible(t, k('data-tab-0'));
      await tapVisible(t, k('data-file-${doc.id}'));
      await tapVisible(t, k('data-doc-export'));
      expect(
        t.widget<PrimaryButton>(k('data-confirm-export')).onPressed,
        isNull,
      );
      await tapVisible(t, k('data-export-consent'));
      await tapVisible(t, k('data-confirm-export'));
      expect(data.exports.single.file.bytes, orderedEquals(doc.file.bytes));
      expect(find.text('Готов к скачиванию'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'Access hub reads the existing family and question objects on return',
    (t) async {
      t.view.physicalSize = const Size(1440, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MontasApp(initialPage: 11));
      await t.pumpAndSettle();
      final screen = t.widget<MyDataScreen>(find.byType(MyDataScreen));
      final person = screen.people().first;
      final transfer = QuestionTransfer(['Точный вопрос'], 7);
      screen.transfers().add(transfer);
      await tapVisible(t, k('data-tab-2'));
      expect(find.text('Елена → мне'), findsOneWidget);
      expect(find.textContaining('Вопросов: 1 · без документов'), findsOneWidget);
      await tapVisible(t, find.text('Управлять в «Семье»'));
      expect(find.text('Доступ действует'), findsOneWidget);
      await tapVisible(t, k('revoke-family-incoming'));
      await tapVisible(t, k('confirm-family-revoke'));
      expect(person.incoming!.revoked, isTrue);
      await tapVisible(t, find.byTooltip('Другие разделы'));
      await tapVisible(t, find.text('Мои данные').last);
      expect(find.text('Отозван'), findsOneWidget);
      await tapVisible(t, find.text('Открыть передачу вопросов'));
      await tapVisible(t, k('revoke-access'));
      await tapVisible(t, k('confirm-revoke'));
      expect(transfer.revoked, isTrue);
      await tapVisible(t, find.text('Мои данные').last);
      await tapVisible(t, k('data-tab-2'));
      expect(find.text('Отозван'), findsNWidgets(2));
      expect(t.takeException(), isNull);
    },
  );
}
