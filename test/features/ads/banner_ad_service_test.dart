import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';

void main() {
  group('BannerAdService Date & Active Filtering', () {
    late FakeFirebaseFirestore db;
    late BannerAdService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = BannerAdService(db);
    });

    test('watchActiveBannerAds filters out inactive, future start, and expired banners', () async {
      final now = DateTime.now();

      // 1. Active & valid date range (SHOULD BE INCLUDED)
      await db.collection('banner_ads').doc('active1').set({
        'title': 'Aktif Kampanya 1',
        'advertiserName': 'Jolly Tur',
        'imageUrl': 'https://example.com/ad1.jpg',
        'targetUrl': 'https://jollytur.com',
        'order': 1,
        'isActive': true,
        'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'createdAt': Timestamp.now(),
      });

      // 2. Inactive banner (SHOULD BE EXCLUDED)
      await db.collection('banner_ads').doc('inactive').set({
        'title': 'Pasif Kampanya',
        'advertiserName': 'Turizm A.Ş.',
        'imageUrl': 'https://example.com/ad2.jpg',
        'targetUrl': 'https://example.com',
        'order': 0,
        'isActive': false,
        'createdAt': Timestamp.now(),
      });

      // 3. Future start date banner (SHOULD BE EXCLUDED)
      await db.collection('banner_ads').doc('future').set({
        'title': 'Gelecek Kampanya',
        'advertiserName': 'Gelecek Tur',
        'imageUrl': 'https://example.com/ad3.jpg',
        'targetUrl': 'https://example.com',
        'order': 2,
        'isActive': true,
        'startDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'createdAt': Timestamp.now(),
      });

      // 4. Expired banner (SHOULD BE EXCLUDED)
      await db.collection('banner_ads').doc('expired').set({
        'title': 'Süresi Dolmuş Kampanya',
        'advertiserName': 'Eski Tur',
        'imageUrl': 'https://example.com/ad4.jpg',
        'targetUrl': 'https://example.com',
        'order': 3,
        'isActive': true,
        'endDate': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'createdAt': Timestamp.now(),
      });

      // 5. Active banner with no date limits (SHOULD BE INCLUDED)
      await db.collection('banner_ads').doc('active2').set({
        'title': 'Aktif Kampanya 2',
        'advertiserName': 'ETS Tur',
        'imageUrl': 'https://example.com/ad5.jpg',
        'targetUrl': 'https://etstur.com',
        'order': 2,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      final activeAds = await service.watchActiveBannerAds().first;

      expect(activeAds.length, equals(2));
      expect(activeAds[0].id, equals('active1'));
      expect(activeAds[1].id, equals('active2'));
      expect(activeAds[0].order, lessThanOrEqualTo(activeAds[1].order));
    });

    test('watchAllBannerAds returns all banners ordered by order field', () async {
      await db.collection('banner_ads').doc('ad_b').set({
        'title': 'B',
        'advertiserName': 'Adv B',
        'imageUrl': 'url',
        'targetUrl': 'url',
        'order': 10,
        'isActive': false,
      });

      await db.collection('banner_ads').doc('ad_a').set({
        'title': 'A',
        'advertiserName': 'Adv A',
        'imageUrl': 'url',
        'targetUrl': 'url',
        'order': 1,
        'isActive': true,
      });

      final allAds = await service.watchAllBannerAds().first;

      expect(allAds.length, equals(2));
      expect(allAds[0].id, equals('ad_a'));
      expect(allAds[1].id, equals('ad_b'));
    });

    test('createBannerAd, updateBannerAd, toggleActive and deleteBannerAd work correctly', () async {
      final ad = BannerAd(
        id: '',
        title: 'Yeni Reklam',
        advertiserName: 'Test Firma',
        imageUrl: 'https://img.com',
        targetUrl: 'https://target.com',
        order: 5,
        isActive: true,
      );

      final newId = await service.createBannerAd(ad);
      expect(newId, isNotEmpty);

      final createdDoc = await db.collection('banner_ads').doc(newId).get();
      expect(createdDoc.exists, isTrue);
      expect(createdDoc.data()!['title'], equals('Yeni Reklam'));

      await service.toggleActive(newId, false);
      final toggledDoc = await db.collection('banner_ads').doc(newId).get();
      expect(toggledDoc.data()!['isActive'], isFalse);

      final updatedAd = BannerAd.fromDoc(toggledDoc).copyWith(title: 'Güncellendi');
      await service.updateBannerAd(updatedAd);
      final updatedDoc = await db.collection('banner_ads').doc(newId).get();
      expect(updatedDoc.data()!['title'], equals('Güncellendi'));

      await service.deleteBannerAd(newId);
      final deletedDoc = await db.collection('banner_ads').doc(newId).get();
      expect(deletedDoc.exists, isFalse);
    });
  });
}
