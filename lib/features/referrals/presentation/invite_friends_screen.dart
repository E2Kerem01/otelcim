import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/referral_code.dart';

/// Lets a user view and share their referral code, and see how many free
/// boost credits they've earned by inviting friends who then publish their
/// first listing or start their first chat.
class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  Future<void> _copyCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n?.codeCopiedMessage ?? 'Kod kopyalandı')),
    );
  }

  Future<void> _shareCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context);
    final message = l10n?.shareReferralMessage(code) ??
        "Otelcim'de otel/turizm işleri bul veya ilan ver! $code kodumla kayıt ol, ikimiz de kazanalım.";
    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final profile = ref.watch(currentUserProfileProvider).value;
    final referralCode = profile?.referralCode ??
        (currentUser != null ? generateReferralCode(currentUser.uid) : '');
    final referralCount = profile?.referralCount ?? 0;
    final freeBoostCredits = profile?.freeBoostCredits ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.inviteFriendsTitle ?? 'Arkadaşını Davet Et'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.inviteFriendsDescription ??
                  'Kodunu arkadaşınla paylaş, o kaydolup ilk ilanını yayınladığında veya ilk sohbetini başlattığında sana ücretsiz bir boost hakkı kazandırsın.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.yourReferralCodeLabel ?? 'Referans Kodun',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n?.copyCodeAction ?? 'Kodu Kopyala',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: referralCode.isEmpty
                              ? null
                              : () => _copyCode(context, referralCode),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: referralCode.isEmpty
                            ? null
                            : () => _shareCode(context, referralCode),
                        icon: const Icon(Icons.share_rounded),
                        label: Text(l10n?.shareCodeAction ?? 'Paylaş'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: l10n?.referralCountLabel ?? 'Davet Ettiğin Kişi Sayısı',
                    value: '$referralCount',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.rocket_launch_rounded,
                    label: l10n?.freeBoostCreditsLabel ?? 'Ücretsiz Boost Hakkın',
                    value: '$freeBoostCredits',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
