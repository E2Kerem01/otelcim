import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/ads/presentation/admin_banner_ads_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/audit_log_screen.dart';
import '../features/admin/presentation/reports_moderation_screen.dart';
import '../features/admin/presentation/verification_review_screen.dart';
import '../features/admin/services/admin_service.dart';
import '../features/boosts/presentation/boost_purchase_screen.dart';
import '../features/boosts/presentation/my_boosts_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/chat/presentation/chat_detail_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/discovery/presentation/regions_screen.dart';
import '../features/discovery/presentation/region_map_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/listings/presentation/batch_create_listing_screen.dart';
import '../features/listings/presentation/create_listing_screen.dart';
import '../features/listings/presentation/edit_listing_screen.dart';
import '../features/listings/presentation/listing_detail_screen.dart';
import '../features/listings/presentation/listing_qr_poster_screen.dart';
import '../features/listings/presentation/my_listings_screen.dart';
import '../features/nearby/presentation/nearby_listings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/admin/presentation/certificate_review_screen.dart';
import '../features/profile/presentation/certificates_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/notification_settings_screen.dart';
import '../features/profile/presentation/privacy_policy_screen.dart';
import '../features/profile/presentation/privacy_settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/talent_pool_screen.dart';
import '../features/profile/presentation/verification_request_screen.dart';
import '../features/ratings/presentation/submit_rating_screen.dart';
import '../features/seasonal/presentation/seasonal_calendar_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/services/auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final adminService = ref.watch(adminServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) async {
      final isLoggedIn = authService.currentUser != null;
      final location = state.matchedLocation;

      final isProtected =
          location == '/create-listing' ||
          location == '/batch-create-listing' ||
          location.startsWith('/chat') ||
          location.startsWith('/profile') ||
          location == '/my-listings' ||
          location == '/my-boosts' ||
          location == '/favorites' ||
          location.endsWith('/boost') ||
          location == '/onboarding' ||
          location.startsWith('/admin');

      if (!isLoggedIn && isProtected) {
        return '/login';
      }

      if (isLoggedIn && location.startsWith('/admin')) {
        final profile = await adminService.getUserProfile(
          authService.currentUser!.uid,
        );
        if (!adminService.isAdminProfile(profile)) return '/';
      }

      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Ana Sayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'Kategoriler',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  activeIcon: Icon(Icons.add_circle_rounded),
                  label: 'İlan Ver',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Mesajlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Hesabım',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create-listing',
                builder: (context, state) => const CreateListingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/regions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegionsScreen(),
      ),
      GoRoute(
        path: '/regions/map',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegionMapScreen(),
      ),
      GoRoute(
        path: '/regions/:regionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            HomeScreen(initialRegion: state.pathParameters['regionId']),
      ),
      GoRoute(
        path: '/nearby',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NearbyListingsScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/listing/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditListingScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/listing/:id/boost',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BoostPurchaseScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/listing/:id/qr-poster',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingQrPosterScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId/rate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return SubmitRatingScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatDetailScreen(
            conversationId: conversationId,
            initialText: state.extra as String?,
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/batch-create-listing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BatchCreateListingScreen(),
      ),
      GoRoute(
        path: '/my-boosts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyBoostsScreen(),
      ),
      GoRoute(
        path: '/seasonal-calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SeasonalCalendarScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/certificates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/profile/talent-pool',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TalentPoolScreen(),
      ),
      GoRoute(
        path: '/profile/verification',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VerificationRequestScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy/policy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsModerationScreen(),
      ),
      GoRoute(
        path: '/admin/verifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VerificationReviewScreen(),
      ),
      GoRoute(
        path: '/admin/certificates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CertificateReviewScreen(),
      ),
      GoRoute(
        path: '/admin/audit-log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/admin/banners',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminBannerAdsScreen(),
      ),
    ],
  );
});
