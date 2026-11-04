import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'expert_test.dart' show k, switchTo, start, sendQuestion;
import 'widget_test.dart' show tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Onest',
    )..addFont(rootBundle.load('assets/Onest.ttf'))).load();
  });
  test(
    'Case consent, disagreement, stale review and revoked source are enforced',
    () {
      final store = ConsiliumStore();
      addTearDown(store.dispose);
      final q = QuestionTransfer(['Fixed question'], 7);
      final c = store.create(q)!;
      expect(store.create(q), same(c));
      expect(store.opinion(c, 0, OpinionStance.support, 'Opinion'), isFalse);
      expect(store.setConsent(c, CaseConsent.approved), isTrue);
      expect(store.opinion(c, 0, OpinionStance.support, 'Opinion A'), isTrue);
      store.opinion(c, 1, OpinionStance.needsInfo, 'Need more context');
      expect(store.publish(c, c.revision, 'Too early'), isFalse);
      store.opinion(c, 1, OpinionStance.abstain, 'Outside my scope');
      expect(c.ready, isFalse);
      store.opinion(c, 1, OpinionStance.partial, 'Disagree on preparation');
      expect(c.ready, isTrue);
      expect(c.disagreement, isTrue);
      final reviewed = c.revision;
      store.opinion(c, 0, OpinionStance.support, 'Revised opinion');
      expect(store.publish(c, reviewed, 'Stale'), isFalse);
      q.revoked = true;
      expect(store.publish(c, c.revision, 'No access'), isFalse);
      expect(store.opinion(c, 0, OpinionStance.support, 'No access'), isFalse);
      expect(q.specialistReply, isNull);
    },
  );
  test(
    'Decline is final; published result survives revocation without allowing edits',
    () {
      final store = ConsiliumStore();
      addTearDown(store.dispose);
      final declined = store.create(QuestionTransfer(['Decline'], 7))!;
      store.setConsent(declined, CaseConsent.declined);
      expect(store.setConsent(declined, CaseConsent.approved), isFalse);
      final c = store.create(QuestionTransfer(['Publish'], 7))!;
      store.setConsent(c, CaseConsent.approved);
      store.opinion(c, 0, OpinionStance.support, 'A');
      store.opinion(c, 1, OpinionStance.partial, 'B');
      expect(store.publish(c, c.revision, '  Result  '), isTrue);
      expect(store.publish(c, c.revision, 'Overwrite'), isFalse);
      expect(store.opinion(c, 0, OpinionStance.support, 'Overwrite'), isFalse);
      store.setConsent(c, CaseConsent.revoked);
      expect(c.result, 'Result');
      expect(c.canWork, isFalse);
      expect(c.opinions[1]!.text, 'B');
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Seeded specialist and consilium publication fit $width', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MontasApp(seedDemo: true));
      await t.pumpAndSettle();
      await switchTo(t, 'expert');
      final expert = t.state<ExpertWorkspaceState>(
        find.byType(ExpertWorkspace),
      );
      final q = expert.widget.transfers().single;
      final c = expert.widget.consiliums.cases.single;
      expect(expert.widget.schedule.current?.time, '18:30');
      expect(expert.widget.data.grants.length, 1);
      expect(expert.patientNote, isNotEmpty);
      expect(find.text('Сегодня, Анна'), findsOneWidget);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('case-open-1'));
      await tapVisible(t, k('case-opinion-0'));
      await tapVisible(t, k('stance-partial'));
      await t.enterText(
        k('case-opinion-text'),
        'Сначала уточним ожидания пациента.',
      );
      await tapVisible(t, k('case-opinion-save'));
      expect(c.ready, isTrue);
      expect(c.disagreement, isTrue);
      await t.enterText(
        k('case-result-draft'),
        'Обсудим вопросы на запланированной встрече.',
      );
      await tapVisible(t, k('case-review'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(c.result, isNull);
      await tapVisible(t, k('case-review'));
      await tapVisible(t, k('case-publish'));
      expect(c.result, 'Обсудим вопросы на запланированной встрече.');
      expect(q.specialistReply, isNull);
      await tapVisible(t, k('case-view-patient'));
      expect(find.text(c.result!), findsOneWidget);
      await tapVisible(t, k('case-revoke-1'));
      await tapVisible(t, k('case-revoke-confirm'));
      expect(c.canWork, isFalse);
      expect(find.text(c.result!), findsOneWidget);
      await switchTo(t, 'expert');
      expect(find.text(c.result!), findsNothing);
      expect(expert.widget.transfers().length, 1);
      expect(expert.widget.consiliums.cases.length, 1);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('Create from request and approve from patient workspace', (
    t,
  ) async {
    await start(t, 390);
    final q = await sendQuestion(t);
    await switchTo(t, 'expert');
    await tapVisible(t, k('expert-next-request'));
    await tapVisible(t, k('create-consilium'));
    await tapVisible(t, k('case-create-confirm'));
    final expert = t.state<ExpertWorkspaceState>(find.byType(ExpertWorkspace));
    final c = expert.widget.consiliums.cases.single;
    expect(c.source, same(q));
    expect(c.consent, CaseConsent.pending);
    expect(k('case-opinion-0'), findsNothing);
    await tapVisible(t, find.text('Открыть согласие в личном кабинете'));
    await tapVisible(t, k('case-consent-1'));
    await switchTo(t, 'expert');
    expect(k('case-opinion-0'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
