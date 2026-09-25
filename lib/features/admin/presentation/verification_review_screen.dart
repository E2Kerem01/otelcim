import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../domain/admin_action_model.dart';
import '../domain/verification_request_model.dart';
import '../services/admin_service.dart';
import '../services/verification_service.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';
import 'widgets/reason_dialog.dart';
import '../../../shared/providers/firestore_provider.dart';

final pendingVerificationsProvider =
    StreamProvider.autoDispose<List<VerificationRequest>>(
  (ref) => ref.watch(verificationServiceProvider).watchPendingVerifications(),
);

const _verificationFilters = <AdminFilter>[
  AdminFilter('pending', 'Bekleyen', icon: Icons.hourglass_top_outlined),
  AdminFilter('approved', 'Onaylanan', icon: Icons.verified_outlined),
  AdminFilter('rejected', 'Reddedilen', icon: Icons.gpp_bad_outlined),
  AdminFilter('all', 'Tümü'),
];

class VerificationReviewScreen extends ConsumerStatefulWidget {
  const VerificationReviewScreen({super.key});

  @override
  ConsumerState<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState
    extends ConsumerState<VerificationReviewScreen> {
  late final AdminPagedController<VerificationRequest> _controller =
      AdminPagedController<VerificationRequest>(
        fromDoc: (doc) => VerificationRequest.fromDoc(doc),
        idOf: (request) => request.id,
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
    unawaited(_controller.setQuery(adminVerificationQuery(
      ref.read(firestoreProvider),
      filter: _filter,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doğrulama Talepleri')),
      body: Column(
        children: [
          AdminFilterBar(
            filters: _verificationFilters,
            selectedId: _filter,
            onSelected: (id) {
              setState(() => _filter = id);
              _reload();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AdminPagedView<VerificationRequest>(
              controller: _controller,
              emptyText: 'Bu filtreyle doğrulama talebi bulunamadı.',
              cardBuilder: (_, request) => _VerificationCard(
                request: request,
                onCompleted: () => _controller.removeWhere(
                  (item) => item.id == request.id,
                ),
              ),
              columns: [
                AdminColumn(
                  label: 'Otel / Kişi',
                  flex: 2,
                  cell: (_, request) => Text(
                    '${request.hotelName}\n${request.employerId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Belge sayısı',
                  cell: (_, request) => Text('${request.documentUrls.length}'),
                ),
                AdminColumn(
                  label: 'Gönderim',
                  cell: (_, request) => Text(
                    request.submittedAt == null
                        ? '—'
                        : DateFormat('dd.MM.yyyy HH:mm')
                            .format(request.submittedAt!),
                  ),
                ),
                AdminColumn(
                  label: 'Durum',
                  cell: (_, request) => Text(request.status.label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends ConsumerStatefulWidget {
  const _VerificationCard({required this.request, required this.onCompleted});

  final VerificationRequest request;
  final VoidCallback onCompleted;

  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doğrulamayı onayla'),
        content: Text(
          '${widget.request.hotelName} için doğrulama talebi onaylansın mı?',
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
    if (confirmed == true && mounted) await _complete(approved: true);
  }

  Future<void> _reject() async {
    final reason = await showReasonDialog(
      context,
      title: 'Doğrulamayı reddet',
      reasonLabel: 'Red sebebi',
      requiredError: 'Red sebebi zorunludur.',
      confirmLabel: 'Reddet',
      maxLines: 3,
    );
    if (reason != null && mounted) {
      await _complete(approved: false, reason: reason);
    }
  }

  Future<void> _complete({required bool approved, String? reason}) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(verificationServiceProvider);
      if (approved) {
        await service.approveVerification(
          verificationId: widget.request.id,
          adminId: adminId,
        );
      } else {
        await service.rejectVerification(
          verificationId: widget.request.id,
          adminId: adminId,
          reason: reason!,
        );
      }
      // The decision has succeeded; remove it even if audit logging later
      // fails, so a reviewed request cannot remain in the queue.
      widget.onCompleted();
      await ref.read(adminServiceProvider).logAdminAction(
            AdminAction(
              adminId: adminId,
              actionType: approved
                  ? AdminActionType.approveVerification
                  : AdminActionType.rejectVerification,
              targetType: AdminActionTargetType.verification,
              targetId: widget.request.id,
              reason: reason,
              details: {
                'employerId': widget.request.employerId,
                'hotelName': widget.request.hotelName,
              },
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Doğrulama onaylandı.' : 'Doğrulama reddedildi.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationReviewScreen._decide');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(String value) async {
    final uri = Uri.tryParse(value);
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
    final request = widget.request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.apartment)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.hotelName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('İşveren: ${request.employerId}'),
                    ],
                  ),
                ),
                Text(request.status.label),
              ],
            ),
            if (request.submittedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'Gönderim: ${DateFormat('dd.MM.yyyy HH:mm').format(request.submittedAt!)}',
              ),
            ],
            const Divider(height: 24),
            Text(
              'Belgeler (${request.documentUrls.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (request.documentUrls.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Belge eklenmemiş.'),
              ),
            for (var i = 0; i < request.documentUrls.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text('Belge ${i + 1}'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openDocument(request.documentUrls[i]),
              ),
            if (request.status == VerificationStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _reject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
          ],
        ),
      ),
    );
  }
}
