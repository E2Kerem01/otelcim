import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/profile_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../ratings/services/rating_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    final profile = ref.watch(currentUserProfileProvider).value;
    final displayName = profile?.displayName;
    final photoUrl = profile?.photoUrl;
    final themeMode = ref.watch(themeModeProvider);
    final ratings = user == null ? null : ref.watch(userRatingsProvider(user.uid));
    final initial = (displayName?.isNotEmpty ?? false)
        ? displayName![0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

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
                      ],
                    ),
                  ),
                ],
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
              error: (_, __) => const SizedBox.shrink(),
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
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
