import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

/// Desktop Top Navigation Bar for Otelcim.
/// Replaces the bottom navigation bar on desktop/tablet screens.
class DesktopTopNavBar extends ConsumerWidget {
  const DesktopTopNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final authService = ref.watch(authServiceProvider);
    final isLoggedIn = authService.currentUser != null;

    final navItems = [
      _NavItemData(
        index: 0,
        label: 'Ana Sayfa',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItemData(
        index: 1,
        label: 'Kategoriler',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      _NavItemData(
        index: 2,
        label: 'İlan Ver',
        icon: Icons.add_circle_outline_rounded,
        activeIcon: Icons.add_circle_rounded,
      ),
      _NavItemData(
        index: 3,
        label: 'Mesajlar',
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      _NavItemData(
        index: 4,
        label: 'Hesabım',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    final backgroundColor = isDark ? const Color(0xFF172A3A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B3644) : const Color(0xFFE5E7EB);

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Brand Logo & Title
                InkWell(
                  onTap: () {
                    navigationShell.goBranch(
                      0,
                      initialLocation: navigationShell.currentIndex == 0,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withRed((primaryColor.red + 30).clamp(0, 255)),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.hotel_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OTELCİM',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Turizm & Otel İş İlanları',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // Center Nav Links
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: navItems.map((item) {
                      final isSelected = navigationShell.currentIndex == item.index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              navigationShell.goBranch(
                                item.index,
                                initialLocation: navigationShell.currentIndex == item.index,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: primaryColor.withOpacity(0.08),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: primaryColor.withOpacity(0.3),
                                        width: 1,
                                      )
                                    : Border.all(color: Colors.transparent, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right side quick actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorites shortcut button
                    IconButton(
                      tooltip: 'Favorilerim',
                      icon: Icon(
                        Icons.favorite_outline_rounded,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                      ),
                      onPressed: () => context.push('/favorites'),
                    ),
                    const SizedBox(width: 4),

                    // Post ad CTA button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!isLoggedIn) {
                          unawaited(context.push('/login'));
                        } else {
                          navigationShell.goBranch(
                            2,
                            initialLocation: navigationShell.currentIndex == 2,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'İlan Ver',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  _NavItemData({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
