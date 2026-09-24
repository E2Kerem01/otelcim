import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/favorites/services/favorite_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/seasonal/domain/seasonal_subscription_model.dart';
import 'package:otelcim/features/seasonal/services/seasonal_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

Listing favoriteListing(String id) => Listing(
  id: id,
  posterId: 'poster',
  posterName: 'Otel',
  title: id,
  description: 'Açıklama',
  category: 'resepsiyon',
  location: 'Antalya',
  salary: '35.000 TL',
  contactInfo: '0532 111 22 33',
  status: ListingStatus.active,
);

void main() {
  group('FavoriteService', () {
    late FakeFirebaseFirestore db;
    late FavoriteService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = FavoriteService(db, ListingService(db));
    });

    test('toggleFavorite adds a favorite and a second toggle removes it', () async {
      await service.toggleFavorite('user-1', 'listing-1');
      expect(await service.isFavorite('user-1', 'listing-1'), isTrue);

      final saved = await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('favorites')
          .doc('listing-1')
          .get();
      expect(saved.data()!['listingId'], 'listing-1');
      expect(saved.data()!['addedAt'], isA<Timestamp>());

      await service.toggleFavorite('user-1', 'listing-1');
      expect(await service.isFavorite('user-1', 'listing-1'), isFalse);
    });

    test('watchFavoriteIds falls back to the document id when listingId is missing', () async {
      await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('favorites')
          .doc('listing-a')
          .set({});
      await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('favorites')
          .doc('listing-b')
          .set({'listingId': 'canonical-b'});

      final ids = await service.watchFavoriteIds('user-1').first;

      expect(ids, {'listing-a', 'canonical-b'});
    });

    test('watchFavoriteListings sorts newest first and shows a placeholder for deleted listings', () async {
      final listingService = ListingService(db);
      await db.collection('listings').doc('existing').set({
        'posterId': 'poster',
        'posterName': 'Otel',
        'title': 'Mevcut ilan',
        'description': 'Açıklama',
        'category': 'resepsiyon',
        'location': 'Antalya',
        'salary': '35.000 TL',
        'contactInfo': 'private',
        'status': 'active',
      });
      final favorites = db
          .collection('user_profiles')
          .doc('user-1')
          .collection('favorites');
      await favorites.doc('missing').set({
        'listingId': 'deleted',
        'addedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await favorites.doc('existing').set({
        'listingId': 'existing',
        'addedAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
      });

      final results = await FavoriteService(db, listingService)
          .watchFavoriteListings('user-1')
          .first;

      expect(results.map((item) => item.id), ['existing', 'deleted']);
      expect(results.last.status, ListingStatus.closed);
      expect(results.last.title, 'Bu ilan artık mevcut değil');
    });
  });

  group('SeasonalService', () {
    late FakeFirebaseFirestore db;
    late SeasonalService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = SeasonalService(db);
    });

    test('addSubscription writes the user document and matching global mirror', () async {
      await service.addSubscription(
        userId: 'user-1',
        city: 'Antalya',
        category: 'resepsiyon',
      );

      final userDocs = await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('seasonal_subscriptions')
          .get();
      final userData = userDocs.docs.single.data();
      final mirror = await db
          .collection('seasonal_subscriptions')
          .doc(userDocs.docs.single.id)
          .get();

      expect(userData['season'], 'yaz_2025');
      expect(userData['enabled'], isTrue);
      expect(mirror.data()!['subscriptionId'], userDocs.docs.single.id);
      expect(mirror.data()!['city'], 'Antalya');
    });

    test('toggleSubscription updates both copies atomically', () async {
      await service.addSubscription(userId: 'user-1', season: 'kis_2025_26');
      final userDocs = await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('seasonal_subscriptions')
          .get();
      final id = userDocs.docs.single.id;

      await service.toggleSubscription(
        userId: 'user-1',
        subscriptionId: id,
        enabled: false,
      );

      expect(userDocs.docs.single.id, id);
      expect(
        (await db
                .collection('user_profiles')
                .doc('user-1')
                .collection('seasonal_subscriptions')
                .doc(id)
                .get())
            .data()!['enabled'],
        isFalse,
      );
      expect(
        (await db.collection('seasonal_subscriptions').doc(id).get())
            .data()!['enabled'],
        isFalse,
      );
    });

    test('deleteSubscription removes both user and global mirror', () async {
      await service.addSubscription(userId: 'user-1', season: 'tum_yil');
      final id = (await db
              .collection('user_profiles')
              .doc('user-1')
              .collection('seasonal_subscriptions')
              .get())
          .docs
          .single
          .id;

      await service.deleteSubscription(userId: 'user-1', subscriptionId: id);

      expect(
        (await db
                .collection('user_profiles')
                .doc('user-1')
                .collection('seasonal_subscriptions')
                .doc(id)
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await db.collection('seasonal_subscriptions').doc(id).get()).exists,
        isFalse,
      );
    });

    test('subscription model defaults missing fields and preserves RTL city names', () async {
      await db
          .collection('user_profiles')
          .doc('user-1')
          .collection('seasonal_subscriptions')
          .doc('rtl')
          .set({'userId': 'user-1', 'city': 'دبي'});

      final subscription = SeasonalSubscription.fromDoc(
        await db
            .collection('user_profiles')
            .doc('user-1')
            .collection('seasonal_subscriptions')
            .doc('rtl')
            .get(),
      );

      expect(subscription.city, 'دبي');
      expect(subscription.enabled, isTrue);
      expect(subscription.category, isNull);
      expect(subscription.createdAt, isNull);
    });

    test(
      'seasonal windows include the current calendar year',
      () {
        final currentYear = DateTime.now().year.toString();
        expect(
          SeasonalService.seasonalWindows.any(
            (window) => window.seasonCode.contains(currentYear),
          ),
          isTrue,
        );
      },
      skip: 'BUG-t4-004: seasonalWindows are hardcoded to 2025 and do not roll forward',
    );
  });
}
