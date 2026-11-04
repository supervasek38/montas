part of 'main.dart';

String discoveryMoney(int value) {
  if (value == 0) return 'Бесплатно';
  final digits = value.toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
  return '$formatted ₽';
}

const discoveryDemoNote =
    'Демо-сценарий · 20 октября 2026. События, товары, продавцы и цены — примеры. '
    'Действия сохраняются до перезагрузки страницы.';

Future<T?> discoveryDialog<T>(
  BuildContext context,
  String title,
  Widget Function(BuildContext) content,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 18),
            content(ctx),
          ],
        ),
      ),
    ),
  ),
);

class DiscoveryLayout extends StatelessWidget {
  const DiscoveryLayout({required this.id, required this.children, super.key});
  final String id;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: PageStorageKey(id),
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            const SizedBox(height: 28),
            Text(discoveryDemoNote, style: tx(11, color: C.muted)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

class DiscoveryHeading extends StatelessWidget {
  const DiscoveryHeading(this.eyebrow, this.title, this.subtitle, {super.key});
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: tx(11, weight: FontWeight.w600, color: C.green),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: tx(
            MediaQuery.sizeOf(context).width < 600 ? 30 : 38,
            weight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: tx(15, color: C.muted)),
      ],
    ),
  );
}

class DiscoveryTabs extends StatelessWidget {
  const DiscoveryTabs({
    required this.id,
    required this.labels,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final String id;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            key: ValueKey('$id-tab-$i'),
            label: Text(labels[i]),
            selected: selected == i,
            showCheckmark: false,
            selectedColor: C.dark,
            labelStyle: tx(
              13,
              weight: FontWeight.w500,
              color: selected == i ? Colors.white : C.ink,
            ),
            onSelected: (_) => onSelect(i),
          ),
      ],
    ),
  );
}

class DiscoveryGrid extends StatelessWidget {
  const DiscoveryGrid({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 1000
          ? 3
          : box.maxWidth >= 660
          ? 2
          : 1;
      final width = (box.maxWidth - (columns - 1) * 20) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class DiscoveryColumns extends StatelessWidget {
  const DiscoveryColumns({required this.main, required this.aside, super.key});
  final Widget main, aside;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 850) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, const SizedBox(height: 20), aside],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: main),
          const SizedBox(width: 24),
          SizedBox(width: 350, child: aside),
        ],
      );
    },
  );
}

class DiscoveryEmpty extends StatelessWidget {
  const DiscoveryEmpty(
    this.title,
    this.description,
    this.action,
    this.onAction, {
    super.key,
  });
  final String title, description, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.search_rounded, size: 32, color: C.green),
        const SizedBox(height: 16),
        Text(title, style: tx(22, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(description, style: tx(14, color: C.muted)),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}

Widget discoveryFact(IconData icon, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: C.green),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: tx(14))),
    ],
  ),
);
