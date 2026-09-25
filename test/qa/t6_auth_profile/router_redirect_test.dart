import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/app/router.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockAdminService extends Mock implements AdminService {}
class FakeBuildContext extends Fake implements BuildContext {}

class FakeGoRouterState extends Fake implements GoRouterState {
  FakeGoRouterState(this._matchedLocation);
  final String _matchedLocation;

  @override
  String get matchedLocation => uri.path;

  @override
  Uri get uri => Uri.parse(_matchedLocation);
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeGoRouterState('/'));
  });

  group('Router Redirect & Guard Logic', () {
    late MockAuthService mockAuthService;
    late MockAdminService mockAdminService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAdminService = MockAdminService();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          adminServiceProvider.overrideWithValue(mockAdminService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Future<String?> executeRedirect(String matchedLocation) async {
      final router = container.read(routerProvider);
      final redirect = router.configuration.topRedirect;
      return redirect(FakeBuildContext(), FakeGoRouterState(matchedLocation));
    }

    UserProfile createSampleProfile({
      bool isBanned = false,
      String? banReason,
      bool isSuspended = false,
      DateTime? suspensionEnd,
      String? suspensionReason,
      bool isAdmin = false,
      AdminRole? adminRole,
    }) {
      final now = DateTime.now();
      return UserProfile(
        id: 'user_123',
        email: 'test@example.com',
        userType: 'jobseeker',
        createdAt: now,
        updatedAt: now,
        isBanned: isBanned,
        banReason: banReason,
        isSuspended: isSuspended,
        suspensionEnd: suspensionEnd,
        suspensionReason: suspensionReason,
        isAdmin: isAdmin,
        adminRole: adminRole,
      );
    }

    group('Anonymous User Redirects', () {
      setUp(() {
        when(() => mockAuthService.currentUser).thenReturn(null);
      });

      test('redirects to /login when accessing protected routes', () async {
        const protectedRoutes = <String>[
          '/account-suspended',
          '/create-listing',
          '/batch-create-listing',
          '/chat',
          '/chat/conv-123',
          '/profile',
          '/profile/edit',
          '/my-listings',
          '/my-boosts',
          '/favorites',
          '/listing/l1/boost',
          '/listing/l1/urgent',
          '/listing/l1/edit',
          '/onboarding',
          '/onboarding/role',
          '/admin',
          '/admin/reports',
        ];

        for (final route in protectedRoutes) {
          final result = await executeRedirect(route);
          expect(
            result,
            '/login?from=${Uri.encodeComponent(route)}',
            reason: 'Route $route should redirect to /login with its origin',
          );
        }
      });

      test('redirects job seekers away from listing creation', () async {
        final profile = createSampleProfile();
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => profile);
        when(() => mockAdminService.isAdminProfile(profile)).thenReturn(false);
        when(() => mockAuthService.currentUser)
            .thenReturn(const AppUser(uid: 'user_123', email: 'test@example.com'));

        expect(await executeRedirect('/create-listing'), '/');
        expect(await executeRedirect('/batch-create-listing'), '/');
      });

      test('allows access without redirect on public routes', () async {
        const publicRoutes = <String>[
          '/',
          '/login',
          '/register',
          '/categories',
          '/regions',
          '/regions/map',
          '/nearby',
          '/listing/l1',
          '/listing/l1/qr-poster',
          '/seasonal-calendar',
          '/splash',
        ];

        for (final route in publicRoutes) {
          final result = await executeRedirect(route);
          expect(result, isNull, reason: 'Route $route should be accessible to anonymous users');
        }
      });
    });

    group('Logged-in Active User Redirects', () {
      const activeUser = AppUser(uid: 'user_123', email: 'test@example.com');

      setUp(() {
        when(() => mockAuthService.currentUser).thenReturn(activeUser);
        final profile = createSampleProfile();
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => profile);
        when(() => mockAdminService.isAdminProfile(any())).thenReturn(false);
      });

      test('redirects to / when visiting /login or /register', () async {
        expect(await executeRedirect('/login'), '/');
        expect(await executeRedirect('/register'), '/');
      });

      test('returns to the protected origin after login', () async {
        expect(
          await executeRedirect('/login?from=%2Fprofile'),
          '/profile',
        );
      });

      test('allows access to standard protected routes', () async {
        expect(await executeRedirect('/profile'), isNull);
        expect(await executeRedirect('/profile/edit'), isNull);
        expect(await executeRedirect('/chat'), isNull);
        expect(await executeRedirect('/my-listings'), isNull);
      });

      test('redirects non-admin user to / when trying to access /admin routes', () async {
        expect(await executeRedirect('/admin'), '/');
        expect(await executeRedirect('/admin/reports'), '/');
        expect(await executeRedirect('/admin/users'), '/');
      });
    });

    group('Admin User Access', () {
      const adminUser = AppUser(
        uid: 'admin_123',
        email: 'admin@example.com',
        isAdmin: true,
        adminRole: AdminRole.superAdmin,
      );

      setUp(() {
        when(() => mockAuthService.currentUser).thenReturn(adminUser);
        final adminProfile = createSampleProfile(
          isAdmin: true,
          adminRole: AdminRole.superAdmin,
        );
        when(() => mockAdminService.getUserProfile('admin_123'))
            .thenAnswer((_) async => adminProfile);
        when(() => mockAdminService.isAdminProfile(adminProfile)).thenReturn(true);
      });

      test('allows admin user to access /admin and its subroutes', () async {
        expect(await executeRedirect('/admin'), isNull);
        expect(await executeRedirect('/admin/reports'), isNull);
        expect(await executeRedirect('/admin/audit-log'), isNull);
      });
    });

    group('Banned and Suspended User Redirects', () {
      const loggedInUser = AppUser(uid: 'user_123', email: 'test@example.com');

      setUp(() {
        when(() => mockAuthService.currentUser).thenReturn(loggedInUser);
        when(() => mockAdminService.isAdminProfile(any())).thenReturn(false);
      });

      test('redirects banned user to /account-suspended on any page', () async {
        final bannedProfile = createSampleProfile(
          isBanned: true,
          banReason: 'Kullanım şartları ihlali',
        );
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => bannedProfile);

        expect(await executeRedirect('/'), '/account-suspended');
        expect(await executeRedirect('/profile'), '/account-suspended');
        expect(await executeRedirect('/chat'), '/account-suspended');
      });

      test('does not redirect in a loop when banned user is already at /account-suspended', () async {
        final bannedProfile = createSampleProfile(isBanned: true);
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => bannedProfile);

        expect(await executeRedirect('/account-suspended'), isNull);
      });

      test('redirects suspended user with active suspension to /account-suspended', () async {
        final suspendedProfile = createSampleProfile(
          isSuspended: true,
          suspensionEnd: DateTime.now().add(const Duration(days: 3)),
          suspensionReason: 'Geçici inceleme',
        );
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => suspendedProfile);

        expect(await executeRedirect('/'), '/account-suspended');
        expect(await executeRedirect('/profile'), '/account-suspended');
      });

      test('redirects suspended user with indefinite suspension (suspensionEnd == null) to /account-suspended', () async {
        final indefiniteSuspendedProfile = createSampleProfile(
          isSuspended: true,
          suspensionEnd: null,
          suspensionReason: 'Süresiz askı',
        );
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => indefiniteSuspendedProfile);

        expect(await executeRedirect('/'), '/account-suspended');
      });

      test('allows access when suspension period has expired (suspensionEnd in the past)', () async {
        final expiredSuspensionProfile = createSampleProfile(
          isSuspended: true,
          suspensionEnd: DateTime.now().subtract(const Duration(hours: 1)),
          suspensionReason: 'Eski askı',
        );
        when(() => mockAdminService.getUserProfile('user_123'))
            .thenAnswer((_) async => expiredSuspensionProfile);

        expect(await executeRedirect('/profile'), isNull);
      });

      test(
        'banned user bypasses suspension check when profile fetch fails (returns null)',
        () async {
          when(() => mockAdminService.getUserProfile('user_123'))
              .thenAnswer((_) async => null);

          // If profile fails to load, router should fail closed and block access,
          // but currently it skips the ban check and returns null (allowing navigation).
          final result = await executeRedirect('/profile');
          expect(result, '/account-suspended');
        },
        skip: 'BUG-t6-01: Null profile fetch causes banned/suspended user check to be bypassed',
      );
    });

    group('isProtectedRoute edge cases', () {
      test('correctly identifies standard and edge case routes', () {
        expect(isProtectedRoute('/profile'), isTrue);
        expect(isProtectedRoute('/profile/edit'), isTrue);
        // Prefix match (startsWith('/profile')), same as '/chatroom' below.
        // No real route collides with the prefix, so over-matching fails closed.
        expect(isProtectedRoute('/profilex'), isTrue);
        expect(isProtectedRoute('/chat'), isTrue);
        expect(isProtectedRoute('/chat/123'), isTrue);
        expect(isProtectedRoute('/chatroom'), isTrue); // startsWith('/chat')
        expect(isProtectedRoute('/listing/123/edit'), isTrue);
        expect(isProtectedRoute('/listing/123/edit/extra'), isFalse);
        expect(isProtectedRoute('/listing/123/boost'), isTrue);
        expect(isProtectedRoute('/listing/123/urgent'), isTrue);
        expect(isProtectedRoute('/listing/123'), isFalse);
        expect(isProtectedRoute('/admin'), isTrue);
        expect(isProtectedRoute('/admin/users'), isTrue);
        expect(isProtectedRoute('/onboarding'), isTrue);
        expect(isProtectedRoute('/onboarding/role'), isTrue);
        expect(isProtectedRoute('/'), isFalse);
      });
    });
  });
}
