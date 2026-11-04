import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder k(String key) => find.byKey(ValueKey(key));
Future<SupportData> open(WidgetTester t, double width) async {
  await home(t, width);
  await tapVisible(t, k('open-support'));
  return t.widget<SupportScreen>(find.byType(SupportScreen)).data;
}

Future<void> record(WidgetTester t, int mood, {String note = ''}) async {
  await tapVisible(t, k('support-check-in'));
  await tapVisible(t, k('support-mood-$mood'));
  if (note.isNotEmpty) await t.enterText(k('support-note'), note);
  await tapVisible(t, k('save-support-mood'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0]) {
    testWidgets('Support check-in, actions and safety fit $width', (t) async {
      final data = await open(t, width);
      expect(t.takeException(), isNull);
      await record(t, 1, note: 'Тестовая заметка только для себя');
      expect(data.latestMood, 'Перегружен(а)');
      await tapVisible(t, k('support-start'));
      await tapVisible(t, k('support-step-0'));
      await tapVisible(t, k('support-lighten-confirm'));
      await tapVisible(t, k('support-step-2'));
      await tapVisible(t, k('support-contact-confirm'));
      expect(data.done, {0, 2});
      await tapVisible(t, k('support-finish'));
      await tapVisible(t, find.text('Без изменений'));
      await tapVisible(t, k('support-finish-confirm'));
      expect(data.active, isFalse);
      expect(data.latestMood, 'Перегружен(а)');
      await tapVisible(t, k('support-tab-2'));
      expect(find.text('Тестовая заметка только для себя'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('support-urgent'));
      expect(find.text('Немедленная помощь'), findsOneWidget);
      await tapVisible(t, k('support-emergency-options'));
      expect(find.text('112'), findsOneWidget);
      await tapVisible(t, find.text('Другая страна'));
      expect(find.text('112'), findsNothing);
      expect(t.takeException(), isNull);
      await tapVisible(t, find.byTooltip('Закрыть'));
      await tapVisible(t, k('support-exit-urgent'));
      await tapVisible(t, k('support-exit-confirm'));
      expect(data.urgent, isFalse);
      expect(data.active, isFalse);
      expect(data.entries.length, 1);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'Draft cancellation, recheck history, and no automatic sharing or scores',
    (t) async {
      final data = await open(t, 1440);
      await tapVisible(t, k('support-check-in'));
      expect(t.widget<PrimaryButton>(k('save-support-mood')).onPressed, isNull);
      await tapVisible(t, k('support-mood-2'));
      await t.enterText(k('support-note'), 'Несохранённый текст');
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.entries, isEmpty);
      await record(t, 2, note: 'Личная заметка');
      await record(t, 0);
      expect(data.entries.length, 2);
      await tapVisible(t, k('support-start'));
      await tapVisible(t, k('support-step-0'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.done, isEmpty);
      await tapVisible(t, k('support-step-2'));
      await t.enterText(k('support-contact-draft'), '   ');
      await t.pump();
      expect(
        t.widget<PrimaryButton>(k('support-copy-contact')).onPressed,
        isNull,
      );
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.done, isEmpty);
      await tapVisible(t, k('support-finish'));
      await tapVisible(t, find.text('Стало немного легче'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.active, isTrue);
      expect(data.latestMood, 'Спокойно');
      await tapVisible(t, k('support-home'));
      expect(find.text('Последняя отметка · Спокойно'), findsOneWidget);
      await go(t, 3, 1440);
      await tapVisible(t, k('domain-1'));
      expect(find.text('Пока нет наблюдений'), findsOneWidget);
      await tapVisible(t, k('radar-open-support'));
      expect(data.entries.length, 2);
      await go(t, 5, 1440);
      expect(find.textContaining('Личная заметка'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Urgent help preserves programs and requires explicit exit', (
    t,
  ) async {
    final data = await open(t, 1440);
    await record(t, 3);
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(data.active, isFalse);
    expect(data.urgent, isFalse);
    await tapVisible(t, k('support-start'));
    await tapVisible(t, k('support-choice-urgent'));
    expect(data.urgent, isTrue);
    await tapVisible(t, k('support-home'));
    expect(k('home-action'), findsNothing);
    expect(k('return-urgent-support'), findsOneWidget);
    await go(t, 4, 1440);
    expect(k('open-program-1'), findsNothing);
    await tapVisible(t, k('return-urgent-support'));
    await tapVisible(t, k('support-exit-urgent'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(data.urgent, isTrue);
    await tapVisible(t, k('support-exit-urgent'));
    await tapVisible(t, k('support-exit-confirm'));
    expect(data.urgent, isFalse);
    expect(data.active, isFalse);
    expect(data.latestMood, 'Очень тяжело');
    await go(t, 1, 1440);
    expect(find.text('План восстановления'), findsOneWidget);
    expect(find.text('20 минут спокойной прогулки'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Pause timer supports pause, resume, completion and immediate help',
    (t) async {
      final data = await open(t, 390);
      await tapVisible(t, k('support-start'));
      await tapVisible(t, k('support-step-1'));
      await t.tap(k('support-timer-toggle'));
      await t.pump();
      await t.pump(const Duration(seconds: 60));
      expect(find.text('2:00'), findsOneWidget);
      await t.tap(k('support-timer-toggle'));
      await t.pump();
      await t.pump(const Duration(seconds: 30));
      expect(find.text('2:00'), findsOneWidget);
      await t.tap(k('support-timer-toggle'));
      await t.pump();
      await t.pump(const Duration(seconds: 120));
      await t.pumpAndSettle();
      expect(find.text('0:00'), findsOneWidget);
      expect(data.done, isEmpty);
      await tapVisible(t, k('support-timer-done'));
      expect(data.done, {1});
      await tapVisible(t, k('support-finish'));
      await tapVisible(t, find.text('Не хочу оценивать'));
      await tapVisible(t, k('support-finish-confirm'));
      await tapVisible(t, k('support-plan-start'));
      await tapVisible(t, k('support-step-1'));
      await t.tap(k('support-timer-toggle'));
      await t.pump();
      await t.pump(const Duration(seconds: 5));
      await t.tap(k('support-timer-urgent'));
      await t.pumpAndSettle();
      expect(data.urgent, isTrue);
      expect(data.done, isEmpty);
      expect(find.byType(SupportPauseDialog), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
