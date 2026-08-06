import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['error'] != null) {
          throw Exception(body['error']['message'] ?? 'Sunucu doğrulaması başarısız oldu.');
        }
        debugPrint('Boost purchase verified and processed via Cloud Function.');
      } else {
        final body = jsonDecode(response.body);
        final msg = body['error']?['message'] ?? 'HTTP ${response.statusCode}: Boost doğrulama hatası.';
        throw Exception(msg);
      }
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
