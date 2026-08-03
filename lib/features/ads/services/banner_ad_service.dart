import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/banner_ad_model.dart';

class BannerAdService {
  BannerAdService(this._db);

  final FirebaseFirestore _db;

  /// Stream of active banner ads for home page display
  /// Filters for isActive == true and non-expired end dates, sorted by order
  Stream<List<BannerAd>> watchActiveBannerAds() {
    return _db
        .collection('banner_ads')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final list = snapshot.docs
          .map(BannerAd.fromDoc)
          .where((ad) {
            if (!ad.isActive) return false;
            if (ad.startDate != null && ad.startDate!.isAfter(now)) return false;
            if (ad.endDate != null && ad.endDate!.isBefore(now)) return false;
            return true;
          })
          .toList();

      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });

      return list;
    }).handleError((error) {
      debugPrint('Error watching active banner ads: $error');
      return <BannerAd>[];
    });
  }

  /// Stream of all banner ads for admin management
  Stream<List<BannerAd>> watchAllBannerAds() {
    return _db
        .collection('banner_ads')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(BannerAd.fromDoc).toList();
      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return list;
    }).handleError((error) {
      debugPrint('Error watching all banner ads: $error');
      return <BannerAd>[];
    });
  }

  /// Create a new banner ad
  Future<String> createBannerAd(BannerAd ad) async {
    final docRef = await _db.collection('banner_ads').add(ad.toMap());
    return docRef.id;
  }

  /// Update an existing banner ad
  Future<void> updateBannerAd(BannerAd ad) async {
    await _db.collection('banner_ads').doc(ad.id).update(ad.toMap());
  }

  /// Delete a banner ad
  Future<void> deleteBannerAd(String id) async {
    await _db.collection('banner_ads').doc(id).delete();
  }

  /// Toggle active status of a banner ad
  Future<void> toggleActive(String id, bool isActive) async {
    await _db.collection('banner_ads').doc(id).update({'isActive': isActive});
  }
}

final bannerAdServiceProvider = Provider<BannerAdService>((ref) {
  return BannerAdService(FirebaseFirestore.instance);
});

final activeBannerAdsProvider = StreamProvider<List<BannerAd>>((ref) {
  return ref.watch(bannerAdServiceProvider).watchActiveBannerAds();
});

final allBannerAdsProvider = StreamProvider<List<BannerAd>>((ref) {
  return ref.watch(bannerAdServiceProvider).watchAllBannerAds();
});
