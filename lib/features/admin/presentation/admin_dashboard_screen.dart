import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';

final _dashboardMetricsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminAnalyticsServiceProvider).getDashboardMetrics(),
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(_dashboardMetricsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_dashboardMetricsProvider);
          await ref.read(_dashboardMetricsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('İçerik moderasyonu', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Şikâyetleri ve doğrulama taleplerini tek yerden yönetin.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            _AdminCard(
              icon: Icons.report_problem_outlined,
              title: 'Şikâyetler',
              subtitle: 'Bekleyen şikâyetleri inceleyin ve işlem yapın.',
              count: metrics.valueOrNull?.openReports,
              onTap: () => context.push('/admin/reports'),
            ),
            const SizedBox(height: 12),
            _AdminCard(
              icon: Icons.verified_user_outlined,
              title: 'Doğrulama Talepleri',
              subtitle: 'İşveren belgelerini inceleyip sonuçlandırın.',
              count: metrics.valueOrNull?.pendingVerifications,
              onTap: () => context.push('/admin/verifications'),
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
            if (metrics.hasError) ...[
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
