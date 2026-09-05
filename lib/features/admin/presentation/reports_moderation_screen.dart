import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/report.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/report_service.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import '../services/moderation_service.dart';

final pendingReportsProvider = StreamProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportServiceProvider).watchPendingReports(),
);

class ReportsModerationScreen extends ConsumerWidget {
  const ReportsModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(pendingReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Şikâyetler')),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Message(icon: Icons.error_outline, text: 'Şikâyetler yüklenemedi.'),
        data: (items) => items.isEmpty
            ? const _Message(icon: Icons.task_alt_rounded, text: 'Bekleyen şikâyet bulunmuyor.')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ReportCard(report: items[index]),
              ),
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});
  final Report report;
  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _run(AdminActionType type) async {
    final requiredReason = type == AdminActionType.banUser;
    final reason = await _reasonDialog(type.label, requiredReason: requiredReason);
    if (!mounted || reason == null) return;
    final report = widget.report;
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      final moderation = ref.read(moderationServiceProvider);
      switch (type) {
        case AdminActionType.dismissReport:
          await moderation.dismissReport(reportId: report.id, adminId: adminId, reason: reason);
        case AdminActionType.warnUser:
          await moderation.warnUser(userId: report.targetId, adminId: adminId, reason: reason);
        case AdminActionType.removeListing:
          await moderation.removeListing(listingId: report.targetId, adminId: adminId, reason: reason);
        case AdminActionType.suspendUser:
          await moderation.suspendUser(userId: report.targetId, adminId: adminId, reason: reason);
        case AdminActionType.banUser:
          await moderation.banUser(userId: report.targetId, adminId: adminId, reason: reason);
        case AdminActionType.restoreListing:
        case AdminActionType.unsuspendUser:
        case AdminActionType.unbanUser:
        case AdminActionType.approveVerification:
        case AdminActionType.rejectVerification:
        case AdminActionType.approveCertificate:
        case AdminActionType.rejectCertificate:
          return;
      }
      await ref.read(adminServiceProvider).logAdminAction(AdminAction(
            adminId: adminId,
            actionType: type,
            targetType: type == AdminActionType.removeListing ? AdminActionTargetType.listing : type == AdminActionType.dismissReport ? AdminActionTargetType.report : AdminActionTargetType.user,
            targetId: type == AdminActionType.dismissReport ? report.id : report.targetId,
            reason: reason.isEmpty ? null : reason,
            details: {'reportId': report.id},
          ));
      if (type != AdminActionType.dismissReport) {
        await moderation.dismissReport(reportId: report.id, adminId: adminId, reason: '${type.label} işlemi uygulandı');
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${type.label} işlemi tamamlandı.')));
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ReportsModerationScreen._applyAction');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapToFailure(error).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _reasonDialog(String title, {required bool requiredReason}) async {
    final controller = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: InputDecoration(labelText: requiredReason ? 'Sebep (zorunlu)' : 'Sebep (isteğe bağlı)', errorText: error)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () {
            final value = controller.text.trim();
            if (requiredReason && value.isEmpty) { setDialogState(() => error = 'Sebep girmeniz gerekiyor.'); return; }
            Navigator.pop(context, value);
          }, child: const Text('Uygula')),
        ],
      )),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isUser = report.targetType == ReportTargetType.user;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(isUser ? Icons.person_outline : Icons.apartment_outlined), const SizedBox(width: 10), Expanded(child: Text(report.reason.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), if (_busy) const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))]),
      const SizedBox(height: 10),
      Text('Hedef: ${isUser ? 'Kullanıcı' : 'İlan'} • ${report.targetId}'),
      Text('Bildiren: ${report.reporterId}'),
      if (report.createdAt != null) Text('Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(report.createdAt!)}'),
      if (report.description?.isNotEmpty == true) ...[const Divider(height: 24), Text(report.description!)],
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: _busy ? null : () => _run(AdminActionType.dismissReport), icon: const Icon(Icons.close), label: const Text('Reddet')),
        if (isUser) ...[
          OutlinedButton.icon(onPressed: _busy ? null : () => _run(AdminActionType.warnUser), icon: const Icon(Icons.warning_amber), label: const Text('Uyar')),
          OutlinedButton.icon(onPressed: _busy ? null : () => _run(AdminActionType.suspendUser), icon: const Icon(Icons.pause_circle_outline), label: const Text('Askıya al')),
          FilledButton.tonalIcon(onPressed: _busy ? null : () => _run(AdminActionType.banUser), icon: const Icon(Icons.block), label: const Text('Yasakla')),
        ] else
          FilledButton.tonalIcon(onPressed: _busy ? null : () => _run(AdminActionType.removeListing), icon: const Icon(Icons.delete_outline), label: const Text('İlanı kaldır')),
      ]),
    ])));
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 52, color: Colors.grey), const SizedBox(height: 12), Text(text)]));
}
