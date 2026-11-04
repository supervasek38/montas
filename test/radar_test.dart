import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'Radar, missing data, programs and observation dialog fit $width',
      (tester) async {
        await home(tester, width);
        await go(tester, 3, width);
        expect(find.byType(LivingRadar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byKey(const ValueKey('domain-2')));
        expect(find.text('Пока нет наблюдений'), findsOneWidget);
        expect(find.text('Обновить наблюдение'), findsNothing);
        await tapVisible(tester, find.byKey(const ValueKey('radar-back')));
        await tapVisible(tester, find.byKey(const ValueKey('record-energy')));
        await tapVisible(tester, find.byKey(const ValueKey('rating-8')));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('save-observation')),
        );
        await go(tester, 4, width);
        await tapVisible(tester, find.byKey(const ValueKey('open-program-1')));
        expect(find.text('Создайте пространство для отдыха'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Energy is shared with home; edits replace today, zero is valid',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 3, 1440);
      await tapVisible(tester, find.byKey(const ValueKey('record-energy')));
      await tapVisible(tester, find.byKey(const ValueKey('rating-8')));
      await tapVisible(tester, find.byKey(const ValueKey('save-observation')));
      await go(tester, 0, 1440);
      expect(find.text('8 из 10 · ваша энергия'), findsOneWidget);
      await go(tester, 3, 1440);
      await tapVisible(tester, find.byKey(const ValueKey('record-energy')));
      await tapVisible(tester, find.byKey(const ValueKey('rating-0')));
      await tapVisible(tester, find.byKey(const ValueKey('save-observation')));
      final model = tester.widget<RadarScreen>(find.byType(RadarScreen)).data;
      expect(
        model.observations.where((o) => o.domain == 0 && o.day == 20).length,
        1,
      );
      expect(model.latest(0)!.value, 0);
      await go(tester, 0, 1440);
      expect(find.text('0 из 10 · ваша энергия'), findsOneWidget);
    },
  );
  testWidgets(
    'Enrollment is confirmed; completion changes progress, not health scores',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 4, 1440);
      await tapVisible(tester, find.byKey(const ValueKey('open-program-1')));
      await tapVisible(tester, find.byKey(const ValueKey('join-program')));
      await tapVisible(tester, find.byTooltip('Закрыть'));
      expect(find.byKey(const ValueKey('join-program')), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('join-program')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-program')));
      expect(find.text('0 из 2 действий сегодня'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('task-ritual')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-task')));
      expect(find.text('1 из 2 действий сегодня'), findsOneWidget);
      final model = tester.widget<RadarScreen>(find.byType(RadarScreen)).data;
      expect(model.latest(0)!.value, 5);
      expect(model.latest(3), isNull);
      await tapVisible(tester, find.byKey(const ValueKey('task-rest')));
      await tapVisible(tester, find.byKey(const ValueKey('rating-7')));
      await tapVisible(tester, find.byKey(const ValueKey('save-observation')));
      expect(find.text('На сегодня всё выполнено ✓'), findsOneWidget);
      expect(model.coverage, 2);
      await tapVisible(tester, find.byKey(const ValueKey('task-ritual')));
      await tapVisible(tester, find.text('Снять отметку выполнения'));
      expect(find.text('1 из 2 действий сегодня'), findsOneWidget);
      expect(model.latest(3)!.value, 7);
      await tapVisible(tester, find.text('Пауза программы'));
      await tapVisible(tester, find.text('Поставить на паузу'));
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('task-ritual')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('Продолжить программу'));
      await tapVisible(tester, find.text('Продолжить'));
      expect(find.text('1 из 2 действий сегодня'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Recovery program shares the existing walk state', (
    tester,
  ) async {
    await home(tester, 1440);
    await go(tester, 4, 1440);
    await tapVisible(tester, find.byKey(const ValueKey('open-program-0')));
    await tapVisible(tester, find.byKey(const ValueKey('task-walk')));
    expect(find.text('План восстановления'), findsOneWidget);
    await tapVisible(tester, find.text('Начать прогулку'));
    await tapVisible(tester, find.byKey(const ValueKey('start-step')));
    await tapVisible(tester, find.text('Завершить прогулку'));
    await tapVisible(tester, find.byKey(const ValueKey('complete-step')));
    await go(tester, 4, 1440);
    expect(find.text('1 из 3 действий сегодня'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
