import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/seasonal_subscription_model.dart';

class SeasonalWindowInfo {
  final String seasonCode;
  final String titleTr;
  final String titleEn;
  final String recruitmentPeriodTr;
  final String recruitmentPeriodEn;
  final String activeMonthsTr;
  final String activeMonthsEn;
  final String descriptionTr;
  final String descriptionEn;

  const SeasonalWindowInfo({
    required this.seasonCode,
    required this.titleTr,
    required this.titleEn,
    required this.recruitmentPeriodTr,
    required this.recruitmentPeriodEn,
    required this.activeMonthsTr,
    required this.activeMonthsEn,
    required this.descriptionTr,
    required this.descriptionEn,
  });
}

class SeasonalService {
  final FirebaseFirestore _db;

  SeasonalService(this._db);

  static const List<SeasonalWindowInfo> seasonalWindows = [
    SeasonalWindowInfo(
      seasonCode: 'yaz_2025',
      titleTr: 'Yaz Sezonu 2025',
      titleEn: 'Summer Season 2025',
      recruitmentPeriodTr: 'Nisan - Haziran',
      recruitmentPeriodEn: 'April - June',
      activeMonthsTr: 'Mayıs - Ekim',
      activeMonthsEn: 'May - October',
      descriptionTr: 'Ege ve Akdeniz otellerinde en yoğun işe alım dönemi. Erken başvurular Nisan ayı başında başlar.',
      descriptionEn: 'Peak hiring period in Aegean and Mediterranean hotels. Early applications start in early April.',
    ),
    SeasonalWindowInfo(
      seasonCode: 'kis_2025_26',
      titleTr: 'Kış Sezonu 2025-26',
      titleEn: 'Winter Season 2025-26',
      recruitmentPeriodTr: 'Ekim - Aralık',
      recruitmentPeriodEn: 'October - December',
      activeMonthsTr: 'Kasım - Nisan',
      activeMonthsEn: 'November - April',
      descriptionTr: 'Kayak merkezleri (Uludağ, Palandöken, Erciyes) ve termal tesislerde işe alım dönemi.',
      descriptionEn: 'Hiring season for ski resorts (Uludağ, Palandöken, Erciyes) and thermal facilities.',
    ),
    SeasonalWindowInfo(
      seasonCode: 'tum_yil',
      titleTr: 'Tüm Yıl Sürekli İşe Alım',
      titleEn: 'Year-Round Hiring',
      recruitmentPeriodTr: 'Sürekli Açık',
      recruitmentPeriodEn: 'Always Open',
      activeMonthsTr: '12 Ay',
      activeMonthsEn: '12 Months',
      descriptionTr: 'Şehir otelleri (İstanbul, Ankara, İzmir) ve yıl boyu açık tesisler için kesintisiz personel alımı.',
      descriptionEn: 'Continuous recruitment for city hotels (Istanbul, Ankara, Izmir) and year-round facilities.',
    ),
  ];

  Stream<List<SeasonalSubscription>> watchUserSubscriptions(String userId) {
    return _db
        .collection('user_profiles')
        .doc(userId)
        .collection('seasonal_subscriptions')
        .snapshots()
        .map((snap) => snap.docs.map(SeasonalSubscription.fromDoc).toList())
        .handleError((Object e) {
      debugPrint('Error watching seasonal subscriptions: $e');
      return <SeasonalSubscription>[];
    });
  }

  Future<void> addSubscription({
    required String userId,
    String? city,
    String? category,
    String? season,
  }) async {
    final subDocRef = _db
        .collection('user_profiles')
        .doc(userId)
        .collection('seasonal_subscriptions')
        .doc();

    final mirrorDocRef = _db.collection('seasonal_subscriptions').doc(subDocRef.id);

    final userSubData = {
      'userId': userId,
      'city': city,
      'category': category,
      'season': season ?? 'yaz_2025',
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final mirrorSubData = {
      'userId': userId,
      'city': city,
      'category': category,
      'season': season ?? 'yaz_2025',
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'subscriptionId': subDocRef.id,
    };

    final batch = _db.batch();
    batch.set(subDocRef, userSubData);
    batch.set(mirrorDocRef, mirrorSubData);
    await batch.commit();
  }

  Future<void> toggleSubscription({
    required String userId,
    required String subscriptionId,
    required bool enabled,
  }) async {
    final subDocRef = _db
        .collection('user_profiles')
        .doc(userId)
        .collection('seasonal_subscriptions')
        .doc(subscriptionId);

    final mirrorDocRef = _db.collection('seasonal_subscriptions').doc(subscriptionId);

    final batch = _db.batch();
    batch.update(subDocRef, {'enabled': enabled});
    batch.update(mirrorDocRef, {'enabled': enabled});
    await batch.commit();
  }

  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    final subDocRef = _db
        .collection('user_profiles')
        .doc(userId)
        .collection('seasonal_subscriptions')
        .doc(subscriptionId);

    final mirrorDocRef = _db.collection('seasonal_subscriptions').doc(subscriptionId);

    final batch = _db.batch();
    batch.delete(subDocRef);
    batch.delete(mirrorDocRef);
    await batch.commit();
  }
}

final seasonalServiceProvider = Provider<SeasonalService>((ref) {
  return SeasonalService(FirebaseFirestore.instance);
});

final userSeasonalSubscriptionsProvider = StreamProvider.family<List<SeasonalSubscription>, String>((ref, userId) {
  return ref.watch(seasonalServiceProvider).watchUserSubscriptions(userId);
});
