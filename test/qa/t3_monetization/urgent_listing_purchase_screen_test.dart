import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/urgent_listing_purchase_screen.dart';
import 'package:otelcim/features/listings/services/urgent_listing_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/payment_service.dart';

import 't3_helpers.dart';

const _buyButton = 'Satın Al ve Acil Yap';
const _skipButton = 'Şimdilik acil yapmadan devam et';
const _successText = 'İlanınız acil olarak işaretlendi.';

void main() {
  setUpAll(registerT3Fallbacks);

  late IapHarness h;
  late MockUrgentListingService urgent;

  setUp(() {
    h = IapHarness(products: [makeProduct('urgent_listing', price: '₺159,99')]);
    urgent = MockUrgentListingService();
    when(() => urgent.processUrgentListingPurchase(
          listingId: any(named: 'listingId'),
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
          verificationData: any(named: 'verificationData'),
          platform: any(named: 'platform'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => h.dispose());

  void verifyNoServerCall() {
    verifyNever(() => urgent.processUrgentListingPurchase(
          listingId: any(named: 'listingId'),
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
          verificationData: any(named: 'verificationData'),
          platform: any(named: 'platform'),
        ));
  }

  /// [pushed]: open the screen on top of `/` (so it can pop) instead of
  /// deep-linking straight to it (post-create redirect: nothing to pop).
  Future<void> openScreen(
    WidgetTester tester, {
    Listing? listing,
    String? uid = 'owner',
    IapHarness? iap,
    bool pushed = true,
  }) async {
    useTallViewport(tester);
    final store = iap ?? h;
    final router = GoRouter(
      initialLocation: pushed ? '/' : '/urgent/l1',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/urgent/l1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/urgent/:id',
          builder: (_, state) => UrgentListingPurchaseScreen(listingId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/my-listings',
          builder: (_, _) => const Scaffold(body: Text('MY_LISTINGS')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentServiceProvider.overrideWith((ref) => PaymentService(store.iap)),
          urgentListingServiceProvider.overrideWithValue(urgent),
          authServiceProvider.overrideWith((ref) => buildAuthService(uid: uid)),
          listingServiceProvider.overrideWithValue(
            FakeListingService(
              listings: {'l1': ?listing},
              errors: {'broken': Exception('unavailable')},
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('tr'),
          localizationsDelegates: localizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (pushed) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapBuy(WidgetTester tester) async {
    await tester.tap(find.text(_buyButton));
    await settleStore(tester);
  }

  group('UrgentListingPurchaseScreen — rendering', () {
    testWidgets('missing listing shows "İlan bulunamadı."', (tester) async {
      await openScreen(tester, listing: null);
      expect(find.text('İlan bulunamadı.'), findsOneWidget);
      expect(find.text(_buyButton), findsNothing);
    });

    testWidgets('store price is shown when the product loads', (tester) async {
      await openScreen(tester, listing: makeListing());
      expect(find.text('₺159,99'), findsOneWidget);
    });

    testWidgets('fallback price ₺149,99 is shown when the product is missing', (tester) async {
      final noProduct = IapHarness(products: const [], notFound: {'urgent_listing'});
      addTearDown(noProduct.dispose);
      await openScreen(tester, listing: makeListing(), iap: noProduct);
      expect(find.text('₺149,99'), findsOneWidget);
    });

    testWidgets('[BUG-t3-10] listing that is already urgent is not offered for sale again', (tester) async {
      await openScreen(tester, listing: makeListing(isUrgent: true));
      // Expected: an "already urgent" state instead of a buy button.
      expect(find.text(_buyButton), findsNothing);
    }, skip: widgetBug('BUG-t3-10: urgent purchase screen sells urgency for a listing that is already isUrgent'));
  });

  group('UrgentListingPurchaseScreen — purchase flow', () {
    testWidgets('signed-out user is asked to log in; no store call', (tester) async {
      await openScreen(tester, listing: makeListing(), uid: null);
      await tapBuy(tester);
      expect(find.text('Lütfen önce giriş yapın.'), findsOneWidget);
      verifyNever(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    });

    testWidgets('store unavailable: explicit message, no fake debug purchase (unlike boost screen)', (tester) async {
      final off = IapHarness(available: false);
      addTearDown(off.dispose);
      await openScreen(tester, listing: makeListing(), iap: off);

      await tapBuy(tester);

      expect(find.text('Satın alma mağazası şu an kullanılamıyor.'), findsOneWidget);
      verifyNoServerCall();
    });

    testWidgets('store available but urgent_listing product not found: store-unavailable message', (tester) async {
      final noProduct = IapHarness(products: const [], notFound: {'urgent_listing'});
      addTearDown(noProduct.dispose);
      await openScreen(tester, listing: makeListing(), iap: noProduct);

      await tapBuy(tester);

      expect(find.text('Satın alma mağazası şu an kullanılamıyor.'), findsOneWidget);
      verifyNever(() => noProduct.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    });

    testWidgets('user cancels in the store sheet: cancel message and no server call', (tester) async {
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.canceled));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(find.text('Satın alma tamamlanamadı veya iptal edildi.'), findsOneWidget);
      verifyNoServerCall();
      expect(find.text(_buyButton), findsOneWidget);
    });

    testWidgets('success sends the receipt as purchaseToken on Android, shows success and pops', (tester) async {
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.purchased, receipt: 'play-token'));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      verify(() => urgent.processUrgentListingPurchase(
            listingId: 'l1',
            productId: 'urgent_listing',
            purchaseToken: 'play-token',
            verificationData: null,
            platform: 'google_play',
          )).called(1);
      expect(find.text(_successText), findsOneWidget);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('success after a deep link (nothing to pop) lands on /my-listings', (tester) async {
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing(), pushed: false);

      await tapBuy(tester);

      expect(find.text('MY_LISTINGS'), findsOneWidget);
    });

    testWidgets('server rejection: error snackbar, stays on screen, button usable again', (tester) async {
      when(() => urgent.processUrgentListingPurchase(
            listingId: any(named: 'listingId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
            verificationData: any(named: 'verificationData'),
            platform: any(named: 'platform'),
          )).thenThrow(Exception('Bu ilan size ait değil.'));
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(find.text(_successText), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text(_buyButton), matching: find.byType(ElevatedButton)),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('[BUG-t3-05] server rejection reason is shown to the (already charged) user', (tester) async {
      when(() => urgent.processUrgentListingPurchase(
            listingId: any(named: 'listingId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
            verificationData: any(named: 'verificationData'),
            platform: any(named: 'platform'),
          )).thenThrow(Exception('Bu ilan size ait değil.'));
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing());

      await tapBuy(tester);

      expect(find.textContaining('size ait değil'), findsOneWidget);
    }, skip: widgetBug('BUG-t3-05: plain Exception from the service is mapped to the generic message'));

    testWidgets("[BUG-t3-06] another user's listing is refused before the store charges", (tester) async {
      h.answerBuyWith(makePurchase('urgent_listing', PurchaseStatus.purchased));
      await openScreen(tester, listing: makeListing(posterId: 'someone-else'), uid: 'owner');

      await tapBuy(tester);

      verifyNever(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    }, skip: widgetBug('BUG-t3-06: no ownership check before charging'));

    testWidgets('"continue without urgent" skips the purchase and leaves the screen', (tester) async {
      await openScreen(tester, listing: makeListing());
      await tester.tap(find.text(_skipButton));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      verifyNever(() => h.iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    });
  });
}
