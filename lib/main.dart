import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'local_file.dart';
import 'file_bridge_stub.dart'
    if (dart.library.js_interop) 'file_bridge_web.dart'
    as file_bridge;

part 'journey.dart';
part 'radar.dart';
part 'ask.dart';
part 'family.dart';
part 'medication.dart';
part 'support.dart';
part 'sleep.dart';
part 'travel.dart';
part 'my_data.dart';
part 'expert.dart';
part 'patients.dart';
part 'schedule.dart';
part 'consilium.dart';
part 'expert_library.dart';
part 'expert_library_views.dart';
part 'expert_profile.dart';
part 'expert_analytics.dart';
part 'specialists.dart';
part 'discovery.dart';
part 'events.dart';
part 'marketplace.dart';

void main() => runApp(const MontasApp(seedDemo: true));

abstract final class C {
  static const canvas = Color(0xFFF5F7F6);
  static const ink = Color(0xFF0B0F0E);
  static const muted = Color(0xFF66716B);
  static const line = Color(0xFFE6EAE4);
  static const soft = Color(0xFFF2F4EF);
  static const dark = Color(0xFF0A2019);
  static const green = Color(0xFF008F4C);
  static const lime = Color(0xFFB6FF00);
}

TextStyle tx(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = C.ink,
  double? height,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height ?? 1.45,
);

class MontasApp extends StatelessWidget {
  const MontasApp({this.initialPage = 0, this.seedDemo = false, super.key});
  final int initialPage;
  final bool seedDemo;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MONTAS · Сегодня',
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Onest',
      scaffoldBackgroundColor: C.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: C.green,
        primary: C.dark,
        surface: Colors.white,
      ),
      textTheme: TextTheme(bodyMedium: tx(14), bodyLarge: tx(15)),
      dividerColor: C.line,
      tooltipTheme: TooltipThemeData(
        textStyle: tx(12, color: Colors.white),
        decoration: BoxDecoration(
          color: C.dark,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: C.dark,
          textStyle: const TextStyle(
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    home: JourneyWorkspace(initialPage: initialPage, seedDemo: seedDemo),
  );
}

class Appointment {
  const Appointment(this.day, this.time, this.online);
  final int day;
  final String time;
  final bool online;
  String get date => '${[21, 22, 23, 24, 26][day]} октября';
  String get format => online ? 'Онлайн' : 'В клинике';
  String get price => online ? '3 000 ₽' : '4 200 ₽';
}

class SpecialistScreen extends StatefulWidget {
  const SpecialistScreen({
    this.embedded = false,
    this.onAppointmentChanged,
    this.onAsk,
    this.schedule,
    this.workProfile,
    this.onDirectory,
    this.isFavorite,
    this.onFavoriteChanged,
    super.key,
  });
  final bool embedded;
  final ValueChanged<Appointment?>? onAppointmentChanged;
  final VoidCallback? onAsk;
  final AppointmentSchedule? schedule;
  final ExpertWorkProfile? workProfile;
  final VoidCallback? onDirectory;
  final bool? isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  @override
  State<SpecialistScreen> createState() => _SpecialistScreenState();
}

class _SpecialistScreenState extends State<SpecialistScreen> {
  ProfessionalDetails get professional =>
      widget.workProfile?.published ?? const ProfessionalDetails();
  int day = 1;
  String? time = '18:30';
  bool online = true, _favorite = false, expanded = false;
  bool get favorite => widget.isFavorite ?? _favorite;
  int tab = 0;
  late final appointments = widget.schedule ?? AppointmentSchedule();
  Appointment? get appointment => appointments.current;
  @override
  void initState() {
    super.initState();
    appointments.addListener(refreshAppointments);
  }

  void refreshAppointments() {
    if (mounted) {
      setState(() {
        if (time != null && !times.contains(time)) time = null;
      });
    }
  }

  @override
  void dispose() {
    appointments.removeListener(refreshAppointments);
    if (widget.schedule == null) appointments.dispose();
    super.dispose();
  }

  final bookingKey = GlobalKey();
  final detailsKey = GlobalKey();
  final List<String> messages = [];
  List<String> get times => appointments.available(day, online);
  static List<String> slots(int day, bool online) => day == 3
      ? []
      : online
      ? [
          ['10:00', '12:30'],
          ['10:00', '12:30', '18:30', '19:15'],
          ['11:00', '15:30', '17:00'],
          <String>[],
          ['09:00', '12:00', '16:30'],
        ][day]
      : [
          ['11:00', '14:00'],
          ['09:30', '14:30'],
          ['10:30', '16:00'],
          <String>[],
          ['12:00', '15:00'],
        ][day];

  void notify(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void jump(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: .08,
      );
    }
  }

  void selectDay(int index) => setState(() {
    day = index;
    time = null;
  });
  void selectFormat(bool value) => setState(() {
    online = value;
    time = null;
  });
  Future<T?> modal<T>(String title, Widget Function(BuildContext) content) =>
      showDialog<T>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.sizeOf(dialogContext).height - 48,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: tx(23, weight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Закрыть',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded, size: 21),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    content(dialogContext),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  void info(String title, String body) => modal<void>(
    title,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(body, style: tx(15, color: C.muted)),
        const SizedBox(height: 24),
        PrimaryButton('Понятно', () => Navigator.pop(ctx)),
      ],
    ),
  );

  Future<void> book() async {
    if (time == null) {
      jump(bookingKey);
      notify('Выберите свободное время приёма');
      return;
    }
    final draft = Appointment(day, time!, online);
    final previous = appointment;
    final confirmed = await modal<bool>(
      appointment == null ? 'Подтвердите запись' : 'Перенести запись',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DoctorMini(details: professional),
          const SizedBox(height: 20),
          detailRow('Дата и время', '${draft.date}, ${draft.time}'),
          detailRow('Формат', '${draft.format} · 45 минут'),
          detailRow('Стоимость', draft.price),
          detailRow('Часовой пояс', 'Иркутск · UTC+8'),
          const Divider(height: 28),
          Text(
            'Можно отменить или перенести приём. В этой демоверсии оплата и реальная запись не выполняются.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            appointment == null ? 'Подтвердить запись' : 'Подтвердить перенос',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-booking'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Изменить время'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!appointments.change(previous, draft, actor: 'Пользователь')) {
      notify(
        'Запись или доступность времени изменились. Выберите время заново.',
      );
      return;
    }
    widget.onAppointmentChanged?.call(appointment);
    await modal<void>(
      'Вы записаны',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFE5F7E9),
              child: Icon(Icons.check_rounded, color: C.green, size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${draft.date} · ${draft.time}',
            textAlign: TextAlign.center,
            style: tx(26, weight: FontWeight.w600),
          ),
          Text(
            '${draft.format} · Анна Волкова',
            textAlign: TextAlign.center,
            style: tx(15, color: C.muted),
          ),
          const SizedBox(height: 24),
          const Surface(
            color: C.soft,
            padding: 18,
            child: Text(
              'Подготовьте результаты анализов и список вопросов. На встрече вы обсудите, что делать дальше.',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Демонстрационная запись сохранена до обновления страницы.',
            textAlign: TextAlign.center,
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton('Вернуться к профилю', () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Future<void> manage() async {
    final current = appointment;
    if (current == null) return;
    final result = await modal<String>(
      'Ваша запись',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DoctorMini(details: professional),
          const SizedBox(height: 20),
          detailRow('Приём', '${current.date} · ${current.time}'),
          detailRow('Формат', current.format),
          detailRow('Стоимость', current.price),
          const SizedBox(height: 20),
          PrimaryButton(
            'Перенести приём',
            () => Navigator.pop(ctx, 'reschedule'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text(
              'Отменить запись',
              style: TextStyle(color: Color(0xFFA64435)),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'reschedule') {
      jump(bookingKey);
      notify(
        'Выберите новые дату и время. Текущая запись сохранится до подтверждения.',
      );
    }
    if (result == 'cancel') {
      final cancel = await modal<bool>(
        'Отменить приём?',
        (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Запись на ${current.date} в ${current.time} будет отменена. Вы сможете выбрать другое время.',
              style: tx(15, color: C.muted),
            ),
            const SizedBox(height: 24),
            PrimaryButton('Оставить запись', () => Navigator.pop(ctx, false)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Да, отменить'),
            ),
          ],
        ),
      );
      if (cancel == true && mounted) {
        if (!appointments.change(
          current,
          null,
          actor: 'Пользователь',
          reason: 'Отменено пользователем',
        )) {
          notify('Запись уже изменилась. Откройте актуальную запись.');
          return;
        }
        widget.onAppointmentChanged?.call(null);
        notify('Запись отменена');
      }
    }
  }

  Future<void> chat() async {
    if (appointment == null) {
      info(
        'Чат после записи',
        'Запишитесь на приём, чтобы задать организационный вопрос и подготовиться к консультации.',
      );
      return;
    }
    await modal<void>(
      'Чат с клиникой',
      (ctx) => DemoChatContent(messages: messages),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final desktop = box.maxWidth >= 1000;
      final narrow = box.maxWidth < 600;
      return Scaffold(
        bottomNavigationBar: desktop
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: C.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          appointment != null
                              ? 'Управлять записью'
                              : time == null
                              ? 'Выбрать время'
                              : 'Записаться · $time',
                          appointment != null
                              ? manage
                              : time == null
                              ? () => jump(bookingKey)
                              : book,
                        ),
                      ),
                      const SizedBox(width: 10),
                      RoundAction(
                        Icons.chat_bubble_outline_rounded,
                        'Чат с клиникой',
                        chat,
                      ),
                    ],
                  ),
                ),
              ),
        body: Column(
          children: [
            if (!widget.embedded) header(narrow),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? 18 : 36,
                        desktop ? 28 : 18,
                        narrow ? 18 : 36,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                key: const ValueKey('specialists-breadcrumb'),
                                onPressed: widget.onDirectory,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Специалисты',
                                  style: tx(13, color: C.muted),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '/',
                                  style: TextStyle(color: C.muted),
                                ),
                              ),
                              Text('Анна Волкова', style: tx(13)),
                              const Spacer(),
                              if (desktop)
                                Text(
                                  'ПРОФИЛЬ СПЕЦИАЛИСТА',
                                  style: tx(
                                    10,
                                    color: C.muted,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (desktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: profile(false)),
                                const SizedBox(width: 28),
                                SizedBox(width: 350, child: booking()),
                              ],
                            )
                          else
                            Column(
                              children: [
                                hero(narrow),
                                const SizedBox(height: 16),
                                facts(narrow),
                                const SizedBox(height: 20),
                                contextCard(),
                                const SizedBox(height: 20),
                                booking(),
                                const SizedBox(height: 24),
                                details(),
                              ],
                            ),
                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              'Демо-профиль · данные и портрет вымышлены · без реальной записи и оплаты',
                              textAlign: TextAlign.center,
                              style: tx(11, color: C.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget header(bool narrow) => Container(
    height: 76,
    padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 40),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: C.line)),
    ),
    child: Row(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: C.dark,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.add_rounded, color: C.lime, size: 22),
        ),
        const SizedBox(width: 9),
        Text('MONTAS', style: tx(20, weight: FontWeight.w600)),
        if (!narrow) ...[
          const SizedBox(width: 24),
          Container(width: 1, height: 22, color: C.line),
          const SizedBox(width: 24),
          Text('Здоровье начинается с ясности', style: tx(13, color: C.muted)),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Демо', style: tx(11, weight: FontWeight.w500)),
        ),
      ],
    ),
  );
  Widget profile(bool narrow) => Column(
    children: [
      hero(narrow),
      const SizedBox(height: 16),
      facts(narrow),
      const SizedBox(height: 22),
      contextCard(),
      const SizedBox(height: 24),
      details(),
    ],
  );
  Widget hero(bool narrow) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 470;
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          height: compact ? 310 : 334,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F6DA), Color(0xFFC7E5D7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: box.maxWidth * (compact ? 0.53 : 0.43),
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black, Colors.black],
                    stops: [0, .22, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/anna-demo.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.85),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: RoundAction(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  favorite ? 'Убрать из избранного' : 'В избранное',
                  () {
                    final next = !favorite;
                    setState(() => _favorite = next);
                    widget.onFavoriteChanged?.call(next);
                    notify(
                      next
                          ? 'Анна добавлена в избранное'
                          : 'Профиль удалён из избранного',
                    );
                  },
                  color: favorite ? C.green : C.ink,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 22 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: compact ? 155 : 230,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.local_hospital_outlined,
                            size: 15,
                            color: C.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              professional.specialty.toUpperCase(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: tx(
                                11,
                                weight: FontWeight.w600,
                                color: C.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Анна\nВолкова',
                      style: tx(
                        compact ? 36 : 45,
                        weight: FontWeight.w600,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: compact ? 155 : 230,
                      child: Text(
                        '${professional.years} лет практики.\nВнимание к каждому вопросу.',
                        style: tx(
                          compact ? 12 : 14,
                          color: const Color(0xFF3E5950),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    InkWell(
                      onTap: () => info(
                        'О данных профиля',
                        'Это вымышленный профиль для проверки интерфейса. Образование, стаж, отзывы и расписание показаны как демонстрационные данные.',
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: C.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'О специалисте',
                              style: tx(11, weight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget facts(bool narrow) => Row(
    children: [
      Expanded(
        child: fact(
          '3 000 ₽',
          'за онлайн-приём',
          Icons.payments_outlined,
          () => info(
            'Стоимость приёма',
            'Онлайн-консультация — 3 000 ₽ за 45 минут. В клинике — 4 200 ₽. Цены демонстрационные, списаний не будет.',
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: fact('4,9', '214 отзывов', Icons.star_outline_rounded, () {
          setState(() => tab = 2);
          jump(detailsKey);
        }),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: fact(
          '45 минут',
          'без спешки',
          Icons.schedule_rounded,
          () => info(
            'Как проходит приём',
            'Вы обсудите свои вопросы и результаты обследований. После встречи сможете вернуться к рекомендациям специалиста. Длительность в демо — 45 минут.',
          ),
        ),
      ),
    ],
  );
  Widget fact(String value, String label, IconData icon, VoidCallback action) =>
      Surface(
        padding: 0,
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: C.muted),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: tx(20, weight: FontWeight.w600)),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 32,
                  child: Text(
                    label,
                    maxLines: 2,
                    style: tx(11, color: C.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget contextCard() => Surface(
    color: C.dark,
    padding: 22,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            size: 19,
            color: Color(0xFFC8FF4D),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Больше энергии — начнём с причин',
                style: tx(16, weight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Обсудите усталость, сон и результаты анализов. Анна поможет разобраться, какой следующий шаг вам нужен.',
                style: tx(13, color: const Color(0xFFBACDC3)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget details() => Surface(
    key: detailsKey,
    padding: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: InkWell(
                  onTap: () => setState(() => tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: tab == i ? C.dark : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      ['О враче', 'Образование', 'Отзывы'][i],
                      textAlign: TextAlign.center,
                      style: tx(
                        13,
                        weight: tab == i ? FontWeight.w600 : FontWeight.w400,
                        color: tab == i ? C.ink : C.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: [about(), education(), reviews()][tab],
          ),
        ),
      ],
    ),
  );
  Widget about() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (professional.city.isNotEmpty ||
          professional.languages.isNotEmpty) ...[
        Text(
          [
            professional.city,
            professional.languages,
          ].where((s) => s.isNotEmpty).join(' · '),
          style: tx(12, color: C.muted),
        ),
        const SizedBox(height: 12),
      ],
      Text(professional.headline, style: tx(21, weight: FontWeight.w600)),
      const SizedBox(height: 12),
      Text(professional.about, style: tx(14, color: C.muted)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: professional.topicList
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: C.soft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(s, style: tx(12)),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Как подготовиться к консультации',
                  style: tx(14, weight: FontWeight.w500),
                ),
              ),
              Icon(expanded ? Icons.remove : Icons.add, size: 20),
            ],
          ),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '1. Запишите вопросы, которые хотите обсудить.\n2. Подготовьте последние анализы, если они есть.\n3. Для онлайн-приёма проверьте камеру, звук и интернет.',
            style: tx(14, color: C.muted),
          ),
        ),
    ],
  );
  Widget education() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Образование и практика', style: tx(21, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Пример заполненного профиля', style: tx(12, color: C.muted)),
      const SizedBox(height: 20),
      Text(professional.education, style: tx(14)),
      const SizedBox(height: 20),
      Text(
        'Документы в прототипе не являются подтверждением квалификации.',
        style: tx(12, color: C.muted),
      ),
    ],
  );
  Widget timeline(String year, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(year, style: tx(12, weight: FontWeight.w600)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tx(15, weight: FontWeight.w500)),
              Text(subtitle, style: tx(13, color: C.muted)),
            ],
          ),
        ),
      ],
    ),
  );
  Widget reviews() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('4,9', style: tx(36, weight: FontWeight.w600)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '★★★★★',
                  style: TextStyle(color: C.green, fontSize: 18),
                ),
                Text(
                  '214 отзывов · демонстрационные данные',
                  style: tx(11, color: C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      review(
        'ЕК',
        'Екатерина',
        'Очень спокойно и по делу. Смогла задать все вопросы и понять, с чего начать.',
      ),
      const Divider(height: 28),
      review(
        'МС',
        'Михаил',
        'Внимательно разобрали результаты анализов. После встречи остался понятный список следующих шагов.',
      ),
      const SizedBox(height: 20),
      Text(
        'Отзывы приведены как примеры интерфейса.',
        style: tx(12, color: C.muted),
      ),
    ],
  );
  Widget review(String initials, String name, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: C.soft,
            child: Text(initials, style: tx(11)),
          ),
          const SizedBox(width: 10),
          Text(name, style: tx(13, weight: FontWeight.w600)),
          const Spacer(),
          Text('5,0 ★', style: tx(12, color: C.green)),
        ],
      ),
      const SizedBox(height: 12),
      Text(value, style: tx(14, color: C.muted)),
    ],
  );

  Widget booking() => Column(
    key: bookingKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (appointment != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Surface(
            color: const Color(0xFFE6F5E9),
            padding: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: C.green,
                    ),
                    const SizedBox(width: 8),
                    Text('Вы записаны', style: tx(14, weight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${appointment!.date} · ${appointment!.time} · ${appointment!.format}',
                  style: tx(13),
                ),
                TextButton(
                  onPressed: manage,
                  child: const Text('Управлять записью'),
                ),
              ],
            ),
          ),
        ),
      Surface(
        padding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Запись на приём',
                    style: tx(22, weight: FontWeight.w600),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: C.muted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Выберите удобные день и время',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: C.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: formatButton(
                      'Онлайн',
                      true,
                      Icons.videocam_outlined,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: formatButton(
                      'В клинике',
                      false,
                      Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              online
                  ? 'Видеоконсультация · 45 минут'
                  : 'Демо-клиника · ул. Ленина, 12',
              style: tx(12, color: C.muted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Октябрь 2026', style: tx(15, weight: FontWeight.w500)),
                const Spacer(),
                Text('UTC+8', style: tx(11, color: C.muted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 4 ? 0 : 6),
                    child: Semantics(
                      selected: day == i,
                      button: true,
                      child: InkWell(
                        key: ValueKey('day-$i'),
                        borderRadius: BorderRadius.circular(17),
                        onTap: () => selectDay(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: day == i ? C.dark : C.soft,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Column(
                            children: [
                              Text(
                                ['Ср', 'Чт', 'Пт', 'Сб', 'Пн'][i],
                                style: tx(
                                  11,
                                  color: day == i ? Colors.white70 : C.muted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${[21, 22, 23, 24, 26][i]}',
                                style: tx(
                                  17,
                                  weight: FontWeight.w600,
                                  color: day == i ? Colors.white : C.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (times.isEmpty)
              Surface(
                color: C.soft,
                padding: 16,
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_outlined, color: C.muted),
                    const SizedBox(height: 8),
                    Text('В этот день нет свободных мест', style: tx(13)),
                    TextButton(
                      onPressed: () => selectDay(4),
                      child: const Text('Посмотреть понедельник'),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: times
                    .map(
                      (slot) => Semantics(
                        selected: time == slot,
                        button: true,
                        child: InkWell(
                          key: ValueKey('slot-$slot'),
                          onTap: () => setState(() => time = slot),
                          borderRadius: BorderRadius.circular(30),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: time == slot ? C.lime : C.soft,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              slot,
                              style: tx(14, weight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 22),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Стоимость приёма', style: tx(13, color: C.muted)),
                const Spacer(),
                Text(
                  online ? '3 000 ₽' : '4 200 ₽',
                  style: tx(23, weight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              appointment != null
                  ? 'Подтвердить новое время'
                  : time == null
                  ? 'Выберите время'
                  : 'Записаться на $time',
              time == null ? null : book,
              key: const ValueKey('book'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Демо-запись · без оплаты',
                style: tx(11, color: C.muted),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => info(
                'Условия отмены',
                'В прототипе вы можете отменить или перенести демонстрационную запись в любой момент. Для будущего приложения в референсе предусмотрена бесплатная отмена за 24 часа до приёма.',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: C.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Условия отмены и переноса',
                    style: tx(12, color: C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (widget.onAsk != null) ...[
        OutlinedButton.icon(
          key: const ValueKey('profile-ask'),
          onPressed: widget.onAsk,
          icon: const Icon(Icons.edit_note),
          label: const Text('Подготовить вопросы к приёму'),
        ),
        const SizedBox(height: 12),
      ],
      Surface(
        padding: 18,
        child: InkWell(
          onTap: chat,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: C.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Есть вопрос?',
                      style: tx(14, weight: FontWeight.w500),
                    ),
                    Text(
                      appointment == null
                          ? 'Чат станет доступен после записи'
                          : 'Напишите в демо-чат клиники',
                      style: tx(11, color: C.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 16, color: C.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Вы управляете записью. Приём можно перенести или отменить в профиле.',
                style: tx(12, color: C.muted),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget formatButton(String label, bool value, IconData icon) => Semantics(
    selected: online == value,
    button: true,
    child: InkWell(
      onTap: () => selectFormat(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: online == value ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: online == value ? C.ink : C.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: tx(
                12,
                weight: FontWeight.w500,
                color: online == value ? C.ink : C.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget detailRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 9),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: tx(13, color: C.muted)),
      ),
      const SizedBox(width: 14),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: tx(14, weight: FontWeight.w500),
        ),
      ),
    ],
  ),
);

class Surface extends StatelessWidget {
  const Surface({
    required this.child,
    this.padding = 24,
    this.color = Colors.white,
    super.key,
  });
  final Widget child;
  final double padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: color == Colors.white ? Border.all(color: C.line) : null,
      boxShadow: color == Colors.white
          ? const [
              BoxShadow(
                color: Color(0x05061713),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: onPressed == null
          ? null
          : const LinearGradient(
              colors: [Color(0xFFC8FF4D), Color(0xFF5CEB7A)],
            ),
      color: onPressed == null ? C.soft : null,
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: const StadiumBorder(),
        foregroundColor: C.ink,
        disabledForegroundColor: C.muted,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Onest',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class RoundAction extends StatelessWidget {
  const RoundAction(
    this.icon,
    this.label,
    this.onPressed, {
    this.color = C.ink,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .9),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 21, color: color),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    ),
  );
}

class DoctorMini extends StatelessWidget {
  const DoctorMini({this.details = const ProfessionalDetails(), super.key});
  final ProfessionalDetails details;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/anna-demo.png',
          width: 60,
          height: 66,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Анна Волкова', style: tx(18, weight: FontWeight.w600)),
            Text(
              '${details.specialty} · ${details.years} лет опыта',
              style: tx(13, color: C.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class DemoChatContent extends StatefulWidget {
  const DemoChatContent({required this.messages, super.key});
  final List<String> messages;

  @override
  State<DemoChatContent> createState() => _DemoChatContentState();
}

class _DemoChatContentState extends State<DemoChatContent> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Демонстрация переписки · сообщения никуда не отправляются',
        style: tx(12, color: C.muted),
      ),
      const SizedBox(height: 18),
      const Surface(
        color: C.soft,
        padding: 16,
        child: Text(
          'Здравствуйте! Здесь можно уточнить организационные вопросы перед приёмом.',
        ),
      ),
      for (final message in widget.messages)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Surface(
            color: const Color(0xFFE5F7E9),
            padding: 16,
            child: Text(message),
          ),
        ),
      const SizedBox(height: 20),
      TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: 'Ваш вопрос',
          hintText: 'Например, как подготовить анализы?',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      const SizedBox(height: 12),
      PrimaryButton('Отправить в демо-чат', () {
        final value = controller.text.trim();
        if (value.isEmpty) return;
        setState(() => widget.messages.add(value));
        controller.clear();
      }),
    ],
  );
}
