import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/boost_model.dart';
import '../domain/boost_purchase_model.dart';

class BoostService {
  BoostService(this._db);

  final FirebaseFirestore _db;

  /// Process successful boost purchase and update listing and boost collections in Firestore
  Future<void> processBoostPurchase({
    required String listingId,
    required String userId,
    required String productId,
    required String transactionId,
    double? priceOverride,
    String? purchaseToken,
    String? verificationData,
    String platform = 'in_app_purchase',
  }) async {
    try {
      int durationDays = 7;
      BoostDurationType durationTypeEnum = BoostDurationType.days7;
      String durationTypeStr = '7';
      double price = priceOverride ?? 49.99;

      if (productId.contains('14') || productId == 'boost_14_days') {
        durationDays = 14;
        durationTypeEnum = BoostDurationType.days14;
        durationTypeStr = '14';
        price = priceOverride ?? 89.99;
      } else if (productId.contains('30') || productId == 'boost_30_days') {
        durationDays = 30;
        durationTypeEnum = BoostDurationType.days30;
        durationTypeStr = '30';
        price = priceOverride ?? 149.99;
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: durationDays));

      // 1. Create Boost document
      final boostDocRef = _db.collection('boosts').doc();
      final boost = Boost(
        id: boostDocRef.id,
        listingId: listingId,
        userId: userId,
        durationType: durationTypeEnum,
        durationDays: durationDays,
        price: price,
        purchasedAt: now,
        expiresAt: expiresAt,
        platform: platform,
        transactionId: transactionId,
        status: BoostStatus.active,
      );
      await boostDocRef.set(boost.toMap());

      // 2. Create BoostPurchase record
      final purchaseDocRef = _db.collection('boost_purchases').doc();
      final boostPurchase = BoostPurchase(
        id: purchaseDocRef.id,
        userId: userId,
        listingId: listingId,
        boostId: boostDocRef.id,
        durationType: durationTypeStr,
        price: price,
        platform: platform,
        transactionId: transactionId,
        productId: productId,
        purchaseToken: purchaseToken,
        verificationData: verificationData,
        status: PurchaseStatus.completed,
        purchasedAt: now,
        verifiedAt: now,
      );
      await purchaseDocRef.set(boostPurchase.toMap());

      // 3. Update Listing document
      await _db.collection('listings').doc(listingId).update({
        'isBoosted': true,
        'boostExpiresAt': Timestamp.fromDate(expiresAt),
        'boostType': productId,
        'boostPurchaseId': purchaseDocRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Boost purchase processed successfully for listing $listingId');
    } catch (e) {
      debugPrint('Error processing boost purchase: $e');
      rethrow;
    }
  }

  /// Watch active and past boost purchases for a specific user
  Stream<List<BoostPurchase>> watchUserBoostPurchases(String userId) {
    return _db
        .collection('boost_purchases')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(BoostPurchase.fromDoc).toList();
      list.sort((a, b) {
        final tA = a.purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return list;
    }).handleError((error) {
      debugPrint('Error watching user boost purchases: $error');
      return <BoostPurchase>[];
    });
  }

  /// Watch active boosts for a specific user
  Stream<List<Boost>> watchUserBoosts(String userId) {
    return _db
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Boost.fromDoc).toList();
      list.sort((a, b) {
        final tA = a.purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.purchasedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return list;
    }).handleError((error) {
      debugPrint('Error watching user boosts: $error');
      return <Boost>[];
    });
  }
}

final boostServiceProvider = Provider<BoostService>((ref) => BoostService(FirebaseFirestore.instance));
