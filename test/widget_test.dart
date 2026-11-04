import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> setup(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MontasApp(initialPage: 2));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Responsive profile and confirmation at $width', (
      tester,
    ) async {
      await setup(tester, width);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byKey(const ValueKey('book')));
      expect(find.text('Подтвердите запись'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
      expect(find.text('Вы записаны'), findsWidgets);
      await tapVisible(tester, find.text('Вернуться к профилю'));
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Date and format reset the time; unavailable day recovers', (
    tester,
  ) async {
    await setup(tester, 1440);
    await tapVisible(tester, find.byKey(const ValueKey('day-3')));
    expect(find.text('В этот день нет свободных мест'), findsOneWidget);
    final book = find.byKey(const ValueKey('book'));
    expect(tester.widget<PrimaryButton>(book).onPressed, isNull);
    await tapVisible(tester, find.text('Посмотреть понедельник'));
    await tapVisible(tester, find.byKey(const ValueKey('slot-12:00')));
    expect(tester.widget<PrimaryButton>(book).onPressed, isNotNull);
    await tapVisible(tester, find.text('В клинике'));
    expect(tester.widget<PrimaryButton>(book).onPressed, isNull);
    expect(find.text('4 200 ₽'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Booking can be rescheduled and cancelled', (tester) async {
    await setup(tester, 1440);
    await tapVisible(tester, find.byKey(const ValueKey('book')));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
    await tapVisible(tester, find.text('Вернуться к профилю'));
    await tapVisible(tester, find.byKey(const ValueKey('day-2')));
    await tapVisible(tester, find.byKey(const ValueKey('slot-15:30')));
    await tapVisible(tester, find.byKey(const ValueKey('book')));
    expect(find.text('23 октября, 15:30'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
    await tapVisible(tester, find.text('Вернуться к профилю'));
    expect(find.text('23 октября · 15:30 · Онлайн'), findsOneWidget);
    await tapVisible(tester, find.text('Управлять записью'));
    await tapVisible(tester, find.text('Отменить запись'));
    await tapVisible(tester, find.text('Да, отменить'));
    expect(find.text('23 октября · 15:30 · Онлайн'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Favorite, tabs, and demo chat respond to user actions', (
    tester,
  ) async {
    await setup(tester, 1440);
    await tapVisible(tester, find.byTooltip('В избранное'));
    expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
    await tapVisible(tester, find.text('Отзывы'));
    expect(find.text('Екатерина'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('book')));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
    await tapVisible(tester, find.text('Вернуться к профилю'));
    await tapVisible(tester, find.text('Есть вопрос?'));
    await tester.enterText(find.byType(TextField), 'Как подготовить анализы?');
    await tapVisible(tester, find.text('Отправить в демо-чат'));
    expect(find.text('Как подготовить анализы?'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Закрыть'));
    expect(tester.takeException(), isNull);
  });
}
