import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';

/// Desktop navigation for the shell and for pages pushed on the root
/// navigator. [navigationShell] remains optional for existing shell callers.
class DesktopTopNavBar extends ConsumerWidget {
  const DesktopTopNavBar({
    super.key,
    this.navigationShell,
  });

  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.watch(authServiceProvider);
    final isLoggedIn = authService.currentUser != null;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isEmployer = profile?.userType == 'employer';
    final location = _currentLocation(context);
    final selectedPath = _selectedPath(location, navigationShell);

    final navItems = <_NavItemData>[
      _NavItemData(
        path: '/',
        label: l10n.navHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        branchIndex: 0,
      ),
      if (!isLoggedIn || !isEmployer)
        _NavItemData(
          path: '/categories',
          label: l10n.navCategories,
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          branchIndex: 1,
        ),
      if (isLoggedIn && isEmployer) ...[
        _NavItemData(
          path: '/my-listings',
          label: l10n.myListings,
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
        ),
        _NavItemData(
          path: '/profile/talent-pool',
          label: l10n.talentPoolTitle,
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
        _NavItemData(
          path: '/chat',
          label: l10n.navMessages,
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          branchIndex: 3,
        ),
      ],
      if (isLoggedIn && !isEmployer) ...[
        _NavItemData(
          path: '/favorites',
          label: l10n.desktopNavFavorites,
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
        ),
        _NavItemData(
          path: '/chat',
          label: l10n.navMessages,
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          branchIndex: 3,
        ),
      ],
    ];

    return Material(
      color: AppColors.surfaceLight,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight),
            ),
            boxShadow: AppElevation.softShadow,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _BrandButton(
                      label: l10n.appName,
                      onPressed: () => _navigate(context, '/', 0),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in navItems)
                              _NavButton(
                                item: item,
                                selected: selectedPath == item.path,
                                onPressed: () =>
                                    _navigate(context, item.path, item.branchIndex),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (!isLoggedIn)
                      _LoggedOutActions(
                        loginLabel: l10n.loginButton,
                        registerLabel: l10n.registerButton,
                        onLogin: () => context.go('/login'),
                        onRegister: () => context.go('/register'),
                      )
                    else
                      _LoggedInActions(
                        showCreateListing: isEmployer,
                        createListingLabel: l10n.navCreateListing,
                        profileLabel: l10n.desktopNavProfile,
                        settingsLabel: l10n.desktopNavSettings,
                        languageLabel: l10n.desktopNavLanguage,
                        signOutLabel: l10n.signOut,
                        displayName: profile?.displayName,
                        photoUrl: profile?.photoUrl,
                        onCreateListing: () =>
                            _navigate(context, '/create-listing', 2),
                        onMenuSelected: (action) =>
                            _handleProfileAction(context, ref, action),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String path, int? branchIndex) {
    final shell = navigationShell;
    if (shell != null && branchIndex != null) {
      shell.goBranch(
        branchIndex,
        initialLocation: shell.currentIndex == branchIndex,
      );
      return;
    }
    context.go(path);
  }

  Future<void> _handleProfileAction(
    BuildContext context,
    WidgetRef ref,
    _ProfileMenuAction action,
  ) async {
    switch (action) {
      case _ProfileMenuAction.profile:
        context.go('/profile');
      case _ProfileMenuAction.settings:
        context.go('/profile/edit');
      case _ProfileMenuAction.language:
        context.go('/profile/language');
      case _ProfileMenuAction.signOut:
        final shouldSignOut = await confirmSignOut(context);
        if (!context.mounted || shouldSignOut != true) return;
        await ref.read(authServiceProvider).signOut();
        ref.invalidate(currentUserProfileProvider);
    }
  }
}

String _currentLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return '/';
  }
}

String _selectedPath(
  String location,
  StatefulNavigationShell? navigationShell,
) {
  if (navigationShell != null) {
    switch (navigationShell.currentIndex) {
      case 1:
        return '/categories';
      case 2:
        return '/create-listing';
      case 3:
        return '/chat';
      case 4:
        return '/profile';
    }
  }

  if (location == '/') return '/';
  if (location.startsWith('/chat')) return '/chat';
  if (location.startsWith('/profile/talent-pool')) {
    return '/profile/talent-pool';
  }
  if (location.startsWith('/profile')) return '/profile';
  if (location.startsWith('/my-listings')) return '/my-listings';
  if (location.startsWith('/categories')) return '/categories';
  if (location.startsWith('/favorites')) return '/favorites';
  if (location.startsWith('/create-listing')) return '/create-listing';
  return '';
}

class _BrandButton extends StatelessWidget {
  const _BrandButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.card_travel_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: AppTypography.titleLargeSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          selected ? item.activeIcon : item.icon,
          size: 19,
        ),
        label: Text(item.label),
        style: TextButton.styleFrom(
          foregroundColor: selected ? primary : AppColors.textSecondaryLight,
          backgroundColor: selected ? AppColors.primaryContainer : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: TextStyle(
            fontSize: AppTypography.bodyLargeSize,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LoggedOutActions extends StatelessWidget {
  const _LoggedOutActions({
    required this.loginLabel,
    required this.registerLabel,
    required this.onLogin,
    required this.onRegister,
  });

  final String loginLabel;
  final String registerLabel;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onLogin, child: Text(loginLabel)),
        const SizedBox(width: AppSpacing.xs),
        FilledButton(onPressed: onRegister, child: Text(registerLabel)),
      ],
    );
  }
}

class _LoggedInActions extends StatelessWidget {
  const _LoggedInActions({
    required this.showCreateListing,
    required this.createListingLabel,
    required this.profileLabel,
    required this.settingsLabel,
    required this.languageLabel,
    required this.signOutLabel,
    required this.displayName,
    required this.photoUrl,
    required this.onCreateListing,
    required this.onMenuSelected,
  });

  final bool showCreateListing;
  final String createListingLabel;
  final String profileLabel;
  final String settingsLabel;
  final String languageLabel;
  final String signOutLabel;
  final String? displayName;
  final String? photoUrl;
  final VoidCallback onCreateListing;
  final ValueChanged<_ProfileMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final initial = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()[0].toUpperCase()
        : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCreateListing) ...[
          FilledButton.icon(
            onPressed: onCreateListing,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(createListingLabel),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        PopupMenuButton<_ProfileMenuAction>(
          tooltip: profileLabel,
          onSelected: onMenuSelected,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _ProfileMenuAction.profile,
              child: Text(profileLabel),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.settings,
              child: Text(settingsLabel),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.language,
              child: Text(languageLabel),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.signOut,
              child: Text(signOutLabel),
            ),
          ],
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: photoUrl?.isNotEmpty == true
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl?.isNotEmpty == true
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

enum _ProfileMenuAction { profile, settings, language, signOut }

class _NavItemData {
  const _NavItemData({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.branchIndex,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? branchIndex;
}
