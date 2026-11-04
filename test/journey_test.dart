import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'widget_test.dart' show tapVisible;

Future<void> home(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MontasApp());
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, int index, double width) async {
  await tapVisible(
    tester,
    width < 1050
        ? find.byKey(ValueKey('mobile-nav-$index'))
        : find.byKey(ValueKey('nav-$index')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Home, plan, dialogs and specialist fit at $width', (
      tester,
    ) async {
      await home(tester, width);
      expect(find.text('Добрый день!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Не подходит'));
      expect(find.text('10 минут прогулки сегодня'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Закрыть'));
      await go(tester, 1, width);
      expect(find.text('План восстановления'), findsOneWidget);
      await tapVisible(tester, find.text('Отметить состояние →'));
      await tapVisible(tester, find.text('Сохранить самочувствие'));
      expect(find.text('5 из 10 · ваша энергия'), findsOneWidget);
      await go(tester, 2, width);
      expect(find.byKey(const ValueKey('book')), findsOneWidget);
      await go(tester, 0, width);
      expect(find.text('5 из 10 · ваша энергия'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Adaptation is confirmed, versioned and shared across pages', (
    tester,
  ) async {
    await home(tester, 1440);
    await tapVisible(tester, find.text('Не подходит'));
    await tapVisible(tester, find.byTooltip('Закрыть'));
    expect(find.text('20 минут спокойной прогулки'), findsOneWidget);
    await tapVisible(tester, find.text('Вернуться мягко →'));
    await tapVisible(tester, find.text('Принять облегчённый шаг'));
    expect(find.text('10 минут спокойной прогулки'), findsOneWidget);
    await go(tester, 1, 1440);
    expect(find.text('Версия 3'), findsOneWidget);
    expect(find.text('10 минут спокойной прогулки'), findsOneWidget);
    await tapVisible(tester, find.text('История плана'));
    expect(find.textContaining('Возвращаюсь после пропуска'), findsOneWidget);
    expect(find.textContaining('Версия 2 · 19 октября'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reschedule, start, finish and check-in stay consistent', (
    tester,
  ) async {
    await home(tester, 1440);
    await tapVisible(tester, find.text('Перенести'));
    await tapVisible(tester, find.text('Завтра · 09:00'));
    await tapVisible(tester, find.text('Подтвердить перенос'));
    await go(tester, 1, 1440);
    expect(find.textContaining('Сюда перенесён ваш шаг'), findsOneWidget);
    await tapVisible(tester, find.text('Начать прогулку'));
    await tapVisible(tester, find.byKey(const ValueKey('start-step')));
    await go(tester, 0, 1440);
    await tapVisible(tester, find.text('Завершить прогулку'));
    await tapVisible(tester, find.byKey(const ValueKey('complete-step')));
    expect(find.text('Вы сделали шаг к своей цели'), findsOneWidget);
    await tapVisible(tester, find.text('Отметить самочувствие'));
    await tapVisible(tester, find.text('5'));
    await tapVisible(tester, find.text('Сохранить самочувствие'));
    expect(find.text('5 из 10 · ваша энергия'), findsOneWidget);
    await go(tester, 1, 1440);
    expect(find.text('Шаг выполнен'), findsOneWidget);
    expect(find.text('5 из 10 · ваша энергия'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pause retains the current step and can be resumed', (
    tester,
  ) async {
    await home(tester, 1440);
    await go(tester, 1, 1440);
    await tapVisible(tester, find.text('Поставить на паузу'));
    await tapVisible(tester, find.text('Подтвердить паузу'));
    await go(tester, 0, 1440);
    expect(find.text('План на паузе'), findsOneWidget);
    expect(find.text('Перенести'), findsNothing);
    await tapVisible(tester, find.text('Продолжить план'));
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Продолжить план'),
      ),
    );
    expect(find.text('20 минут спокойной прогулки'), findsOneWidget);
    expect(find.text('Начать прогулку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Booking survives navigation and updates home, including cancellation',
    (tester) async {
      await home(tester, 1440);
      await go(tester, 2, 1440);
      await tapVisible(tester, find.byKey(const ValueKey('book')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
      await tapVisible(tester, find.text('Вернуться к профилю'));
      await go(tester, 0, 1440);
      expect(find.text('Ваша ближайшая запись'), findsOneWidget);
      await tapVisible(tester, find.text('Открыть запись'));
      expect(find.text('Вы записаны'), findsWidgets);
      await tapVisible(tester, find.text('Управлять записью'));
      await tapVisible(tester, find.text('Отменить запись'));
      await tapVisible(tester, find.text('Да, отменить'));
      await go(tester, 0, 1440);
      expect(find.text('Ваша ближайшая запись'), findsNothing);
      expect(find.text('Открыть профиль'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
