import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/auth_service.dart';
import '../../profile/domain/certificate_model.dart';
import '../../profile/services/certificate_service.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';

class CertificateReviewScreen extends ConsumerWidget {
  const CertificateReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCertificatesAsync = ref.watch(pendingCertificatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belge Onay Kuyruğu'),
      ),
      body: pendingCertificatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Text('Bekleyen belgeler yüklenemedi: $err'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Bekleyen belge / sertifika bulunmuyor.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _AdminCertificateCard(cert: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _AdminCertificateCard extends ConsumerStatefulWidget {
  const _AdminCertificateCard({required this.cert});

  final Certificate cert;

  @override
  ConsumerState<_AdminCertificateCard> createState() =>
      __AdminCertificateCardState();
}

class __AdminCertificateCardState extends ConsumerState<_AdminCertificateCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Onayla'),
        content: Text(
          '${widget.cert.title ?? widget.cert.type.label} belgesi onaylansın mı? Kullanıcının profilinde onay rozeti gösterilecek.',
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

    if (confirmed != true) return;
    if (!mounted) return;

    await _processDecision(approved: true);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    String? error;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Belgeyi Reddet'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Red sebebi',
              hintText: 'Belge okunamıyor, süresi dolmuş vb.',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setState(() => error = 'Red sebebi zorunludur.');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Reddet'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (reason != null && mounted) {
      await _processDecision(approved: false, reason: reason);
    }
  }

  Future<void> _processDecision({required bool approved, String? reason}) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;

    setState(() => _busy = true);
    try {
      final certService = ref.read(certificateServiceProvider);
      if (approved) {
        await certService.approveCertificate(
          certId: widget.cert.id,
          adminId: adminId,
        );
      } else {
        await certService.rejectCertificate(
          certId: widget.cert.id,
          adminId: adminId,
          reason: reason!,
        );
      }

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
          SnackBar(
            content: Text(
              approved ? 'Belge onaylandı.' : 'Belge reddedildi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge açılamadı.')),
        );
      }
    }
  }

  IconData _getIconForType(CertificateType type) {
    switch (type) {
      case CertificateType.hijyen:
        return Icons.clean_hands_outlined;
      case CertificateType.cankurtaran:
        return Icons.pool_outlined;
      case CertificateType.ehliyet:
        return Icons.drive_eta_outlined;
      case CertificateType.dil:
        return Icons.g_translate_outlined;
      case CertificateType.diger:
        return Icons.card_membership_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cert = widget.cert;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                  child: Icon(
                    _getIconForType(cert.type),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title ?? cert.type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tür: ${cert.type.label}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanıcı: ${cert.userName ?? cert.userEmail ?? cert.userId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (cert.userEmail != null && cert.userName != null)
                    Text(
                      'E-posta: ${cert.userEmail}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  Text(
                    'Kullanıcı ID: ${cert.userId}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yükleme Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(cert.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Belge / Sertifika Dosyası'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _openDocument(cert.fileUrl),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _reject,
                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                    label: const Text('Reddet', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _approve,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
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
