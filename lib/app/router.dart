import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/onboarding_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/role_selection_screen.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/user_service.dart';

/// Provider for the app router instance
///
/// This provider creates and manages the GoRouter configuration
/// with authentication-aware redirects and onboarding flow logic.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Get auth state
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.value;

      // While auth is loading, stay on current route
      if (isLoading) {
        return null;
      }

      // User is not authenticated
      if (user == null) {
        // Allow access to auth routes (login, register)
        // For now, redirect to a placeholder login route
        // This will be implemented in a future task
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/register') {
          return null;
        }
        return '/login';
      }

      // User is authenticated - check onboarding status
      // We need to check if user has completed onboarding
      // This is done asynchronously, so we can't block here
      // Instead, we'll let the routes handle their own guards
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          // Placeholder for login screen
          // Will be implemented in a future task
          return const Scaffold(
            body: Center(
              child: Text('Login Screen - To be implemented'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          // Placeholder for register screen
          // Will be implemented in a future task
          return const Scaffold(
            body: Center(
              child: Text('Register Screen - To be implemented'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
          );
        },
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const RoleSelectionScreen(),
          );
        },
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const ProfileSetupScreen(),
          );
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const _HomeScreenGuard(),
          );
        },
      ),
    ],
  );
});

/// Home screen guard that checks onboarding status
///
/// This widget wraps the home screen and redirects to onboarding
/// if the user hasn't completed it yet. It uses Riverpod to watch
/// the user's profile and determine if onboarding is needed.
class _HomeScreenGuard extends ConsumerWidget {
  const _HomeScreenGuard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // If no user, this shouldn't happen due to redirect,
    // but handle it gracefully
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch user profile to check onboarding status
    final userProfileAsync = ref.watch(userProfileStreamProvider(user.uid));

    return userProfileAsync.when(
      data: (profile) {
        // If profile doesn't exist, redirect to onboarding
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/onboarding');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if onboarding is completed
        final onboardingCompleted =
            profile['onboardingCompleted'] as bool? ?? false;

        if (!onboardingCompleted) {
          // Redirect to onboarding
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/onboarding');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Onboarding completed, show home screen placeholder
        // This will be replaced with actual home screen implementation
        return _HomeScreenPlaceholder(
          displayName: profile['displayName'] as String? ?? 'User',
          role: profile['role'] as String?,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder home screen
///
/// Shows a simple welcome message based on user role.
/// Will be replaced with actual home screen implementation.
class _HomeScreenPlaceholder extends ConsumerWidget {
  final String displayName;
  final String? role;

  const _HomeScreenPlaceholder({
    required this.displayName,
    this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    String greeting;
    String subtitle;

    if (role == 'job_seeker') {
      greeting = 'Hoş geldin, $displayName!';
      subtitle = 'İş aramanıza hazırsınız';
    } else if (role == 'employer') {
      greeting = 'Hoş geldin, $displayName!';
      subtitle = 'Personel aramanıza hazırsınız';
    } else {
      greeting = 'Hoş geldin, $displayName!';
      subtitle = 'Otelcim\'e hoş geldiniz';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otelcim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılamadı: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role == 'job_seeker'
                    ? Icons.work_outline
                    : role == 'employer'
                        ? Icons.business_outlined
                        : Icons.person_outline,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                greeting,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                'Ana ekran yakında gelecek...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Global router instance for the app
///
/// Use this in MaterialApp.router's routerConfig parameter.
/// This allows the router to be used without Riverpod context.
final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        // Placeholder for login screen
        return const Scaffold(
          body: Center(
            child: Text('Login Screen - To be implemented'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        // Placeholder for register screen
        return const Scaffold(
          body: Center(
            child: Text('Register Screen - To be implemented'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        );
      },
    ),
    GoRoute(
      path: '/role-selection',
      name: 'role-selection',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
        );
      },
    ),
    GoRoute(
      path: '/profile-setup',
      name: 'profile-setup',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
        );
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) {
        // For now, return a simple placeholder
        // The _HomeScreenGuard will be used in the Riverpod-aware version
        return const Scaffold(
          body: Center(
            child: Text('Home Screen - Loading...'),
          ),
        );
      },
    ),
  ],
);

/// Provider for AuthService instance
///
/// This provider creates and manages the AuthService instance
/// for use throughout the app.
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(auth);
});
