import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/seasonal/domain/seasonal_subscription_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';

void main() {
  group('ListingSeason Enum & Listing Model Tests', () {
    test('ListingSeason converts code to label correctly', () {
      expect(ListingSeason.yaz2025.code, equals('yaz_2025'));
      expect(ListingSeason.yaz2025.label, equals('Yaz 2025'));

      expect(ListingSeason.kis202526.code, equals('kis_2025_26'));
      expect(ListingSeason.kis202526.label, equals('Kış 2025-26'));

      expect(ListingSeason.tumYil.code, equals('tum_yil'));
      expect(ListingSeason.tumYil.label, equals('Tüm Yıl'));

      expect(ListingSeason.fromCode('yaz_2025'), equals(ListingSeason.yaz2025));
      expect(ListingSeason.fromCode('kis_2025_26'), equals(ListingSeason.kis202526));
      expect(ListingSeason.fromCode('tum_yil'), equals(ListingSeason.tumYil));
      expect(ListingSeason.fromCode('invalid'), isNull);
      expect(ListingSeason.fromCode(null), isNull);
    });

    test('Listing model handles season fields', () {
      final now = DateTime.now();
      final listing = Listing(
        id: 'test-1',
        posterId: 'user-1',
        posterName: 'Hotel Antalya',
        title: 'Resepsiyonist',
        description: 'Mevsimlik resepsiyonist aranıyor',
        category: 'resepsiyon',
        location: 'Antalya',
        salary: '35000 TL',
        city: 'Antalya',
        contactInfo: '05551234567',
        season: 'yaz_2025',
        contractStartDate: now,
        contractEndDate: now.add(const Duration(days: 180)),
      );

      expect(listing.season, equals('yaz_2025'));
      expect(listing.contractStartDate, equals(now));
      expect(listing.contractEndDate, isNotNull);

      final map = listing.toMap();
      expect(map['season'], equals('yaz_2025'));
      expect(map['contractStartDate'], isNotNull);
      expect(map['contractEndDate'], isNotNull);
    });

    test('SeasonalSubscription model serializes correctly', () {
      final sub = SeasonalSubscription(
        id: 'sub-1',
        userId: 'user-123',
        city: 'Antalya',
        category: 'resepsiyon',
        season: 'yaz_2025',
        enabled: true,
      );

      expect(sub.id, equals('sub-1'));
      expect(sub.userId, equals('user-123'));
      expect(sub.city, equals('Antalya'));
      expect(sub.category, equals('resepsiyon'));
      expect(sub.season, equals('yaz_2025'));
      expect(sub.enabled, isTrue);

      final map = sub.toMap();
      expect(map['userId'], equals('user-123'));
      expect(map['city'], equals('Antalya'));
      expect(map['category'], equals('resepsiyon'));
      expect(map['season'], equals('yaz_2025'));
      expect(map['enabled'], isTrue);
    });

    test('Seasonal filter logic correctly filters listings by season', () {
      final listings = [
        const Listing(
          id: '1',
          posterId: 'p1',
          posterName: 'P1',
          title: 'Resepsiyonist',
          description: 'Desc',
          category: 'resepsiyon',
          location: 'Antalya',
          salary: '30000 TL',
          contactInfo: '123',
          season: 'yaz_2025',
        ),
        const Listing(
          id: '2',
          posterId: 'p2',
          posterName: 'P2',
          title: 'Aşçı',
          description: 'Desc',
          category: 'mutfak',
          location: 'Uludağ',
          salary: '40000 TL',
          contactInfo: '123',
          season: 'kis_2025_26',
        ),
        const Listing(
          id: '3',
          posterId: 'p3',
          posterName: 'P3',
          title: 'Garson',
          description: 'Desc',
          category: 'servis',
          location: 'İstanbul',
          salary: '25000 TL',
          contactInfo: '123',
          season: 'tum_yil',
        ),
      ];

      final summerListings = listings.where((l) => l.season == 'yaz_2025').toList();
      expect(summerListings.length, equals(1));
      expect(summerListings.first.id, equals('1'));

      final winterListings = listings.where((l) => l.season == 'kis_2025_26').toList();
      expect(winterListings.length, equals(1));
      expect(winterListings.first.id, equals('2'));
    });
  });
}
