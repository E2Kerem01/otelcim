import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../shared/error/error_reporter.dart';
import '../domain/boost_model.dart';
import '../domain/boost_purchase_model.dart';

class BoostService {
  BoostService(this._db);

  final FirebaseFirestore _db;

  /// Process successful boost purchase via server-side Cloud Function verification
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
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final url = Uri.parse(
        'https://europe-west1-otelcim-7f0ba.cloudfunctions.net/verifyAndProcessBoostPurchase',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'listingId': listingId,
            'productId': productId,
            'transactionId': transactionId,
            'purchaseToken': purchaseToken,
            'verificationData': verificationData,
            'platform': platform,
          },
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        if (error != null) {
          throw Exception(error['message'] as String? ?? 'Sunucu doğrulaması başarısız oldu.');
        }
        debugPrint('Boost purchase verified and processed via Cloud Function.');
      } else {
        final msg = error?['message'] as String? ?? 'HTTP ${response.statusCode}: Boost doğrulama hatası.';
        throw Exception(msg);
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'BoostService.processBoostPurchase');
      rethrow;
    }
  }

  /// Redeems one of the user's free (referral-earned) 7-day boost credits
  /// on [listingId] via the redeemFreeBoost Cloud Function. The
  /// check-and-decrement of freeBoostCredits, and the boosts/boost_purchases
  /// writes, all happen server-side in one transaction — firestore.rules
  /// denies clients from writing those documents directly, since a client
  /// transaction can't be trusted to have actually consumed a credit.
  ///
  /// Throws an [Exception] if the user has no free boost credits left.
  Future<void> redeemFreeBoost({
    required String listingId,
    required String userId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final url = Uri.parse(
        'https://europe-west1-otelcim-7f0ba.cloudfunctions.net/redeemFreeBoost',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {'listingId': listingId},
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      if (response.statusCode != 200 || error != null) {
        final msg = error?['message'] as String? ?? 'HTTP ${response.statusCode}: Boost doğrulama hatası.';
        throw Exception(msg);
      }

      debugPrint('Free boost redeemed successfully for listing $listingId');
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'BoostService.redeemFreeBoost');
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
    }).handleError((Object error) {
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
    }).handleError((Object error) {
      debugPrint('Error watching user boosts: $error');
      return <Boost>[];
    });
  }
}

final boostServiceProvider = Provider<BoostService>((ref) => BoostService(FirebaseFirestore.instance));
