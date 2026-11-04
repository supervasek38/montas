import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder k(String key) => find.byKey(ValueKey(key));
Future<SleepScreen> open(WidgetTester t, double width) async {
  await home(t, width);
  await tapVisible(t, k('open-sleep'));
  return t.widget<SleepScreen>(find.byType(SleepScreen));
}

Future<void> scenario(WidgetTester t, int i) async {
  await tapVisible(t, k('sleep-scenarios'));
  await tapVisible(t, k('sleep-scenario-$i'));
  await tapVisible(t, k('apply-sleep-scenario'));
}

Future<void> consent(WidgetTester t) async {
  await tapVisible(t, k('sleep-connect-consent'));
  await tapVisible(t, k('confirm-sleep-connect'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1350.0, 1440.0]) {
    testWidgets('Sleep and device flows fit $width', (t) async {
      final screen = await open(t, width);
      expect(screen.data.average, 384);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('sleep-night-17'));
      expect(find.text('Нет данных'), findsOneWidget);
      await tapVisible(t, find.byTooltip('Закрыть'));
      await tapVisible(t, k('sleep-record'));
      await tapVisible(t, find.text('Плохо'));
      await t.enterText(k('sleep-duration'), '4:30');
      await tapVisible(t, k('sleep-recovery-0'));
      await tapVisible(t, k('save-sleep-report'));
      expect(screen.data.report!.minutes, 270);
      expect(screen.radar.latest(3)!.value, 0);
      await tapVisible(t, k('sleep-compare'));
      await tapVisible(t, k('save-sleep-comparison'));
      expect(screen.data.comparisonNote, 'Причина пока неизвестна');
      expect(screen.data.nights[20], 371);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('sleep-tab-1'));
      await scenario(t, 2);
      expect(find.textContaining('Неполный сигнал.'), findsOneWidget);
      await scenario(t, 3);
      await tapVisible(t, k('sleep-sync'));
      expect(
        find.textContaining('Не удалось синхронизировать:'),
        findsOneWidget,
      );
      await tapVisible(t, k('sleep-reconnect'));
      expect(
        t.widget<PrimaryButton>(k('confirm-sleep-connect')).onPressed,
        isNull,
      );
      await consent(t);
      expect(screen.data.quality, SleepQuality.partial);
      await tapVisible(t, k('sleep-sync'));
      expect(screen.data.nights.length, 5);
      expect(screen.data.nights.containsKey(17), isFalse);
      await tapVisible(t, k('sleep-tab-2'));
      expect(find.textContaining('Демо-синхронизация 09:12:'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Report validation and cancellation preserve existing data', (
    t,
  ) async {
    final screen = await open(t, 390);
    await tapVisible(t, k('sleep-record'));
    expect(t.widget<PrimaryButton>(k('save-sleep-report')).onPressed, isNull);
    await tapVisible(t, find.text('Средне'));
    await t.enterText(k('sleep-duration'), '25:00');
    await tapVisible(t, k('save-sleep-report'));
    expect(find.text('Введите длительность от 0:00 до 24:00'), findsOneWidget);
    expect(screen.data.report, isNull);
    await t.enterText(k('sleep-duration'), '0:00');
    await tapVisible(t, k('save-sleep-report'));
    expect(screen.data.report!.minutes, 0);
    expect(screen.radar.latest(3), isNull);
    await tapVisible(t, k('sleep-record'));
    await t.enterText(k('sleep-duration'), '08:00');
    await tapVisible(t, k('sleep-recovery-7'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(screen.data.report!.minutes, 0);
    expect(screen.radar.latest(3), isNull);
    await tapVisible(t, k('sleep-record'));
    await t.enterText(k('sleep-duration'), '08:00');
    await tapVisible(t, k('save-sleep-report'));
    expect(screen.data.report!.minutes, 480);
    await tapVisible(t, k('sleep-compare'));
    await tapVisible(t, find.text('Устройство снималось ночью'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(screen.data.comparisonNote, isNull);
    await tapVisible(t, k('sleep-record'));
    await t.enterText(k('sleep-duration'), '');
    await tapVisible(t, k('save-sleep-report'));
    expect(screen.data.report!.minutes, isNull);
    expect(screen.data.mismatch, isFalse);
    expect(k('sleep-compare'), findsNothing);
    expect(screen.data.nights[20], 371);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Revocation, reconnect, and repeated sync keep one history of nights',
    (t) async {
      final screen = await open(t, 1440);
      final samples = Map<int, int>.from(screen.data.nights);
      await tapVisible(t, k('sleep-tab-1'));
      await tapVisible(t, k('sleep-disconnect'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(screen.data.authorized, isTrue);
      await tapVisible(t, k('sleep-disconnect'));
      await tapVisible(t, k('confirm-sleep-disconnect'));
      expect(screen.data.authorized, isFalse);
      expect(k('sleep-sync'), findsNothing);
      await tapVisible(t, k('sleep-connect'));
      await tapVisible(t, k('sleep-connect-consent'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(screen.data.authorized, isFalse);
      await tapVisible(t, k('sleep-connect'));
      expect(
        t.widget<PrimaryButton>(k('confirm-sleep-connect')).onPressed,
        isNull,
      );
      await consent(t);
      await tapVisible(t, k('sleep-sync'));
      await tapVisible(t, k('sleep-sync'));
      expect(screen.data.nights, samples);
      expect(screen.data.lastSync, '20 октября · 09:12');
      expect(screen.radar.coverage, 1);
      await scenario(t, 1);
      expect(screen.data.nights, samples);
      expect(find.text('Калибровка · 5 из 7 ночей'), findsOneWidget);
      await tapVisible(t, k('sleep-scenarios'));
      await tapVisible(t, k('sleep-scenario-3'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(screen.data.online, isTrue);
      expect(screen.data.quality, SleepQuality.calibration);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Recovery is shared with radar and the existing sleep program', (
    t,
  ) async {
    final screen = await open(t, 1440);
    await tapVisible(t, k('sleep-record'));
    await tapVisible(t, find.text('Выспался(-ась)'));
    await tapVisible(t, k('sleep-recovery-8'));
    await tapVisible(t, k('save-sleep-report'));
    expect(screen.radar.latest(3)!.value, 8);
    await tapVisible(t, k('sleep-open-program'));
    expect(find.text('Создайте пространство для отдыха'), findsOneWidget);
    await tapVisible(t, k('join-program'));
    await tapVisible(t, k('confirm-program'));
    expect(screen.radar.sleepJoined, isTrue);
    expect(find.text('1 из 2 действий сегодня'), findsOneWidget);
    await tapVisible(t, k('program-open-sleep'));
    expect(find.textContaining('Восстановление: 8/10'), findsOneWidget);
    await tapVisible(t, k('sleep-back-radar'));
    await tapVisible(t, k('domain-3'));
    await tapVisible(t, k('radar-open-sleep'));
    expect(screen.data.report!.feeling, 'Выспался(-ась)');
    await go(t, 0, 1440);
    expect(find.text('Устройства и сон'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
