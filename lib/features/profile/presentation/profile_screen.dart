import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/video_player_dialog.dart';
import '../../boosts/presentation/my_boosts_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../listings/presentation/my_listings_screen.dart';
import '../../ratings/services/rating_service.dart';
import '../services/certificate_service.dart';
import 'certificates_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'talent_pool_screen.dart';

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
    await ref.read(authServiceProvider).signOut();
    ref.invalidate(currentUserProfileProvider);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    final profile = ref.watch(currentUserProfileProvider).value;
    final displayName = profile?.displayName;
    final photoUrl = profile?.photoUrl;
    final themeMode = ref.watch(themeModeProvider);
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
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName?.isNotEmpty == true ? displayName! : (email.isNotEmpty ? email : 'Kullanıcı'),
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
                                        profile?.userType == 'employer' ? 'İşveren' : 'İş Arayan',
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
                              _buildSidebarItem(
                                id: 'overview',
                                icon: Icons.grid_view_rounded,
                                title: 'Genel Bakış',
                                subtitle: 'Profil özeti ve istatistikler',
                              ),
                              _buildSidebarItem(
                                id: 'edit',
                                icon: Icons.edit_outlined,
                                title: 'Profili Düzenle',
                                subtitle: 'Kişisel bilgiler, fotoğraf ve cv',
                              ),
                              _buildSidebarItem(
                                id: 'certificates',
                                icon: Icons.verified_outlined,
                                title: 'Belgelerim / Sertifika Cüzdanı',
                                subtitle: 'Hijyen, ehliyet, sertifika yönetimi',
                                badgeCount: approvedCerts?.length,
                              ),
                              _buildSidebarItem(
                                id: 'favorites',
                                icon: Icons.favorite_outline_rounded,
                                title: 'Favorilerim',
                                subtitle: 'Kaydedilen ilanlar',
                              ),
                              _buildSidebarItem(
                                id: 'my_listings',
                                icon: Icons.list_alt_rounded,
                                title: 'İlanlarım',
                                subtitle: 'Yayındaki ve pasif ilanlar',
                              ),
                              if (profile?.userType == 'employer')
                                _buildSidebarItem(
                                  id: 'talent_pool',
                                  icon: Icons.folder_shared_outlined,
                                  title: 'Yetenek Havuzum',
                                  subtitle: 'Aday listesi ve notlar',
                                ),
                              _buildSidebarItem(
                                id: 'boosts',
                                icon: Icons.rocket_launch_rounded,
                                title: 'Öne Çıkarılan İlanlarım',
                                subtitle: 'Doping ve öne çıkarma paketleri',
                              ),
                              _buildSidebarItem(
                                id: 'notifications',
                                icon: Icons.notifications_outlined,
                                title: 'Bildirim Ayarları',
                                subtitle: 'Sohbet ve duyuru tercihleri',
                              ),
                              _buildSidebarItem(
                                id: 'privacy',
                                icon: Icons.security_rounded,
                                title: 'Gizlilik ve Veri Ayarları',
                                subtitle: 'KVKK ve hesap ayarları',
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Sidebar Footer: Theme Switcher & Sign out
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.palette_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Görünüm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  SizedBox(
                                    height: 32,
                                    child: SegmentedButton<ThemeMode>(
                                      segments: const [
                                        ButtonSegment(
                                          value: ThemeMode.light,
                                          icon: Icon(Icons.light_mode, size: 14),
                                        ),
                                        ButtonSegment(
                                          value: ThemeMode.dark,
                                          icon: Icon(Icons.dark_mode, size: 14),
                                        ),
                                        ButtonSegment(
                                          value: ThemeMode.system,
                                          icon: Icon(Icons.settings_suggest, size: 14),
                                        ),
                                      ],
                                      selected: {themeMode},
                                      showSelectedIcon: false,
                                      onSelectionChanged: (selection) {
                                        ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _handleLogout,
                                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontSize: 13)),
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
          appBar: AppBar(title: const Text('Hesabım')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                initial,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : null,
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
                                      (profile?.availableImmediately ?? false) ? 'Hemen Başlayabilir' : 'Müsait Değil',
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
                                          cert.title ?? cert.type.label,
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
                      title: const Text('Tanıtım Videosu', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('15-30 saniyelik profil videonuz'),
                      trailing: OutlinedButton.icon(
                        onPressed: () => VideoPlayerDialog.show(context, videoUrl: profile.introVideoUrl!),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                        label: const Text('İzle'),
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
                          subtitle: Text('${items.length} değerlendirme'),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Profili Düzenle'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/edit'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_outlined, color: Colors.blue),
                  title: const Text('Belgelerim / Sertifika Cüzdanı'),
                  subtitle: const Text('Hijyen, cankurtaran, ehliyet ve dil belgelerinizi yönetin'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/certificates'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.favorite_outline_rounded),
                  title: const Text('Favorilerim'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/favorites'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('İlanlarım'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/my-listings'),
                ),
              ),
              if (profile?.userType == 'employer') ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_shared_outlined, color: Colors.indigo),
                    title: const Text('Yetenek Havuzum'),
                    subtitle: const Text('Gelecek sezon adayları ve notlar'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/talent-pool'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.rocket_launch_rounded, color: Colors.amber.shade800),
                  title: const Text('Öne Çıkarılan İlanlarım'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/my-boosts'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Bildirim Ayarları'),
                  subtitle: const Text('Mesaj, ilan ve duyuru bildirimleri'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/notifications'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Gizlilik ve Veri Ayarları'),
                  subtitle: const Text('KVKK, veri indirme ve hesap silme'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/privacy'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Görünüm',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Açık'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Koyu'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.settings_suggest_outlined),
                              label: Text('Sistem'),
                            ),
                          ],
                          selected: {themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds individual master menu sidebar items for desktop layout.
  Widget _buildSidebarItem({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    int? badgeCount,
  }) {
    final isSelected = _selectedSection == id;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected
            ? primaryColor.withAlpha(24)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedSection = id;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: primaryColor.withAlpha(80), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? primaryColor : Colors.grey.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? primaryColor : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
    AsyncValue<List<dynamic>>? ratings,
    List<dynamic>? approvedCerts,
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
    AsyncValue<List<dynamic>>? ratings,
    List<dynamic>? approvedCerts,
  ) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Genel Bakışı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Profili Düzenle',
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
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: primaryColor,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName?.isNotEmpty == true ? displayName! : (email.isNotEmpty ? email : 'Kullanıcı'),
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
                                profile?.userType == 'employer' ? 'İşveren Profili' : 'İş Arayan Profili',
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
                                      (profile?.availableImmediately ?? false) ? 'Hemen Başlayabilir' : 'Müsait Değil',
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
                                        cert.title ?? cert.type.label,
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
                title: const Text('Tanıtım Videonuz Yüklendi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('İşverenler profilinizi incelerken bu videoyu izleyebilir.'),
                trailing: FilledButton.icon(
                  onPressed: () => VideoPlayerDialog.show(context, videoUrl: profile.introVideoUrl!),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                  label: const Text('Videoyu İzle'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Section Shortcut Grid Cards
          Text('Hızlı Erişim', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _buildShortcutCard(
                icon: Icons.edit_outlined,
                color: Colors.purple,
                title: 'Profili Düzenle',
                subtitle: 'Kişisel ve iş detayları',
                onTap: () => setState(() => _selectedSection = 'edit'),
              ),
              _buildShortcutCard(
                icon: Icons.verified_outlined,
                color: Colors.blue,
                title: 'Sertifika Cüzdanı',
                subtitle: '${approvedCerts?.length ?? 0} onaylı belge',
                onTap: () => setState(() => _selectedSection = 'certificates'),
              ),
              _buildShortcutCard(
                icon: Icons.list_alt_rounded,
                color: Colors.teal,
                title: 'İlanlarım',
                subtitle: 'İlanlarınızı yönetin',
                onTap: () => setState(() => _selectedSection = 'my_listings'),
              ),
              _buildShortcutCard(
                icon: Icons.favorite_outline_rounded,
                color: Colors.red,
                title: 'Favorilerim',
                subtitle: 'Kayıtlı ilanlar',
                onTap: () => setState(() => _selectedSection = 'favorites'),
              ),
              _buildShortcutCard(
                icon: Icons.notifications_outlined,
                color: Colors.amber.shade900,
                title: 'Bildirim Ayarları',
                subtitle: 'Sessiz saatler ve tercihler',
                onTap: () => setState(() => _selectedSection = 'notifications'),
              ),
              _buildShortcutCard(
                icon: Icons.security_rounded,
                color: Colors.indigo,
                title: 'Gizlilik ve Veri',
                subtitle: 'Güvenlik ve KVKK',
                onTap: () => setState(() => _selectedSection = 'privacy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
