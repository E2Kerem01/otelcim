import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../shared/error/error_reporter.dart';

/// Talks to the `verifyAndProcessUrgentListingPurchase` Cloud Function, which
/// verifies a real store receipt for the `urgent_listing` product and then
/// flips `isUrgent: true` on the listing under the Admin SDK.
///
/// This mirrors [BoostService.processBoostPurchase]: the client never writes
/// `isUrgent` on an existing listing itself (firestore.rules denies it via
/// `isNotChangingBoostOrOwnershipFields`), because a client can't be trusted
/// to have actually paid.
class UrgentListingService {
  const UrgentListingService();

  static const String urgentListingProductId = 'urgent_listing';

  Future<void> processUrgentListingPurchase({
    required String listingId,
    required String productId,
    String? purchaseToken,
    String? verificationData,
    required String platform,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final url = Uri.parse(
        'https://europe-west1-otelcim-7f0ba.cloudfunctions.net/'
        'verifyAndProcessUrgentListingPurchase',
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
          throw Exception(
            error['message'] as String? ?? 'Sunucu doğrulaması başarısız oldu.',
          );
        }
        debugPrint('Urgent listing purchase verified and processed.');
      } else {
        final msg = error?['message'] as String? ??
            'HTTP ${response.statusCode}: Acil ilan doğrulama hatası.';
        throw Exception(msg);
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'UrgentListingService.processUrgentListingPurchase');
      rethrow;
    }
  }
}

final urgentListingServiceProvider = Provider<UrgentListingService>(
  (ref) => const UrgentListingService(),
);
