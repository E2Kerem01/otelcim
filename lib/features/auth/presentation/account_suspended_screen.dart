import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../admin/services/admin_service.dart';

/// Shown when router.dart's redirect detects the current account is banned,
/// or suspended and the suspension hasn't expired yet. Reachable regardless
/// of which screen the admin action fired from - the account is locked out
/// app-wide until an admin lifts it (or the suspension window ends).
class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final profileAsync = uid == null
        ? null
        : ref.watch(
            FutureProvider(
              (ref) => ref.watch(adminServiceProvider).getUserProfile(uid),
            ),
          );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded, size: 56, color: Colors.red.shade400),
                  const SizedBox(height: 20),
                  profileAsync?.when(
                        data: (profile) {
                          if (profile?.isBanned ?? false) {
                            return _Message(
                              title: 'Hesabınız Yasaklandı',
                              reason: profile?.banReason,
                            );
                          }
                          final end = profile?.suspensionEnd;
                          return _Message(
                            title: 'Hesabınız Askıya Alındı',
                            reason: profile?.suspensionReason,
                            extra: end != null
                                ? 'Askı bitiş: ${DateFormat('dd.MM.yyyy HH:mm').format(end)}'
                                : null,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const _Message(title: 'Hesabınıza erişim kısıtlandı'),
                      ) ??
                      const _Message(title: 'Hesabınıza erişim kısıtlandı'),
                  const SizedBox(height: 28),
                  Text(
                    'Bunun bir hata olduğunu düşünüyorsanız destek ekibimizle iletişime geçin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.reason, this.extra});

  final String title;
  final String? reason;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: otelcimBlue,
          ),
        ),
        if (reason != null && reason!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            reason!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
        if (extra != null) ...[
          const SizedBox(height: 6),
          Text(
            extra!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
