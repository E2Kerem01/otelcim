import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    final profile = ref.watch(currentUserProfileProvider).value;
    final displayName = profile?.displayName;
    final photoUrl = profile?.photoUrl;
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              leading: const Icon(Icons.list_alt_rounded),
              title: const Text('İlanlarım'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/my-listings'),
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
