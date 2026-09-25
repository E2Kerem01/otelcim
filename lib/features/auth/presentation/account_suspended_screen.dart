import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/auth_service.dart';
import '../../admin/services/admin_service.dart';

/// Shown when router.dart's redirect detects the current account is banned,
/// or suspended and the suspension hasn't expired yet. Reachable regardless
/// of which screen the admin action fired from - the account is locked out
/// app-wide until an admin lifts it (or the suspension window ends).
/// Declared once at top level: creating the FutureProvider inside build()
/// made every rebuild a brand-new provider that never resolved, so the
/// banned/suspended screen spun forever instead of showing the reason.
final _restrictedProfileProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>(
  (ref, uid) => ref.watch(adminServiceProvider).getUserProfile(uid),
);

class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).value?.uid;
    final profileAsync =
        uid == null ? null : ref.watch(_restrictedProfileProvider(uid));

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
                              title: l10n.coreAccountBannedTitle,
                              reason: profile?.banReason,
                            );
                          }
                          final end = profile?.suspensionEnd;
                          return _Message(
                            title: l10n.coreAccountSuspendedTitle,
                            reason: profile?.suspensionReason,
                            extra: end != null
                                ? l10n.coreSuspensionEndAt(DateFormat('dd.MM.yyyy HH:mm').format(end))
                                : null,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) =>
                            _Message(title: l10n.coreAccountRestrictedTitle),
                      ) ??
                      _Message(title: l10n.coreAccountRestrictedTitle),
                  const SizedBox(height: 28),
                  Text(
                    l10n.coreAccountSuspendedContactSupport,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.signOut),
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
