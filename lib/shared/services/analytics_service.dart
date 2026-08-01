import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Analytics event logged: $name');
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  Future<void> logShareListing({
    required String listingId,
    required String listingTitle,
    String? category,
    String? location,
  }) async {
    await logEvent(
      name: 'share_listing',
      parameters: {
        'listing_id': listingId,
        'listing_title': listingTitle,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
      },
    );
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting analytics user ID: $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting analytics user property: $e');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(FirebaseAnalytics.instance),
);
