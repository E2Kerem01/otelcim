import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:otelcim/features/admin/services/analytics_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('AdminDashboardScreen Widget Tests', () {
    late MockAdminAnalyticsService mockAnalyticsService;

    setUp(() {
      mockAnalyticsService = MockAdminAnalyticsService();
    });

    Widget buildDashboardScreen({
      required AdminAnalyticsService analyticsService,
      List<String>? navigatedRoutes,
    }) {
      final routes = [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/reports');
            return const Scaffold(body: Text('Reports Page'));
          },
        ),
        GoRoute(
          path: '/admin/verifications',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/verifications');
            return const Scaffold(body: Text('Verifications Page'));
          },
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/users');
            return const Scaffold(body: Text('Users Page'));
          },
        ),
        GoRoute(
          path: '/admin/listings',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/listings');
            return const Scaffold(body: Text('Listings Page'));
          },
        ),
        GoRoute(
          path: '/admin/certificates',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/certificates');
            return const Scaffold(body: Text('Certificates Page'));
          },
        ),
        GoRoute(
          path: '/admin/banners',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/banners');
            return const Scaffold(body: Text('Banners Page'));
          },
        ),
        GoRoute(
          path: '/admin/audit-log',
          builder: (context, state) {
            navigatedRoutes?.add('/admin/audit-log');
            return const Scaffold(body: Text('Audit Log Page'));
          },
        ),
      ];

      final router = GoRouter(
        initialLocation: '/admin',
        routes: routes,
      );

      return ProviderScope(
        overrides: [
          adminAnalyticsServiceProvider.overrideWith((ref) => analyticsService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', ''), Locale('en', '')],
        ),
      );
    }

    testWidgets('renders header, all 7 management cards and loaded badge counts', (tester) async {
      await configureTestScreenSize(tester);

      when(() => mockAnalyticsService.getDashboardMetrics()).thenAnswer(
        (_) async => const DashboardMetrics(
          activeListings: 42,
          newUsers: 15,
          openReports: 7,
          pendingVerifications: 3,
        ),
      );

      await tester.pumpWidget(buildDashboardScreen(analyticsService: mockAnalyticsService));
      await tester.pumpAndSettle();

      expect(find.text('Yönetim Paneli'), findsOneWidget);
      expect(find.text('İçerik moderasyonu'), findsOneWidget);
      expect(find.text('Şikâyetleri ve doğrulama taleplerini tek yerden yönetin.'), findsOneWidget);

      expect(find.text('Şikâyetler'), findsOneWidget);
      expect(find.text('Doğrulama Talepleri'), findsOneWidget);
      expect(find.text('Kullanıcı Yönetimi'), findsOneWidget);
      expect(find.text('İlan Yönetimi'), findsOneWidget);
      expect(find.text('Belge Onay Kuyruğu'), findsOneWidget);
      expect(find.text('Banner Reklamlar'), findsOneWidget);
      expect(find.text('İşlem Geçmişi'), findsOneWidget);

      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays error text when metrics fail to load', (tester) async {
      await configureTestScreenSize(tester);

      when(() => mockAnalyticsService.getDashboardMetrics())
          .thenThrow(Exception('Firestore connection error'));

      await tester.pumpWidget(buildDashboardScreen(analyticsService: mockAnalyticsService));
      await tester.pumpAndSettle();

      expect(
        find.text('Özet bilgiler yüklenemedi. Yenilemek için aşağı kaydırın.'),
        findsOneWidget,
      );
      expect(find.text('Şikâyetler'), findsOneWidget);
      expect(find.text('Kullanıcı Yönetimi'), findsOneWidget);
    });

    testWidgets('navigates to respective admin screens on card tap', (tester) async {
      await configureTestScreenSize(tester);

      final navigatedRoutes = <String>[];
      when(() => mockAnalyticsService.getDashboardMetrics()).thenAnswer(
        (_) async => const DashboardMetrics(
          activeListings: 10,
          newUsers: 5,
          openReports: 2,
          pendingVerifications: 1,
        ),
      );

      await tester.pumpWidget(
        buildDashboardScreen(
          analyticsService: mockAnalyticsService,
          navigatedRoutes: navigatedRoutes,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Şikâyetler' card
      await tester.tap(find.text('Şikâyetler'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/admin/reports'));
      expect(find.text('Reports Page'), findsOneWidget);
    });

    testWidgets('pull to refresh triggers metrics re-fetch', (tester) async {
      await configureTestScreenSize(tester);

      var fetchCount = 0;
      when(() => mockAnalyticsService.getDashboardMetrics()).thenAnswer((_) async {
        fetchCount++;
        return const DashboardMetrics(
          activeListings: 10,
          newUsers: 5,
          openReports: 1,
          pendingVerifications: 2,
        );
      });

      await tester.pumpWidget(buildDashboardScreen(analyticsService: mockAnalyticsService));
      await tester.pumpAndSettle();

      expect(fetchCount, equals(1));

      // Trigger pull to refresh gesture on ListView
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(fetchCount, greaterThanOrEqualTo(2));
    });
  });
}
