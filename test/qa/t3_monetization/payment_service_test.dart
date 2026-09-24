import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/services/payment_service.dart';

import 't3_helpers.dart';

void main() {
  setUpAll(registerT3Fallbacks);

  final boost7 = makeProduct('boost_7_days', price: '₺49,99');
  final boost14 = makeProduct('boost_14_days', price: '₺89,99');

  group('PaymentService initialisation', () {
    test('null InAppPurchase (web) stays unavailable and exposes an empty stream', () async {
      final service = PaymentService(null);
      await pumpEventQueue();
      expect(service.isAvailable, isFalse);
      expect(await service.purchaseStream.isEmpty, isTrue);
      expect(await service.purchaseProduct(boost7), isNull);
      service.dispose();
    });

    test('isAvailable() throwing leaves the store unavailable instead of crashing', () async {
      final iap = MockInAppPurchase();
      when(() => iap.isAvailable()).thenThrow(Exception('billing service disconnected'));
      final service = PaymentService(iap);
      await pumpEventQueue();
      expect(service.isAvailable, isFalse);
      expect(service.isLoading, isFalse);
      service.dispose();
    });

    test('available store queries exactly the four known product ids', () async {
      final h = IapHarness(products: [boost7, boost14]);
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      final ids = verify(() => h.iap.queryProductDetails(captureAny())).captured.single as Set<String>;
      expect(ids, {'boost_7_days', 'boost_14_days', 'boost_30_days', 'urgent_listing'});
      expect(service.products.map((p) => p.id), ['boost_7_days', 'boost_14_days']);
      service.dispose();
      await h.dispose();
    });
  });

  group('PaymentService.fetchProducts', () {
    test('partial result (notFoundIDs) keeps the products that were found', () async {
      final h = IapHarness(products: [boost7], notFound: {'boost_30_days', 'urgent_listing'});
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      expect(service.getProductById('boost_7_days'), same(boost7));
      expect(service.getProductById('boost_30_days'), isNull);
      expect(service.isLoading, isFalse);
      service.dispose();
      await h.dispose();
    });

    test('response.error clears products and resets isLoading', () async {
      final h = IapHarness(products: [boost7]);
      when(() => h.iap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [boost7],
          notFoundIDs: const [],
          error: IAPError(source: 'google_play', code: 'x', message: 'boom'),
        ),
      );
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      expect(service.products, isEmpty);
      expect(service.isLoading, isFalse);
      service.dispose();
      await h.dispose();
    });

    test('query throwing clears products and still resets isLoading', () async {
      final h = IapHarness(products: [boost7]);
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      expect(service.products, hasLength(1));

      when(() => h.iap.queryProductDetails(any())).thenThrow(Exception('network'));
      await service.fetchProducts();
      expect(service.products, isEmpty);
      expect(service.isLoading, isFalse);
      service.dispose();
      await h.dispose();
    });

    test('isLoading is true while the query is in flight and listeners are notified', () async {
      final h = IapHarness();
      final gate = Completer<ProductDetailsResponse>();
      when(() => h.iap.queryProductDetails(any())).thenAnswer((_) => gate.future);
      final service = PaymentService(h.iap);
      var notifications = 0;
      service.addListener(() => notifications++);
      await pumpEventQueue();
      expect(service.isLoading, isTrue);

      gate.complete(ProductDetailsResponse(productDetails: [boost14], notFoundIDs: const []));
      await pumpEventQueue();
      expect(service.isLoading, isFalse);
      expect(service.products, [boost14]);
      expect(notifications, greaterThanOrEqualTo(2));
      service.dispose();
      await h.dispose();
    });

    test('fetchProducts on an unavailable store is a no-op', () async {
      final h = IapHarness(available: false);
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      await service.fetchProducts();
      verifyNever(() => h.iap.queryProductDetails(any()));
      service.dispose();
      await h.dispose();
    });
  });

  group('PaymentService.purchaseProduct', () {
    late IapHarness h;
    late PaymentService service;

    setUp(() async {
      h = IapHarness(products: [boost7, boost14]);
      service = PaymentService(h.iap);
      await pumpEventQueue();
    });

    tearDown(() async {
      service.dispose();
      await h.dispose();
    });

    test('returns the purchased details for the requested product', () async {
      final purchased = makePurchase('boost_14_days', PurchaseStatus.purchased);
      h.answerBuyWith(purchased);
      expect(await service.purchaseProduct(boost14), same(purchased));
    });

    test('ignores events for other products and waits for its own', () async {
      final other = makePurchase('boost_7_days', PurchaseStatus.purchased, purchaseId: 'OTHER');
      final mine = makePurchase('boost_14_days', PurchaseStatus.purchased, purchaseId: 'MINE');
      when(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async {
        scheduleMicrotask(() => h.controller.add([other, mine]));
        return true;
      });
      final result = await service.purchaseProduct(boost14);
      expect(result?.purchaseID, 'MINE');
    });

    test('pending then purchased resolves to the purchased event', () async {
      when(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async {
        scheduleMicrotask(() {
          h.controller.add([makePurchase('boost_14_days', PurchaseStatus.pending)]);
          h.controller.add([makePurchase('boost_14_days', PurchaseStatus.purchased, purchaseId: 'OK')]);
        });
        return true;
      });
      expect((await service.purchaseProduct(boost14))?.purchaseID, 'OK');
    });

    test('user cancellation resolves to null', () async {
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.canceled));
      expect(await service.purchaseProduct(boost14), isNull);
    });

    test('store error resolves to null', () async {
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.error));
      expect(await service.purchaseProduct(boost14), isNull);
    });

    test('store refusing to send the request resolves to null without waiting', () async {
      h.answerBuyWith(null, requestSent: false);
      expect(await service.purchaseProduct(boost14), isNull);
    });

    test('buyNonConsumable throwing resolves to null and cancels its stream subscription', () async {
      final perCall = StreamController<List<PurchaseDetails>>();
      var cancelled = false;
      perCall.onCancel = () => cancelled = true;
      when(() => h.iap.purchaseStream).thenAnswer((_) => perCall.stream);
      when(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenThrow(Exception('BillingResponse.itemAlreadyOwned'));

      expect(await service.purchaseProduct(boost14), isNull);
      expect(cancelled, isTrue);
      await perCall.close();
    });

    test('unavailable store never starts a purchase', () async {
      final off = IapHarness(available: false);
      final offService = PaymentService(off.iap);
      await pumpEventQueue();
      expect(await offService.purchaseProduct(boost14), isNull);
      verifyNever(() => off.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
      offService.dispose();
      await off.dispose();
    });

    test('boost / urgent products are bought as consumables so they can be bought again', () async {
      when(() => h.iap.buyConsumable(
            purchaseParam: any(named: 'purchaseParam'),
            autoConsume: any(named: 'autoConsume'),
          )).thenAnswer((_) async {
        scheduleMicrotask(() => h.controller.add([makePurchase('boost_14_days', PurchaseStatus.purchased)]));
        return true;
      });
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));

      await service.purchaseProduct(boost14);

      verifyNever(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    }, skip: bug('BUG-t3-03: purchaseProduct uses buyNonConsumable for consumable boost/urgent products and never consumes -> 2nd purchase blocked with "already owned" on Android'));
  });

  group('PaymentService background purchase listener', () {
    test('successful purchase is NOT acknowledged before the backend verified it', () async {
      final h = IapHarness(products: [boost14]);
      final service = PaymentService(h.iap);
      await pumpEventQueue();

      h.controller.add([makePurchase('boost_14_days', PurchaseStatus.purchased, pendingComplete: true)]);
      await pumpEventQueue();

      // completePurchase acknowledges the payment to the store. Doing it
      // before verifyAndProcessBoostPurchase succeeded means a server-side
      // rejection leaves the user charged with nothing to show for it and
      // no automatic refund.
      verifyNever(() => h.iap.completePurchase(any()));
      service.dispose();
      await h.dispose();
    }, skip: bug('BUG-t3-04: _onPurchaseUpdate calls completePurchase immediately, before server verification'));

    test('purchased and restored events are recorded, pending/error are not', () async {
      final h = IapHarness(products: [boost14]);
      final service = PaymentService(h.iap);
      await pumpEventQueue();

      h.controller.add([
        makePurchase('boost_14_days', PurchaseStatus.pending),
        makePurchase('boost_14_days', PurchaseStatus.error),
        makePurchase('boost_14_days', PurchaseStatus.purchased, purchaseId: 'P'),
        makePurchase('boost_7_days', PurchaseStatus.restored, purchaseId: 'R'),
      ]);
      await pumpEventQueue();

      expect(service.purchases.map((p) => p.purchaseID), ['P', 'R']);
      service.dispose();
      await h.dispose();
    });

    test('events arriving after dispose do not throw "used after dispose"', () async {
      final h = IapHarness(products: [boost14]);
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      service.dispose();

      h.controller.add([makePurchase('boost_14_days', PurchaseStatus.purchased)]);
      await pumpEventQueue();
      expect(service.purchases, isEmpty);
      await h.dispose();
    });
  });

  group('PaymentService.restorePurchases', () {
    test('exception is swallowed and isLoading resets', () async {
      final h = IapHarness();
      when(() => h.iap.restorePurchases()).thenThrow(Exception('no network'));
      final service = PaymentService(h.iap);
      await pumpEventQueue();
      await service.restorePurchases();
      expect(service.isLoading, isFalse);
      service.dispose();
      await h.dispose();
    });
  });

  testWidgets('purchaseProduct gives up with null after 5 minutes without a store callback', (tester) async {
    final h = IapHarness(products: [boost14]);
    h.answerBuyWith(null); // request sent, store never answers
    final service = PaymentService(h.iap);
    await tester.pump();

    PurchaseDetails? result = makePurchase('sentinel', PurchaseStatus.pending);
    var done = false;
    unawaited(service.purchaseProduct(boost14).then((r) {
      result = r;
      done = true;
    }));

    await tester.pump(const Duration(minutes: 4, seconds: 59));
    expect(done, isFalse);
    await tester.pump(const Duration(seconds: 2));
    // subscription.cancel() on a broadcast stream completes on the root
    // zone, outside the fake clock; let the real event loop turn once.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(done, isTrue);
    expect(result, isNull);

    service.dispose();
    await h.dispose();
  });
}
