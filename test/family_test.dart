import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'journey_test.dart' show home, go;
import 'widget_test.dart' show tapVisible;

Finder k(String key) => find.byKey(ValueKey(key));
Future<FamilyScreenState> openFamily(
  WidgetTester t, {
  double width = 1440,
  int person = 1,
}) async {
  await home(t, width);
  await go(t, 6, width);
  await tapVisible(t, k('family-person-$person'));
  return t.state<FamilyScreenState>(find.byType(FamilyScreen));
}

Future<void> confirmAccess(WidgetTester t) async {
  await tapVisible(t, k('review-family-access'));
  await tapVisible(t, k('confirm-family-access'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0]) {
    testWidgets('Family overview, permissions and confirmation fit $width', (
      t,
    ) async {
      await openFamily(t, width: width);
      expect(find.text('Задачи заботы'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('family-tab-1'));
      await tapVisible(t, k('grant-family'));
      await confirmAccess(t);
      expect(find.text('Доступ действует'), findsNWidgets(2));
      expect(t.takeException(), isNull);
      await tapVisible(t, k('revoke-family-outgoing'));
      await tapVisible(t, k('confirm-family-revoke'));
      expect(find.text('Доступ прекращён'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'Requests do not open data; owner can decline or approve exact scopes',
    (t) async {
      final state = await openFamily(t, person: 2);
      final p = state.selected!;
      await tapVisible(t, k('family-data-results'));
      expect(find.text('Раздел закрыт'), findsOneWidget);
      await tapVisible(t, find.byTooltip('Закрыть'));
      await tapVisible(t, k('family-tab-1'));
      await tapVisible(t, k('request-family'));
      await tapVisible(t, k('scope-visits'));
      await tapVisible(t, k('scope-tasks'));
      expect(
        t.widget<PrimaryButton>(k('review-family-access')).onPressed,
        isNull,
      );
      await tapVisible(t, k('scope-results'));
      await confirmAccess(t);
      expect(p.can(FamilyScope.results), isFalse);
      expect(p.pending!.scopes, {FamilyScope.results});
      await tapVisible(t, k('simulate-family-owner'));
      await tapVisible(t, k('owner-decline'));
      expect(p.pending, isNull);
      expect(p.can(FamilyScope.results), isFalse);
      await tapVisible(t, k('request-family'));
      await tapVisible(t, k('scope-results'));
      await confirmAccess(t);
      await tapVisible(t, k('simulate-family-owner'));
      await tapVisible(t, k('owner-approve'));
      expect(p.can(FamilyScope.results), isTrue);
      expect(p.can(FamilyScope.plan), isFalse);
      await tapVisible(t, k('family-tab-0'));
      await tapVisible(t, k('family-data-results'));
      expect(
        find.text('В этом демо нет загруженных результатов обследований.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Revoke blocks dependent tasks, preserves history and other profiles',
    (t) async {
      final state = await openFamily(t);
      final mother = state.selected!;
      await tapVisible(t, k('family-visit'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(mother.visitConfirmed, isFalse);
      await tapVisible(t, k('family-visit'));
      await tapVisible(t, k('confirm-family-visit'));
      expect(mother.visitConfirmed, isTrue);
      await tapVisible(t, k('family-tab-1'));
      await tapVisible(t, k('revoke-family-incoming'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(mother.canConfirmVisit, isTrue);
      await tapVisible(t, k('revoke-family-incoming'));
      await tapVisible(t, k('confirm-family-revoke'));
      await tapVisible(t, k('family-tab-0'));
      expect(find.text('Поручения недоступны'), findsOneWidget);
      expect(find.textContaining('Кардиолог · 28 октября'), findsNothing);
      expect(mother.visitConfirmed, isTrue);
      await tapVisible(t, k('family-tab-2'));
      expect(
        find.text(
          'Время визита подтверждено в пределах разрешённого поручения.',
        ),
        findsOneWidget,
      );
      await tapVisible(t, k('family-back'));
      await tapVisible(t, k('family-person-2'));
      expect(state.selected!.incoming, isNull);
      await go(t, 0, 1440);
      expect(find.text('Добрый день!'), findsOneWidget);
      await go(t, 6, 1440);
      expect(state.people.first.incoming!.revoked, isTrue);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Outgoing grants need confirmation and narrow rather than merge scopes',
    (t) async {
      final state = await openFamily(t);
      final p = state.selected!;
      await tapVisible(t, k('family-tab-1'));
      await tapVisible(t, k('grant-family'));
      await tapVisible(t, k('review-family-access'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(p.outgoing, isNull);
      await tapVisible(t, k('grant-family'));
      await confirmAccess(t);
      expect(p.outgoing!.allows(FamilyScope.visits), isTrue);
      await tapVisible(t, k('grant-family'));
      await tapVisible(t, k('scope-visits'));
      await tapVisible(t, k('scope-tasks'));
      await tapVisible(t, k('scope-plan'));
      await confirmAccess(t);
      expect(p.outgoing!.scopes, {FamilyScope.plan});
      expect(p.can(FamilyScope.visits), isTrue);
      expect(p.can(FamilyScope.plan), isFalse);
    },
  );

  testWidgets(
    'Adding relative grants no access and cancelling leaves list unchanged',
    (t) async {
      await home(t, 390);
      await go(t, 6, 390);
      final state = t.state<FamilyScreenState>(find.byType(FamilyScreen));
      await tapVisible(t, k('add-relative'));
      expect(t.widget<PrimaryButton>(k('confirm-relative')).onPressed, isNull);
      await t.enterText(k('relative-name'), 'Павел');
      await tapVisible(t, find.byTooltip('Закрыть'));
      await t.pump(const Duration(milliseconds: 300));
      expect(state.people.length, 2);
      await tapVisible(t, k('add-relative'));
      await t.enterText(k('relative-name'), 'Павел');
      await tapVisible(t, k('confirm-relative'));
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(state.people.length, 3);
      expect(state.people.last.incoming, isNull);
      expect(state.people.last.outgoing, isNull);
      expect(t.takeException(), isNull);
    },
  );
}
