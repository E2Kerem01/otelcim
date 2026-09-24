import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/admin_action_model.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import 'widgets/admin_shell.dart';

final _overviewProvider = FutureProvider.autoDispose<AdminOverview>(
  (ref) => ref.watch(adminAnalyticsServiceProvider).getOverview(),
);

final _dailySeriesProvider = FutureProvider.autoDispose<List<AdminDailySeries>>(
  (ref) => ref.watch(adminAnalyticsServiceProvider).getDailySeries(),
);

final _recentAuditProvider = StreamProvider.autoDispose<List<AdminAction>>(
  (ref) => ref.watch(adminServiceProvider).watchAuditLog(limit: 10),
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
          ref.invalidate(_dailySeriesProvider);
          ref.invalidate(_recentAuditProvider);
          await ref.read(_overviewProvider.future);
          await ref.read(_dailySeriesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Genel Bakış', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _OverviewPanel(overview: overview),
            const SizedBox(height: 28),
            _DailyInsightsPanel(series: ref.watch(_dailySeriesProvider)),
            const SizedBox(height: 20),
            _RecentActivitiesPanel(audit: ref.watch(_recentAuditProvider)),
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
        trend: data.trendFor('newUsers'),
      ),
      _StatTile(
        icon: Icons.post_add,
        label: 'Yeni ilan',
        value: data['newListings'],
        detail: 'son $days gün',
        trend: data.trendFor('newListings'),
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
    this.trend,
  });

  final IconData icon;
  final String label;
  final int? value;
  final String? detail;
  final AdminTrend? trend;

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
            if (trend != null) ...[
              const SizedBox(height: 4),
              Text(
                _trendLabel(trend!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _trendColor(theme.colorScheme, trend!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _trendLabel(AdminTrend trend) {
  final current = trend.current;
  final previous = trend.previous;
  if (current == null || previous == null) return 'Karşılaştırma verisi yok';
  if (previous == 0) return current == 0 ? 'Değişim yok' : 'Yeni dönem';
  final percent = trend.percentChange;
  if (percent == null || percent == 0) return 'Değişim yok';
  final arrow = percent > 0 ? '↑' : '↓';
  return '$arrow %${percent.abs().round()} önceki haftaya göre';
}

Color _trendColor(ColorScheme colors, AdminTrend trend) {
  final percent = trend.percentChange;
  if (percent == null || percent == 0) return colors.onSurfaceVariant;
  return percent > 0 ? colors.primary : colors.error;
}

class _DailyInsightsPanel extends StatelessWidget {
  const _DailyInsightsPanel({required this.series});

  final AsyncValue<List<AdminDailySeries>> series;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kayıt trendi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Son 30 günde günlük yeni üye ve ilan sayısı',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            series.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('Trend verisi yüklenemedi.')),
              ),
              data: (points) => _buildChart(context, points),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<AdminDailySeries> points) {
    final hasData = points.any(
      (point) => point.newUsers > 0 || point.newListings > 0,
    );
    if (!hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text('Bu dönemde yeni kayıt yok.')),
      );
    }

    var largestValue = 0.0;
    for (final point in points) {
      largestValue = math
          .max(
            largestValue,
            math.max(point.newUsers, point.newListings).toDouble(),
          )
          .toDouble();
    }
    final maxY = largestValue <= 1 ? 1.0 : largestValue * 1.2;
    final interval = maxY <= 4 ? 1.0 : (maxY / 4).ceilToDouble();
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 ||
                          index >= points.length ||
                          (index % 7 != 0 && index != points.length - 1)) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('d/M').format(points[index].date),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                _line(
                  points.map((point) => point.newUsers).toList(),
                  colors.primary,
                ),
                _line(
                  points.map((point) => point.newListings).toList(),
                  colors.tertiary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _ChartLegend(color: colors.primary, label: 'Yeni üye'),
            _ChartLegend(color: colors.tertiary, label: 'Yeni ilan'),
          ],
        ),
      ],
    );
  }

  LineChartBarData _line(List<int> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var index = 0; index < values.length; index++)
          FlSpot(index.toDouble(), values[index].toDouble()),
      ],
      isCurved: true,
      // Counts never go below zero; without this the spline dips under the axis.
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _RecentActivitiesPanel extends StatelessWidget {
  const _RecentActivitiesPanel({required this.audit});

  final AsyncValue<List<AdminAction>> audit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Son işlemler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/admin/audit-log'),
                  child: const Text('Tümünü gör'),
                ),
              ],
            ),
            audit.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Son işlemler yüklenemedi.')),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Henüz işlem kaydı yok.')),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final action = items[index];
                    final timestamp = action.timestamp;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(_auditIcon(action.actionType)),
                      ),
                      title: Text(action.actionType.label),
                      subtitle: Text(
                        '${action.targetType.label}: ${action.targetId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        timestamp == null
                            ? '–'
                            : DateFormat('dd.MM HH:mm').format(timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

IconData _auditIcon(AdminActionType type) => switch (type) {
      AdminActionType.dismissReport => Icons.close,
      AdminActionType.warnUser => Icons.warning_amber,
      AdminActionType.removeListing => Icons.delete_outline,
      AdminActionType.restoreListing => Icons.restore_outlined,
      AdminActionType.suspendUser => Icons.pause_circle_outline,
      AdminActionType.unsuspendUser => Icons.play_circle_outline,
      AdminActionType.banUser => Icons.block,
      AdminActionType.unbanUser => Icons.lock_open_outlined,
      AdminActionType.approveVerification => Icons.verified_outlined,
      AdminActionType.rejectVerification => Icons.gpp_bad_outlined,
      AdminActionType.approveCertificate => Icons.workspace_premium_outlined,
      AdminActionType.rejectCertificate => Icons.remove_moderator_outlined,
    };
