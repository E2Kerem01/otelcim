import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/services/listing_service.dart';

void main() {
  group('Batch Listing Creation Tests (Spec 018)', () {
    late FakeFirebaseFirestore db;
    late ListingService listingService;

    setUp(() {
      db = FakeFirebaseFirestore();
      listingService = ListingService(db);
    });

    test('createBatchListings creates multiple listing documents atomically', () async {
      final sharedHotelName = 'Granada Luxury Hotel';
      final sharedLocation = 'Antalya, Belek';
      final sharedCity = 'Antalya';
      final sharedContact = '0242 123 4567';
      final sharedImages = ['https://example.com/hotel1.jpg', 'https://example.com/hotel2.jpg'];
      final posterId = 'employer_123';

      final listingsToCreate = [
        Listing(
          id: '',
          posterId: posterId,
          posterName: sharedHotelName,
          title: 'Resepsiyon Görevlisi',
          description: 'İngilizce ve Rusça bilen resepsiyonist aranıyor.',
          category: 'resepsiyon',
          location: sharedLocation,
          salary: '35.000 TL / Ay',
          city: sharedCity,
          minSalaryTl: 35000,
          maxSalaryTl: 35000,
          employmentType: EmploymentType.fullTime,
          contactInfo: sharedContact,
          images: sharedImages,
        ),
        Listing(
          id: '',
          posterId: posterId,
          posterName: sharedHotelName,
          title: 'Garson',
          description: 'A la carte restoranda çalışacak tecrübeli garson.',
          category: 'servis',
          location: sharedLocation,
          salary: '30.000 TL / Ay + Tip',
          city: sharedCity,
          minSalaryTl: 30000,
          maxSalaryTl: 30000,
          employmentType: EmploymentType.seasonal,
          contactInfo: sharedContact,
          images: sharedImages,
        ),
        Listing(
          id: '',
          posterId: posterId,
          posterName: sharedHotelName,
          title: 'Kat Görevlisi',
          description: 'Oda temizliği ve düzeninden sorumlu kat hizmetleri.',
          category: 'kat_hizmetleri',
          location: sharedLocation,
          salary: '28.000 TL / Ay',
          city: sharedCity,
          minSalaryTl: 28000,
          maxSalaryTl: 28000,
          employmentType: EmploymentType.fullTime,
          contactInfo: sharedContact,
          images: sharedImages,
        ),
      ];

      final createdIds = await listingService.createBatchListings(listingsToCreate);

      expect(createdIds, hasLength(3));

      final snapshot = await db.collection('listings').get();
      expect(snapshot.docs, hasLength(3));

      for (int i = 0; i < createdIds.length; i++) {
        final doc = snapshot.docs.firstWhere((d) => d.id == createdIds[i]);
        final data = doc.data();

        expect(data['posterId'], equals(posterId));
        expect(data['posterName'], equals(sharedHotelName));
        expect(data['location'], equals(sharedLocation));
        expect(data['city'], equals(sharedCity));
        expect(data['images'], equals(sharedImages));
        expect(data['status'], equals('active'));

        // contactInfo is deliberately kept off the publicly-readable listing
        // doc and written to the sign-in-gated private/contact subdoc instead
        // (see ListingService / the contactInfo-privacy migration).
        expect(data.containsKey('contactInfo'), isFalse);
        final contactSnap = await db
            .collection('listings')
            .doc(createdIds[i])
            .collection('private')
            .doc('contact')
            .get();
        expect(contactSnap.data()?['value'], equals(sharedContact));

        final expected = listingsToCreate[i];
        expect(data['title'], equals(expected.title));
        expect(data['category'], equals(expected.category));
        expect(data['salary'], equals(expected.salary));
        expect(data['employmentType'], equals(expected.employmentType?.name));
      }
    });

    test('createBatchListings returns empty list when given empty input', () async {
      final createdIds = await listingService.createBatchListings([]);
      expect(createdIds, isEmpty);

      final snapshot = await db.collection('listings').get();
      expect(snapshot.docs, isEmpty);
    });

    test('listings created in batch appear in watchMyListings and watchActiveListings', () async {
      final posterId = 'emp_456';
      final batchListings = [
        Listing(
          id: '',
          posterId: posterId,
          posterName: 'Bodrum Bay Resort',
          title: 'Aşçı Yardımcısı',
          description: 'Mutfak ekibine katılacak aşçı yardımcısı.',
          category: 'mutfak',
          location: 'Muğla, Bodrum',
          salary: '40.000 TL',
          city: 'Muğla',
          contactInfo: '0532 999 8877',
        ),
        Listing(
          id: '',
          posterId: posterId,
          posterName: 'Bodrum Bay Resort',
          title: 'Cankurtaran',
          description: 'Havuz ve plaj bölgesinde görev alacak cankurtaran.',
          category: 'diger',
          location: 'Muğla, Bodrum',
          salary: '32.000 TL',
          city: 'Muğla',
          contactInfo: '0532 999 8877',
        ),
      ];

      await listingService.createBatchListings(batchListings);

      final myListings = await listingService.watchMyListings(posterId).first;
      expect(myListings, hasLength(2));
      expect(myListings.map((l) => l.title), containsAll(['Aşçı Yardımcısı', 'Cankurtaran']));
    });
  });
}
