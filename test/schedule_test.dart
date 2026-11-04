import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'expert_test.dart' show start, switchTo, k;
import 'widget_test.dart' show tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/Onest.ttf'));
    await font.load();
  });
  test(
    'Shared schedule rejects stale changes, blocked time and duplicate confirmation',
    () {
      final s = AppointmentSchedule();
      const a = Appointment(1, '18:30', true);
      const b = Appointment(2, '15:30', true);
      expect(s.change(null, a, actor: 'User'), isTrue);
      expect(s.setBlocked(a, true), isFalse);
      expect(s.change(null, b, actor: 'Stale'), isFalse);
      expect(s.change(a, a, actor: 'Repeat'), isFalse);
      s.setBlocked(b, true);
      expect(s.change(a, b, actor: 'Expert'), isFalse);
      s.setBlocked(b, false);
      expect(s.change(a, b, actor: 'Expert'), isTrue);
      expect(s.change(a, null, actor: 'Stale cancel'), isFalse);
      expect(s.change(b, null, actor: 'Expert', reason: 'Reason'), isTrue);
      expect(s.history.length, 3);
      expect(s.history.first.reason, 'Reason');
      expect(s.history.last.after, same(a));
      expect(
        s.change(null, const Appointment(3, '10:00', true), actor: 'User'),
        isFalse,
      );
      s.dispose();
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Booking, patient, move, history and cancellation at $width', (
      t,
    ) async {
      await start(t, width, page: 2);
      await tapVisible(t, k('book'));
      await tapVisible(t, k('confirm-booking'));
      await tapVisible(t, find.text('Вернуться к профилю'));
      await switchTo(t, 'expert');
      final s = t
          .widget<ExpertWorkspace>(find.byType(ExpertWorkspace))
          .schedule;
      expect(s.current!.time, '18:30');
      await tapVisible(t, k('expert-open-appointment'));
      await tapVisible(t, k('schedule-patient'));
      expect(find.text('Карточка пациента'), findsOneWidget);
      expect(
        t.widget<OutlinedButton>(k('patient-edit-note')).onPressed,
        isNull,
      );
      await tapVisible(t, k('patient-tab-2'));
      expect(find.text('Доступных документов пока нет'), findsOneWidget);
      await tapVisible(t, k('expert-nav-4'));
      await tapVisible(t, k('schedule-reschedule'));
      await tapVisible(t, k('move-day-3'));
      expect(
        find.text('Свободного времени нет. Выберите другой день.'),
        findsOneWidget,
      );
      expect(
        t.widget<PrimaryButton>(k('schedule-review-move')).onPressed,
        isNull,
      );
      await tapVisible(t, k('move-day-2'));
      await tapVisible(t, k('move-slot-15:30'));
      await tapVisible(t, k('schedule-review-move'));
      await tapVisible(t, k('schedule-confirm-move'));
      expect(s.current!.day, 2);
      expect(s.current!.time, '15:30');
      await tapVisible(t, k('schedule-view-user'));
      expect(find.text('23 октября · 15:30 · Онлайн'), findsOneWidget);
      await switchTo(t, 'expert');
      await tapVisible(t, k('schedule-cancel'));
      expect(
        t.widget<PrimaryButton>(k('schedule-confirm-cancel')).onPressed,
        isNull,
      );
      await t.enterText(k('schedule-cancel-reason'), 'Перерыв в работе');
      await tapVisible(t, find.text('Оставить приём'));
      expect(s.current, isNotNull);
      await tapVisible(t, k('schedule-cancel'));
      await t.enterText(k('schedule-cancel-reason'), 'Перерыв в работе');
      await tapVisible(t, k('schedule-confirm-cancel'));
      expect(s.current, isNull);
      await tapVisible(t, k('schedule-tab-2'));
      expect(find.text('Приём перенесён'), findsOneWidget);
      expect(find.text('Приём отменён'), findsOneWidget);
      expect(find.text('Причина: Перерыв в работе'), findsOneWidget);
      await switchTo(t, 'personal');
      expect(find.text('23 октября · 15:30 · Онлайн'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'Closing slot updates profile; reopening restores it; review cancel preserves appointment',
    (t) async {
      await start(t, 1440, page: 2);
      await switchTo(t, 'expert');
      await tapVisible(t, k('expert-nav-4'));
      await tapVisible(t, k('schedule-tab-1'));
      await tapVisible(t, k('schedule-slot-18:30'));
      await tapVisible(t, k('schedule-confirm-slot'));
      await switchTo(t, 'personal');
      expect(k('slot-18:30'), findsNothing);
      expect(t.widget<PrimaryButton>(k('book')).onPressed, isNull);
      await switchTo(t, 'expert');
      await tapVisible(t, k('schedule-slot-18:30'));
      await tapVisible(t, k('schedule-confirm-slot'));
      await switchTo(t, 'personal');
      await tapVisible(t, k('slot-18:30'));
      await tapVisible(t, k('book'));
      await tapVisible(t, k('confirm-booking'));
      await tapVisible(t, find.text('Вернуться к профилю'));
      await switchTo(t, 'expert');
      await tapVisible(t, k('schedule-tab-0'));
      final s = t
          .widget<ExpertWorkspace>(find.byType(ExpertWorkspace))
          .schedule;
      final a = s.current;
      await tapVisible(t, k('schedule-reschedule'));
      await tapVisible(t, k('move-slot-12:30'));
      await tapVisible(t, k('schedule-review-move'));
      await tapVisible(t, find.text('Оставить прежнюю запись'));
      expect(s.current, same(a));
      expect(s.history.length, 1);
    },
  );
}
