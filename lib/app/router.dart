import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/ads/presentation/admin_banner_ads_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/audit_log_screen.dart';
import '../features/admin/presentation/reports_moderation_screen.dart';
import '../features/admin/presentation/listing_management_screen.dart';
import '../features/admin/presentation/user_management_screen.dart';
import '../features/admin/presentation/verification_review_screen.dart';
import '../features/admin/services/admin_service.dart';
import '../features/auth/presentation/account_suspended_screen.dart';
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
import '../features/referrals/presentation/invite_friends_screen.dart';
import '../features/profile/presentation/talent_pool_screen.dart';
import '../features/profile/presentation/verification_request_screen.dart';
import '../features/ratings/presentation/submit_rating_screen.dart';
import '../features/seasonal/presentation/seasonal_calendar_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/services/auth_service.dart';
import '../shared/widgets/desktop_top_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

Page<T> buildAppPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final wrappedChild = PopScope(
    canPop: true,
    onPopInvokedWithResult: (didPop, result) {
      // PopScope guarantees pop event capture and router state synchronization
    },
    child: child,
  );

  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoPage<T>(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: state.pathParameters,
      child: wrappedChild,
    );
  }
  return MaterialPage<T>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: state.pathParameters,
    child: wrappedChild,
  );
}

bool isProtectedRoute(String location) {
  final segments = Uri.parse(location).pathSegments;
  final isListingEditRoute =
      segments.length == 3 &&
      segments.first == 'listing' &&
      segments.last == 'edit';

  return location == '/create-listing' ||
      location == '/batch-create-listing' ||
      location.startsWith('/chat') ||
      location.startsWith('/profile') ||
      location == '/my-listings' ||
      location == '/my-boosts' ||
      location == '/favorites' ||
      location.endsWith('/boost') ||
      location.startsWith('/onboarding') ||
      location.startsWith('/admin') ||
      isListingEditRoute;
}

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

      if (!isLoggedIn && isProtectedRoute(location)) {
        return '/login';
      }

      if (isLoggedIn && location != '/account-suspended') {
        final profile = await adminService.getUserProfile(
          authService.currentUser!.uid,
        );

        final suspensionActive =
            profile != null &&
            profile.isSuspended &&
            (profile.suspensionEnd == null ||
                profile.suspensionEnd!.isAfter(DateTime.now()));
        if (profile != null && (profile.isBanned || suspensionActive)) {
          return '/account-suspended';
        }

        if (location.startsWith('/admin') &&
            !adminService.isAdminProfile(profile)) {
          return '/';
        }
      }

      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/account-suspended',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const AccountSuspendedScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/role',
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const RoleSelectionScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final isDesktop = MediaQuery.sizeOf(context).width >= 768;

          return Scaffold(
            body: Column(
              children: [
                if (isDesktop)
                  DesktopTopNavBar(
                    navigationShell: navigationShell,
                  ),
                Expanded(
                  child: navigationShell,
                ),
              ],
            ),
            bottomNavigationBar: isDesktop
                ? null
                : BottomNavigationBar(
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
                pageBuilder: (context, state) => buildAppPage(
                  context: context,
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                pageBuilder: (context, state) => buildAppPage(
                  context: context,
                  state: state,
                  child: const CategoriesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create-listing',
                pageBuilder: (context, state) => buildAppPage(
                  context: context,
                  state: state,
                  child: const CreateListingScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                pageBuilder: (context, state) => buildAppPage(
                  context: context,
                  state: state,
                  child: const ChatListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => buildAppPage(
                  context: context,
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/regions',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const RegionsScreen(),
        ),
      ),
      GoRoute(
        path: '/regions/map',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const RegionMapScreen(),
        ),
      ),
      GoRoute(
        path: '/regions/:regionId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: HomeScreen(initialRegion: state.pathParameters['regionId']),
        ),
      ),
      GoRoute(
        path: '/nearby',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const NearbyListingsScreen(),
        ),
      ),
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return buildAppPage(
            context: context,
            state: state,
            child: ListingDetailScreen(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/listing/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return buildAppPage(
            context: context,
            state: state,
            child: EditListingScreen(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/listing/:id/boost',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return buildAppPage(
            context: context,
            state: state,
            child: BoostPurchaseScreen(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/listing/:id/qr-poster',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return buildAppPage(
            context: context,
            state: state,
            child: ListingQrPosterScreen(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/chat/:conversationId/rate',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return buildAppPage(
            context: context,
            state: state,
            child: SubmitRatingScreen(conversationId: conversationId),
          );
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return buildAppPage(
            context: context,
            state: state,
            child: ChatDetailScreen(
              conversationId: conversationId,
              initialText: state.extra as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: '/my-listings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const MyListingsScreen(),
        ),
      ),
      GoRoute(
        path: '/batch-create-listing',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const BatchCreateListingScreen(),
        ),
      ),
      GoRoute(
        path: '/my-boosts',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const MyBoostsScreen(),
        ),
      ),
      GoRoute(
        path: '/seasonal-calendar',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const SeasonalCalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/certificates',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const CertificatesScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/talent-pool',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const TalentPoolScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/verification',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const VerificationRequestScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/invite',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const InviteFriendsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const PrivacySettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/privacy/policy',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const ReportsModerationScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const UserManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/listings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const ListingManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/verifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const VerificationReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/certificates',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const CertificateReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/audit-log',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const AuditLogScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/banners',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildAppPage(
          context: context,
          state: state,
          child: const AdminBannerAdsScreen(),
        ),
      ),
    ],
  );
});
