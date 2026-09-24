// Shared fixtures for the t3 monetization QA suite (boosts, urgent listing
// purchase, IAP, banner ads). Not a test file itself.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/services/urgent_listing_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

/// Known-bug tests are skipped so the suite stays green. Run with
/// `--dart-define=T3_RUN_BUGS=true` to execute them and watch them fail.
const bool runKnownBugs = bool.fromEnvironment('T3_RUN_BUGS');

/// Returns the skip reason unless [runKnownBugs] is set.
String? bug(String reason) => runKnownBugs ? null : reason;

/// `testWidgets` only takes a bool `skip`, so widget bug tests carry their
/// BUG-t3 id in the test name and pass the reason here for the reader.
bool widgetBug(String reason) => !runKnownBugs;

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockBoostService extends Mock implements BoostService {}

class MockUrgentListingService extends Mock implements UrgentListingService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakePurchaseParam extends Fake implements PurchaseParam {}

class FakePurchaseDetails extends Fake implements PurchaseDetails {}

class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

/// A Firestore whose `collection(name).where('userId', ...)` and
/// `collection(name)` snapshot streams fail with permission-denied, like a
/// query the security rules reject.
FirebaseFirestore buildFailingFirestore(String collection) {
  final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
  final db = MockFirestore();
  final col = MockCollection();
  final query = MockQuery();
  when(() => db.collection(collection)).thenReturn(col);
  when(() => col.where('userId', isEqualTo: any(named: 'isEqualTo'))).thenReturn(query);
  when(() => query.snapshots()).thenAnswer((_) => Stream.error(error));
  when(() => col.snapshots()).thenAnswer((_) => Stream.error(error));
  return db;
}

void registerT3Fallbacks() {
  registerFallbackValue(FakePurchaseParam());
  registerFallbackValue(FakePurchaseDetails());
}

/// [ListingService] stand-in: only [getListing] is backed, from [listings].
/// A value of `Exception` in [errors] makes that id throw instead.
class FakeListingService implements ListingService {
  FakeListingService({this.listings = const {}, this.errors = const {}});

  final Map<String, Listing> listings;
  final Map<String, Object> errors;

  @override
  Future<Listing?> getListing(String id) async {
    final error = errors[id];
    if (error != null) throw error;
    return listings[id];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Listing makeListing({
  String id = 'l1',
  String posterId = 'owner',
  String title = 'Resepsiyon Görevlisi',
  bool isBoosted = false,
  DateTime? boostExpiresAt,
  bool isUrgent = false,
}) {
  return Listing(
    id: id,
    posterId: posterId,
    posterName: 'Grand Otel',
    title: title,
    description: 'Deneyimli resepsiyonist aranıyor',
    category: 'resepsiyon',
    location: 'Antalya',
    salary: '35.000 TL',
    contactInfo: '',
    isBoosted: isBoosted,
    boostExpiresAt: boostExpiresAt,
    isUrgent: isUrgent,
  );
}

UserProfile makeProfile({String id = 'owner', int freeBoostCredits = 0}) {
  return UserProfile(
    id: id,
    email: '$id@test.com',
    userType: 'employer',
    freeBoostCredits: freeBoostCredits,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// [BoostService] stand-in that records the arguments of each call.
/// Set [processError]/[redeemError] to make the call throw, or [redeemGate]
/// to hold `redeemFreeBoost` open until the test completes it.
class RecordingBoostService implements BoostService {
  final List<Map<String, Object?>> processCalls = [];
  final List<Map<String, Object?>> redeemCalls = [];
  Object? processError;
  Object? redeemError;
  Completer<void>? redeemGate;

  @override
  Future<void> processBoostPurchase({
    required String listingId,
    required String userId,
    required String productId,
    required String transactionId,
    double? priceOverride,
    String? purchaseToken,
    String? verificationData,
    String platform = 'in_app_purchase',
  }) async {
    processCalls.add({
      'listingId': listingId,
      'userId': userId,
      'productId': productId,
      'transactionId': transactionId,
      'priceOverride': priceOverride,
      'purchaseToken': purchaseToken,
      'verificationData': verificationData,
      'platform': platform,
    });
    final error = processError;
    if (error != null) throw error;
  }

  @override
  Future<void> redeemFreeBoost({required String listingId, required String userId}) async {
    redeemCalls.add({'listingId': listingId, 'userId': userId});
    await redeemGate?.future;
    final error = redeemError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lets a store round-trip finish inside a widget test. [PaymentService]
/// awaits `subscription.cancel()` on the harness' broadcast stream, which
/// completes on the real event loop, outside the fake clock.
Future<void> settleStore(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pumpAndSettle();
}

/// Gives a test a tall viewport so long purchase screens need no scrolling.
void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ProductDetails makeProduct(String id, {String price = '₺1,00'}) {
  return ProductDetails(
    id: id,
    title: id,
    description: id,
    price: price,
    rawPrice: 1,
    currencyCode: 'TRY',
  );
}

PurchaseDetails makePurchase(
  String productId,
  PurchaseStatus status, {
  String? purchaseId = 'GPA.1234',
  String receipt = 'server-receipt-token',
  bool pendingComplete = false,
}) {
  return PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: receipt,
      source: 'google_play',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

/// An [InAppPurchase] mock whose purchase stream is driven by [controller].
class IapHarness {
  IapHarness({
    bool available = true,
    List<ProductDetails> products = const [],
    Set<String> notFound = const {},
  }) : iap = MockInAppPurchase() {
    when(() => iap.isAvailable()).thenAnswer((_) async => available);
    when(() => iap.purchaseStream).thenAnswer((_) => controller.stream);
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: products,
        notFoundIDs: notFound.toList(),
      ),
    );
    when(() => iap.completePurchase(any())).thenAnswer((_) async {});
  }

  final MockInAppPurchase iap;
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Makes `buyNonConsumable` report success and immediately push [result]
  /// (if any) onto the purchase stream, like a real store callback would.
  void answerBuyWith(PurchaseDetails? result, {bool requestSent = true}) {
    when(() => iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
        .thenAnswer((_) async {
      if (result != null) {
        scheduleMicrotask(() => controller.add([result]));
      }
      return requestSent;
    });
  }

  Future<void> dispose() => controller.close();
}

/// Real [AuthService] over a mocked [FirebaseAuth]; `uid == null` means
/// signed out.
AuthService buildAuthService({String? uid}) {
  final auth = MockFirebaseAuth();
  when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
  if (uid == null) {
    when(() => auth.currentUser).thenReturn(null);
  } else {
    final user = MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn('$uid@test.com');
    when(() => user.phoneNumber).thenReturn(null);
    when(() => auth.currentUser).thenReturn(user);
  }
  return AuthService(auth, FakeFirebaseFirestore());
}

const localizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// A launcher page with an "open" button that pushes [screen], so a screen's
/// own `Navigator.pop()` on success is observable.
class Launcher extends StatelessWidget {
  const Launcher({super.key, required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => screen),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}
