import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/listings/screens/edit_listing_screen.dart';

/// GoRouter configuration for the Otelcim app.
///
/// This router handles all navigation and route management throughout the app.
/// It includes authentication-aware routing and redirects.
///
/// Routes:
/// - `/` - Home screen (placeholder)
/// - `/listings/:id/edit` - Edit listing screen (requires authentication)
final GoRouter router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    // Get current user authentication state
    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = user != null;

    // Define protected routes that require authentication
    final isEditListingRoute = state.matchedLocation.startsWith('/listings/') &&
        state.matchedLocation.endsWith('/edit');

    // Redirect to home if trying to access protected route without authentication
    if (!isAuthenticated && isEditListingRoute) {
      return '/';
    }

    // No redirect needed
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/listings/:id/edit',
      name: 'edit-listing',
      builder: (context, state) {
        final listingId = state.pathParameters['id'];

        // Validate that listingId is provided
        if (listingId == null || listingId.isEmpty) {
          return const ErrorScreen(
            message: 'İlan ID\'si bulunamadı',
          );
        }

        return EditListingScreen(listingId: listingId);
      },
    ),
  ],
  errorBuilder: (context, state) => ErrorScreen(
    message: state.error?.toString() ?? 'Sayfa bulunamadı',
  ),
);

/// Placeholder home screen for the app.
///
/// This is a temporary screen that will be replaced with the actual
/// home/feed screen in future implementations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otelcim'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Hoş Geldiniz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user != null
                  ? 'Oturum açık: ${user.email ?? user.uid}'
                  : 'Oturum açılmadı',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ana sayfa yakında eklenecek',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen displayed when routing errors occur.
///
/// Shows a user-friendly error message and provides a button to return home.
class ErrorScreen extends StatelessWidget {
  /// The error message to display
  final String message;

  const ErrorScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hata'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
