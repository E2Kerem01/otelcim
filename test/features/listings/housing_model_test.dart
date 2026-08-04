import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';

void main() {
  test(
    'housing fields round-trip and legacy listings remain compatible',
    () async {
      final db = FakeFirebaseFirestore();
      const listing = Listing(
        id: 'housing',
        posterId: 'poster',
        posterName: 'Hotel',
        title: 'Job',
        description: 'Description',
        category: 'service',
        location: 'Bodrum',
        salary: '40000',
        contactInfo: 'contact',
        housingRoomType: 'shared',
        housingHasAc: true,
        housingHasWifi: true,
        housingMealsIncluded: 3,
        housingImages: ['https://example.com/housing.jpg'],
      );
      await db.collection('listings').doc('housing').set(listing.toMap());
      final parsed = Listing.fromDoc(
        await db.collection('listings').doc('housing').get(),
      );
      expect(parsed.housingRoomType, 'shared');
      expect(parsed.housingHasAc, isTrue);
      expect(parsed.housingHasWifi, isTrue);
      expect(parsed.housingMealsIncluded, 3);
      expect(parsed.housingImages, hasLength(1));

      await db.collection('listings').doc('legacy').set({'title': 'Legacy'});
      final legacy = Listing.fromDoc(
        await db.collection('listings').doc('legacy').get(),
      );
      expect(legacy.housingRoomType, isNull);
      expect(legacy.housingImages, isEmpty);
    },
  );
}
