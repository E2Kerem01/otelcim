import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/boosts/presentation/boost_purchase_screen.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/payment_service.dart';

import 't3_helpers.dart';

const _buyButton = 'Satın Al ve Öne Çıkar';
const _successText = 'Tebrikler! İlanınız başarıyla öne çıkarıldı.';
const _cancelledText = 'Satın alma işlemi tamamlanamadı veya iptal edildi.';

void main() {
  setUpAll(registerT3Fallbacks);

  late IapHarness h;
  late RecordingBoostService boost;

  final storeProducts = [
    makeProduct('boost_7_days', price: '₺59,99'),
    makeProduct('boost_14_days', price: '₺99,99'),
    makeProduct('boost_30_days', price: '₺159,99'),
  ];

  setUp(() {
    h = IapHarness(products: storeProducts);
    boost = RecordingBoostService();
  });

  tearDown(() => h.dispose());

  void verifyNoStorePurchase(IapHarness store) {
    verifyNever(() => store.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
  }

  ElevatedButton buyButton(WidgetTester tester) => tester.widget<ElevatedButton>(find.ancestor(
        of: find.text(_buyButton),
        matching: find.byType(ElevatedButton),
      ));

  /// Pumps the launcher, opens the boost screen for listing `l1` and settles.
  Future<void> openScreen(
    WidgetTester tester, {
    Listing? listing,
    String? uid = 'owner',
    int freeBoostCredits = 0,
    IapHarness? iap,
    Locale locale = const Locale('tr'),
  }) async {
    useTallViewport(tester);
    final store = iap ?? h;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentServiceProvider.overrideWith((ref) => PaymentService(store.iap)),
          boostServiceProvider.overrideWithValue(boost),
          authServiceProvider.overrideWith((ref) => buildAuthService(uid: uid)),
          listingServiceProvider.overrideWithValue(
            FakeListingService(listings: {'l1': ?listing}),
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              uid == null ? null : makeProfile(id: uid, freeBoostCredits: freeBoostCredits),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: localizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Launcher(screen: BoostPurchaseScreen(listingId: 'l1')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapBuy(WidgetTester tester) async {
    await tester.tap(find.text(_buyButton));
    await settleStore(tester);
  }

  group('BoostPurchaseScreen — rendering', () {
    testWidgets('unknown listing id shows "İlan bulunamadı."', (tester) async {
      await openScreen(tester, listing: null);
      expect(find.text('İlan bulunamadı.'), findsOneWidget);
      expect(find.text(_buyButton), findsNothing);
    });

    testWidgets('store prices replace the hardcoded fallbacks when products load', (tester) async {
      await openScreen(tester, listing: makeListing());
      expect(find.text('₺59,99'), findsOneWidget);
      expect(find.text('₺99,99'), findsOneWidget);
      expect(find.text('₺159,99'), findsOneWidget);
      expect(find.text('₺49,99'), findsNothing);
    });

    testWidgets('hardcoded fallback prices are shown when the store returns no products', (tester) async {
      final empty = IapHarness(products: const []);
      addTearDown(empty.dispose);
      await openScreen(tester, listing: makeListing(), iap: empty);
      expect(find.text('₺49,99'), findsOneWidget);
      expect(find.text('₺89,99'), findsOneWidget);
      expect(find.text('₺149,99'), findsOneWidget);
    });

    testWidgets('already boosted listing shows the compact badge and its current end date', (tester) async {
      final expiry = DateTime.now().add(const Duration(days: 25));
      await openScreen(tester, listing: makeListing(isBoosted: true, boostExpiresAt: expiry));
      expect(find.text('Öne Çıkan'), findsOneWidget);
      expect(
        find.text('Bu ilan zaten öne çıkarılmıştır. Bitiş: ${expiry.day}.${expiry.month}.${expiry.year}'),
        findsOneWidget,
      );
    });

    testWidgets('boost whose expiry passed is not presented as still boosted', (tester) async {
      await openScreen(
        tester,
        listing: makeListing(
          isBoosted: true,
          boostExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      expect(find.textContaining('zaten öne çıkarılmıştır'), findsNothing);
      expect(find.text('Öne Çıkan'), findsNothing);
    });

    testWidgets('[BUG-t3-07] extending an active boost warns that the new package replaces the remaining time',
        (tester) async {
      // verifyAndProcessBoostPurchase sets expiresAt = now + package, so
      // buying 7 days on a boost with 25 days left SHORTENS it to 7 days
      // (PLAN t1). The screen shows the old end date and happily sells.
      await openScreen(
        tester,
        listing: makeListing(isBoosted: true, boostExpiresAt: DateTime.now().add(const Duration(days: 25))),
      );
      expect(find.textContaining('kalan süre'), findsOneWidget);
    }, skip: widgetBug('BUG-t3-07: buying on an active boost silently replaces (can shorten) the remaining time'));

    testWidgets('Arabic / RTL locale lays the screen out without overflow errors', (tester) async {
      await openScreen(tester, listing: makeListing(title: 'موظف استقبال'), locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(find.text('موظف استقبال'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(_buyButton))), TextDirection.rtl);
    });
  });

  group('BoostPurchaseScreen — paid purchase flow', () {
    testWidgets('signed-out user gets a login prompt and no purchase starts', (tester) async {
      await openScreen(tester, listing: makeListing(), uid: null);
      await tapBuy(tester);
      expect(find.text('Lütfen önce giriş yapın.'), findsOneWidget);
      verifyNoStorePurchase(h);
      expect(boost.processCalls, isEmpty);
    });

    testWidgets('default 14-day package: store receipt is forwarded to the server, then success + pop',
        (tester) async {
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(boost.processCalls, hasLength(1));
      final args = boost.processCalls.single;
      expect(args['listingId'], 'l1');
      expect(args['userId'], 'owner');
      expect(args['productId'], 'boost_14_days');
      expect(args['transactionId'], 'GPA.1234');
      expect(args['purchaseToken'], 'server-receipt-token');
      expect(args['verificationData'], isNull);
      expect(args['platform'], 'google_play');

      expect(find.text(_successText), findsOneWidget);
      expect(find.text('open'), findsOneWidget, reason: 'screen pops back to the launcher');
    });

    testWidgets('selecting the 30-day package buys and verifies boost_30_days', (tester) async {
      h.answerBuyWith(makePurchase('boost_30_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tester.tap(find.text('30 Günlük Öne Çıkarma'));
      await tester.pump();
      await tapBuy(tester);

      final param = verify(() => h.iap.buyNonConsumable(purchaseParam: captureAny(named: 'purchaseParam')))
          .captured
          .single as PurchaseParam;
      expect(param.productDetails.id, 'boost_30_days');
      expect(boost.processCalls.single['productId'], 'boost_30_days');
    });

    testWidgets('store cancellation shows the cancel message and never calls the server', (tester) async {
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.canceled));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(find.text(_cancelledText), findsOneWidget);
      expect(buyButton(tester).onPressed, isNotNull, reason: 'stays on the screen, button re-enabled');
      expect(boost.processCalls, isEmpty);
    });

    testWidgets('server rejection keeps the user on the screen with the button re-enabled', (tester) async {
      boost.processError = Exception('Bu satın alma zaten işlenmiş.');
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(find.text(_successText), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(buyButton(tester).onPressed, isNotNull);
    });

    testWidgets('[BUG-t3-05] server rejection message reaches the user (they have already been charged)',
        (tester) async {
      boost.processError = Exception('Bu satın alma zaten işlenmiş.');
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      // BoostService wraps the Cloud Function's error in a plain Exception;
      // mapToFailure turns every plain Exception into the generic
      // "Bir şeyler ters gitti" text, so the real reason is lost.
      expect(find.textContaining('zaten işlenmiş'), findsOneWidget);
    }, skip: widgetBug('BUG-t3-05: server error text replaced by generic "Bir şeyler ters gitti" after charge'));

    testWidgets('a second tap while the store sheet is open does not start a second purchase', (tester) async {
      // Request accepted, but the store has not answered yet.
      when(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async => true);
      await openScreen(tester, listing: makeListing());

      await tester.tap(find.text(_buyButton));
      await tester.pump();
      expect(find.text(_buyButton), findsNothing, reason: 'button shows a spinner while processing');
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pump();

      verify(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam'))).called(1);

      h.controller.add([makePurchase('boost_14_days', PurchaseStatus.purchased)]);
      await settleStore(tester);
      expect(boost.processCalls, hasLength(1));
    });

    testWidgets('debug build with no store fakes a purchase and sends a fabricated tx id with no receipt',
        (tester) async {
      // kDebugMode is true under `flutter test`, so this is the branch that
      // runs; it documents that debug builds call the paid Cloud Function
      // with `tx_<millis>` and no purchaseToken (the server rejects it).
      final off = IapHarness(available: false);
      addTearDown(off.dispose);
      await openScreen(tester, listing: makeListing(), iap: off);

      await tester.tap(find.text(_buyButton));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final args = boost.processCalls.single;
      expect(args['transactionId'] as String, startsWith('tx_'));
      expect(args['purchaseToken'], isNull);
      expect(args['verificationData'], isNull);
      verifyNoStorePurchase(off);
    });

    testWidgets('[BUG-t3-08] priceOverride parses a store price with a thousands separator', (tester) async {
      final pricey = IapHarness(products: [makeProduct('boost_14_days', price: '₺1.299,99')]);
      addTearDown(pricey.dispose);
      pricey.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing(), iap: pricey);

      await tapBuy(tester);

      // "₺1.299,99" -> "1.299.99" -> double.tryParse fails -> 49.99.
      expect(boost.processCalls.single['priceOverride'], 1299.99);
    }, skip: widgetBug('BUG-t3-08: _parsePrice("₺1.299,99") yields 49.99; value is also ignored by the server'));

    testWidgets("[BUG-t3-06] purchase is refused before payment when the listing is not the user's",
        (tester) async {
      // Route /listing/:id/boost has no ownership check and the screen does
      // not compare listing.posterId with the user: the store charges first,
      // then the Cloud Function rejects with permission-denied.
      h.answerBuyWith(makePurchase('boost_14_days', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing(posterId: 'someone-else'), uid: 'owner');

      await tapBuy(tester);

      verifyNoStorePurchase(h);
    }, skip: widgetBug("BUG-t3-06: boost screen charges the user for someone else's listing"));
  });

  group('BoostPurchaseScreen — free referral boost', () {
    testWidgets('0 credits: the free boost block is not shown', (tester) async {
      await openScreen(tester, listing: makeListing(), freeBoostCredits: 0);
      expect(find.text('Ücretsiz Kullan'), findsNothing);
    });

    testWidgets('2 credits: banner shows the count and redeeming calls redeemFreeBoost then pops', (tester) async {
      await openScreen(tester, listing: makeListing(), freeBoostCredits: 2);
      expect(find.text('2 ücretsiz boost hakkınız var'), findsOneWidget);

      await tester.tap(find.text('Ücretsiz Kullan'));
      await tester.pumpAndSettle();

      expect(boost.redeemCalls, [
        {'listingId': 'l1', 'userId': 'owner'},
      ]);
      verifyNoStorePurchase(h);
      expect(find.text('Ücretsiz boost uygulandı!'), findsOneWidget);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('redeem failure shows an error and keeps the user on the screen', (tester) async {
      boost.redeemError = Exception('Ücretsiz boost hakkınız kalmadı.');
      await openScreen(tester, listing: makeListing(), freeBoostCredits: 1);

      await tester.tap(find.text('Ücretsiz Kullan'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Ücretsiz boost uygulandı!'), findsNothing);
      expect(find.text('Ücretsiz Kullan'), findsOneWidget);
    });

    testWidgets('[BUG-t3-09] paid purchase button is disabled while a free boost is being redeemed',
        (tester) async {
      boost.redeemGate = Completer<void>();
      await openScreen(tester, listing: makeListing(), freeBoostCredits: 1);

      await tester.tap(find.text('Ücretsiz Kullan'));
      await tester.pump();
      expect(buyButton(tester).onPressed, isNull);

      boost.redeemGate!.complete();
      await tester.pumpAndSettle();
    }, skip: widgetBug('BUG-t3-09: paid "Satın Al" stays enabled while a free boost is being redeemed'));
  });
}
