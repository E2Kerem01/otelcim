import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';
import 'widgets/admin_shell.dart';

final _overviewProvider = FutureProvider.autoDispose<AdminOverview>(
  (ref) => ref.watch(adminAnalyticsServiceProvider).getOverview(),
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(_overviewProvider);
    final counts = overview.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        actions: const [AdminThemeToggle()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_overviewProvider);
          await ref.read(_overviewProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Genel Bakış', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _OverviewPanel(overview: overview),
            const SizedBox(height: 28),
            Text('İçerik moderasyonu', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Şikâyetleri ve doğrulama taleplerini tek yerden yönetin.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            _AdminCard(
              icon: Icons.report_problem_outlined,
              title: 'Şikâyetler',
              subtitle: 'Bekleyen şikâyetleri inceleyin ve işlem yapın.',
              count: counts?['pendingReports'],
              onTap: () => context.push('/admin/reports'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.verified_user_outlined,
              title: 'Doğrulama Talepleri',
              subtitle: 'İşveren belgelerini inceleyip sonuçlandırın.',
              count: counts?['pendingVerifications'],
              onTap: () => context.push('/admin/verifications'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.people_alt_outlined,
              title: 'Kullanıcı Yönetimi',
              subtitle: 'Kullanıcı arayın, askıya alın veya yasaklayın.',
              onTap: () => context.push('/admin/users'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.list_alt_outlined,
              title: 'İlan Yönetimi',
              subtitle: 'İlan arayın, kaldırın veya geri yükleyin.',
              onTap: () => context.push('/admin/listings'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.card_membership_outlined,
              title: 'Belge Onay Kuyruğu',
              subtitle: 'İş arayanların hijyen, cankurtaran, ehliyet vb. belgelerini onaylayın.',
              count: counts?['pendingCertificates'],
              onTap: () => context.push('/admin/certificates'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.campaign_outlined,
              title: 'Banner Reklamlar',
              subtitle: 'Anasayfa sponsorlu reklam banner\'larını yönetin.',
              onTap: () => context.push('/admin/banners'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.history_rounded,
              title: 'İşlem Geçmişi',
              subtitle: 'Yönetici aksiyonlarını ve gerekçelerini görüntüleyin.',
              onTap: () => context.push('/admin/audit-log'),
            ),
            if (overview.hasError) ...[
              const SizedBox(height: 16),
              const Text('Özet bilgiler yüklenemedi. Yenilemek için aşağı kaydırın.', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.icon, required this.title, required this.subtitle, required this.onTap, this.count});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              CircleAvatar(radius: 25, child: Icon(icon)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), if (count != null) Badge(label: Text('$count'))]),
                const SizedBox(height: 5),
                Text(subtitle),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
      );
}

/// Headline numbers at the top of the admin dashboard. Tiles wrap so the
/// panel stays readable on phones, at large text sizes and in RTL.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.overview});

  final AsyncValue<AdminOverview> overview;

  @override
  Widget build(BuildContext context) {
    final data = overview.valueOrNull;
    if (data == null) {
      return overview.isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : const SizedBox.shrink();
    }
    final days = data.recentDays;
    String? split(String a, String labelA, String b, String labelB) {
      final x = data[a];
      final y = data[b];
      if (x == null && y == null) return null;
      return '${x ?? '–'} $labelA · ${y ?? '–'} $labelB';
    }

    final tiles = <_StatTile>[
      _StatTile(
        icon: Icons.people_alt_outlined,
        label: 'Toplam üye',
        value: data['users'],
        detail: split('jobseekers', 'iş arayan', 'employers', 'işveren'),
      ),
      _StatTile(
        icon: Icons.work_outline,
        label: 'Aktif ilan',
        value: data['activeListings'],
        detail: data['listings'] == null ? null : 'toplam ${data['listings']}',
      ),
      _StatTile(
        icon: Icons.person_add_alt,
        label: 'Yeni üye',
        value: data['newUsers'],
        detail: 'son $days gün',
      ),
      _StatTile(
        icon: Icons.post_add,
        label: 'Yeni ilan',
        value: data['newListings'],
        detail: 'son $days gün',
      ),
      _StatTile(
        icon: Icons.bolt_outlined,
        label: 'Acil / öne çıkan',
        value: data['urgentListings'],
        detail: data['boostedListings'] == null
            ? null
            : '${data['boostedListings']} öne çıkan',
      ),
      _StatTile(
        icon: Icons.verified_outlined,
        label: 'Doğrulanmış işveren',
        value: data['verifiedEmployers'],
      ),
      _StatTile(
        icon: Icons.block,
        label: 'Yasaklı / askıda',
        value: data['banned'],
        detail: data['suspended'] == null ? null : '${data['suspended']} askıda',
      ),
      _StatTile(
        icon: Icons.forum_outlined,
        label: 'Sohbet',
        value: data['conversations'],
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 360
                ? 2
                : 1;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;
  final int? value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: theme.textTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value?.toString() ?? '–',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(detail!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
