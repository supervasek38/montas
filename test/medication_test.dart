import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder k(String key) => find.byKey(ValueKey(key));
Future<MedicationData> open(WidgetTester t, double width) async {
  await home(t, width);
  await tapVisible(t, k('open-medications'));
  return t.widget<MedicationScreen>(find.byType(MedicationScreen)).data;
}

Future<void> prepare(WidgetTester t) async {
  await tapVisible(t, k('med-change'));
  await t.enterText(k('med-change-text'), 'На приёме врач уточнил схему.');
  await tapVisible(t, k('prepare-med-review'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0]) {
    testWidgets('Medication flows fit $width and share state with plan', (
      t,
    ) async {
      final data = await open(t, width);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('med-log'));
      await tapVisible(t, k('confirm-med-intake'));
      expect(data.takenAt, '08:03');
      expect(t.takeException(), isNull);
      await prepare(t);
      expect(data.review, MedicationReview.ready);
      await tapVisible(t, k('med-send'));
      expect(t.widget<PrimaryButton>(k('confirm-med-send')).onPressed, isNull);
      await tapVisible(t, k('med-transfer-consent'));
      await tapVisible(t, k('confirm-med-send'));
      expect(data.review, MedicationReview.waiting);
      await tapVisible(t, k('med-simulate-decision'));
      await tapVisible(t, k('confirm-med-decision'));
      expect(data.version, 1);
      await tapVisible(t, k('med-accept'));
      await tapVisible(t, k('confirm-med-accept'));
      expect(data.version, 2);
      expect(data.takenAt, '08:03');
      expect(data.versions.length, 2);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('med-tab-2'));
      expect(find.textContaining('Время исправлено'), findsNothing);
      expect(find.textContaining('Версия 1 · 14 августа'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('med-back-plan'));
      expect(find.text('Приём отмечен · 08:03'), findsOneWidget);
      await go(t, 0, width);
      expect(find.text('Приём отмечен · 08:03'), findsOneWidget);
      await tapVisible(t, k('open-medications'));
      expect(data.version, 2);
    });
  }

  testWidgets(
    'Intake validation, cancellation and correction preserve prescription',
    (t) async {
      final data = await open(t, 390);
      await tapVisible(t, k('med-log'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.takenAt, isNull);
      await tapVisible(t, k('med-log'));
      await t.enterText(k('med-time'), '25:61');
      await tapVisible(t, k('confirm-med-intake'));
      expect(data.takenAt, isNull);
      expect(find.text('Введите время от 00:00 до 23:59'), findsOneWidget);
      await t.enterText(k('med-time'), '00:00');
      await tapVisible(t, k('confirm-med-intake'));
      expect(data.takenAt, '00:00');
      await tapVisible(t, k('med-edit-time'));
      await t.enterText(k('med-time'), '08:20');
      await tapVisible(t, k('confirm-med-intake'));
      expect(data.takenAt, '08:20');
      expect(data.intakeHistory.first, contains('Время исправлено с 00:00'));
      await tapVisible(t, k('med-undo'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.takenAt, '08:20');
      await tapVisible(t, k('med-undo'));
      await tapVisible(t, k('confirm-med-undo'));
      expect(data.takenAt, isNull);
      expect(data.intakeHistory.length, 3);
      expect(data.version, 1);
      expect(data.review, MedicationReview.none);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Review is transactional; no send or new version from closing dialogs',
    (t) async {
      final data = await open(t, 1440);
      await tapVisible(t, k('med-change'));
      await t.enterText(k('med-change-text'), '   ');
      await tapVisible(t, k('prepare-med-review'));
      expect(data.review, MedicationReview.none);
      await t.enterText(k('med-change-text'), 'Несохранённый текст');
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.changeText, isEmpty);
      await prepare(t);
      await tapVisible(t, k('med-edit-change'));
      await t.enterText(k('med-change-text'), 'Отменённое исправление');
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.changeText, 'На приёме врач уточнил схему.');
      await tapVisible(t, k('med-send'));
      await tapVisible(t, k('med-transfer-consent'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.review, MedicationReview.ready);
      await tapVisible(t, k('med-send'));
      expect(t.widget<PrimaryButton>(k('confirm-med-send')).onPressed, isNull);
      await tapVisible(t, k('med-transfer-consent'));
      await tapVisible(t, k('confirm-med-send'));
      await tapVisible(t, k('med-simulate-decision'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.review, MedicationReview.waiting);
      await tapVisible(t, k('med-simulate-decision'));
      await tapVisible(t, k('confirm-med-decision'));
      await tapVisible(t, k('med-accept'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(data.version, 1);
      expect(data.review, MedicationReview.decision);
      await tapVisible(t, k('med-accept'));
      await tapVisible(t, k('confirm-med-accept'));
      expect(data.version, 2);
      await tapVisible(t, k('med-new-change'));
      await t.enterText(k('med-change-text'), 'Следующее уточнение для врача');
      await tapVisible(t, k('prepare-med-review'));
      expect(data.review, MedicationReview.ready);
      expect(
        data.reviewHistory.any(
          (v) => v.contains('На приёме врач уточнил схему.'),
        ),
        isTrue,
      );
      expect(data.version, 2);
      expect(t.takeException(), isNull);
    },
  );
}
