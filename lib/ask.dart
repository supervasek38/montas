part of 'main.dart';

class AskMessage {
  const AskMessage(this.text, {this.user = false, this.action, this.source});
  final String text;
  final bool user;
  final String? action, source;
}

class QuestionTransfer {
  QuestionTransfer(List<String> questions, this.days)
    : questions = List.unmodifiable(questions);
  final List<String> questions;
  final int days;
  bool revoked = false, exampleAnswer = false;
  bool inProgress = false;
  String replyDraft = '';
  String? specialistReply;
  bool publishReply(String value) {
    final text = value.trim();
    if (revoked ||
        specialistReply != null ||
        text.isEmpty ||
        text.length > 3000) {
      return false;
    }
    specialistReply = text;
    replyDraft = '';
    inProgress = false;
    return true;
  }

  String get until => '${20 + days} октября 2026, 23:59 · Иркутск';
}

class AskScreen extends StatefulWidget {
  const AskScreen({
    required this.energy,
    required this.energyDay,
    required this.planStatus,
    required this.onPlan,
    required this.onRadar,
    required this.onSpecialist,
    this.appointment,
    this.onData,
    this.onConversationChanged,
    this.consiliums,
    this.workProfile,
    super.key,
  });
  final int energy, energyDay;
  final String planStatus;
  final Appointment? appointment;
  final VoidCallback onPlan, onRadar, onSpecialist;
  final VoidCallback? onData;
  final VoidCallback? onConversationChanged;
  final ConsiliumStore? consiliums;
  final ExpertWorkProfile? workProfile;
  @override
  State<AskScreen> createState() => AskScreenState();
}

class AskScreenState extends State<AskScreen> {
  static const examples = [
    'Что может быть связано с моей усталостью?',
    'Какие данные стоит обсудить после получения анализа?',
    'Как согласовать мой план с текущим самочувствием?',
  ];
  final composer = TextEditingController();
  final chatScroll = ScrollController();
  final pageScroll = ScrollController();
  final questions = examples
      .map((q) => TextEditingController(text: q))
      .toList();
  final messages = <AskMessage>[];
  final transfers = <QuestionTransfer>[];
  final history = <String>[];
  List<String> saved = [];
  bool specialist = false, editing = true;
  String? validation;
  QuestionTransfer? get activeTransfer =>
      transfers.where((t) => !t.revoked).firstOrNull;

  @override
  void dispose() {
    composer.dispose();
    chatScroll.dispose();
    pageScroll.dispose();
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  void openSpecialist() => setState(() => specialist = true);
  void refreshReplies() {
    if (mounted) setState(() {});
  }

  Future<T?> popup<T>(
    String title,
    Widget Function(BuildContext) body,
  ) => showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(ctx).height - 64,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: tx(23, weight: FontWeight.w600)),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              body(ctx),
            ],
          ),
        ),
      ),
    ),
  );

  void notify(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  void send([String? prompt]) {
    final text = (prompt ?? composer.text).trim();
    if (text.isEmpty || text.length > 1200) return;
    final lower = text.toLowerCase();
    late AskMessage answer;
    if (lower == 'подготовить вопросы к приёму') {
      answer = const AskMessage(
        'Можно начать с трёх вопросов: о причинах усталости, данных для обсуждения и согласовании плана. Откройте черновик и отредактируйте формулировки под себя.',
        action: 'draft',
        source: 'Шаблон вопросов из Figma · цель «Больше энергии».',
      );
    } else if (lower == 'объяснить показатели') {
      answer = AskMessage(
        'В радаре последняя отметка энергии — ${widget.energy}/10 за ${widget.energyDay} октября. Это самооценка. Отдельной отметки недостаточно, чтобы объяснить причину усталости или сделать вывод об улучшении. Историю можно посмотреть в дневнике.',
        action: 'radar',
        source:
            'Радар → Энергия · личная отметка за ${widget.energyDay} октября. Анализы и данные устройства не подключены.',
      );
    } else if (lower == 'что в моём плане?') {
      answer = AskMessage(
        'Ваш план восстановления: «${widget.planStatus}». Откройте его, чтобы посмотреть текущий шаг и доступные действия.',
        action: 'plan',
        source: 'Мой план · текущее состояние демонстрационного сценария.',
      );
    } else {
      answer = const AskMessage(
        'В этой версии свободные сообщения не обрабатываются моделью. Могу перенести ваш текст в редактируемые вопросы специалисту. Для проверки чата также доступны сценарии про показатели и план.',
        action: 'question',
        source: 'Демонстрационный ответ · внешняя ИИ-модель не подключена.',
      );
    }
    setState(() {
      messages.add(AskMessage(text, user: true));
      messages.add(answer);
      composer.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScroll.hasClients) {
        chatScroll.jumpTo(chatScroll.position.maxScrollExtent);
      }
    });
  }

  void addFromChat(String text) {
    if (questions.any((q) => q.text.trim() == text.trim())) {
      setState(() {
        specialist = true;
        editing = true;
      });
      notify('Этот вопрос уже в черновике');
      return;
    }
    if (questions.length >= 5) {
      notify('В списке уже 5 вопросов. Удалите один, чтобы добавить новый.');
      setState(() {
        specialist = true;
        editing = true;
      });
      return;
    }
    setState(() {
      questions.add(TextEditingController(text: text));
      specialist = true;
      editing = true;
    });
  }

  Future<void> review() async {
    final values = questions.map((q) => q.text.trim()).toList();
    if (values.isEmpty || values.any((q) => q.isEmpty || q.length > 1200)) {
      setState(
        () => validation =
            'Заполните каждый вопрос или удалите пустой. Максимум — 1200 символов.',
      );
      return;
    }
    setState(() => validation = null);
    final ok = await popup<bool>(
      'Проверьте вопросы',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Сохраним список в вашем прототипе. Передача специалисту — отдельный шаг.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 18),
          questionList(values),
          const SizedBox(height: 20),
          PrimaryButton(
            'Сохранить вопросы',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('save-questions'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Вернуться к редактированию'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        saved = List.of(values);
        editing = false;
        history.insert(0, 'Сохранён список из ${saved.length} вопросов');
      });
    }
  }

  Future<void> handoff() async {
    if (widget.workProfile?.acceptingRequests == false) {
      notify('Специалист временно приостановил новые запросы');
      return;
    }
    if (saved.isEmpty || activeTransfer != null) return;
    var consent = false;
    var days = 7;
    final snapshot = List<String>.of(saved);
    final ok = await popup<bool>(
      'Передать вопросы?',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DoctorMini(),
            const SizedBox(height: 18),
            Text(
              'Только этот список · ${snapshot.length} вопроса',
              style: tx(16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            questionList(snapshot),
            const SizedBox(height: 12),
            Text(
              'Анализы, дневник, переписка с ИИ и семейные данные не включены. Доступ — только для просмотра при подготовке к приёму.',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const ValueKey('access-duration'),
              initialValue: days,
              decoration: const InputDecoration(
                labelText: 'Срок доступа',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 день')),
                DropdownMenuItem(value: 7, child: Text('7 дней')),
              ],
              onChanged: (value) => update(() => days = value!),
            ),
            const SizedBox(height: 12),
            Text(
              'До ${20 + days} октября 2026, 23:59 · Иркутск\nДемо-дата сценария: 20 октября.',
              style: tx(12, color: C.muted),
            ),
            CheckboxListTile(
              key: const ValueKey('handoff-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Разрешаю Анне Волковой просматривать эти вопросы',
                style: tx(14),
              ),
              value: consent,
              onChanged: (value) => update(() => consent = value!),
            ),
            PrimaryButton(
              'Разрешить и отправить',
              consent ? () => Navigator.pop(ctx, true) : null,
              key: const ValueKey('confirm-handoff'),
            ),
            const SizedBox(height: 10),
            Text(
              'Демонстрация: информация остаётся в этом браузере.',
              textAlign: TextAlign.center,
              style: tx(12, color: C.muted),
            ),
          ],
        ),
      ),
    );
    if (ok == true &&
        mounted &&
        widget.workProfile?.acceptingRequests != false &&
        activeTransfer == null) {
      setState(() {
        transfers.add(QuestionTransfer(snapshot, days));
        history.insert(
          0,
          'Демо-передача №${transfers.length}: ${snapshot.length} вопросов · доступ на $days дн.',
        );
      });
      widget.onConversationChanged?.call();
    }
  }

  Future<void> revoke(QuestionTransfer transfer) async {
    final ok = await popup<bool>(
      'Отозвать доступ?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Специалист больше не сможет открывать этот список через предоставленный доступ. Ваш список и история сохранятся. Запись на приём остаётся в силе.',
            style: tx(15),
          ),
          const SizedBox(height: 14),
          Text(
            'Уже просмотренную или сохранённую получателем информацию нельзя забрать обратно.',
            style: tx(13, color: C.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Да, отозвать доступ',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('confirm-revoke'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Не отзывать'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        transfer.revoked = true;
        history.insert(
          0,
          'Доступ к передаче №${transfers.indexOf(transfer) + 1} отозван',
        );
      });
      widget.onConversationChanged?.call();
    }
  }

  Widget questionList(List<String> values) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < values.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${i + 1}.',
                style: tx(15, color: C.green, weight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(values[i], style: tx(15))),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 950;
      final main = specialist ? questionPanel() : chatPanel();
      return SingleChildScrollView(
        controller: pageScroll,
        padding: EdgeInsets.all(box.maxWidth < 600 ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ПОДДЕРЖКА НА ВАШЕМ ПУТИ', style: tx(11, color: C.muted)),
                const SizedBox(height: 8),
                Text(
                  'Спросить MONTAS',
                  style: tx(
                    box.maxWidth < 600 ? 29 : 36,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Разобраться в контексте. Подготовиться к разговору. Сделать следующий шаг.',
                  style: tx(15, color: C.muted),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.onData != null)
                      TextButton.icon(
                        onPressed: widget.onData,
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('Мои данные'),
                      ),
                    ChoiceChip(
                      key: const ValueKey('ask-ai-tab'),
                      selected: !specialist,
                      showCheckmark: false,
                      avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Чат с ИИ'),
                      onSelected: (_) => setState(() => specialist = false),
                    ),
                    ChoiceChip(
                      key: const ValueKey('ask-specialist-tab'),
                      selected: specialist,
                      showCheckmark: false,
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Вопрос специалисту'),
                      onSelected: (_) => openSpecialist(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: main),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: contextPanel()),
                    ],
                  )
                else ...[
                  main,
                  const SizedBox(height: 20),
                  contextPanel(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget chatPanel() => Surface(
    padding: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.dark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: C.lime, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MONTAS AI', style: tx(18, weight: FontWeight.w600)),
                  Text(
                    'Демо · ответы по сценарию',
                    style: tx(12, color: C.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Новый диалог',
              onPressed: messages.isEmpty
                  ? null
                  : () async {
                      final ok = await popup<bool>(
                        'Начать новый диалог?',
                        (ctx) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Переписка очистится. Подготовленные вопросы специалисту сохранятся.',
                              style: tx(14),
                            ),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              'Начать заново',
                              () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        setState(() {
                          messages.clear();
                          composer.clear();
                        });
                      }
                    },
              icon: const Icon(Icons.edit_square, size: 21),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('С чего начнём?', style: tx(28, weight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(
                  'Помогу посмотреть на ваши отметки и подготовить вопросы к приёму. Вы выбираете, что сохранить и передать специалисту.',
                  style: tx(15, color: C.muted),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 340,
            child: ListView.builder(
              key: const ValueKey('ai-messages'),
              controller: chatScroll,
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final m = messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: m.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: m.user ? const Color(0xFFEAFBD9) : C.soft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.user ? 'Вы' : 'MONTAS AI · демо',
                            style: tx(
                              11,
                              color: C.muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(m.text, style: tx(14)),
                          if (m.action != null)
                            TextButton(
                              key: ValueKey('message-action-$i'),
                              onPressed: () {
                                switch (m.action) {
                                  case 'draft':
                                    openSpecialist();
                                  case 'radar':
                                    widget.onRadar();
                                  case 'plan':
                                    widget.onPlan();
                                  default:
                                    addFromChat(messages[i - 1].text);
                                }
                              },
                              child: Text(switch (m.action) {
                                'draft' => 'Открыть черновик →',
                                'radar' => 'Открыть радар →',
                                'plan' => 'Открыть план →',
                                _ => 'В вопросы специалисту →',
                              }),
                            ),
                          if (m.source != null)
                            TextButton.icon(
                              onPressed: () => popup<void>(
                                'На чём основан ответ',
                                (_) => Text(m.source!, style: tx(15)),
                              ),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Контекст ответа'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final prompt in [
              'Подготовить вопросы к приёму',
              'Объяснить показатели',
              'Что в моём плане?',
            ])
              ActionChip(
                label: Text(prompt, style: tx(12)),
                onPressed: () => send(prompt),
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('ai-composer'),
          controller: composer,
          minLines: 2,
          maxLines: 5,
          maxLength: 1200,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Напишите сообщение…',
            filled: true,
            fillColor: C.canvas,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: C.line),
            ),
          ),
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          'Отправить сообщение',
          composer.text.trim().isEmpty ? null : send,
          key: const ValueKey('send-ai'),
        ),
        const SizedBox(height: 12),
        Text(
          'ИИ помогает с формулировками. Медицинские решения — со специалистом.',
          textAlign: TextAlign.center,
          style: tx(11, color: C.muted),
        ),
      ],
    ),
  );

  Widget questionPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.workProfile != null) ...[
        Surface(
          color: C.soft,
          padding: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.workProfile!.acceptingRequests
                    ? 'Анна Волкова принимает вопросы'
                    : 'Новые запросы временно на паузе',
                style: tx(16, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                widget.workProfile!.acceptingRequests
                    ? 'Ориентир ответа: ${widget.workProfile!.responseDays} дн. Точный срок согласуется отдельно.'
                    : 'Сохраните вопросы, чтобы передать их позже. Уже переданные обращения и записи на приём сохраняются.',
                style: tx(13, color: C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag(editing ? 'Черновик' : 'Сохранено', green: !editing),
                const Tag('Только вопросы'),
              ],
            ),
            const SizedBox(height: 18),
            Text('Вопросы к приёму', style: tx(27, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              editing
                  ? 'Измените пример под себя. Сначала проверим список, затем вы решите, передавать ли его специалисту.'
                  : 'Ваш список сохранён в текущем сеансе. Его можно изменить или передать специалисту.',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 24),
            if (editing) ...[
              for (var i = 0; i < questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: ValueKey('question-$i'),
                          controller: questions[i],
                          minLines: 2,
                          maxLines: 6,
                          maxLength: 1200,
                          decoration: InputDecoration(
                            labelText: 'Вопрос ${i + 1}',
                            alignLabelWithHint: true,
                            counterText: '',
                            filled: true,
                            fillColor: C.canvas,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: C.line),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Удалить вопрос ${i + 1}',
                        onPressed: questions.length == 1
                            ? null
                            : () => setState(() {
                                questions.removeAt(i).dispose();
                              }),
                        icon: const Icon(Icons.close, size: 19),
                      ),
                    ],
                  ),
                ),
              if (questions.length < 5)
                TextButton.icon(
                  key: const ValueKey('add-question'),
                  onPressed: () =>
                      setState(() => questions.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить свой вопрос'),
                ),
              if (validation != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    validation!,
                    style: tx(13, color: const Color(0xFFAA3636)),
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                'Проверить вопросы',
                review,
                key: const ValueKey('review-questions'),
              ),
            ] else ...[
              questionList(saved),
              PrimaryButton(
                transfers.isEmpty ? 'Передать специалисту' : 'Передать снова',
                activeTransfer == null &&
                        widget.workProfile?.acceptingRequests != false
                    ? handoff
                    : null,
                key: const ValueKey('handoff-questions'),
              ),
              if (activeTransfer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Чтобы передать новый список, сначала отзовите прежний доступ ниже.',
                    style: tx(12, color: C.muted),
                  ),
                ),
              TextButton(
                key: const ValueKey('edit-questions'),
                onPressed: () => setState(() => editing = true),
                child: const Text('Изменить вопросы'),
              ),
            ],
          ],
        ),
      ),
      if (transfers.isNotEmpty) ...[
        const SizedBox(height: 20),
        transferPanel(transfers.last),
      ],
      if (widget.consiliums != null)
        ConsiliumPatientPanel(store: widget.consiliums!),
      if (history.isNotEmpty) ...[
        const SizedBox(height: 16),
        Surface(
          padding: 8,
          child: ExpansionTile(
            key: const ValueKey('question-history'),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'История действий · ${history.length}',
              style: tx(14, weight: FontWeight.w600),
            ),
            children: [
              for (final event in history)
                ListTile(
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(event, style: tx(13)),
                  subtitle: Text(
                    '20 октября · демо-сеанс',
                    style: tx(11, color: C.muted),
                  ),
                ),
              for (var i = 0; i < transfers.length; i++)
                ExpansionTile(
                  title: Text(
                    'Передача №${i + 1} · ${transfers[i].revoked ? 'отозвана' : 'доступ открыт'}',
                    style: tx(13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: questionList(transfers[i].questions),
                    ),
                    if (transfers[i].specialistReply != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Ответ Анны Волковой · демо',
                              style: tx(14, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(transfers[i].specialistReply!, style: tx(14)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget transferPanel(QuestionTransfer transfer) => Surface(
    color: transfer.revoked ? C.soft : const Color(0xFFEAF5EF),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              transfer.revoked
                  ? Icons.lock_outline
                  : Icons.mark_email_read_outlined,
              color: C.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                transfer.revoked ? 'Доступ отозван' : 'Вопросы переданы · демо',
                style: tx(20, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          transfer.revoked
              ? 'Прежнее разрешение закрыто. Повторная передача потребует нового подтверждения.'
              : 'Анна Волкова · ${transfer.questions.length} вопроса\nТолько просмотр до ${transfer.until}',
          style: tx(14),
        ),
        const SizedBox(height: 12),
        if (transfer.specialistReply != null) ...[
          Text(
            'Ответ Анны Волковой · демо',
            style: tx(16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SelectableText(
            transfer.specialistReply!,
            key: const ValueKey('received-specialist-reply'),
            style: tx(15),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавлен в кабинете специалиста. План автоматически не изменялся.',
            style: tx(12, color: C.muted),
          ),
          const SizedBox(height: 16),
        ],
        if (!transfer.revoked) ...[
          if (transfer.specialistReply == null)
            Text(
              transfer.exampleAnswer
                  ? 'Пример ответа · не сообщение реального специалиста'
                  : 'Ожидаем ответа. Специалист ещё не подтвердил разбор. Срок ответа не подтверждён.',
              style: tx(13, color: C.muted),
            ),
          if (transfer.exampleAnswer && transfer.specialistReply == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '«Спасибо за подготовленный список. Обсудим эти вопросы на встрече. Если есть результаты обследований, подготовьте их к приёму».',
                style: tx(15),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('revoke-access'),
            onPressed: () => revoke(transfer),
            child: const Text('Отозвать доступ'),
          ),
          if (!transfer.exampleAnswer && transfer.specialistReply == null)
            TextButton(
              key: const ValueKey('example-answer'),
              onPressed: () => setState(() {
                transfer.exampleAnswer = true;
                history.insert(0, 'Открыт демонстрационный пример ответа');
              }),
              child: const Text('Показать пример ответа'),
            ),
        ],
      ],
    ),
  );

  Widget contextPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Surface(
        color: C.dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ВАШ КОНТЕКСТ', style: tx(11, color: C.lime)),
            const SizedBox(height: 14),
            Text(
              'Больше энергии',
              style: tx(24, weight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              '${widget.energy} / 10',
              style: tx(32, weight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              'Энергия · ваша отметка\n${widget.energyDay} октября',
              style: tx(13, color: const Color(0xFFBCD5C8)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFF365347)),
            ),
            Text(
              'План восстановления',
              style: tx(14, weight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              widget.planStatus,
              style: tx(13, color: const Color(0xFFBCD5C8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Анализы и данные сна пока не подключены.',
              style: tx(12, color: const Color(0xFFBCD5C8)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ВАШ СПЕЦИАЛИСТ', style: tx(11, color: C.muted)),
            const SizedBox(height: 16),
            const DoctorMini(),
            const SizedBox(height: 16),
            Text(
              widget.appointment == null
                  ? 'Вопросы можно подготовить заранее, до записи на приём.'
                  : '${widget.appointment!.date} · ${widget.appointment!.time}\n${widget.appointment!.format}',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onSpecialist,
              child: const Text('Профиль специалиста'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Это интерактивное демо. Переписка, вопросы и разрешения хранятся до перезагрузки страницы. Реальной отправки врачу и ИИ нет.',
          style: tx(12, color: C.muted),
        ),
      ),
    ],
  );
}
