part of 'main.dart';

class MarketOffer {
  const MarketOffer(
    this.id,
    this.seller,
    this.price,
    this.delivery,
    this.warranty,
    this.returns,
  );
  final String id, seller, delivery, warranty, returns;
  final int price;
}

class MarketProduct {
  const MarketProduct(
    this.id,
    this.name,
    this.category,
    this.description,
    this.variant,
    this.facts,
    this.icon,
    this.offers,
  );
  final String id, name, category, description, variant, facts;
  final IconData icon;
  final List<MarketOffer> offers;
  int get price => offers.map((o) => o.price).reduce((a, b) => a < b ? a : b);
}

const marketProducts = [
  MarketProduct(
    'ring',
    'Ring X',
    'Устройства',
    'Кольцо для наблюдения за повседневной активностью и режимом сна. '
        'Демонстрационный товар из каталога MONTAS.',
    'Серебристый · размер 9',
    'В примере: приложение для телефона, зарядная станция в комплекте. '
        'Характеристики условные; точность измерений и совместимость здесь не проверяются.',
    Icons.circle_outlined,
    [
      MarketOffer(
        'ring-care',
        'TechCare · демо',
        24900,
        '22 октября',
        'Гарантия продавца · 1 год',
        'Возврат по условиям демо-продавца · 14 дней',
      ),
      MarketOffer(
        'ring-home',
        'Home Lab · демо',
        25900,
        '21 октября',
        'Гарантия продавца · 1 год',
        'Возврат по условиям демо-продавца · 7 дней',
      ),
    ],
  ),
  MarketProduct(
    'light',
    'Световой будильник',
    'Устройства',
    'Мягкий свет для вечернего ритуала и постепенного пробуждения. '
        'Выберите предложение и условия получения.',
    'Белый · базовая комплектация',
    'В примере: настройка яркости и времени включения, питание от сети. '
        'Устройство не заменяет медицинскую диагностику.',
    Icons.wb_twilight_rounded,
    [
      MarketOffer(
        'light-home',
        'Home Lab · демо',
        8900,
        '21 октября',
        'Гарантия продавца · 1 год',
        'Возврат по условиям демо-продавца · 14 дней',
      ),
      MarketOffer(
        'light-care',
        'TechCare · демо',
        8500,
        '23 октября',
        'Гарантия продавца · 1 год',
        'Возврат по условиям демо-продавца · 14 дней',
      ),
    ],
  ),
  MarketProduct(
    'mask',
    'Маска для сна',
    'Аксессуары',
    'Небольшая деталь для привычного отдыха дома и в поездке. '
        'Мягкая ткань и регулируемая посадка в демонстрационном описании.',
    'Графит · универсальный размер',
    'В примере: текстильный чехол в комплекте. Состав и уход нужно '
        'уточнять по маркировке реального товара.',
    Icons.bedtime_outlined,
    [
      MarketOffer(
        'mask-home',
        'Home Lab · демо',
        2990,
        '21 октября',
        'Проверка комплектности при получении',
        'Возврат при сохранении упаковки · демо',
      ),
      MarketOffer(
        'mask-care',
        'TechCare · демо',
        2790,
        '23 октября',
        'Проверка комплектности при получении',
        'Возврат при сохранении упаковки · демо',
      ),
    ],
  ),
];

class MarketLine {
  const MarketLine(this.product, this.offer, this.quantity);
  final MarketProduct product;
  final MarketOffer offer;
  final int quantity;
  String get id => offer.id;
  int get total => offer.price * quantity;
}

enum MarketDelivery { pickup, courier }

class MarketQuote {
  MarketQuote._(
    this._source,
    this.revision,
    List<MarketLine> items,
    this.delivery,
  ) : items = List.unmodifiable(items);
  final MarketplaceStore _source;
  final int revision;
  final List<MarketLine> items;
  final MarketDelivery delivery;
  int get subtotal => items.fold(0, (sum, line) => sum + line.total);
  Set<String> get sellers => items.map((line) => line.offer.seller).toSet();
  int get shipping =>
      delivery == MarketDelivery.pickup ? 0 : sellers.length * 300;
  int get total => subtotal + shipping;
  String get destination => delivery == MarketDelivery.pickup
      ? 'Самовывоз · демо-пункт MONTAS Hub, Москва'
      : 'Курьер · демо-адрес: Москва, Тестовая улица, 1';
}

class MarketOrder {
  MarketOrder(this.id, this.quote);
  final String id;
  final MarketQuote quote;
  bool cancelled = false;
}

class MarketplaceStore extends ChangeNotifier {
  final _cart = <MarketLine>[];
  final _orders = <MarketOrder>[];
  final saved = <String>{};
  int _revision = 0;
  List<MarketLine> get cart => List.unmodifiable(_cart);
  List<MarketOrder> get orders => List.unmodifiable(_orders);
  int get quantity => _cart.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => _cart.fold(0, (sum, line) => sum + line.total);
  void toggleSaved(String id) {
    if (!saved.remove(id)) saved.add(id);
    notifyListeners();
  }

  bool add(MarketProduct product, MarketOffer offer) {
    if (!marketProducts.contains(product) || !product.offers.contains(offer)) {
      return false;
    }
    final i = _cart.indexWhere((line) => line.id == offer.id);
    if (i >= 0 && _cart[i].quantity >= 5) return false;
    if (i < 0) {
      _cart.add(MarketLine(product, offer, 1));
    } else {
      _cart[i] = MarketLine(product, offer, _cart[i].quantity + 1);
    }
    _revision++;
    notifyListeners();
    return true;
  }

  bool setQuantity(String id, int value) {
    final i = _cart.indexWhere((line) => line.id == id);
    if (i < 0 || value < 1 || value > 5 || _cart[i].quantity == value) {
      return false;
    }
    _cart[i] = MarketLine(_cart[i].product, _cart[i].offer, value);
    _revision++;
    notifyListeners();
    return true;
  }

  void remove(String id) {
    final length = _cart.length;
    _cart.removeWhere((line) => line.id == id);
    if (length != _cart.length) {
      _revision++;
      notifyListeners();
    }
  }

  MarketQuote quote(MarketDelivery delivery) =>
      MarketQuote._(this, _revision, _cart, delivery);
  MarketOrder? checkout(MarketQuote quote) {
    // A confirmed quote belongs to this store and the exact cart revision.
    if (!identical(quote._source, this) ||
        quote.revision != _revision ||
        _cart.isEmpty) {
      return null;
    }
    final order = MarketOrder(
      'MK-${(_orders.length + 1).toString().padLeft(3, '0')}',
      quote,
    );
    _orders.add(order);
    _cart.clear();
    _revision++;
    notifyListeners();
    return order;
  }

  bool cancel(MarketOrder order) {
    if (!_orders.contains(order) || order.cancelled) return false;
    order.cancelled = true;
    notifyListeners();
    return true;
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => MarketplaceScreenState();
}

class MarketplaceScreenState extends State<MarketplaceScreen> {
  final store = MarketplaceStore();
  final search = TextEditingController();
  int tab = 0;
  String category = 'Все товары';
  bool cheapestFirst = false;
  MarketProduct? selected;
  MarketOffer? selectedOffer;
  @override
  void dispose() {
    store.dispose();
    search.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    search.clear();
    category = 'Все товары';
    cheapestFirst = false;
    selected = null;
    tab = 0;
  });
  void open(MarketProduct product) => setState(() {
    selected = product;
    selectedOffer = product.offers.first;
  });
  void showTab(int value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      tab = value;
      selected = null;
    });
  }

  Future<void> checkout() async {
    var delivery = MarketDelivery.pickup;
    var quote = store.quote(delivery);
    var accepted = false;
    String? error;
    final result = await discoveryDialog<MarketOrder>(
      context,
      'Оформление демо-заказа',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('1. Получение', style: tx(17, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in MarketDelivery.values)
                  ChoiceChip(
                    key: ValueKey('market-delivery-${value.name}'),
                    label: Text(
                      value == MarketDelivery.pickup ? 'Самовывоз' : 'Курьер',
                    ),
                    selected: delivery == value,
                    onSelected: (_) => update(() {
                      delivery = value;
                      quote = store.quote(value);
                      accepted = false;
                      error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(quote.destination, style: tx(13, color: C.muted)),
            const SizedBox(height: 22),
            Text(
              '2. Состав и стоимость',
              style: tx(17, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final seller in quote.sellers) ...[
              Text(seller, style: tx(14, weight: FontWeight.w600)),
              for (final line in quote.items.where(
                (l) => l.offer.seller == seller,
              ))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${line.product.name} · ${line.product.variant}\n'
                    '${line.quantity} × ${discoveryMoney(line.offer.price)} = ${discoveryMoney(line.total)}\n'
                    'Получение: ${line.offer.delivery} · демо',
                    style: tx(13),
                  ),
                ),
              const Divider(height: 20),
            ],
            totals(quote.subtotal, quote.shipping),
            const SizedBox(height: 12),
            Text(
              delivery == MarketDelivery.courier
                  ? 'Доставка: 300 ₽ за отправление каждого продавца.'
                  : 'Самовывоз бесплатный. Пункт и адрес — примеры для проверки интерфейса.',
              style: tx(12, color: C.muted),
            ),
            const SizedBox(height: 18),
            Text(
              'Оплата не подключена. Товары не резервируются и не отправляются.',
              style: tx(13, color: C.muted),
            ),
            CheckboxListTile(
              key: const ValueKey('market-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: accepted,
              onChanged: (v) => update(() => accepted = v ?? false),
              title: Text('Проверил товары, продавцов и итог', style: tx(13)),
            ),
            if (error != null) ...[
              Text(error!, style: tx(13, color: Colors.red.shade700)),
              TextButton(
                onPressed: () => update(() {
                  quote = store.quote(delivery);
                  accepted = false;
                  error = null;
                }),
                child: const Text('Обновить состав заказа'),
              ),
            ],
            PrimaryButton(
              'Создать демо-заказ',
              accepted && quote.items.isNotEmpty && error == null
                  ? () {
                      final order = store.checkout(quote);
                      if (order == null) {
                        update(() {
                          error =
                              'Корзина изменилась. Проверьте новый состав и стоимость.';
                          accepted = false;
                        });
                      } else {
                        Navigator.pop(ctx, order);
                      }
                    }
                  : null,
              key: const ValueKey('market-confirm'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      showTab(3);
      await orderDetail(result);
    }
  }

  Future<void> cancelOrder(MarketOrder order) async {
    final yes = await discoveryDialog<bool>(
      context,
      'Отменить демо-заказ?',
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${order.id} · ${discoveryMoney(order.quote.total)}',
            style: tx(18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Состав останется в истории. Возврат денег не требуется: оплаты не было.',
            style: tx(14, color: C.muted),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            'Отменить заказ',
            () => Navigator.pop(ctx, true),
            key: const ValueKey('market-cancel-confirm'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Оставить заказ'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) store.cancel(order);
  }

  Future<void> orderDetail(MarketOrder order) => discoveryDialog<void>(
    context,
    'Заказ ${order.id}',
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tag(
          order.cancelled ? 'Отменён' : 'Создан · демо',
          green: !order.cancelled,
        ),
        const SizedBox(height: 14),
        Text(
          order.cancelled
              ? 'Запись сохранена в истории.'
              : 'Демо-заказ сохранён. Подтверждения от продавцов и реальной доставки нет.',
          style: tx(14, color: C.muted),
        ),
        const SizedBox(height: 18),
        Text(order.quote.destination, style: tx(14)),
        const SizedBox(height: 18),
        for (final seller in order.quote.sellers) ...[
          Text(seller, style: tx(16, weight: FontWeight.w600)),
          for (final line in order.quote.items.where(
            (l) => l.offer.seller == seller,
          ))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${line.product.name}\n${line.product.variant}\n'
                '${line.quantity} × ${discoveryMoney(line.offer.price)}\n'
                'Получение по макету: ${line.offer.delivery}\n${line.offer.returns}',
                style: tx(13),
              ),
            ),
          const Divider(height: 22),
        ],
        totals(order.quote.subtotal, order.quote.shipping),
        const SizedBox(height: 22),
        PrimaryButton(
          'К моим заказам',
          () => Navigator.pop(ctx),
          key: const ValueKey('market-order-close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => selected != null
        ? detail(selected!)
        : DiscoveryLayout(
            id: 'market-list-$tab',
            children: [
              const DiscoveryHeading(
                'MONTAS MARKET',
                'Маркетплейс',
                'Товары и устройства для повседневной заботы о себе.',
              ),
              DiscoveryTabs(
                id: 'market',
                labels: [
                  'Каталог',
                  'Сохранённые (${store.saved.length})',
                  'Корзина (${store.quantity})',
                  'Мои заказы (${store.orders.length})',
                ],
                selected: tab,
                onSelect: showTab,
              ),
              if (tab < 2) ...catalog() else if (tab == 2) cart() else orders(),
            ],
          ),
  );

  List<Widget> catalog() {
    final query = search.text.trim().toLowerCase();
    final products = marketProducts
        .where(
          (p) =>
              '${p.name} ${p.description}'.toLowerCase().contains(query) &&
              (category == 'Все товары' || p.category == category) &&
              (tab != 1 || store.saved.contains(p.id)),
        )
        .toList();
    if (cheapestFirst) products.sort((a, b) => a.price.compareTo(b.price));
    return [
      Surface(
        color: const Color(0xFFE9F2E9),
        padding: 22,
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.bedtime_outlined, size: 30, color: C.green),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сон и восстановление',
                  style: tx(22, weight: FontWeight.w600),
                ),
                Text(
                  'Небольшая подборка для первого знакомства',
                  style: tx(12, color: C.muted),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Surface(
        padding: 18,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('market-search'),
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Название товара или задача',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in [
                    'Все товары',
                    'Устройства',
                    'Аксессуары',
                  ])
                    ChoiceChip(
                      label: Text(value),
                      selected: category == value,
                      onSelected: (_) => setState(() => category = value),
                    ),
                  FilterChip(
                    label: const Text('Сначала дешевле'),
                    selected: cheapestFirst,
                    onSelected: (v) => setState(() => cheapestFirst = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Найдено: ${products.length} · все предложения демонстрационные',
        style: tx(12, color: C.muted),
      ),
      const SizedBox(height: 16),
      if (products.isEmpty)
        DiscoveryEmpty(
          'Товары не найдены',
          'Измените запрос или вернитесь ко всему каталогу.',
          'Сбросить фильтры',
          reset,
        )
      else
        DiscoveryGrid(children: products.map(productCard).toList()),
      const SizedBox(height: 22),
      Text(
        'Подборка по теме сна. Это не медицинская рекомендация и не оценка того, подходит ли вам товар.',
        style: tx(12, color: C.muted),
      ),
    ];
  }

  Widget visual(MarketProduct product) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            'assets/market/${product.id}-v1.png',
            fit: BoxFit.contain,
            semanticLabel: '${product.name} · ИИ-иллюстрация демо-товара',
          ),
        ),
      ),
    ),
  );

  Widget productCard(MarketProduct product) => Surface(
    padding: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        visual(product),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(product.category, style: tx(12, color: C.green)),
            ),
            IconButton(
              key: ValueKey('market-save-${product.id}'),
              tooltip: store.saved.contains(product.id)
                  ? 'Убрать товар из сохранённых'
                  : 'Сохранить товар',
              onPressed: () => store.toggleSaved(product.id),
              icon: Icon(
                store.saved.contains(product.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: C.green,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 58,
          child: Text(
            product.name,
            style: tx(22, weight: FontWeight.w600, height: 1.25),
          ),
        ),
        Text(product.variant, style: tx(13, color: C.muted)),
        const SizedBox(height: 18),
        Text(
          'от ${discoveryMoney(product.price)}',
          style: tx(23, weight: FontWeight.w600),
        ),
        Text(
          '${product.offers.length} предложения · разные условия',
          style: tx(12, color: C.muted),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Выбрать предложение',
          () => open(product),
          key: ValueKey('market-open-${product.id}'),
        ),
      ],
    ),
  );

  Widget detail(MarketProduct product) {
    final offer = selectedOffer!;
    final quantity = store.cart
        .where((l) => l.offer.id == offer.id)
        .fold(0, (sum, l) => sum + l.quantity);
    return DiscoveryLayout(
      id: 'market-detail-${product.id}',
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 8,
          children: [
            TextButton.icon(
              key: const ValueKey('market-back'),
              onPressed: () => setState(() => selected = null),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('К каталогу'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('market-to-cart'),
              onPressed: () => showTab(2),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text('Корзина (${store.quantity})'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DiscoveryHeading(
          'MONTAS MARKET · ${product.category.toUpperCase()}',
          product.name,
          product.description,
        ),
        DiscoveryColumns(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    visual(product),
                    const SizedBox(height: 20),
                    Text(product.name, style: tx(26, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(product.variant, style: tx(15)),
                    const SizedBox(height: 16),
                    Text(product.facts, style: tx(14, color: C.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Предложения продавцов',
                      style: tx(22, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Один вариант товара. Цена, срок получения и условия зависят от продавца.',
                      style: tx(13, color: C.muted),
                    ),
                    const SizedBox(height: 18),
                    for (final option in product.offers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton(
                          key: ValueKey('market-offer-${option.id}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(18),
                            backgroundColor: option == offer
                                ? C.soft
                                : Colors.white,
                            side: BorderSide(
                              color: option == offer ? C.green : C.line,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () =>
                              setState(() => selectedOffer = option),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                option == offer
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: C.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.seller,
                                      style: tx(16, weight: FontWeight.w600),
                                    ),
                                    Text(
                                      discoveryMoney(option.price),
                                      style: tx(22, weight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Получение: ${option.delivery}\n${option.warranty}\n${option.returns}',
                                      style: tx(13, color: C.muted),
                                    ),
                                  ],
                                ),
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
          aside: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Tag('Выбранное предложение', green: true),
                const SizedBox(height: 18),
                Text(
                  discoveryMoney(offer.price),
                  style: tx(30, weight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(offer.seller, style: tx(16, weight: FontWeight.w600)),
                Text(product.variant, style: tx(13, color: C.muted)),
                discoveryFact(
                  Icons.local_shipping_outlined,
                  'Получение: ${offer.delivery}',
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  quantity >= 5
                      ? 'В корзине максимум: 5'
                      : quantity > 0
                      ? 'Добавить ещё один'
                      : 'В корзину',
                  quantity >= 5
                      ? null
                      : () {
                          if (store.add(product, offer)) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${product.name} добавлен в корзину',
                                ),
                                action: SnackBarAction(
                                  label: 'Открыть',
                                  onPressed: () => showTab(2),
                                ),
                              ),
                            );
                          }
                        },
                  key: const ValueKey('market-add'),
                ),
                if (quantity > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'В корзине от этого продавца: $quantity',
                      style: tx(13, color: C.green),
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => store.toggleSaved(product.id),
                  icon: Icon(
                    store.saved.contains(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(
                    store.saved.contains(product.id)
                        ? 'Сохранено'
                        : 'Сохранить товар',
                  ),
                ),
                const Divider(height: 30),
                Text('Доставка и итог', style: tx(16, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Самовывоз бесплатно или 300 ₽ за доставку от каждого продавца. Выбор — при оформлении.',
                  style: tx(13, color: C.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Тестовая покупка. Оплата не подключена.',
                  style: tx(12, color: C.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget totals(int subtotal, int shipping) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text('Товары', style: tx(14))),
          Text(discoveryMoney(subtotal), style: tx(14)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: Text('Получение', style: tx(14))),
          Text(discoveryMoney(shipping), style: tx(14)),
        ],
      ),
      const Divider(height: 28),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 14,
        children: [
          Text('Итого', style: tx(21, weight: FontWeight.w600)),
          Text(
            discoveryMoney(subtotal + shipping),
            style: tx(23, weight: FontWeight.w600),
          ),
        ],
      ),
    ],
  );

  Widget cart() {
    if (store.cart.isEmpty) {
      return DiscoveryEmpty(
        'В корзине пока пусто',
        'Выберите товар и подходящее предложение продавца.',
        'Открыть каталог',
        () => showTab(0),
      );
    }
    return DiscoveryColumns(
      main: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in store.cart)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Surface(
                key: ValueKey('cart-line-${line.id}'),
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      line.offer.seller,
                      style: tx(12, weight: FontWeight.w600, color: C.green),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      line.product.name,
                      style: tx(22, weight: FontWeight.w600),
                    ),
                    Text(line.product.variant, style: tx(13, color: C.muted)),
                    const SizedBox(height: 8),
                    Text(
                      'Получение: ${line.offer.delivery}\n${discoveryMoney(line.offer.price)} за единицу',
                      style: tx(13, color: C.muted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 18,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: ValueKey('cart-minus-${line.id}'),
                              tooltip: 'Уменьшить количество',
                              onPressed: line.quantity <= 1
                                  ? null
                                  : () => store.setQuantity(
                                      line.id,
                                      line.quantity - 1,
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${line.quantity}',
                              style: tx(17, weight: FontWeight.w600),
                            ),
                            IconButton(
                              key: ValueKey('cart-plus-${line.id}'),
                              tooltip: 'Увеличить количество',
                              onPressed: line.quantity >= 5
                                  ? null
                                  : () => store.setQuantity(
                                      line.id,
                                      line.quantity + 1,
                                    ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        Text(
                          discoveryMoney(line.total),
                          style: tx(21, weight: FontWeight.w600),
                        ),
                        TextButton(
                          key: ValueKey('cart-remove-${line.id}'),
                          onPressed: () => store.remove(line.id),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: () => showTab(0),
            child: const Text('Продолжить покупки'),
          ),
        ],
      ),
      aside: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ваш заказ', style: tx(24, weight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(
              'Единиц: ${store.quantity}\nПродавцов: ${store.cart.map((l) => l.offer.seller).toSet().length}',
              style: tx(14, color: C.muted),
            ),
            const SizedBox(height: 18),
            Text(
              discoveryMoney(store.subtotal),
              style: tx(30, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Сумма товаров. Самовывоз бесплатно; доставка рассчитывается на следующем шаге.',
              style: tx(13, color: C.muted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              'Оформить демо-заказ',
              checkout,
              key: const ValueKey('market-checkout'),
            ),
            const SizedBox(height: 12),
            Text(
              'Без оплаты и передачи данных продавцам.',
              style: tx(12, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget orders() {
    if (store.orders.isEmpty) {
      return DiscoveryEmpty(
        'Заказов пока нет',
        'Оформленный демо-заказ появится здесь с составом и условиями получения.',
        'Перейти в каталог',
        () => showTab(0),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final order in store.orders.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Surface(
              key: ValueKey('order-${order.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Tag(
                        order.cancelled ? 'Отменён' : 'Создан · демо',
                        green: !order.cancelled,
                      ),
                      Tag(order.id),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    discoveryMoney(order.quote.total),
                    style: tx(26, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.quote.items
                        .map((l) => '${l.product.name} × ${l.quantity}')
                        .join(' · '),
                    style: tx(15),
                  ),
                  const SizedBox(height: 8),
                  Text(order.quote.destination, style: tx(13, color: C.muted)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => orderDetail(order),
                        child: const Text('Состав и условия'),
                      ),
                      if (!order.cancelled)
                        TextButton(
                          key: ValueKey('market-cancel-${order.id}'),
                          onPressed: () => cancelOrder(order),
                          child: const Text('Отменить заказ'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
