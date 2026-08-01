import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

/// Dialog for reporting listings or users
/// Shows reason selection dropdown, optional description field, and submit button
class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  final TargetType targetType;
  final String targetId;
  final String targetName;

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason _selectedReason = ReportReason.scamFraud;
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getReasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.scamFraud:
        return 'Dolandırıcılık/Sahtecilik';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Uygunsuz İçerik';
      case ReportReason.misleadingInformation:
        return 'Yanıltıcı Bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
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
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu bildirimi daha önce gönderdiniz.'),
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildiriminiz başarıyla gönderildi. Teşekkür ederiz.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
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
    final targetTypeLabel = widget.targetType == TargetType.listing ? 'İlanı' : 'Kullanıcıyı';

    return AlertDialog(
      title: Text('$targetTypeLabel Bildir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bildireceğiniz: ${widget.targetName}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bildirim Nedeni',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              value: _selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ReportReason.values
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(_getReasonLabel(reason)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Açıklama (İsteğe Bağlı)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ek bilgi ekleyebilirsiniz...',
                contentPadding: EdgeInsets.all(12),
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
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submitReport,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }
}
