import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'expert_test.dart' show k, start, switchTo, sendQuestion;
import 'widget_test.dart' show tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0, 1750.0]) {
    testWidgets('Patient card, note, request and return fit $width', (t) async {
      await start(t, width);
      final q = await sendQuestion(t);
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-nav-3'));
      expect(find.text('1 человек'), findsOneWidget);
      await t.enterText(k('patient-search'), 'does not exist');
      await t.pumpAndSettle();
      expect(find.text('Ничего не найдено'), findsOneWidget);
      await tapVisible(t, k('patients-reset'));
      await tapVisible(t, k('patient-open'));
      expect(find.text('Карточка пациента'), findsOneWidget);
      await tapVisible(t, k('patient-edit-note'));
      await t.enterText(
        k('patient-note-input'),
        'Уточнить вопросы к следующей встрече',
      );
      await tapVisible(t, k('patient-note-save'));
      expect(find.text('Уточнить вопросы к следующей встрече'), findsOneWidget);
      await tapVisible(t, k('patient-edit-note'));
      await t.enterText(k('patient-note-input'), 'Несохранённое изменение');
      await tapVisible(t, find.text('Отмена'));
      expect(find.text('Уточнить вопросы к следующей встрече'), findsOneWidget);
      expect(find.text('Несохранённое изменение'), findsNothing);
      await tapVisible(t, k('patient-answer'));
      await t.enterText(
        k('expert-reply-draft'),
        'Ответ через карточку пациента',
      );
      await tapVisible(t, k('expert-request-patient'));
      expect(find.text('История обращений'), findsOneWidget);
      await tapVisible(t, k('patient-request-1'));
      expect(
        t.widget<TextField>(k('expert-reply-draft')).controller!.text,
        'Ответ через карточку пациента',
      );
      await tapVisible(t, k('expert-review-reply'));
      await tapVisible(t, k('expert-confirm-reply'));
      expect(q.specialistReply, 'Ответ через карточку пациента');
      await tapVisible(t, k('expert-view-as-user'));
      expect(find.text('Ответ через карточку пациента'), findsOneWidget);
      expect(find.text('Уточнить вопросы к следующей встрече'), findsNothing);
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-request-patient'));
      await tapVisible(t, k('patient-tab-0'));
      expect(find.text('Уточнить вопросы к следующей встрече'), findsOneWidget);
      await tapVisible(t, k('patient-tab-2'));
      expect(find.text('Доступных документов пока нет'), findsOneWidget);
      await tapVisible(t, k('patient-tab-3'));
      expect(find.textContaining('Только просмотр · до'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'No patient from personal or family files; document grant creates one and revokes live',
    (t) async {
      await start(t, 1440, page: 11);
      final data = t.widget<MyDataScreen>(find.byType(MyDataScreen)).data;
      final doc = data.documents.single;
      data.saveNote(
        title: 'PRIVATE TITLE',
        body: 'PRIVATE BODY',
        documentId: doc.id,
      );
      data.grant(doc, 'Елена', 'Family only', 7, recipientId: 'family-1');
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-nav-3'));
      expect(find.text('Пациентов пока нет'), findsOneWidget);
      expect(k('patient-open'), findsNothing);
      final g = data.grant(
        doc,
        'Анна',
        'Подготовка к встрече',
        7,
        recipientId: 'expert-anna',
      );
      await t.pumpAndSettle();
      await tapVisible(t, k('patient-filter-Есть документы'));
      await tapVisible(t, k('patient-open'));
      await tapVisible(t, k('patient-tab-1'));
      expect(find.text('Вопросы пока не переданы.'), findsOneWidget);
      await tapVisible(t, k('patient-tab-2'));
      expect(find.text('PRIVATE BODY'), findsNothing);
      await tapVisible(t, k('expert-document-${doc.id}'));
      expect(find.textContaining('Вопросы для обсуждения:'), findsOneWidget);
      data.revoke(g);
      await t.pumpAndSettle();
      expect(
        find.text('Доступ отозван. Содержимое больше недоступно.'),
        findsOneWidget,
      );
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(find.text(doc.file.name), findsNothing);
      await tapVisible(t, k('patient-tab-3'));
      expect(find.text(doc.file.name), findsNothing);
      expect(find.text('Доступ отозван'), findsOneWidget);
      await tapVisible(t, k('patient-tab-0'));
      expect(
        t.widget<OutlinedButton>(k('patient-edit-note')).onPressed,
        isNull,
      );
      await tapVisible(t, k('patient-back'));
      expect(find.text('Ничего не найдено'), findsOneWidget);
      await tapVisible(t, k('patient-filter-Доступ закрыт'));
      expect(k('patient-open'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Revoking questions hides content and note; next transfer keeps one patient',
    (t) async {
      await start(t, 390);
      final first = await sendQuestion(t);
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-nav-3'));
      await tapVisible(t, k('patient-open'));
      await tapVisible(t, k('patient-edit-note'));
      await t.enterText(k('patient-note-input'), 'Private expert note');
      await tapVisible(t, k('patient-note-save'));
      await switchTo(t, 'personal');
      await tapVisible(t, k('revoke-access'));
      await tapVisible(t, k('confirm-revoke'));
      await switchTo(t, 'expert');
      expect(find.text('Private expert note'), findsNothing);
      await tapVisible(t, k('patient-tab-1'));
      expect(find.text(first.questions.first), findsNothing);
      expect(find.text('Содержимое закрыто пользователем.'), findsOneWidget);
      final ask = t.state<AskScreenState>(
        find.byType(AskScreen, skipOffstage: false),
      );
      ask.transfers.add(QuestionTransfer(['New separate question'], 7));
      ask.refreshReplies();
      await switchTo(t, 'personal');
      await switchTo(t, 'expert');
      await tapVisible(t, k('patient-back'));
      expect(find.text('1 человек'), findsOneWidget);
      await tapVisible(t, k('patient-open'));
      await tapVisible(t, k('patient-tab-1'));
      expect(find.text('New separate question'), findsOneWidget);
      expect(find.text(first.questions.first), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Revocation during note editing hides text and disables saving', (
    t,
  ) async {
    await start(t, 1440, page: 11);
    final data = t.widget<MyDataScreen>(find.byType(MyDataScreen)).data;
    final g = data.grant(
      data.documents.single,
      'Анна',
      'Подготовка',
      7,
      recipientId: 'expert-anna',
    );
    await switchTo(t, 'expert');
    await tapVisible(t, k('expert-nav-3'));
    await tapVisible(t, k('patient-open'));
    await tapVisible(t, k('patient-edit-note'));
    await t.enterText(k('patient-note-input'), 'Unsaved private draft');
    data.revoke(g);
    await t.pumpAndSettle();
    expect(k('patient-note-input'), findsNothing);
    expect(t.widget<PrimaryButton>(k('patient-note-save')).onPressed, isNull);
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(find.text('Unsaved private draft'), findsNothing);
  });
}
