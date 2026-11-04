import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'expert_library_test.dart' show libraryStart;
import 'expert_test.dart' show k, switchTo, start;
import 'widget_test.dart' show tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Onest',
    )..addFont(rootBundle.load('assets/Onest.ttf'))).load();
  });
  test(
    'Profile drafts, publication, validation and stale actions are isolated',
    () {
      final p = ExpertWorkProfile();
      addTearDown(p.dispose);
      expect(p.draft.completeness, 88);
      expect(p.save(const ProfessionalDetails(years: -1), p.revision), isFalse);
      expect(
        p.save(const ProfessionalDetails(topics: '', about: ''), p.revision),
        isTrue,
      );
      expect(p.publish(p.revision), isFalse);
      expect(p.published.about, isNotEmpty);
      expect(
        p.save(const ProfessionalDetails(languages: 'Русский'), p.revision),
        isTrue,
      );
      final reviewed = p.revision;
      expect(p.draft.completeness, 100);
      expect(p.published.languages, isEmpty);
      expect(
        p.save(
          const ProfessionalDetails(languages: 'Русский, английский'),
          p.revision,
        ),
        isTrue,
      );
      expect(p.publish(reviewed), isFalse);
      expect(p.discard(reviewed), isFalse);
      expect(p.publish(p.revision), isTrue);
      expect(p.version, 2);
      expect(p.published.languages, 'Русский, английский');
      expect(p.publish(p.revision), isFalse);
      expect(
        p.save(const ProfessionalDetails(languages: 'Отменить'), p.revision),
        isTrue,
      );
      expect(p.discard(p.revision), isTrue);
      expect(p.draft, same(p.published));
      expect(p.dirty, isFalse);
      expect(p.configure(accepting: false, days: 0), isFalse);
      expect(p.acceptingRequests, isTrue);
      expect(p.configure(accepting: false, days: 3), isTrue);
      expect(p.responseDays, 3);
    },
  );
  test(
    'Analytics follows program progress, replies, consents and revocation',
    () {
      final lib = ExpertLibrary()..seedDemo();
      final cases = ConsiliumStore();
      final schedule = AppointmentSchedule();
      addTearDown(lib.dispose);
      addTearDown(cases.dispose);
      addTearDown(schedule.dispose);
      final q = QuestionTransfer(['Private question not for export'], 7);
      ExpertAnalytics snapshot() => ExpertAnalytics(
        requests: [q],
        schedule: schedule,
        consiliums: cases,
        library: lib,
        hasPatient: true,
      );
      var a = snapshot();
      expect(
        [a.newRequests, a.publishedPrograms, a.publishedArticles, a.drafts],
        [1, 1, 1, 1],
      );
      expect(a.ratio(0, 0), '—');
      final c = cases.create(q)!;
      expect(snapshot().casesPending, 1);
      cases.setConsent(c, CaseConsent.approved);
      expect(snapshot().casesOpen, 1);
      cases.opinion(c, 0, OpinionStance.support, 'First opinion');
      cases.opinion(c, 1, OpinionStance.support, 'Second opinion');
      cases.publish(c, c.revision, 'Private conclusion');
      expect(snapshot().casesDone, 1);
      q.publishReply('Private reply');
      expect(snapshot().answered, 1);
      final p = lib.item(2)!;
      final d = lib.offer(p, p.published!, q)!;
      expect(snapshot().offered, 1);
      expect(snapshot().acceptedPrograms, 0);
      lib.transition(d, DeliveryStatus.active);
      lib.mark(d, 0, true);
      lib.transition(d, DeliveryStatus.paused);
      a = snapshot();
      expect(
        [a.paused, a.acceptedPrograms, a.stepsDone, a.stepsTotal],
        [1, 1, 1, 2],
      );
      lib.transition(d, DeliveryStatus.active);
      lib.mark(d, 1, true);
      final article = lib.item(1)!;
      final reading = lib.offer(article, article.published!, q)!;
      lib.transition(reading, DeliveryStatus.active);
      lib.mark(reading, 0, true);
      a = snapshot();
      expect([a.completed, a.materialsShared, a.materialsRead], [1, 1, 1]);
      expect(a.csv, startsWith('\uFEFFПоказатель;Значение\r\n'));
      expect(a.csv, isNot(contains('Private')));
      lib.archive(p, true);
      expect(snapshot().publishedPrograms, 0);
      expect(snapshot().completed, 1);
      q.revoked = true;
      a = snapshot();
      expect(
        [
          a.requestsTotal,
          a.casesDone,
          a.completed,
          a.materialsRead,
          a.stepsTotal,
        ],
        [0, 0, 0, 0, 0],
      );
      expect(a.revoked, 1);
      expect(a.patients, 1);
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Analytics, report and published work profile fit $width', (
      t,
    ) async {
      final expert = await libraryStart(t, width);
      await tapVisible(t, k('expert-nav-8'));
      for (final id in ['patients', 'pending', 'appointments', 'cases']) {
        expect(t.widget<Text>(k('analytics-value-$id')).data, '1');
      }
      await tapVisible(t, k('analytics-report'));
      await t.ensureVisible(k('analytics-download'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await tapVisible(t, find.byTooltip('Закрыть'));
      await tapVisible(t, k('analytics-tab-1'));
      expect(t.widget<Text>(k('analytics-completed')).data, '0 из 0 завершено');
      final lib = expert.widget.library;
      final p = lib.item(2)!;
      final d = lib.offer(p, p.published!, expert.requests.single)!;
      lib.transition(d, DeliveryStatus.active);
      lib.mark(d, 0, true);
      lib.mark(d, 1, true);
      await t.pumpAndSettle();
      expect(t.widget<Text>(k('analytics-completed')).data, '1 из 1 завершено');
      expect(t.widget<Text>(k('analytics-steps')).data, 'Шаги: 2 из 2 · 100%');
      await tapVisible(t, k('analytics-tab-2'));
      expect(
        t.widget<Text>(k('analytics-read')).data,
        '0 из 0 отмечены прочитанными',
      );
      await tapVisible(t, k('analytics-tab-0'));
      await tapVisible(t, k('analytics-drill-pending'));
      expect(expert.section, 1);
      await tapVisible(t, k('expert-nav-9'));
      await tapVisible(t, k('work-profile-edit'));
      await t.enterText(
        k('profile-field-0'),
        'Терапевт и специалист по профилактической медицине',
      );
      await t.enterText(
        k('profile-field-2'),
        'Обсудим ваши вопросы на встрече',
      );
      await t.enterText(k('profile-field-7'), 'Русский, английский');
      await tapVisible(t, k('work-profile-save'));
      expect(expert.widget.workProfile.draft.completeness, 100);
      expect(expert.widget.workProfile.published.languages, isEmpty);
      await tapVisible(t, k('work-profile-review'));
      await tapVisible(t, find.byTooltip('Закрыть'));
      expect(expert.widget.workProfile.version, 1);
      await tapVisible(t, k('work-profile-review'));
      await tapVisible(t, k('work-profile-publish'));
      expect(expert.widget.workProfile.version, 2);
      await tapVisible(t, k('work-profile-public'));
      expect(find.text('Обсудим ваши вопросы на встрече'), findsOneWidget);
      expect(find.textContaining('Русский, английский'), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('Work settings pause new handoffs, cancel safely and resume', (
    t,
  ) async {
    await start(t, 390);
    await switchTo(t, 'expert');
    final expert = t.state<ExpertWorkspaceState>(find.byType(ExpertWorkspace));
    await tapVisible(t, k('expert-nav-9'));
    await tapVisible(t, k('profile-tab-1'));
    await tapVisible(t, k('work-settings-edit'));
    await tapVisible(t, k('work-accepting'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(expert.widget.workProfile.acceptingRequests, isTrue);
    await tapVisible(t, k('work-settings-edit'));
    await tapVisible(t, k('work-accepting'));
    await tapVisible(t, k('work-response-3'));
    await tapVisible(t, k('work-settings-save'));
    await switchTo(t, 'personal');
    await tapVisible(t, k('ask-specialist-tab'));
    expect(find.text('Новые запросы временно на паузе'), findsOneWidget);
    await t.enterText(k('question-0'), 'Вопрос после возобновления приёма');
    await tapVisible(t, k('review-questions'));
    await tapVisible(t, k('save-questions'));
    final ask = t.state<AskScreenState>(find.byType(AskScreen));
    await ask.handoff();
    await t.pumpAndSettle();
    expect(ask.transfers, isEmpty);
    expect(find.byType(Dialog), findsNothing);
    await switchTo(t, 'expert');
    await tapVisible(t, k('work-settings-edit'));
    await tapVisible(t, k('work-accepting'));
    await tapVisible(t, k('work-settings-save'));
    await switchTo(t, 'personal');
    await tapVisible(t, k('handoff-questions'));
    await tapVisible(t, k('handoff-consent'));
    // Settings can change while the confirmation is open; final guard must hold.
    expert.widget.workProfile.configure(accepting: false, days: 3);
    await t.pumpAndSettle();
    await tapVisible(t, k('confirm-handoff'));
    expect(ask.transfers, isEmpty);
    expert.widget.workProfile.configure(accepting: true, days: 3);
    await t.pumpAndSettle();
    await tapVisible(t, k('handoff-questions'));
    await tapVisible(t, k('handoff-consent'));
    await tapVisible(t, k('confirm-handoff'));
    expect(ask.transfers.length, 1);
    expect(t.takeException(), isNull);
  });
}
