import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/video_player_dialog.dart';
import '../../admin/services/admin_service.dart';
import '../../boosts/presentation/my_boosts_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../listings/presentation/my_listings_screen.dart';
import '../../ratings/domain/rating_model.dart';
import '../../ratings/services/rating_service.dart';
import '../domain/certificate_model.dart';
import '../services/certificate_service.dart';
import 'certificates_screen.dart';
import 'edit_profile_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import '../../referrals/presentation/invite_friends_screen.dart';
import 'talent_pool_screen.dart';
import 'widgets/profile_screen_widgets.dart';

Future<bool?> confirmSignOut(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.signOut),
      content: Text(l10n.profileSignOutConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.signOut),
        ),
      ],
    ),
  );
}

/// Screen for user profile management.
/// Supports responsive Master-Detail layout for Desktop/Tablet wide screens (>= 768px).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedSection = 'overview';

  Future<void> _handleLogout() async {
    final shouldLogout = await confirmSignOut(context);
    if (!mounted || shouldLogout != true) return;
    await ref.read(authServiceProvider).signOut();
    ref.invalidate(currentUserProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    final email = user?.email ?? '';
    // .valueOrNull, not .value: an AsyncError's .value getter rethrows the
    // error synchronously from build(), which would take down the whole
    // account screen (blank/grey in release mode) on any transient profile
    // stream failure instead of just rendering with profile == null.
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final adminService = ref.watch(adminServiceProvider);
    final isAdmin = adminService.isAdminProfile(profile);
    final displayName = profile?.displayName;
    final photoUrl = profile?.photoUrl;
    final ratings = user == null ? null : ref.watch(userRatingsProvider(user.uid));
    final approvedCerts = user == null ? null : ref.watch(userApprovedCertificatesProvider(user.uid)).valueOrNull;
    final initial = (displayName?.isNotEmpty ?? false)
        ? displayName![0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                // Desktop Master Navigation Sidebar
                SizedBox(
                  width: 320,
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // User Profile Header Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              ProfileAvatar(
                                photoUrl: photoUrl,
                                initial: initial,
                                radius: 28,
                                fontSize: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName?.isNotEmpty == true ? displayName! : (email.isNotEmpty ? email : l10n.profileUserFallback),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: profile?.userType == 'employer'
                                            ? Colors.indigo.shade50
                                            : Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        profile?.userType == 'employer' ? l10n.profileEmployerRole : l10n.profileJobSeekerRole,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: profile?.userType == 'employer'
                                              ? Colors.indigo.shade800
                                              : Colors.teal.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Master Navigation Menu Options
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            children: [
                              if (isAdmin)
                                ProfileSidebarItem(
                                  icon: Icons.admin_panel_settings_outlined,
                                  title: AppLocalizations.of(context)!.adminPanelEntry,
                                  subtitle: l10n.profileAdminSubtitle,
                                  isSelected: false,
                                  onTap: () => context.push('/admin'),
                                ),
                              ProfileSidebarItem(
                                icon: Icons.grid_view_rounded,
                                title: l10n.profileOverviewTitle,
                                subtitle: l10n.profileOverviewSubtitle,
                                isSelected: _selectedSection == 'overview',
                                onTap: () => setState(() => _selectedSection = 'overview'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.edit_outlined,
                                title: l10n.editProfile,
                                subtitle: l10n.profileEditSubtitle,
                                isSelected: _selectedSection == 'edit',
                                onTap: () => setState(() => _selectedSection = 'edit'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.verified_outlined,
                                title: l10n.profileCertificatesTitle,
                                subtitle: l10n.profileCertificatesSubtitle,
                                badgeCount: approvedCerts?.length,
                                isSelected: _selectedSection == 'certificates',
                                onTap: () => setState(() => _selectedSection = 'certificates'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.favorite_outline_rounded,
                                title: l10n.profileFavoritesTitle,
                                subtitle: l10n.profileFavoritesSubtitle,
                                isSelected: _selectedSection == 'favorites',
                                onTap: () => setState(() => _selectedSection = 'favorites'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.list_alt_rounded,
                                title: l10n.myListings,
                                subtitle: l10n.profileListingsSubtitle,
                                isSelected: _selectedSection == 'my_listings',
                                onTap: () => setState(() => _selectedSection = 'my_listings'),
                              ),
                              if (profile?.userType == 'employer')
                                ProfileSidebarItem(
                                  icon: Icons.folder_shared_outlined,
                                  title: l10n.talentPoolMyPool,
                                  subtitle: l10n.talentPoolSubtitle,
                                  isSelected: _selectedSection == 'talent_pool',
                                  onTap: () => setState(() => _selectedSection = 'talent_pool'),
                                ),
                              ProfileSidebarItem(
                                icon: Icons.rocket_launch_rounded,
                                title: l10n.profileBoostsTitle,
                                subtitle: l10n.profileBoostsSubtitle,
                                isSelected: _selectedSection == 'boosts',
                                onTap: () => setState(() => _selectedSection = 'boosts'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.notifications_outlined,
                                title: l10n.profileNotificationsTitle,
                                subtitle: l10n.profileNotificationsSubtitle,
                                isSelected: _selectedSection == 'notifications',
                                onTap: () => setState(() => _selectedSection = 'notifications'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.security_rounded,
                                title: l10n.profilePrivacyTitle,
                                subtitle: l10n.profilePrivacySubtitle,
                                isSelected: _selectedSection == 'privacy',
                                onTap: () => setState(() => _selectedSection = 'privacy'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.card_giftcard_rounded,
                                title: l10n.inviteFriendsTitle,
                                subtitle: l10n.profileInviteSubtitle,
                                isSelected: _selectedSection == 'invite',
                                onTap: () => setState(() => _selectedSection = 'invite'),
                              ),
                              ProfileSidebarItem(
                                icon: Icons.language_rounded,
                                title: l10n.languageSettingsTitle,
                                subtitle: l10n.profileLanguageSubtitle,
                                isSelected: _selectedSection == 'language',
                                onTap: () => setState(() => _selectedSection = 'language'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Sidebar Footer: Sign out
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _handleLogout,
                                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                                label: Text(l10n.signOut, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Desktop Detail Area
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: _buildDetailContent(
                      _selectedSection,
                      context,
                      ref,
                      profile,
                      email,
                      displayName,
                      photoUrl,
                      initial,
                      ratings,
                      approvedCerts,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Single Column Layout
        return Scaffold(
          appBar: AppBar(title: Text(l10n.profileTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        photoUrl: photoUrl,
                        initial: initial,
                        radius: 30,
                        fontSize: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName?.isNotEmpty == true ? displayName! : email,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (displayName?.isNotEmpty == true)
                              Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            if (profile?.userType != 'employer') ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (profile?.availableImmediately ?? false) ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (profile?.availableImmediately ?? false) ? Colors.green.shade300 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 14,
                                      color: (profile?.availableImmediately ?? false) ? Colors.green.shade700 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (profile?.availableImmediately ?? false)
                                          ? l10n.availableImmediatelyBadge
                                          : l10n.notAvailableBadge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: (profile?.availableImmediately ?? false) ? Colors.green.shade800 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (approvedCerts != null && approvedCerts.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: approvedCerts.map((cert) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 12, color: Colors.blue.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          cert.title ?? certificateTypeLabel(l10n, cert.type),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (profile?.introVideoUrl != null && profile!.introVideoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: Colors.blue.shade50.withValues(alpha: 0.4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.play_arrow_rounded, color: Colors.blue.shade800),
                      ),
                      title: Text(l10n.introVideoTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(l10n.profileIntroVideoSubtitle),
                      trailing: OutlinedButton.icon(
                        onPressed: () => VideoPlayerDialog.show(context, videoUrl: profile.introVideoUrl!),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                        label: Text(l10n.watchIntroVideo),
                      ),
                    ),
                  ),
                ),
              if (ratings != null)
                ratings.when(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    final average = items.fold<int>(
                          0,
                          (total, rating) => total + rating.stars,
                        ) /
                        items.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Card(
                        child: ListTile(
                          leading: Icon(Icons.star_rounded, color: Colors.amber.shade700),
                          title: Text(
                            '${average.toStringAsFixed(1)} / 5',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(l10n.profileRatingsCount(items.length)),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 20),
              if (isAdmin) ...[
                const AdminPanelMenuTile(),
                const SizedBox(height: 12),
              ],
              ProfileMenuTile(
                icon: Icons.edit_outlined,
                title: l10n.editProfile,
                onTap: () => context.push('/profile/edit'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.verified_outlined,
                iconColor: Colors.blue,
                title: l10n.profileCertificatesTitle,
                subtitle: l10n.profileCertificatesSubtitle,
                onTap: () => context.push('/profile/certificates'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.favorite_outline_rounded,
                title: l10n.profileFavoritesTitle,
                onTap: () => context.push('/favorites'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.list_alt_rounded,
                title: l10n.myListings,
                onTap: () => context.push('/my-listings'),
              ),
              if (profile?.userType == 'employer') ...[
                const SizedBox(height: 12),
                ProfileMenuTile(
                  icon: Icons.folder_shared_outlined,
                  iconColor: Colors.indigo,
                  title: l10n.talentPoolMyPool,
                  subtitle: l10n.talentPoolSubtitle,
                  onTap: () => context.push('/profile/talent-pool'),
                ),
              ],
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.rocket_launch_rounded,
                iconColor: Colors.amber.shade800,
                title: l10n.profileBoostsTitle,
                onTap: () => context.push('/my-boosts'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.notifications_outlined,
                title: l10n.profileNotificationsTitle,
                subtitle: l10n.profileNotificationsSubtitle,
                onTap: () => context.push('/profile/notifications'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.security_rounded,
                title: l10n.profilePrivacyTitle,
                subtitle: l10n.profilePrivacySubtitle,
                onTap: () => context.push('/profile/privacy'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.card_giftcard_rounded,
                iconColor: Theme.of(context).primaryColor,
                title: l10n.inviteFriendsTitle,
                subtitle: l10n.profileInviteSubtitle,
                onTap: () => context.push('/profile/invite'),
              ),
              const SizedBox(height: 12),
              ProfileMenuTile(
                icon: Icons.language_rounded,
                title: l10n.languageSettingsTitle,
                subtitle: l10n.profileLanguageSubtitle,
                onTap: () => context.push('/profile/language'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the detail panel content based on the selected menu section.
  Widget _buildDetailContent(
    String section,
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    String email,
    String? displayName,
    String? photoUrl,
    String initial,
    AsyncValue<List<Rating>>? ratings,
    List<Certificate>? approvedCerts,
  ) {
    switch (section) {
      case 'edit':
        return const EditProfileScreen();
      case 'certificates':
        return const CertificatesScreen();
      case 'favorites':
        return const FavoritesScreen();
      case 'my_listings':
        return const MyListingsScreen();
      case 'talent_pool':
        return const TalentPoolScreen();
      case 'boosts':
        return const MyBoostsScreen();
      case 'notifications':
        return const NotificationSettingsScreen();
      case 'privacy':
        return const PrivacySettingsScreen();
      case 'invite':
        return const InviteFriendsScreen();
      case 'language':
        return const LanguageSettingsScreen();
      case 'overview':
      default:
        return _buildOverviewDetail(
          context,
          ref,
          profile,
          email,
          displayName,
          photoUrl,
          initial,
          ratings,
          approvedCerts,
        );
  }
}

  /// Desktop Overview Detail panel content
  Widget _buildOverviewDetail(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    String email,
    String? displayName,
    String? photoUrl,
    String initial,
    AsyncValue<List<Rating>>? ratings,
    List<Certificate>? approvedCerts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileOverviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editProfile,
            onPressed: () {
              setState(() {
                _selectedSection = 'edit';
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Banner Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileAvatar(
                    photoUrl: photoUrl,
                    initial: initial,
                    radius: 44,
                    fontSize: 36,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName?.isNotEmpty == true ? displayName! : (email.isNotEmpty ? email : l10n.profileUserFallback),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: profile?.userType == 'employer'
                                    ? Colors.indigo.shade50
                                    : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: profile?.userType == 'employer'
                                      ? Colors.indigo.shade200
                                      : Colors.teal.shade200,
                                ),
                              ),
                              child: Text(
                                profile?.userType == 'employer' ? l10n.profileEmployerLabel : l10n.profileJobSeekerLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: profile?.userType == 'employer'
                                      ? Colors.indigo.shade800
                                      : Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                        if (profile?.phoneNumber != null && profile!.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(profile.phoneNumber!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                            ],
                          ),
                        ],
                        if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            profile.bio!,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (profile?.userType != 'employer')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (profile?.availableImmediately ?? false) ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (profile?.availableImmediately ?? false) ? Colors.green.shade300 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 16,
                                      color: (profile?.availableImmediately ?? false) ? Colors.green.shade700 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      (profile?.availableImmediately ?? false)
                                          ? l10n.availableImmediatelyBadge
                                          : l10n.notAvailableBadge,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (profile?.availableImmediately ?? false) ? Colors.green.shade800 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (approvedCerts != null && approvedCerts.isNotEmpty)
                              ...approvedCerts.map((cert) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 14, color: Colors.blue.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        cert.title ?? certificateTypeLabel(l10n, cert.type),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Intro Video Card (If available)
          if (profile?.introVideoUrl != null && profile!.introVideoUrl!.isNotEmpty) ...[
            Card(
              color: Colors.blue.shade50.withAlpha(100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.blue.shade800, size: 28),
                ),
                title: Text(l10n.profileIntroVideoUploadedTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(l10n.profileIntroVideoUploadedSubtitle),
                trailing: FilledButton.icon(
                  onPressed: () => VideoPlayerDialog.show(context, videoUrl: profile.introVideoUrl!),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                  label: Text(l10n.watchIntroVideo),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Section Shortcut Grid Cards
          Text(l10n.profileQuickAccessTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              ProfileShortcutCard(
                icon: Icons.edit_outlined,
                color: Colors.purple,
                title: l10n.editProfile,
                subtitle: l10n.profileShortcutEditSubtitle,
                onTap: () => setState(() => _selectedSection = 'edit'),
              ),
              ProfileShortcutCard(
                icon: Icons.verified_outlined,
                color: Colors.blue,
                title: l10n.profileCertificatesTitle,
                subtitle: l10n.profileApprovedCertificateCount(approvedCerts?.length ?? 0),
                onTap: () => setState(() => _selectedSection = 'certificates'),
              ),
              ProfileShortcutCard(
                icon: Icons.list_alt_rounded,
                color: Colors.teal,
                title: l10n.myListings,
                subtitle: l10n.profileListingsShortcutSubtitle,
                onTap: () => setState(() => _selectedSection = 'my_listings'),
              ),
              ProfileShortcutCard(
                icon: Icons.favorite_outline_rounded,
                color: Colors.red,
                title: l10n.profileFavoritesTitle,
                subtitle: l10n.profileFavoritesShortcutSubtitle,
                onTap: () => setState(() => _selectedSection = 'favorites'),
              ),
              ProfileShortcutCard(
                icon: Icons.notifications_outlined,
                color: Colors.amber.shade900,
                title: l10n.profileNotificationsTitle,
                subtitle: l10n.profileNotificationsShortcutSubtitle,
                onTap: () => setState(() => _selectedSection = 'notifications'),
              ),
              ProfileShortcutCard(
                icon: Icons.security_rounded,
                color: Colors.indigo,
                title: l10n.profilePrivacyShortcutTitle,
                subtitle: l10n.profilePrivacyShortcutSubtitle,
                onTap: () => setState(() => _selectedSection = 'privacy'),
              ),
              ProfileShortcutCard(
                icon: Icons.card_giftcard_rounded,
                color: Colors.pink,
                title: l10n.inviteFriendsTitle,
                subtitle: l10n.profileInviteSubtitle,
                onTap: () => setState(() => _selectedSection = 'invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// Entry to the admin panel, shown in "Hesabım" to admins only (D1): without
/// it an admin on mobile has no way to reach /admin.
class AdminPanelMenuTile extends StatelessWidget {
  const AdminPanelMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileMenuTile(
      icon: Icons.admin_panel_settings_outlined,
      title: AppLocalizations.of(context)!.adminPanelEntry,
      onTap: () => context.push('/admin'),
    );
  }
}
