import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/app/router.dart';

void main() {
  group('isProtectedRoute', () {
    test('protects authenticated flows and their nested routes', () {
      const protectedLocations = [
        '/create-listing',
        '/batch-create-listing',
        '/chat',
        '/chat/conversation-id',
        '/profile',
        '/profile/edit',
        '/my-listings',
        '/my-boosts',
        '/favorites',
        '/listing/listing-id/boost',
        '/listing/listing-id/urgent',
        '/listing/listing-id/edit',
        '/onboarding',
        '/onboarding/role',
        '/admin',
        '/admin/reports',
      ];

      for (final location in protectedLocations) {
        expect(isProtectedRoute(location), isTrue, reason: location);
      }
    });

    test('keeps public discovery and sharing routes accessible', () {
      const publicLocations = [
        '/',
        '/login',
        '/register',
        '/categories',
        '/regions',
        '/nearby',
        '/listing/listing-id',
        '/listing/listing-id/qr-poster',
        '/seasonal-calendar',
      ];

      for (final location in publicLocations) {
        expect(isProtectedRoute(location), isFalse, reason: location);
      }
    });
  });
}
