import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/boosts/presentation/my_boosts_screen.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

import 't3_helpers.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  /// Seeds a boost_purchases doc in the shape verifyAndProcessBoostPurchase
  /// writes (functions/src/index.ts:620-633).
  Future<void> seedPurchase({
    required String id,
    String userId = 'owner',
    String listingId = 'l1',
    String durationType = '14',
    num price = 89.99,
    DateTime? purchasedAt,
    String platform = 'google_play',
  }) {
    return db.collection('boost_purchases').doc(id).set({
      'userId': userId,
      'listingId': listingId,
      'boostId': 'b_$id',
      'durationType': durationType,
      'price': price,
      'platform': platform,
      'transactionId': 'GPA.$id',
      'productId': 'boost_${durationType}_days',
      'status': 'completed',
      'purchasedAt': purchasedAt == null ? null : Timestamp.fromDate(purchasedAt),
      'verifiedAt': null,
    });
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? uid = 'owner',
    Map<String, Listing> listings = const {},
    Map<String, Object> listingErrors = const {},
    BoostService? service,
    Locale locale = const Locale('tr'),
    bool settle = true,
  }) async {
    useTallViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(uid == null ? null : AppUser(uid: uid, email: '$uid@test.com')),
          ),
          boostServiceProvider.overrideWithValue(service ?? BoostService(db)),
          listingServiceProvider.overrideWithValue(
            FakeListingService(listings: listings, errors: listingErrors),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: localizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MyBoostsScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(seconds: 2));
    }
  }

  final activeListing = makeListing(
    title: 'Aktif Resepsiyon',
    isBoosted: true,
    boostExpiresAt: DateTime.now().add(const Duration(days: 10)),
  );

  testWidgets('signed-out user sees a login prompt', (tester) async {
    await pumpScreen(tester, uid: null);
    expect(find.text('Lütfen giriş yapın.'), findsOneWidget);
  });

  testWidgets('user without purchases sees the empty state and a CTA', (tester) async {
    await seedPurchase(id: 'someone-elses', userId: 'other', purchasedAt: DateTime(2026, 9, 1));
    await pumpScreen(tester);
    expect(find.text('Henüz Öne Çıkarılmış İlanınız Yok'), findsOneWidget);
    expect(find.text('İlanlarıma Git ve Öne Çıkar'), findsOneWidget);
  });

  testWidgets('active boost card: package, price, "Aktif", end date and "Süreyi Uzat"', (tester) async {
    await seedPurchase(id: 'p1', purchasedAt: DateTime(2026, 9, 20));
    await pumpScreen(tester, listings: {'l1': activeListing});

    final end = activeListing.boostExpiresAt!;
    expect(find.text('14 Günlük Paket'), findsOneWidget);
    expect(find.text('₺89.99'), findsOneWidget);
    expect(find.text('Aktif Resepsiyon'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Satın Alma Tarihi: 20.9.2026'), findsOneWidget);
    expect(find.text('Bitiş Tarihi: ${end.day}.${end.month}.${end.year}'), findsOneWidget);
    expect(find.text('Süreyi Uzat'), findsOneWidget);
  });

  testWidgets('expired boost card: "Süresi Doldu", no end date, "Tekrar Öne Çıkar"', (tester) async {
    await seedPurchase(id: 'p1', durationType: '7', price: 49.99, purchasedAt: DateTime(2026, 8, 1));
    await pumpScreen(tester, listings: {
      'l1': makeListing(isBoosted: true, boostExpiresAt: DateTime.now().subtract(const Duration(hours: 1))),
    });

    expect(find.text('7 Günlük Paket'), findsOneWidget);
    expect(find.text('Süresi Doldu'), findsOneWidget);
    expect(find.textContaining('Bitiş Tarihi'), findsNothing);
    expect(find.text('Tekrar Öne Çıkar'), findsOneWidget);
  });

  testWidgets('purchase for a deleted listing still renders, with a "silinmiş" note', (tester) async {
    await seedPurchase(id: 'p1', listingId: 'gone', purchasedAt: DateTime(2026, 9, 1));
    await pumpScreen(tester);
    expect(find.text('İlan silinmiş veya bulunamadı.'), findsOneWidget);
    expect(find.text('14 Günlük Paket'), findsOneWidget);
  });

  testWidgets('listing lookup error shows "İlan bilgisi alınamadı." on that card only', (tester) async {
    await seedPurchase(id: 'p1', listingId: 'broken', purchasedAt: DateTime(2026, 9, 2));
    await seedPurchase(id: 'p2', listingId: 'l1', purchasedAt: DateTime(2026, 9, 1));
    await pumpScreen(
      tester,
      listings: {'l1': activeListing},
      listingErrors: {'broken': Exception('unavailable')},
    );
    expect(find.text('İlan bilgisi alınamadı.'), findsOneWidget);
    expect(find.text('Aktif Resepsiyon'), findsOneWidget);
  });

  testWidgets('cards are newest first; a pending serverTimestamp (null date) shows "-" and sinks last',
      (tester) async {
    await seedPurchase(id: 'old', durationType: '7', purchasedAt: DateTime(2026, 7, 1));
    await seedPurchase(id: 'pending', durationType: '30', purchasedAt: null);
    await seedPurchase(id: 'new', durationType: '14', purchasedAt: DateTime(2026, 9, 1));
    await pumpScreen(tester, listings: {'l1': activeListing});

    final packages = tester
        .widgetList<Text>(find.textContaining('Günlük Paket'))
        .map((t) => t.data)
        .toList();
    expect(packages, ['14 Günlük Paket', '7 Günlük Paket', '30 Günlük Paket']);
    expect(find.text('Satın Alma Tarihi: -'), findsOneWidget);
  });

  testWidgets('[BUG-t3-11] only the purchase that is actually running is marked "Aktif"', (tester) async {
    // Status is derived from the LISTING's current boost, not from the
    // purchase, so a 7-day package bought two months ago is shown as
    // "Aktif" with today's end date just because a newer boost exists.
    await seedPurchase(
      id: 'old',
      durationType: '7',
      purchasedAt: DateTime.now().subtract(const Duration(days: 60)),
    );
    await seedPurchase(id: 'new', durationType: '14', purchasedAt: DateTime.now());
    await pumpScreen(tester, listings: {'l1': activeListing});

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Süresi Doldu'), findsOneWidget);
  }, skip: widgetBug('BUG-t3-11: every purchase of a currently boosted listing shows "Aktif" + current end date'));

  testWidgets('[BUG-t3-13] prices use Turkish formatting and a free referral boost is labelled as free',
      (tester) async {
    await seedPurchase(id: 'paid', purchasedAt: DateTime(2026, 9, 2));
    await seedPurchase(
      id: 'ref',
      durationType: '7',
      price: 0,
      platform: 'referral_reward',
      purchasedAt: DateTime(2026, 9, 1),
    );
    await pumpScreen(tester, listings: {'l1': activeListing});

    // Purchase screen shows "₺89,99"; this list shows "₺89.99" and "₺0.00".
    expect(find.text('₺89,99'), findsOneWidget);
    expect(find.text('₺0.00'), findsNothing);
  }, skip: widgetBug('BUG-t3-13: "₺89.99" / "₺0.00" hardcoded en-US formatting; referral boost shown as a ₺0.00 sale'));

  testWidgets('[BUG-t3-14] a failing purchases query shows an error instead of spinning forever',
      (tester) async {
    await pumpScreen(
      tester,
      service: BoostService(buildFailingFirestore('boost_purchases')),
      settle: false,
    );
    // BoostService.watchUserBoostPurchases uses `.handleError((e) { return
    // <BoostPurchase>[]; })`; the return value is ignored, so the stream
    // neither errors nor emits and the screen never leaves "loading".
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Hata'), findsOneWidget);
  }, skip: widgetBug('BUG-t3-14: .handleError swallows the error -> stream never emits -> infinite spinner'));

  testWidgets('Arabic / RTL: a card renders without layout exceptions', (tester) async {
    await seedPurchase(id: 'p1', purchasedAt: DateTime(2026, 9, 20));
    await pumpScreen(
      tester,
      listings: {
        'l1': makeListing(
          title: 'مطلوب موظف استقبال بخبرة في الفنادق الكبرى',
          isBoosted: true,
          boostExpiresAt: DateTime.now().add(const Duration(days: 3)),
        ),
      },
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Aktif'), findsOneWidget);
  });
}
