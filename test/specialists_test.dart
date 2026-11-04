import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'widget_test.dart' show setup, tapVisible;

Finder key(String id) => find.byKey(ValueKey(id));

Future<void> directory(WidgetTester t, double width) async {
  await setup(t, width);
  await tapVisible(t, key('specialists-breadcrumb'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Onest',
    )..addFont(rootBundle.load('assets/Onest.ttf'))).load();
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Catalog search, empty recovery and comparison at $width', (
      t,
    ) async {
      await directory(t, width);
      expect(find.text('Найдено: 2'), findsOneWidget);
      await t.enterText(key('directory-search'), 'Неизвестное имя');
      await t.pumpAndSettle();
      expect(find.text('Подходящих специалистов нет'), findsOneWidget);
      await tapVisible(t, key('directory-reset'));
      await tapVisible(t, key('directory-compare-anna'));
      expect(
        t.widget<PrimaryButton>(key('directory-compare-open')).onPressed,
        isNull,
      );
      await tapVisible(t, key('directory-compare-ilya'));
      await tapVisible(t, key('directory-compare-open'));
      expect(key('comparison-anna'), findsOneWidget);
      expect(key('comparison-ilya'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapVisible(t, find.byTooltip('Закрыть'));
      if (width < 1000) {
        await tapVisible(t, key('directory-filters'));
      }
      await tapVisible(t, key('directory-years-0'));
      await t.tap(find.text('От 15 лет').last);
      await t.pumpAndSettle();
      if (width < 1000) await tapVisible(t, key('directory-apply-filters'));
      expect(find.text('Найдено: 0'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Favorite, search and booking survive profile round trip', (
    t,
  ) async {
    await directory(t, 1440);
    await t.enterText(key('directory-search'), 'Анна');
    await t.pumpAndSettle();
    await tapVisible(t, key('directory-save-anna'));
    await tapVisible(t, key('directory-open-anna'));
    expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
    await tapVisible(t, key('book'));
    await tapVisible(t, key('confirm-booking'));
    await tapVisible(t, find.text('Вернуться к профилю'));
    await tapVisible(t, key('specialists-breadcrumb'));
    expect(
      t.widget<TextField>(key('directory-search')).controller!.text,
      'Анна',
    );
    expect(find.text('Найдено: 1'), findsOneWidget);
    final catalog = t.widget<SpecialistsDirectory>(
      find.byType(SpecialistsDirectory),
    );
    expect(catalog.schedule.current, isNotNull);
    await tapVisible(t, key('directory-open-anna'));
    await tapVisible(t, find.byTooltip('Убрать из избранного'));
    await tapVisible(t, key('specialists-breadcrumb'));
    await tapVisible(t, key('directory-saved'));
    expect(find.text('Найдено: 0'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Clinic price filter carries format into Anna booking', (
    t,
  ) async {
    await directory(t, 1440);
    await tapVisible(t, key('directory-format-Любой формат'));
    await t.tap(find.text('В клинике').last);
    await t.pumpAndSettle();
    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(find.text('4 200 ₽'), findsOneWidget);
    await tapVisible(t, key('directory-price-0'));
    await t.tap(find.text('До 4 000 ₽').last);
    await t.pumpAndSettle();
    expect(find.text('Найдено: 0'), findsOneWidget);
    await tapVisible(t, key('directory-price-4000'));
    await t.tap(find.text('До 5 000 ₽').last);
    await t.pumpAndSettle();
    await tapVisible(t, key('directory-open-anna'));
    expect(find.text('4 200 ₽'), findsOneWidget);
    expect(t.widget<PrimaryButton>(key('book')).onPressed, isNull);
    expect(t.takeException(), isNull);
  });

  testWidgets('Second profile does not book Anna; navigation opens catalog', (
    t,
  ) async {
    await setup(t, 1440);
    await tapVisible(t, key('nav-2'));
    await tapVisible(t, key('directory-open-ilya'));
    expect(find.text('Расписание пока не подключено'), findsOneWidget);
    await tapVisible(t, key('directory-detail-save'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    await tapVisible(t, key('directory-saved'));
    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(key('directory-card-ilya'), findsOneWidget);
    final catalog = t.widget<SpecialistsDirectory>(
      find.byType(SpecialistsDirectory),
    );
    expect(catalog.schedule.current, isNull);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Only published profile changes reach catalog; blocked slots update',
    (t) async {
      await directory(t, 1440);
      final catalog = t.widget<SpecialistsDirectory>(
        find.byType(SpecialistsDirectory),
      );
      final p = catalog.profile;
      p.save(
        const ProfessionalDetails(specialty: 'Кардиолог', topics: 'Пульс'),
        p.revision,
      );
      await t.pumpAndSettle();
      await t.enterText(key('directory-search'), 'Кардиолог');
      await t.pumpAndSettle();
      expect(find.text('Найдено: 0'), findsOneWidget);
      p.publish(p.revision);
      await t.pumpAndSettle();
      expect(find.text('Найдено: 1'), findsOneWidget);
      expect(find.text('21 октября · 10:00'), findsOneWidget);
      catalog.schedule.setBlocked(const Appointment(0, '10:00', true), true);
      await t.pumpAndSettle();
      expect(find.text('21 октября · 12:30'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
