import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/discovery/domain/tourism_region.dart';
import 'package:otelcim/features/discovery/domain/region_map_data.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/services/listing_service.dart';

void main() {
  test('tourism taxonomy contains ten stable unique region ids', () {
    expect(tourismRegions, hasLength(10));
    expect(tourismRegions.map((region) => region.id).toSet(), hasLength(10));
    expect(tourismRegionById('bodrum')?.nameTr, 'Bodrum');
    expect(tourismRegionById('unknown'), isNull);
    expect(
      tourismRegions.every(
        (region) => region.latitude >= 35 && region.latitude <= 43,
      ),
      isTrue,
    );
    expect(
      tourismRegions.every(
        (region) => region.longitude >= 25 && region.longitude <= 45,
      ),
      isTrue,
    );
  });

  test('map counts only listings assigned to known tourism regions', () {
    Listing listing(String id, String? region) => Listing(
      id: id,
      posterId: 'poster',
      posterName: 'Hotel',
      title: 'Job',
      description: 'Description',
      category: 'service',
      location: 'Turkey',
      salary: '40000',
      region: region,
      contactInfo: 'contact',
    );

    final counts = countRegionListings([
      listing('a', 'antalya'),
      listing('b', 'antalya'),
      listing('c', 'unknown'),
      listing('d', null),
    ]);

    expect(counts, hasLength(10));
    expect(counts['antalya'], 2);
    expect(counts.containsKey('unknown'), isFalse);
    expect(regionMarkerDiameter(0), 44);
    expect(regionMarkerDiameter(100), 72);
  });

  test(
    'Listing serializes region and legacy documents remain null-safe',
    () async {
      final db = FakeFirebaseFirestore();
      const listing = Listing(
        id: 'listing',
        posterId: 'poster',
        posterName: 'Otel',
        title: 'Resepsiyonist',
        description: 'Açıklama',
        category: 'resepsiyon',
        location: 'Muğla / Bodrum',
        salary: '40.000 TL',
        region: 'bodrum',
        contactInfo: 'contact',
      );
      await db.collection('listings').doc('listing').set(listing.toMap());
      expect(
        Listing.fromDoc(
          await db.collection('listings').doc('listing').get(),
        ).region,
        'bodrum',
      );

      await db.collection('listings').doc('legacy').set({'title': 'Eski ilan'});
      expect(
        Listing.fromDoc(
          await db.collection('listings').doc('legacy').get(),
        ).region,
        isNull,
      );
    },
  );

  test('paginated listings can be filtered by region', () async {
    final db = FakeFirebaseFirestore();
    final now = Timestamp.now();
    for (final entry in [('a', 'antalya'), ('b', 'bodrum')]) {
      await db.collection('listings').doc(entry.$1).set({
        'title': entry.$1,
        'region': entry.$2,
        'status': 'active',
        'createdAt': now,
      });
    }

    final result = await ListingService(
      db,
    ).getPaginatedListings(region: 'bodrum');
    expect(result.listings.map((listing) => listing.id), ['b']);
  });
}
