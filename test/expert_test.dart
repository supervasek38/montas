import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'widget_test.dart' show tapVisible;

Finder k(String value) => find.byKey(ValueKey(value));
Future<void> switchTo(WidgetTester t, String role) async {
  await tapVisible(t, k('workspace-switcher'));
  await tapVisible(t, k('workspace-$role'));
}

Future<void> start(WidgetTester t, double width, {int page = 5}) async {
  t.view.physicalSize = Size(width, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MontasApp(initialPage: page));
  await t.pumpAndSettle();
}

Future<QuestionTransfer> sendQuestion(WidgetTester t) async {
  await tapVisible(t, k('ask-specialist-tab'));
  await t.enterText(k('question-0'), 'Мой вопрос о подготовке к встрече');
  await tapVisible(t, k('review-questions'));
  await tapVisible(t, k('save-questions'));
  await tapVisible(t, k('handoff-questions'));
  await tapVisible(t, k('handoff-consent'));
  await tapVisible(t, k('confirm-handoff'));
  return t.state<AskScreenState>(find.byType(AskScreen)).transfers.single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  test(
    'Reply applies once to the exact active transfer and does not mutate questions',
    () {
      final questions = ['Original question'];
      final transfer = QuestionTransfer(questions, 7)..replyDraft = 'Draft';
      questions[0] = 'Changed after handoff';
      expect(transfer.questions.single, 'Original question');
      expect(transfer.publishReply('   '), isFalse);
      transfer.revoked = true;
      expect(transfer.publishReply('Answer'), isFalse);
      expect(transfer.replyDraft, 'Draft');
      expect(transfer.specialistReply, isNull);
      transfer.revoked = false;
      expect(transfer.publishReply('  Exact answer  '), isTrue);
      expect(transfer.publishReply('Overwrite'), isFalse);
      expect(transfer.specialistReply, 'Exact answer');
      expect(transfer.replyDraft, isEmpty);
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0, 1750.0]) {
    testWidgets('Two workspace request/reply/revocation flow fits $width', (
      t,
    ) async {
      await start(t, width);
      final transfer = await sendQuestion(t);
      await switchTo(t, 'expert');
      expect(find.text('Сегодня, Анна'), findsOneWidget);
      expect(find.text('Личные заметки'), findsNothing);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('expert-next-request'));
      expect(find.text('1. Мой вопрос о подготовке к встрече'), findsOneWidget);
      await tapVisible(t, k('expert-take-request'));
      expect(transfer.inProgress, isTrue);
      await t.enterText(
        k('expert-reply-draft'),
        'Точный ответ из рабочего кабинета',
      );
      await switchTo(t, 'personal');
      expect(find.text('Спросить MONTAS'), findsOneWidget);
      expect(find.text('Точный ответ из рабочего кабинета'), findsNothing);
      await switchTo(t, 'expert');
      expect(
        t.widget<TextField>(k('expert-reply-draft')).controller!.text,
        'Точный ответ из рабочего кабинета',
      );
      await tapVisible(t, k('expert-review-reply'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(transfer.specialistReply, isNull);
      await tapVisible(t, k('expert-review-reply'));
      await tapVisible(t, k('expert-confirm-reply'));
      expect(transfer.specialistReply, 'Точный ответ из рабочего кабинета');
      await tapVisible(t, k('expert-view-as-user'));
      expect(find.text('Точный ответ из рабочего кабинета'), findsOneWidget);
      await tapVisible(t, k('revoke-access'));
      await tapVisible(t, k('confirm-revoke'));
      expect(find.text('Точный ответ из рабочего кабинета'), findsOneWidget);
      await switchTo(t, 'expert');
      expect(find.text('Пользователь отозвал доступ'), findsOneWidget);
      expect(find.text('1. Мой вопрос о подготовке к встрече'), findsNothing);
      expect(k('expert-reply-draft'), findsNothing);
      expect(find.text('Точный ответ из рабочего кабинета'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'Empty workspace does not invent requests and retains personal page and AI draft',
    (t) async {
      await start(t, 390);
      await t.enterText(k('ai-composer'), 'Личный черновик чата');
      await switchTo(t, 'expert');
      expect(find.text('Всё спокойно'), findsOneWidget);
      expect(find.text('Личный черновик чата'), findsNothing);
      await tapVisible(t, k('expert-nav-1'));
      expect(find.text('В этом списке пока нет обращений.'), findsOneWidget);
      await switchTo(t, 'personal');
      expect(
        t.widget<TextField>(k('ai-composer')).controller!.text,
        'Личный черновик чата',
      );
      await switchTo(t, 'expert');
      expect(find.text('Обращения пользователей'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Document visibility is recipient-specific, independent of questions and live after revoke',
    (t) async {
      await start(t, 1440, page: 11);
      final data = t.widget<MyDataScreen>(find.byType(MyDataScreen)).data;
      final document = data.documents.single;
      data.saveNote(
        title: 'PRIVATE NOTE',
        body: 'PRIVATE CONTENT',
        documentId: document.id,
      );
      final relative = data.grant(
        document,
        'Елена',
        'Помощь',
        7,
        recipientId: 'family-1',
      );
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-nav-2'));
      expect(find.text('Доступных документов пока нет'), findsOneWidget);
      final specialist = data.grant(
        document,
        'Анна',
        'Подготовка',
        7,
        recipientId: 'expert-anna',
      );
      await t.pumpAndSettle();
      expect(find.text(document.file.name), findsOneWidget);
      expect(find.text('PRIVATE NOTE'), findsNothing);
      await tapVisible(t, k('expert-document-${document.id}'));
      expect(find.textContaining('Вопросы для обсуждения:'), findsOneWidget);
      data.revoke(specialist);
      await t.pumpAndSettle();
      expect(
        find.text('Доступ отозван. Содержимое больше недоступно.'),
        findsOneWidget,
      );
      expect(find.textContaining('Вопросы для обсуждения:'), findsNothing);
      expect(relative.revoked, isFalse);
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(find.text(document.file.name), findsNothing);
      await switchTo(t, 'personal');
      expect(find.text(document.file.name), findsOneWidget);
    },
  );
  testWidgets(
    'Revocation during answer review prevents publishing and preserves draft',
    (t) async {
      await start(t, 1440);
      final transfer = await sendQuestion(t);
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-next-request'));
      await t.enterText(
        k('expert-reply-draft'),
        'Draft retained after revocation',
      );
      await tapVisible(t, k('expert-review-reply'));
      transfer.revoked = true;
      await tapVisible(t, k('expert-confirm-reply'));
      expect(transfer.specialistReply, isNull);
      expect(transfer.replyDraft, 'Draft retained after revocation');
      expect(find.text('Пользователь отозвал доступ'), findsOneWidget);
      expect(k('expert-reply-draft'), findsNothing);
    },
  );
}
