import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_mapper.dart';
import '../error/error_reporter.dart';
import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required ReportTargetType targetType,
}) async {
  final reporterId = ref.read(authServiceProvider).currentUser?.uid;
  if (reporterId == null) return;

  if (reporterId == targetId) return;

  final reportService = ref.read(reportServiceProvider);
  final alreadyReported = await reportService.hasAlreadyReported(
    reporterId: reporterId,
    targetId: targetId,
  );
  if (!context.mounted) return;

  if (alreadyReported) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu içeriği zaten bildirdiniz.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ReportSheetContent(
      targetId: targetId,
      targetType: targetType,
      reporterId: reporterId,
    ),
  );
}

class _ReportSheetContent extends ConsumerStatefulWidget {
  const _ReportSheetContent({
    required this.targetId,
    required this.targetType,
    required this.reporterId,
  });

  final String targetId;
  final ReportTargetType targetType;
  final String reporterId;

  @override
  ConsumerState<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends ConsumerState<_ReportSheetContent> {
  ReportReason _reason = ReportReason.scam;
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(reportServiceProvider).submitReport(
            Report(
              reporterId: widget.reporterId,
              targetId: widget.targetId,
              targetType: widget.targetType,
              reason: _reason,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildiriminiz alındı, teşekkür ederiz.')),
        );
      }
    } on Object catch (error, stackTrace) {
      logError(error, stackTrace, context: '_ReportSheetContentState._submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.targetType == ReportTargetType.listing ? 'İlanı Bildir' : 'Kullanıcıyı Bildir';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Bildirim sebebi', style: TextStyle(fontSize: 13, color: Colors.grey)),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ReportReason.values
                    .map(
                      (reason) => RadioListTile<ReportReason>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason.label),
                        value: reason,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ek açıklama (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bildir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
