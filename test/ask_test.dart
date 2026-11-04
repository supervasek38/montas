import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> saveQuestions(WidgetTester tester) async {
  await tapVisible(tester, key('review-questions'));
  await tapVisible(tester, key('save-questions'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0]) {
    testWidgets('Ask chat, draft and consent fit at $width', (tester) async {
      await home(tester, width);
      await go(tester, 5, width);
      expect(find.text('Спросить MONTAS'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Подготовить вопросы к приёму'));
      await tapVisible(tester, find.text('Открыть черновик →'));
      expect(key('question-2'), findsOneWidget);
      await saveQuestions(tester);
      await tapVisible(tester, key('handoff-questions'));
      expect(
        tester.widget<PrimaryButton>(key('confirm-handoff')).onPressed,
        isNull,
      );
      await tapVisible(tester, key('handoff-consent'));
      await tapVisible(tester, key('confirm-handoff'));
      expect(find.text('Вопросы переданы · демо'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Review cancellation, validation, exact transfer, revoke and regrant',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 5, 1440);
      await tapVisible(tester, key('ask-specialist-tab'));
      final state = tester.state<AskScreenState>(find.byType(AskScreen));
      await tester.enterText(key('question-0'), '  ');
      await tapVisible(tester, key('review-questions'));
      expect(find.byType(Dialog), findsNothing);
      expect(state.saved, isEmpty);
      await tester.enterText(key('question-0'), 'Мой точный вопрос?');
      await tapVisible(tester, key('review-questions'));
      await tapVisible(tester, find.byTooltip('Закрыть'));
      expect(state.saved, isEmpty);
      await saveQuestions(tester);
      await tapVisible(tester, key('handoff-questions'));
      await tapVisible(tester, key('handoff-consent'));
      await tapVisible(tester, find.byTooltip('Закрыть'));
      expect(state.transfers, isEmpty);
      await tapVisible(tester, key('handoff-questions'));
      expect(
        tester.widget<PrimaryButton>(key('confirm-handoff')).onPressed,
        isNull,
      );
      await tapVisible(tester, key('handoff-consent'));
      await tapVisible(tester, key('confirm-handoff'));
      expect(state.transfers.single.questions.first, 'Мой точный вопрос?');
      await tapVisible(tester, key('edit-questions'));
      await tester.enterText(key('question-0'), 'Новая редакция');
      await saveQuestions(tester);
      expect(state.saved.first, 'Новая редакция');
      expect(state.transfers.single.questions.first, 'Мой точный вопрос?');
      expect(
        tester.widget<PrimaryButton>(key('handoff-questions')).onPressed,
        isNull,
      );
      await tapVisible(tester, key('revoke-access'));
      await tapVisible(tester, find.byTooltip('Закрыть'));
      expect(state.transfers.single.revoked, isFalse);
      await tapVisible(tester, key('revoke-access'));
      await tapVisible(tester, key('confirm-revoke'));
      expect(state.transfers.single.revoked, isTrue);
      await tapVisible(tester, key('handoff-questions'));
      await tapVisible(tester, key('handoff-consent'));
      await tapVisible(tester, key('confirm-handoff'));
      expect(state.transfers.length, 2);
      expect(state.transfers.last.questions.first, 'Новая редакция');
      expect(state.transfers.first.revoked, isTrue);
      await tapVisible(tester, key('example-answer'));
      expect(state.transfers.last.exampleAnswer, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI carries exact user text into draft and retains state across navigation',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 5, 1440);
      expect(tester.widget<PrimaryButton>(key('send-ai')).onPressed, isNull);
      await tester.enterText(
        key('ai-composer'),
        '  Мой вопрос о подготовке?  ',
      );
      await tapVisible(tester, key('send-ai'));
      await tapVisible(tester, find.text('В вопросы специалисту →'));
      expect(
        tester.widget<TextField>(key('question-3')).controller!.text,
        'Мой вопрос о подготовке?',
      );
      await go(tester, 0, 1440);
      await go(tester, 5, 1440);
      expect(key('question-3'), findsOneWidget);
      await tapVisible(tester, key('ask-ai-tab'));
      expect(find.text('Мой вопрос о подготовке?'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Новый диалог'));
      await tapVisible(tester, find.text('Начать заново'));
      final state = tester.state<AskScreenState>(find.byType(AskScreen));
      expect(state.messages, isEmpty);
      expect(state.questions.length, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI reads shared radar observation; profile opens specialist questions',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 3, 1440);
      await tapVisible(tester, key('record-energy'));
      await tapVisible(tester, key('rating-8'));
      await tapVisible(tester, key('save-observation'));
      await go(tester, 5, 1440);
      await tapVisible(tester, find.text('Объяснить показатели'));
      final state = tester.state<AskScreenState>(find.byType(AskScreen));
      expect(state.messages.last.text, contains('8/10 за 20 октября'));
      await go(tester, 2, 1440);
      await tapVisible(tester, key('profile-ask'));
      expect(state.specialist, isTrue);
      expect(key('question-0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
