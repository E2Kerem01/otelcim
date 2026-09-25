import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/report.dart';
import '../../../shared/services/auth_service.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import '../services/moderation_service.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';
import 'widgets/reason_dialog.dart';
import '../../../shared/providers/firestore_provider.dart';

const _reportFilters = <AdminFilter>[
  AdminFilter('pending', 'Bekleyen', icon: Icons.pending_actions),
  AdminFilter('dismissed', 'Reddedilen', icon: Icons.close),
  AdminFilter('all', 'Tümü'),
];

const _reportTargetFilters = <AdminFilter>[
  AdminFilter('all', 'Tüm hedefler'),
  AdminFilter('listing', 'İlan', icon: Icons.apartment_outlined),
  AdminFilter('user', 'Kullanıcı', icon: Icons.person_outline),
];

/// Firestore query used by the paginated report moderation screen.
Query<Map<String, dynamic>> adminReportsQuery(
  FirebaseFirestore db, {
  required String filter,
  ReportTargetType? targetType,
}) {
  Query<Map<String, dynamic>> query = db.collection('reports');
  query = switch (filter) {
    'pending' => query.where('status', isEqualTo: 'pending'),
    'dismissed' || 'rejected' => query.where('status', isEqualTo: 'dismissed'),
    _ => query,
  };
  if (targetType != null) {
    query = query.where('targetType', isEqualTo: targetType.name);
  }
  return query.orderBy('createdAt', descending: true);
}

/// The shared [Report] model intentionally contains only report content. The
/// admin queue also needs the moderation status for its table, so keep that
/// queue-only value out of the shared model.
class _AdminReport {
  const _AdminReport({required this.report, required this.status});

  final Report report;
  final String status;

  String get id => report.id;

  factory _AdminReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final status = doc.data()?['status'] as String?;
    return _AdminReport(
      report: Report.fromDoc(doc),
      status: status == null || status == 'pending' ? 'pending' : status,
    );
  }
}

class ReportsModerationScreen extends ConsumerStatefulWidget {
  const ReportsModerationScreen({super.key});

  @override
  ConsumerState<ReportsModerationScreen> createState() =>
      _ReportsModerationScreenState();
}

class _ReportsModerationScreenState
    extends ConsumerState<ReportsModerationScreen> {
  late final AdminPagedController<_AdminReport> _reports =
      AdminPagedController(
        fromDoc: _AdminReport.fromDoc,
        idOf: (report) => report.id,
      );
  String _filter = 'pending';
  String _targetFilter = 'all';

  ReportTargetType? get _targetType => switch (_targetFilter) {
        'listing' => ReportTargetType.listing,
        'user' => ReportTargetType.user,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _reports.dispose();
    super.dispose();
  }

  void _reload() {
    unawaited(
      _reports.setQuery(
        adminReportsQuery(
          ref.read(firestoreProvider),
          filter: _filter,
          targetType: _targetType,
        ),
      ),
    );
  }

  Future<void> _openReport(_AdminReport item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: _ReportCard(
              report: item.report,
              onChanged: () => unawaited(_reports.refresh()),
            ),
          ),
        ),
      ),
    );
    await _reports.refresh();
  }

  Future<void> _dismissSelected() async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null || _reports.selectedIds.isEmpty) return;
    final reason = await showReasonDialog(
      context,
      title: 'Seçili şikâyetleri reddet',
      message: '${_reports.selectedIds.length} şikâyet reddedilecek.',
      showReasonField: true,
      reasonRequired: false,
      confirmLabel: 'Toplu reddet',
      maxLines: 3,
    );
    if (reason == null || !mounted) return;

    final ids = _reports.selectedIds.toList();
    try {
      await ref.read(moderationServiceProvider).dismissReports(
            ids: ids,
            adminId: adminId,
            reason: reason.isEmpty ? null : reason,
          );
      _reports.removeWhere((item) => ids.contains(item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ids.length} şikâyet reddedildi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ReportsModerationScreen._dismissSelected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _reports.selectedIds.length;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Şikâyetler')),
      body: Column(
        children: [
          AdminFilterBar(
            filters: _reportFilters,
            selectedId: _filter,
            onSelected: (id) {
              setState(() => _filter = id);
              _reload();
            },
          ),
          const SizedBox(height: 4),
          AdminFilterBar(
            filters: _reportTargetFilters,
            selectedId: _targetFilter,
            onSelected: (id) {
              setState(() => _targetFilter = id);
              _reload();
            },
          ),
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('$selectedCount seçili')),
                      TextButton(
                        onPressed: _dismissSelected,
                        child: const Text('Toplu reddet'),
                      ),
                      TextButton(
                        onPressed: _reports.clearSelection,
                        child: const Text('Seçimi temizle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: AdminPagedView<_AdminReport>(
              controller: _reports,
              selectable: true,
              emptyText: _filter == 'pending'
                  ? 'Bekleyen şikâyet bulunmuyor.'
                  : 'Şikâyet bulunamadı.',
              cardBuilder: (_, item) => _ReportCard(
                report: item.report,
                onChanged: () => unawaited(_reports.refresh()),
              ),
              onRowTap: (item) => unawaited(_openReport(item)),
              columns: [
                AdminColumn(
                  label: 'Hedef',
                  flex: 2,
                  cell: (_, item) => Text(
                    '${item.report.targetType == ReportTargetType.user ? 'Kullanıcı' : 'İlan'} • ${item.report.targetId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Sebep',
                  flex: 2,
                  cell: (_, item) => Text(
                    item.report.reason.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Açıklama',
                  flex: 3,
                  cell: (_, item) => Text(
                    item.report.description?.trim().isNotEmpty == true
                        ? item.report.description!
                        : '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Tarih',
                  cell: (_, item) => Text(
                    item.report.createdAt == null
                        ? '—'
                        : dateFormat.format(item.report.createdAt!),
                  ),
                ),
                AdminColumn(
                  label: 'Durum',
                  cell: (_, item) => Text(
                    item.status == 'pending' ? 'Bekleyen' : 'Reddedilen',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report, this.onChanged});

  final Report report;
  final VoidCallback? onChanged;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _run(AdminActionType type) async {
    final requiredReason = type == AdminActionType.banUser;
    final reason = await showReasonDialog(
      context,
      title: type.label,
      reasonRequired: requiredReason,
      confirmLabel: 'Uygula',
      maxLines: 3,
    );
    if (!mounted || reason == null) return;

    final report = widget.report;
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      final moderation = ref.read(moderationServiceProvider);
      switch (type) {
        case AdminActionType.dismissReport:
          await moderation.dismissReport(
            reportId: report.id,
            adminId: adminId,
            reason: reason,
          );
        case AdminActionType.warnUser:
          await moderation.warnUser(
            userId: report.targetId,
            adminId: adminId,
            reason: reason,
          );
        case AdminActionType.removeListing:
          await moderation.removeListing(
            listingId: report.targetId,
            adminId: adminId,
            reason: reason,
          );
        case AdminActionType.suspendUser:
          await moderation.suspendUser(
            userId: report.targetId,
            adminId: adminId,
            reason: reason,
          );
        case AdminActionType.banUser:
          await moderation.banUser(
            userId: report.targetId,
            adminId: adminId,
            reason: reason,
          );
        case AdminActionType.restoreListing:
        case AdminActionType.unsuspendUser:
        case AdminActionType.unbanUser:
        case AdminActionType.approveVerification:
        case AdminActionType.rejectVerification:
        case AdminActionType.approveCertificate:
        case AdminActionType.rejectCertificate:
          return;
      }
      await ref.read(adminServiceProvider).logAdminAction(
            AdminAction(
              adminId: adminId,
              actionType: type,
              targetType: type == AdminActionType.removeListing
                  ? AdminActionTargetType.listing
                  : type == AdminActionType.dismissReport
                      ? AdminActionTargetType.report
                      : AdminActionTargetType.user,
              targetId: type == AdminActionType.dismissReport
                  ? report.id
                  : report.targetId,
              reason: reason.isEmpty ? null : reason,
              details: {'reportId': report.id},
            ),
          );
      if (type != AdminActionType.dismissReport) {
        await moderation.dismissReport(
          reportId: report.id,
          adminId: adminId,
          reason: '${type.label} işlemi uygulandı',
        );
      }
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.label} işlemi tamamlandı.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ReportsModerationScreen._applyAction');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isUser = report.targetType == ReportTargetType.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.apartment_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.reason.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Hedef: ${isUser ? 'Kullanıcı' : 'İlan'} • ${report.targetId}',
            ),
            Text('Bildiren: ${report.reporterId}'),
            if (report.createdAt != null)
              Text(
                'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(report.createdAt!)}',
              ),
            if (report.description?.isNotEmpty == true) ...[
              const Divider(height: 24),
              Text(report.description!),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(AdminActionType.dismissReport),
                  icon: const Icon(Icons.close),
                  label: const Text('Reddet'),
                ),
                if (isUser) ...[
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(AdminActionType.warnUser),
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Uyar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(AdminActionType.suspendUser),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Askıya al'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => _run(AdminActionType.banUser),
                    icon: const Icon(Icons.block),
                    label: const Text('Yasakla'),
                  ),
                ] else
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => _run(AdminActionType.removeListing),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('İlanı kaldır'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
