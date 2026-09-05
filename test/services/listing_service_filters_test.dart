import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/services/listing_service.dart';

void main() {
  group('ListingService Advanced Filter Tests', () {
    late FakeFirebaseFirestore db;
    late ListingService service;
    final now = DateTime.now();

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = ListingService(db);

      // Seed test listings
      await db.collection('listings').doc('l_antalya').set({
        'posterId': 'u1',
        'posterName': 'Antalya Otel',
        'title': 'Antalya Resepsiyonist',
        'description': 'Açıklama',
        'category': 'resepsiyon',
        'location': 'Antalya / Muratpaşa',
        'city': 'Antalya',
        'salary': '40.000 TL',
        'minSalaryTl': 35000,
        'maxSalaryTl': 45000,
        'employmentType': 'fullTime',
        'contactInfo': '05551112233',
        'status': 'active',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
        'images': ['https://example.com/img1.jpg'],
      });

      await db.collection('listings').doc('l_mugla').set({
        'posterId': 'u2',
        'posterName': 'Bodrum Otel',
        'title': 'Bodrum Aşçı Başı',
        'description': 'Açıklama',
        'category': 'mutfakMutfakEkip',
        'location': 'Muğla / Bodrum',
        'city': 'Muğla',
        'salary': '60.000 TL',
        'minSalaryTl': 55000,
        'maxSalaryTl': 70000,
        'employmentType': 'seasonal',
        'contactInfo': '05552223344',
        'status': 'active',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      });

      await db.collection('listings').doc('l_istanbul_old').set({
        'posterId': 'u3',
        'posterName': 'İstanbul Otel',
        'title': 'İstanbul Garson',
        'description': 'Açıklama',
        'category': 'servisGarson',
        'location': 'İstanbul / Şişli',
        'city': 'İstanbul',
        'salary': '25.000 TL',
        'minSalaryTl': 20000,
        'maxSalaryTl': 30000,
        'employmentType': 'partTime',
        'contactInfo': '05553334455',
        'status': 'active',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 40))),
      });
    });

    test('filter by city returns only matching city listings', () async {
      final antalyaResult = await service.getPaginatedListings(city: 'Antalya');
      expect(antalyaResult.listings.length, equals(1));
      expect(antalyaResult.listings.single.id, equals('l_antalya'));

      final muglaResult = await service.getPaginatedListings(city: 'Muğla');
      expect(muglaResult.listings.length, equals(1));
      expect(muglaResult.listings.single.id, equals('l_mugla'));
    });

    test('filter by minSalaryTl returns listings meeting minimum salary criteria', () async {
      final result = await service.getPaginatedListings(minSalaryTl: 50000);
      expect(result.listings.length, equals(1));
      expect(result.listings.single.id, equals('l_mugla'));
    });

    test('filter by maxSalaryTl returns listings within maximum salary ceiling', () async {
      final result = await service.getPaginatedListings(maxSalaryTl: 25000);
      expect(result.listings.length, equals(1));
      expect(result.listings.single.id, equals('l_istanbul_old'));
    });

    test('filter by dateFilter excludes older listings beyond cutoff', () async {
      final recentResult = await service.getPaginatedListings(dateFilter: ListingDateFilter.lastWeek);
      expect(recentResult.listings.length, equals(2));
      final ids = recentResult.listings.map((l) => l.id).toList();
      expect(ids, contains('l_antalya'));
      expect(ids, contains('l_mugla'));
      expect(ids, isNot(contains('l_istanbul_old')));
    });

    test('filter by employmentType returns only matching employment type listings', () async {
      final seasonalResult = await service.getPaginatedListings(employmentType: EmploymentType.seasonal);
      expect(seasonalResult.listings.length, equals(1));
      expect(seasonalResult.listings.single.id, equals('l_mugla'));

      final partTimeResult = await service.getPaginatedListings(employmentType: EmploymentType.partTime);
      expect(partTimeResult.listings.length, equals(1));
      expect(partTimeResult.listings.single.id, equals('l_istanbul_old'));
    });

    test('sortOrder orders listings by salary or creation date', () async {
      final highestSalary = await service.getPaginatedListings(sortOrder: ListingSortOrder.salaryHighToLow);
      expect(highestSalary.listings.first.id, equals('l_mugla'));

      final lowestSalary = await service.getPaginatedListings(sortOrder: ListingSortOrder.salaryLowToHigh);
      expect(lowestSalary.listings.first.id, equals('l_istanbul_old'));
    });

    test('Listing.images property parses and serializes image URLs', () async {
      final listingWithImages = await service.getListing('l_antalya');
      expect(listingWithImages, isNotNull);
      expect(listingWithImages!.images, equals(['https://example.com/img1.jpg']));

      final listingWithoutImages = await service.getListing('l_mugla');
      expect(listingWithoutImages!.images, isEmpty);
    });
  });
}
