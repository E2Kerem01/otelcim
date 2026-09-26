import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/seasonal/domain/seasonal_subscription_model.dart';
import 'package:otelcim/features/seasonal/presentation/seasonal_calendar_screen.dart';
import 'package:otelcim/features/seasonal/services/seasonal_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('SeasonalCalendarScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockSeasonalService mockSeasonalService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockSeasonalService = MockSeasonalService();
    });

    Widget buildSeasonalCalendarScreen({
      required AppUser? currentUser,
      Stream<List<SeasonalSubscription>>? subscriptionsStream,
      List<String>? navigatedRoutes,
    }) {
      final router = GoRouter(
        initialLocation: '/seasonal-calendar',
        routes: [
          GoRoute(
            path: '/seasonal-calendar',
            builder: (context, state) => const SeasonalCalendarScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              navigatedRoutes?.add('/login');
              return const Scaffold(body: Text('Login Screen'));
            },
          ),
        ],
      );

      final overrides = <Override>[
        authServiceProvider.overrideWith((ref) => mockAuthService),
        authStateProvider.overrideWith((ref) => Stream.value(currentUser)),
        seasonalServiceProvider.overrideWith((ref) => mockSeasonalService),
      ];

      if (currentUser != null && subscriptionsStream != null) {
        overrides.add(
          userSeasonalSubscriptionsProvider(currentUser.uid)
              .overrideWith((ref) => subscriptionsStream),
        );
      }

      return ProviderScope(
        overrides: overrides,
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

    testWidgets('renders recruitment periods and login prompt when unauthenticated', (tester) async {
      await configureTestScreenSize(tester);

      final navigatedRoutes = <String>[];
      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: null,
          navigatedRoutes: navigatedRoutes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sezonluk İşe Alım Takvimi'), findsOneWidget);
      expect(find.text('Turizm Sezonu İşe Alım Dönemleri'), findsOneWidget);

      // Seasonal window cards
      expect(find.text('Yaz Sezonu 2025'), findsOneWidget);
      expect(find.text('Kış Sezonu 2025-26'), findsOneWidget);
      expect(find.text('Tüm Yıl Sürekli İşe Alım'), findsOneWidget);

      // Sign-in card
      expect(
        find.text('Sezonluk işe alım hatırlatıcıları kurmak için lütfen giriş yapın.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Giriş Yap'), findsOneWidget);

      // Tap 'Giriş Yap'
      await tester.tap(find.widgetWithText(OutlinedButton, 'Giriş Yap'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/login'));
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('displays empty subscriptions state when logged-in user has no alerts', (tester) async {
      await configureTestScreenSize(tester);

      final user = createDummyAdminUser(uid: 'user_seasonal_1');
      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: user,
          subscriptionsStream: Stream.value([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sezonluk Hatırlatıcılarım'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Ekle'), findsOneWidget);
      expect(find.text('Henüz kurulmuş bir sezon hatırlatıcısı yok.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'İlk Hatırlatıcıyı Oluştur'), findsOneWidget);
    });

    testWidgets('renders user seasonal subscriptions with city, category and enabled switch', (tester) async {
      await configureTestScreenSize(tester);

      final user = createDummyAdminUser(uid: 'user_seasonal_2');
      final subscriptions = [
        createDummySeasonalSubscription(
          id: 'sub_1',
          userId: user.uid,
          city: 'Antalya',
          category: 'resepsiyon',
          season: 'yaz_2025',
          enabled: true,
        ),
        createDummySeasonalSubscription(
          id: 'sub_2',
          userId: user.uid,
          city: 'Muğla',
          category: 'servisGarson',
          season: 'yaz_2025',
          enabled: false,
        ),
      ];

      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: user,
          subscriptionsStream: Stream.value(subscriptions),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antalya - Resepsiyon'), findsOneWidget);
      expect(find.text('Muğla - Servis / Garson'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
    });

    testWidgets('toggles subscription switch and calls seasonalService.toggleSubscription', (tester) async {
      await configureTestScreenSize(tester);

      final user = createDummyAdminUser(uid: 'user_seasonal_toggle');
      final subscription = createDummySeasonalSubscription(
        id: 'sub_toggle_id',
        userId: user.uid,
        enabled: true,
      );

      when(() => mockSeasonalService.toggleSubscription(
            userId: any(named: 'userId'),
            subscriptionId: any(named: 'subscriptionId'),
            enabled: any(named: 'enabled'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: user,
          subscriptionsStream: Stream.value([subscription]),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockSeasonalService.toggleSubscription(
            userId: 'user_seasonal_toggle',
            subscriptionId: 'sub_toggle_id',
            enabled: false,
          )).called(1);
    });

    testWidgets('deletes subscription when delete icon is tapped', (tester) async {
      await configureTestScreenSize(tester);

      final user = createDummyAdminUser(uid: 'user_seasonal_delete');
      final subscription = createDummySeasonalSubscription(
        id: 'sub_delete_id',
        userId: user.uid,
      );

      when(() => mockSeasonalService.deleteSubscription(
            userId: any(named: 'userId'),
            subscriptionId: any(named: 'subscriptionId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: user,
          subscriptionsStream: Stream.value([subscription]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      verify(() => mockSeasonalService.deleteSubscription(
            userId: 'user_seasonal_delete',
            subscriptionId: 'sub_delete_id',
          )).called(1);
    });

    testWidgets('opens add subscription modal sheet and creates reminder', (tester) async {
      await configureTestScreenSize(tester);

      final user = createDummyAdminUser(uid: 'user_seasonal_add');
      when(() => mockSeasonalService.addSubscription(
            userId: any(named: 'userId'),
            city: any(named: 'city'),
            category: any(named: 'category'),
            season: any(named: 'season'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSeasonalCalendarScreen(
          currentUser: user,
          subscriptionsStream: Stream.value([]),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Ekle' in section header
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('Sezon İlanı Hatırlatıcı Ekle'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Hatırlatıcı Oluştur'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Hatırlatıcı Oluştur'));
      await tester.pumpAndSettle();

      verify(() => mockSeasonalService.addSubscription(
            userId: 'user_seasonal_add',
            city: null,
            category: null,
            season: 'yaz_2026',
          )).called(1);

      expect(find.text('Sezonluk hatırlatıcı başarıyla oluşturuldu.'), findsOneWidget);
    });

    testWidgets(
      'supports selecting 2026 seasons in seasonal reminder modal (D23)',
      (tester) async {
        await configureTestScreenSize(tester);

        final user = createDummyAdminUser(uid: 'user_d23');
        await tester.pumpWidget(
          buildSeasonalCalendarScreen(
            currentUser: user,
            subscriptionsStream: Stream.value([]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Ekle'));
        await tester.pumpAndSettle();

        // The current-year options are generated by ListingSeason.values.
        expect(find.textContaining('2026'), findsWidgets,
            reason: 'Seasonal reminder options must include 2026 seasons (D23)');
      },
    );
  });
}
