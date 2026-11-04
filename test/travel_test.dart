import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder k(String key) => find.byKey(ValueKey(key));
Future<TravelScreen> open(WidgetTester t, double width) async {
  await home(t, width);
  await tapVisible(t, k('open-travel'));
  return t.widget<TravelScreen>(find.byType(TravelScreen));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1350.0, 1440.0, 1600.0]) {
    testWidgets('Travel selection, review and history fit $width', (t) async {
      final screen = await open(t, width);
      final data = screen.data;
      expect(data.conflict, isTrue);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('travel-find-dates'));
      await tapVisible(t, k('travel-option-0'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.selected, isFalse);
      expect(data.procedure, DateTime(2026, 10, 24));
      await tapVisible(t, k('travel-option-0'));
      await tapVisible(t, k('confirm-travel-window'));
      expect(data.current, isTrue);
      expect(data.procedure, DateTime(2026, 10, 20));
      expect(data.conflict, isFalse);
      await tapVisible(t, k('travel-return-plan'));
      await tapVisible(t, k('open-travel'));
      expect(data.current, isTrue);
      await tapVisible(t, k('travel-procedure'));
      expect(
        find.textContaining('Демонстрационная карточка специалиста'),
        findsOneWidget,
      );
      await tapVisible(t, find.byTooltip('Закрыть'));
      await tapVisible(t, k('travel-change'));
      await tapVisible(t, k('confirm-travel-change'));
      expect(data.needsReview, isTrue);
      expect(data.current, isFalse);
      expect(data.procedure, DateTime(2026, 10, 20));
      await tapVisible(t, k('travel-tab-1'));
      expect(k('travel-option-0'), findsNothing);
      await tapVisible(t, k('travel-tab-0'));
      await tapVisible(t, k('travel-request-review'));
      await tapVisible(t, k('confirm-travel-review'));
      await tapVisible(t, k('travel-review-result'));
      await tapVisible(t, k('accept-travel-review'));
      expect(data.recoveryDays, 7);
      expect(data.current, isFalse);
      await tapVisible(t, k('travel-find-dates'));
      expect(find.textContaining('До поездки полного периода'), findsOneWidget);
      await tapVisible(t, k('travel-option-0'));
      await tapVisible(t, k('confirm-travel-window'));
      expect(data.procedure, DateTime(2026, 10, 31));
      expect(data.endFor(data.procedure), DateTime(2026, 11, 7));
      expect(data.current, isTrue);
      await tapVisible(t, k('travel-tab-2'));
      expect(
        find.textContaining('принят демонстрационный ответ:'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Trip editor validates dates and cancels without mutation', (
    t,
  ) async {
    final data = (await open(t, 390)).data;
    data.choose(DateTime(2026, 10, 20));
    await t.pumpAndSettle();
    await tapVisible(t, k('travel-edit-trip'));
    await t.enterText(k('travel-route'), '');
    await tapVisible(t, k('save-travel-trip'));
    expect(find.text('Укажите маршрут или название'), findsOneWidget);
    expect(data.current, isTrue);
    await t.enterText(k('travel-route'), 'Иркутск → Казань');
    await tapVisible(t, k('travel-departure'));
    await tapVisible(t, find.text('31').last);
    await tapVisible(t, find.text('Выбрать'));
    expect(k('travel-date-error'), findsOneWidget);
    expect(t.widget<PrimaryButton>(k('save-travel-trip')).onPressed, isNull);
    await tapVisible(t, k('travel-return'));
    await tapVisible(t, find.text('Выбрать'));
    expect(k('travel-date-error'), findsNothing);
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(data.destination, 'Иркутск → Москва');
    expect(data.departure, DateTime(2026, 10, 26));
    expect(data.current, isTrue);
    await tapVisible(t, k('travel-edit-trip'));
    await t.enterText(k('travel-route'), 'Иркутск → Казань');
    await tapVisible(t, k('save-travel-trip'));
    expect(data.destination, 'Иркутск → Казань');
    expect(data.current, isFalse);
    expect(data.procedure, DateTime(2026, 10, 20));
    await tapVisible(t, k('travel-clear'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(data.selected, isTrue);
    await tapVisible(t, k('travel-clear'));
    await tapVisible(t, k('confirm-clear-travel'));
    expect(data.selected, isFalse);
    expect(t.takeException(), isNull);
  });

  test('Calendar boundaries, review and medication version propagation', () {
    final med = MedicationData();
    final data = TravelData(med);
    addTearDown(() {
      data.dispose();
      med.dispose();
    });
    expect(
      data.conflicts(DateTime(2026, 10, 21)),
      isTrue,
    ); // Ends on departure.
    expect(
      data.conflicts(DateTime(2026, 10, 30)),
      isTrue,
    ); // Return day included.
    expect(data.conflicts(DateTime(2026, 10, 31)), isFalse);
    data.choose(DateTime(2026, 10, 24));
    expect(data.selected, isFalse);
    data.choose(DateTime(2026, 10, 19));
    expect(data.selected, isFalse);
    data.choose(DateTime(2026, 10, 20));
    med.logIntake('08:00');
    expect(data.current, isTrue); // Intake is not a prescription revision.
    med.prepare('Контекст', 'Демо');
    med.simulateSend();
    med.simulateDecision();
    med.acceptDecision();
    expect(data.needsReview, isTrue);
    expect(data.medicationVersion, 2);
    final retainedDate = data.procedure;
    data.choose(DateTime(2026, 10, 31));
    expect(data.procedure, retainedDate);
    data.demoReviewResult();
    expect(data.needsReview, isTrue); // No result without a request.
    data.requestReview();
    final historyLength = data.history.length;
    data.requestReview();
    expect(data.history.length, historyLength);
    data.editTrip(
      'Новая поездка',
      DateTime(2026, 10, 27),
      DateTime(2026, 10, 31),
    );
    expect(
      data.reviewRequested,
      isFalse,
    ); // Old request cannot clear changed context.
    data.demoReviewResult();
    expect(data.needsReview, isTrue);
    data.requestReview();
    data.demoReviewResult();
    expect(data.current, isFalse);
    expect(med.version, 2);
    data.choose(data.options.first);
    expect(data.current, isTrue);
    data.editTrip('', DateTime(2026, 10, 25), DateTime(2026, 10, 20));
    expect(data.current, isTrue);
  });

  testWidgets('Desktop menu and specialist route remain usable', (t) async {
    await home(t, 1050);
    await tapVisible(t, find.byTooltip('Другие разделы'));
    await tapVisible(t, find.text('Процедуры и поездки').last);
    expect(find.byType(TravelScreen), findsOneWidget);
    await tapVisible(t, k('travel-ask'));
    expect(find.byType(AskScreen), findsOneWidget);
    await go(t, 0, 1050);
    await tapVisible(t, k('open-travel'));
    expect(k('travel-status'), findsOneWidget);
  });
}
