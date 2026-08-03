import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/services/analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics analytics;
  late AnalyticsService service;

  setUp(() {
    analytics = MockFirebaseAnalytics();
    service = AnalyticsService(analytics);
    when(() => analytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(() => analytics.setUserId(id: any(named: 'id'))).thenAnswer((_) async {});
    when(() => analytics.setUserProperty(name: any(named: 'name'), value: any(named: 'value'))).thenAnswer((_) async {});
  });

  test('logEvent forwards name and parameters', () async {
    await service.logEvent(name: 'event', parameters: {'key': 'value'});
    final captured = verify(() => analytics.logEvent(name: 'event', parameters: captureAny(named: 'parameters'))).captured.single as Map<String, Object>;
    expect(captured, {'key': 'value'});
  });

  test('logShareListing builds expected event', () async {
    await service.logShareListing(listingId: 'l', listingTitle: 'İlan', category: 'servis', location: 'Antalya');
    final captured = verify(() => analytics.logEvent(name: 'share_listing', parameters: captureAny(named: 'parameters'))).captured.single as Map<String, Object>;
    expect(captured, {'listing_id': 'l', 'listing_title': 'İlan', 'category': 'servis', 'location': 'Antalya'});
  });

  test('user identity methods forward values', () async {
    await service.setUserId('u');
    await service.setUserProperty(name: 'role', value: 'employer');
    verify(() => analytics.setUserId(id: 'u')).called(1);
    verify(() => analytics.setUserProperty(name: 'role', value: 'employer')).called(1);
  });

  test('analytics exceptions are swallowed', () async {
    when(() => analytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters'))).thenThrow(Exception('offline'));
    await expectLater(service.logEvent(name: 'event'), completes);
  });
}
