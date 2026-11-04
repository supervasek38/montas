import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:montas_prototype/main.dart';
import 'widget_test.dart' show tapVisible;

Finder k(String id) => find.byKey(ValueKey(id));

Future<void> start(WidgetTester t, int page, double width) async {
  t.view.physicalSize = Size(width, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MontasApp(initialPage: page));
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Onest',
    )..addFont(rootBundle.load('assets/Onest.ttf'))).load();
  });

  test(
    'Registration prevents duplicates, restores capacity and keeps history',
    () {
      final store = EventsStore();
      final event = montasEvents.first;
      final ticket = event.tickets[1];
      expect(store.remaining(event, ticket), 24);
      expect(store.register(event, montasEvents[1].tickets.first), isNull);
      final registration = store.register(event, ticket)!;
      expect(store.remaining(event, ticket), 23);
      expect(store.register(event, event.tickets.last), isNull);
      expect(store.cancel(registration), isTrue);
      expect(store.cancel(registration), isFalse);
      expect(store.remaining(event, ticket), 24);
      expect(store.active(event.id), isNull);
      expect(store.register(event, event.tickets.last)!.id, 'EV-002');
      expect(store.registrations.first.ticket.price, 8900);
      expect(store.registrations.first.cancelled, isTrue);
      store.dispose();
    },
  );

  test(
    'Cart separates sellers, caps quantity and calculates shipping per seller',
    () {
      final store = MarketplaceStore();
      final ring = marketProducts.first;
      final mask = marketProducts.last;
      expect(store.add(ring, mask.offers.first), isFalse);
      store.add(ring, ring.offers.first);
      store.add(ring, ring.offers.last);
      store.add(mask, mask.offers.first);
      expect(store.cart.length, 3);
      expect(store.setQuantity(ring.offers.first.id, 0), isFalse);
      expect(store.setQuantity(ring.offers.first.id, 6), isFalse);
      store.setQuantity(ring.offers.first.id, 5);
      expect(store.add(ring, ring.offers.first), isFalse);
      final quote = store.quote(MarketDelivery.courier);
      expect(quote.shipping, 600);
      expect(quote.total, 24900 * 5 + 25900 + 2990 + 600);
      expect(store.quote(MarketDelivery.pickup).shipping, 0);
      store.remove(ring.offers.first.id);
      expect(store.quote(MarketDelivery.courier).shipping, 300);
      store.dispose();
    },
  );

  test(
    'Checkout rejects stale/foreign/reused quotes and keeps an immutable snapshot',
    () {
      final store = MarketplaceStore();
      final other = MarketplaceStore();
      final ring = marketProducts.first;
      store.add(ring, ring.offers.first);
      final stale = store.quote(MarketDelivery.pickup);
      store.add(ring, ring.offers.first);
      expect(store.checkout(stale), isNull);
      final quote = store.quote(MarketDelivery.courier);
      expect(other.checkout(quote), isNull);
      final order = store.checkout(quote)!;
      expect(store.checkout(quote), isNull);
      expect(store.cart, isEmpty);
      store.add(ring, ring.offers.last);
      expect(order.quote.total, 50100);
      expect(order.quote.items.single.quantity, 2);
      expect(order.quote.items.single.offer.seller, 'TechCare · демо');
      expect(() => order.quote.items.clear(), throwsUnsupportedError);
      expect(store.cancel(order), isTrue);
      expect(store.cancel(order), isFalse);
      expect(store.cart.single.offer, ring.offers.last);
      store.dispose();
      other.dispose();
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Events registration, selection and cancellation at $width', (
      t,
    ) async {
      await start(t, 12, width);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('event-open-sleep-lab'));
      await tapVisible(t, k('event-register'));
      await tapVisible(t, k('event-ticket-live'));
      await tapVisible(t, k('event-continue'));
      expect(t.widget<PrimaryButton>(k('event-confirm')).onPressed, isNull);
      await tapVisible(t, k('event-consent'));
      await tapVisible(t, k('event-confirm'));
      final state = t.state<EventsScreenState>(find.byType(EventsScreen));
      expect(state.store.active('sleep-lab')!.ticket.id, 'live');
      expect(find.text('Вы записаны · демо'), findsOneWidget);
      await tapVisible(t, k('event-cancel'));
      await tapVisible(t, find.text('Сохранить участие'));
      expect(state.store.active('sleep-lab'), isNotNull);
      await tapVisible(t, k('event-cancel'));
      await tapVisible(t, k('event-cancel-confirm'));
      expect(state.store.active('sleep-lab'), isNull);
      await tapVisible(t, k('event-back'));
      await tapVisible(t, k('events-tab-2'));
      expect(find.text('Отменено'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('Marketplace seller, cart and checkout at $width', (t) async {
      await start(t, 13, width);
      expect(t.takeException(), isNull);
      await tapVisible(t, k('market-open-ring'));
      await tapVisible(t, k('market-offer-ring-home'));
      await tapVisible(t, k('market-add'));
      await tapVisible(t, k('market-to-cart'));
      final state = t.state<MarketplaceScreenState>(
        find.byType(MarketplaceScreen),
      );
      expect(state.store.cart.single.offer.price, 25900);
      await tapVisible(t, k('cart-plus-ring-home'));
      await tapVisible(t, k('market-checkout'));
      await tapVisible(t, k('market-delivery-courier'));
      expect(find.text('52 100 ₽'), findsOneWidget);
      expect(t.widget<PrimaryButton>(k('market-confirm')).onPressed, isNull);
      await tapVisible(t, k('market-consent'));
      await tapVisible(t, k('market-confirm'));
      expect(find.text('Заказ MK-001'), findsOneWidget);
      expect(state.store.cart, isEmpty);
      expect(state.store.orders.single.quote.total, 52100);
      await tapVisible(t, k('market-order-close'));
      await tapVisible(t, k('market-cancel-MK-001'));
      await tapVisible(t, k('market-cancel-confirm'));
      expect(state.store.orders.single.cancelled, isTrue);
      expect(find.text('Отменён'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Filters, saved items and cancelled drafts preserve state', (
    t,
  ) async {
    await start(t, 12, 1440);
    await t.enterText(k('events-search'), 'нет такого события');
    await t.pumpAndSettle();
    expect(find.text('Подходящих событий нет'), findsOneWidget);
    await tapVisible(t, find.text('Сбросить фильтры'));
    await tapVisible(t, k('event-save-analysis'));
    await tapVisible(t, k('events-tab-1'));
    expect(k('event-open-analysis'), findsOneWidget);
    expect(k('event-open-sleep-lab'), findsNothing);
    await tapVisible(t, k('event-open-analysis'));
    await tapVisible(t, k('event-register'));
    await tapVisible(t, k('event-continue'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    expect(
      t.state<EventsScreenState>(find.byType(EventsScreen)).store.registrations,
      isEmpty,
    );
    await tapVisible(t, k('nav-13'));
    await t.enterText(k('market-search'), 'нет такого товара');
    await t.pumpAndSettle();
    expect(find.text('Товары не найдены'), findsOneWidget);
    await tapVisible(t, find.text('Сбросить фильтры'));
    await tapVisible(t, k('market-save-mask'));
    await tapVisible(t, k('market-tab-1'));
    expect(k('market-open-ring'), findsNothing);
    await tapVisible(t, k('market-open-mask'));
    await tapVisible(t, k('market-add'));
    await tapVisible(t, k('market-to-cart'));
    await tapVisible(t, k('market-checkout'));
    await tapVisible(t, find.byTooltip('Закрыть'));
    final state = t.state<MarketplaceScreenState>(
      find.byType(MarketplaceScreen),
    );
    expect(state.store.cart.single.product.id, 'mask');
    expect(state.store.orders, isEmpty);
    await tapVisible(t, k('cart-remove-mask-home'));
    expect(find.text('В корзине пока пусто'), findsOneWidget);
    await tapVisible(t, k('nav-12'));
    expect(find.text('Разбор анализов без тревоги'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Both modules reachable from mobile all-sections menu', (
    t,
  ) async {
    await start(t, 0, 390);
    await tapVisible(t, find.byTooltip('Все разделы'));
    await tapVisible(t, find.text('Мероприятия').last);
    expect(find.text('События и встречи'), findsOneWidget);
    await tapVisible(t, find.byTooltip('Все разделы'));
    await tapVisible(t, find.text('Маркетплейс').last);
    expect(find.text('MONTAS MARKET'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
