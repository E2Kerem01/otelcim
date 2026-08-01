import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/chat/presentation/chat_detail_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/listings/presentation/create_listing_screen.dart';
import '../features/listings/presentation/listing_detail_screen.dart';
import '../features/listings/presentation/my_listings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/services/auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authService,
    redirect: (context, state) {
      final isLoggedIn = authService.currentUser != null;
      final loggingInPath = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final onSplash = state.matchedLocation == '/splash';

      if (!isLoggedIn) {
        return loggingInPath ? null : '/login';
      }
      if (isLoggedIn && loggingInPath) {
        return authService.consumeJustRegistered() ? '/onboarding' : '/';
      }
      if (isLoggedIn && onSplash) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/onboarding/role', builder: (context, state) => const RoleSelectionScreen()),
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
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/create-listing', builder: (context, state) => const CreateListingScreen())],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
        ],
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
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatDetailScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/my-listings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyListingsScreen(),
      ),
    ],
  );
});
