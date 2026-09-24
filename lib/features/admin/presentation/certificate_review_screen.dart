import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../../profile/domain/certificate_model.dart';
import '../../profile/services/certificate_service.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';
import 'widgets/reason_dialog.dart';

const _certificateFilters = <AdminFilter>[
  AdminFilter('pending', 'Bekleyen', icon: Icons.hourglass_top_outlined),
  AdminFilter('approved', 'Onaylanan', icon: Icons.verified_outlined),
  AdminFilter('rejected', 'Reddedilen', icon: Icons.gpp_bad_outlined),
  AdminFilter('all', 'Tümü'),
];

class CertificateReviewScreen extends ConsumerStatefulWidget {
  const CertificateReviewScreen({super.key});

  @override
  ConsumerState<CertificateReviewScreen> createState() =>
      _CertificateReviewScreenState();
}

class _CertificateReviewScreenState
    extends ConsumerState<CertificateReviewScreen> {
  late final AdminPagedController<Certificate> _controller =
      AdminPagedController<Certificate>(
        fromDoc: (doc) => Certificate.fromDoc(doc),
        idOf: (certificate) => certificate.id,
      );
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    unawaited(_controller.setQuery(adminCertificatesQuery(
      FirebaseFirestore.instance,
      filter: _filter,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belge Onay Kuyruğu')),
      body: Column(
        children: [
          AdminFilterBar(
            filters: _certificateFilters,
            selectedId: _filter,
            onSelected: (id) {
              setState(() => _filter = id);
              _reload();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AdminPagedView<Certificate>(
              controller: _controller,
              emptyText: 'Bu filtreyle belge / sertifika bulunamadı.',
              cardBuilder: (_, certificate) => _AdminCertificateCard(
                cert: certificate,
                onCompleted: () => _controller.removeWhere(
                  (item) => item.id == certificate.id,
                ),
              ),
              columns: [
                AdminColumn(
                  label: 'Otel / Kişi',
                  flex: 2,
                  cell: (_, certificate) => Text(
                    '${certificate.userName ?? certificate.userEmail ?? certificate.userId}\n${certificate.title ?? certificate.type.label}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Belge sayısı',
                  cell: (_, _) => const Text('1'),
                ),
                AdminColumn(
                  label: 'Gönderim',
                  cell: (_, certificate) => Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(certificate.createdAt),
                  ),
                ),
                AdminColumn(
                  label: 'Durum',
                  cell: (_, certificate) => Text(certificate.status.label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCertificateCard extends ConsumerStatefulWidget {
  const _AdminCertificateCard({required this.cert, required this.onCompleted});

  final Certificate cert;
  final VoidCallback onCompleted;

  @override
  ConsumerState<_AdminCertificateCard> createState() =>
      _AdminCertificateCardState();
}

class _AdminCertificateCardState
    extends ConsumerState<_AdminCertificateCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi onayla'),
        content: Text(
          '${widget.cert.title ?? widget.cert.type.label} belgesi onaylansın mı?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _processDecision(approved: true);
  }

  Future<void> _reject() async {
    final reason = await showReasonDialog(
      context,
      title: 'Belgeyi reddet',
      reasonLabel: 'Red sebebi',
      reasonHint: 'Belge okunamıyor, süresi dolmuş vb.',
      requiredError: 'Red sebebi zorunludur.',
      confirmLabel: 'Reddet',
      maxLines: 3,
    );
    if (reason != null && mounted) {
      await _processDecision(approved: false, reason: reason);
    }
  }

  Future<void> _processDecision({required bool approved, String? reason}) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(certificateServiceProvider);
      if (approved) {
        await service.approveCertificate(
          certId: widget.cert.id,
          adminId: adminId,
        );
      } else {
        await service.rejectCertificate(
          certId: widget.cert.id,
          adminId: adminId,
          reason: reason!,
        );
      }
      // The decision has succeeded; remove it even if audit logging later
      // fails, so a reviewed certificate cannot remain in the queue.
      widget.onCompleted();
      await ref.read(adminServiceProvider).logAdminAction(
            AdminAction(
              adminId: adminId,
              actionType: approved
                  ? AdminActionType.approveCertificate
                  : AdminActionType.rejectCertificate,
              targetType: AdminActionTargetType.certificate,
              targetId: widget.cert.id,
              reason: reason,
              details: {
                'userId': widget.cert.userId,
                'certType': widget.cert.type.name,
                'certTitle': widget.cert.title,
              },
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Belge onaylandı.' : 'Belge reddedildi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'CertificateReviewScreen._decide');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument() async {
    final uri = Uri.tryParse(widget.cert.fileUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge açılamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cert = widget.cert;
    final name = cert.userName ?? cert.userEmail ?? cert.userId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(cert.isApproved
                      ? Icons.verified_outlined
                      : Icons.workspace_premium_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title ?? cert.type.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('$name · ${cert.type.label}'),
                    ],
                  ),
                ),
                Text(cert.status.label),
              ],
            ),
            const SizedBox(height: 10),
            Text('Yükleme: ${DateFormat('dd.MM.yyyy HH:mm').format(cert.createdAt)}'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Belge / Sertifika dosyası'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: _openDocument,
            ),
            if (cert.status == CertificateStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _reject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _approve,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Onayla'),
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
