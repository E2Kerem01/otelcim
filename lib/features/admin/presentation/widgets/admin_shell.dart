import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';

/// Light/dark switch for the admin area only (the public app has no dark
/// theme yet - see QA D27).
final adminThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final _adminDarkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: otelcimBlue,
    brightness: Brightness.dark,
  ),
);

class _AdminDestination {
  const _AdminDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

const _destinations = <_AdminDestination>[
  _AdminDestination('/admin', 'Genel Bakış', Icons.dashboard_outlined),
  _AdminDestination('/admin/reports', 'Şikâyetler', Icons.report_problem_outlined),
  _AdminDestination('/admin/users', 'Kullanıcılar', Icons.people_alt_outlined),
  _AdminDestination('/admin/listings', 'İlanlar', Icons.list_alt_outlined),
  _AdminDestination('/admin/verifications', 'Doğrulamalar', Icons.verified_user_outlined),
  _AdminDestination('/admin/certificates', 'Belgeler', Icons.card_membership_outlined),
  _AdminDestination('/admin/banners', 'Bannerlar', Icons.campaign_outlined),
  _AdminDestination('/admin/audit-log', 'İşlem Geçmişi', Icons.history_rounded),
];

/// Frame around every /admin route (a go_router ShellRoute). On wide screens
/// it adds a persistent side menu so admins can jump between sections; on
/// phones it leaves the screen as is (dashboard cards + back navigation).
/// It also applies the admin-only light/dark theme.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  static const double sideMenuBreakpoint = 900;

  final String location;
  final Widget child;

  int get _selectedIndex {
    // Longest matching prefix, so /admin/users/... selects "Kullanıcılar".
    var best = 0;
    for (var i = 1; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(adminThemeModeProvider);
    final theme = mode == ThemeMode.dark ? _adminDarkTheme : Theme.of(context);
    return Theme(
      data: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < sideMenuBreakpoint) return child;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1200,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => context.go(_destinations[i].path),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Icon(Icons.admin_panel_settings_outlined, size: 32),
                  ),
                  trailing: const Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AdminThemeToggle(),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Icon button that flips the admin theme; used in the side menu and in the
/// dashboard app bar on phones.
class AdminThemeToggle extends ConsumerWidget {
  const AdminThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(adminThemeModeProvider) == ThemeMode.dark;
    return IconButton(
      tooltip: dark ? 'Açık tema' : 'Koyu tema',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(adminThemeModeProvider.notifier).state =
          dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
