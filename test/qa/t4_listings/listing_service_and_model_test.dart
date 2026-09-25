import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/services/listing_service.dart';

Listing listing({
  String id = 'listing-1',
  String title = 'Resepsiyonist',
  DateTime? createdAt,
  bool isBoosted = false,
  DateTime? boostExpiresAt,
}) => Listing(
  id: id,
  posterId: 'employer-1',
  posterName: 'Otel',
  posterVerified: true,
  isUrgent: true,
  title: title,
  description: 'Açıklama',
  category: 'resepsiyon',
  location: 'Antalya',
  salary: '35.000 TL',
  city: 'Antalya',
  region: 'Akdeniz',
  lat: 36.8841,
  lng: 30.7056,
  minSalaryTl: 35000,
  maxSalaryTl: 40000,
  employmentType: EmploymentType.fullTime,
  experienceLevel: ExperienceLevel.oneToThreeYears.name,
  educationLevel: EducationLevel.highSchool.name,
  season: 'yaz_2025',
  contactInfo: '0532 111 22 33',
  images: const ['https://example.com/listing.jpg'],
  housingImages: const ['https://example.com/room.jpg'],
  status: ListingStatus.active,
  createdAt: createdAt,
  isBoosted: isBoosted,
  boostExpiresAt: boostExpiresAt,
  viewCount: 7,
  messageCount: 2,
);

Map<String, dynamic> listingDocument({
  required DateTime createdAt,
  String id = 'listing-1',
  String title = 'Resepsiyonist',
  String status = 'active',
  bool isBoosted = false,
  DateTime? boostExpiresAt,
  int? minSalaryTl = 35000,
  int? maxSalaryTl = 40000,
}) => {
  'posterId': 'employer-1',
  'posterName': 'Otel',
  'title': title,
  'description': 'Açıklama',
  'category': 'resepsiyon',
  'location': 'Antalya',
  'city': 'Antalya',
  'region': 'Akdeniz',
  'salary': '35.000 TL',
  'minSalaryTl': minSalaryTl,
  'maxSalaryTl': maxSalaryTl,
  'employmentType': 'fullTime',
  'contactInfo': '0532 111 22 33',
  'status': status,
  'createdAt': Timestamp.fromDate(createdAt),
  'isBoosted': isBoosted,
  'boostExpiresAt': boostExpiresAt == null
      ? null
      : Timestamp.fromDate(boostExpiresAt),
};

void main() {
  group('Listing model public behavior', () {
    test('fromDoc applies safe defaults and preserves Arabic/RTL text', () {
      final db = FakeFirebaseFirestore();

      return db
          .collection('listings')
          .doc('rtl')
          .set({
            'title': 'موظف استقبال',
            'description': 'مطلوب للعمل في فندق',
            'location': 'أنطاليا',
            'category': 'unknown-category',
            'status': 'unknown-status',
            'imageUrls': ['https://example.com/legacy.jpg'],
            'lat': 36.5,
            'lng': 30,
            'minSalaryTl': 0,
            'maxSalaryTl': 999999,
          })
          .then((_) async {
            final doc = await db.collection('listings').doc('rtl').get();
            final parsed = Listing.fromDoc(doc);

            expect(parsed.title, 'موظف استقبال');
            expect(parsed.description, 'مطلوب للعمل في فندق');
            expect(parsed.location, 'أنطاليا');
            expect(parsed.category, 'unknown-category');
            expect(parsed.status, ListingStatus.active);
            expect(parsed.images, ['https://example.com/legacy.jpg']);
            expect(parsed.lat, 36.5);
            expect(parsed.lng, 30.0);
            expect(parsed.minSalaryTl, 0);
            expect(parsed.maxSalaryTl, 999999);
            expect(parsed.contactInfo, isEmpty);
          });
    });

    test('toMap keeps listing state but never exposes contactInfo', () {
      final map = listing().toMap();

      expect(map['posterVerified'], isTrue);
      expect(map['isUrgent'], isTrue);
      expect(map['lat'], 36.8841);
      expect(map['lng'], 30.7056);
      expect(map['minSalaryTl'], 35000);
      expect(map['employmentType'], 'fullTime');
      expect(map['images'], ['https://example.com/listing.jpg']);
      expect(map['housingImages'], ['https://example.com/room.jpg']);
      expect(map.containsKey('contactInfo'), isFalse);
    });

    test('fromDoc falls back to imageUrls when images is absent', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('listings').doc('legacy').set({
        'imageUrls': ['a.jpg', 'b.jpg'],
      });

      final parsed = Listing.fromDoc(
        await db.collection('listings').doc('legacy').get(),
      );

      expect(parsed.images, ['a.jpg', 'b.jpg']);
    });

    test(
      'tolerates malformed scalar types without dropping a valid listing',
      () async {
        final db = FakeFirebaseFirestore();
        await db.collection('listings').doc('good').set({
          ...listingDocument(createdAt: DateTime(2026, 1, 2), id: 'good'),
          'housingMealsIncluded': '2',
          'lat': '36.5',
          'lng': 30,
          'minSalaryTl': '35000',
          'posterVerified': 'true',
          'images': [1, 'good.jpg'],
        });
        await db.collection('listings').doc('bad').set({
          ...listingDocument(createdAt: DateTime(2025, 12, 31), id: 'bad'),
          'housingMealsIncluded': true,
          'lat': true,
          'images': [1],
        });

        final results = await ListingService(db).watchActiveListings().first;

        expect(results.map((item) => item.id), contains('good'));
        final parsedGood = results.singleWhere((item) => item.id == 'good');
        expect(parsedGood.housingMealsIncluded, 2);
        expect(parsedGood.lat, 36.5);
        expect(parsedGood.minSalaryTl, 35000);
        expect(parsedGood.posterVerified, isTrue);
        expect(parsedGood.images, ['good.jpg']);
      },
    );

    test(
      'malformed image data is ignored instead of crashing listing parsing',
      () async {
        final db = FakeFirebaseFirestore();
        await db.collection('listings').doc('bad-images').set({
          'images': [1, 2],
        });
        final doc = await db.collection('listings').doc('bad-images').get();

        expect(() => Listing.fromDoc(doc), returnsNormally);
      },
      skip:
          'BUG-t4-001: Listing.fromDoc casts malformed image entries to String',
    );
  });

  group('ListingService', () {
    late FakeFirebaseFirestore db;
    late ListingService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = ListingService(db);
    });

    test(
      'createListingWithId stores contact only in the private subdocument',
      () async {
        await service.createListingWithId('created', listing(id: 'created'));

        final publicDoc = await db.collection('listings').doc('created').get();
        final contactDoc = await db
            .collection('listings')
            .doc('created')
            .collection('private')
            .doc('contact')
            .get();

        expect(publicDoc.data()!.containsKey('contactInfo'), isFalse);
        expect(publicDoc.data()!['isUrgent'], isTrue);
        expect(publicDoc.data()!['lat'], 36.8841);
        expect(contactDoc.data()!['value'], '0532 111 22 33');
      },
    );

    test('increments a non-owner view only once per service session', () async {
      await db.collection('listings').doc('viewed').set({
        ...listingDocument(createdAt: DateTime(2026, 2, 1), id: 'viewed'),
        'viewCount': 4,
      });

      await service.incrementViewCountIfNeeded(
        listingId: 'viewed',
        ownerId: 'employer-1',
        viewerId: 'employer-1',
      );
      await service.incrementViewCountIfNeeded(
        listingId: 'viewed',
        ownerId: 'employer-1',
        viewerId: 'seeker-1',
      );
      await service.incrementViewCountIfNeeded(
        listingId: 'viewed',
        ownerId: 'employer-1',
        viewerId: 'seeker-1',
      );

      final saved = await db.collection('listings').doc('viewed').get();
      expect(saved.data()!['viewCount'], 5);
    });

    test(
      'updateListing preserves createdAt, removes legacy contact, and updates contact subdoc',
      () async {
        final originalCreatedAt = DateTime(2026, 1, 2, 3, 4);
        await db.collection('listings').doc('edited').set({
          ...listingDocument(createdAt: originalCreatedAt, id: 'edited'),
          'createdAt': Timestamp.fromDate(originalCreatedAt),
          'contactInfo': 'legacy public contact',
        });

        await service.updateListing(
          listing(id: 'edited', createdAt: originalCreatedAt),
        );

        final publicData = (await db.collection('listings').doc('edited').get())
            .data()!;
        final contactData =
            (await db
                    .collection('listings')
                    .doc('edited')
                    .collection('private')
                    .doc('contact')
                    .get())
                .data()!;

        expect(
          (publicData['createdAt'] as Timestamp).toDate(),
          originalCreatedAt,
        );
        expect(publicData.containsKey('contactInfo'), isFalse);
        expect(contactData['value'], '0532 111 22 33');
      },
    );

    test(
      'getListing returns null for an unknown id and merges private contact',
      () async {
        await db
            .collection('listings')
            .doc('known')
            .set(listingDocument(createdAt: DateTime(2026, 2, 1), id: 'known'));
        await db
            .collection('listings')
            .doc('known')
            .collection('private')
            .doc('contact')
            .set({'value': 'contact loaded after sign-in'});

        final known = await service.getListing('known');
        final missing = await service.getListing('missing');

        expect(known, isNotNull);
        expect(known!.contactInfo, 'contact loaded after sign-in');
        expect(missing, isNull);
      },
    );

    test(
      'active stream excludes closed and removed listings and ranks live boosts first',
      () async {
        final now = DateTime.now();
        await db
            .collection('listings')
            .doc('normal')
            .set(
              listingDocument(createdAt: now, id: 'normal', title: 'Normal'),
            );
        await db
            .collection('listings')
            .doc('live-boost')
            .set(
              listingDocument(
                createdAt: now.subtract(const Duration(days: 1)),
                id: 'live-boost',
                title: 'Boost',
                isBoosted: true,
                boostExpiresAt: now.add(const Duration(days: 1)),
              ),
            );
        await db
            .collection('listings')
            .doc('expired-boost')
            .set(
              listingDocument(
                createdAt: now.add(const Duration(minutes: 1)),
                id: 'expired-boost',
                title: 'Expired',
                isBoosted: true,
                boostExpiresAt: now.subtract(const Duration(minutes: 1)),
              ),
            );
        await db
            .collection('listings')
            .doc('closed')
            .set(
              listingDocument(
                createdAt: now.add(const Duration(minutes: 2)),
                id: 'closed',
                status: 'closed',
              ),
            );

        final results = await service.watchActiveListings().first;

        expect(results.map((item) => item.id), [
          'live-boost',
          'expired-boost',
          'normal',
        ]);
        expect(results.any((item) => item.id == 'closed'), isFalse);
      },
    );

    test(
      'pagination reports no next page at the exact limit and a next page above it',
      () async {
        final createdAt = DateTime(2026, 3, 1);
        for (var i = 0; i < 3; i++) {
          await db
              .collection('listings')
              .doc('page-$i')
              .set(
                listingDocument(
                  createdAt: createdAt.subtract(Duration(days: i)),
                  id: 'page-$i',
                  title: 'Page $i',
                ),
              );
        }

        final exact = await service.getPaginatedListings(limit: 3);
        final partial = await service.getPaginatedListings(limit: 2);

        expect(exact.listings, hasLength(3));
        expect(exact.hasMore, isFalse);
        expect(exact.lastDocument, isNotNull);
        expect(partial.listings, hasLength(2));
        expect(partial.hasMore, isTrue);
      },
    );

    test(
      'salary filters include boundary values and exclude null salary ranges',
      () async {
        final createdAt = DateTime(2026, 4, 1);
        await db
            .collection('listings')
            .doc('boundary')
            .set(
              listingDocument(
                createdAt: createdAt,
                id: 'boundary',
                minSalaryTl: 35000,
                maxSalaryTl: 40000,
              ),
            );
        await db
            .collection('listings')
            .doc('no-salary')
            .set(
              listingDocument(
                createdAt: createdAt.subtract(const Duration(days: 1)),
                id: 'no-salary',
                minSalaryTl: null,
                maxSalaryTl: null,
              ),
            );

        final result = await service.getPaginatedListings(
          minSalaryTl: 40000,
          maxSalaryTl: 35000,
        );

        expect(result.listings.map((item) => item.id), ['boundary']);
      },
    );

    test(
      'admin title search matches a trimmed prefix and empty input returns no results',
      () async {
        await db.collection('listings').doc('admin-1').set({
          ...listingDocument(createdAt: DateTime(2026, 5, 1), id: 'admin-1'),
          'title': 'Ön Büro Resepsiyonisti',
        });

        final prefix = await service.searchListingsForAdmin('  Ön  ');
        final empty = await service.searchListingsForAdmin('   ');

        expect(prefix.map((item) => item.id), ['admin-1']);
        expect(empty, isEmpty);
      },
    );

    test(
      'Turkish dotted-I search is case-insensitive for listing locations',
      () async {
        await db
            .collection('listings')
            .doc('istanbul')
            .set(
              listingDocument(
                createdAt: DateTime(2026, 6, 1),
                id: 'istanbul',
                title: 'Garson',
              )..['location'] = 'İstanbul',
            );

        final result = await service.getPaginatedListings(
          searchQuery: 'istanbul',
        );

        expect(result.listings.map((item) => item.id), ['istanbul']);
      },
      skip:
          'BUG-t4-002: Dart lower-case matching does not normalize Turkish dotted-I',
    );

    test(
      'zero page size does not advertise a phantom next page',
      () async {
        await db
            .collection('listings')
            .doc('one')
            .set(listingDocument(createdAt: DateTime(2026, 7, 1), id: 'one'));

        final result = await service.getPaginatedListings(limit: 0);

        expect(result.listings, isEmpty);
        expect(result.hasMore, isFalse);
      },
      skip:
          'BUG-t4-003: limit zero yields hasMore=true when any document exists',
    );
  });
}
