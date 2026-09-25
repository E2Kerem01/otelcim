import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_mapper.dart';
import '../error/error_reporter.dart';
import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../../l10n/app_localizations.dart';

/// Dialog for reporting listings or users
/// Shows reason selection dropdown, optional description field, and submit button
class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String targetName;

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason _selectedReason = ReportReason.scam;
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      // Check for duplicate report
      final hasReported = await ref.read(reportServiceProvider).hasUserReportedTarget(
            reporterId: user.uid,
            targetType: widget.targetType,
            targetId: widget.targetId,
          );

      if (hasReported) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.coreReportAlreadySubmitted ?? 'Bu bildirimi daha önce gönderdiniz.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Submit report
      final report = Report(
        id: '',
        reporterId: user.uid,
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
      );

      await ref.read(reportServiceProvider).submitReport(report);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.coreReportSubmittedSuccess ?? 'Bildiriminiz başarıyla gönderildi. Teşekkür ederiz.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      logError(error, stackTrace, context: '_ReportDialogState._submitReport');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mapToFailure(error).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targetTypeLabel = widget.targetType == ReportTargetType.listing
        ? l10n.coreReportListingTitle
        : l10n.coreReportUserTitle;

    return AlertDialog(
      title: Text(targetTypeLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.coreReportingTarget(widget.targetName),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.coreReportReasonLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ReportReason.values
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason.localizedLabel(l10n)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.coreReportDescriptionLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.coreReportDescriptionHint,
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submitReport,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.coreSubmitAction),
        ),
      ],
    );
  }
}
