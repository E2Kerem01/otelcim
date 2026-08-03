import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/auth_service.dart';
import '../domain/admin_action_model.dart';
import '../domain/verification_request_model.dart';
import '../services/admin_service.dart';
import '../services/verification_service.dart';

final pendingVerificationsProvider = StreamProvider.autoDispose<List<VerificationRequest>>(
  (ref) => ref.watch(verificationServiceProvider).watchPendingVerifications(),
);

class VerificationReviewScreen extends ConsumerWidget {
  const VerificationReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingVerificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Doğrulama Talepleri')),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Doğrulama talepleri yüklenemedi.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Bekleyen doğrulama talebi bulunmuyor.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _VerificationCard(request: items[index]),
              ),
      ),
    );
  }
}

class _VerificationCard extends ConsumerStatefulWidget {
  const _VerificationCard({required this.request});
  final VerificationRequest request;
  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Doğrulamayı onayla'),
      content: Text('${widget.request.hotelName} için doğrulama talebi onaylansın mı?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Onayla'))],
    ));
    if (confirmed != true) return;
    if (!mounted) return;
    await _complete(approved: true);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    String? error;
    final reason = await showDialog<String>(context: context, builder: (context) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: const Text('Doğrulamayı reddet'),
      content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: InputDecoration(labelText: 'Red sebebi', errorText: error)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')), FilledButton(onPressed: () {
        final value = controller.text.trim();
        if (value.isEmpty) { setState(() => error = 'Red sebebi zorunludur.'); return; }
        Navigator.pop(context, value);
      }, child: const Text('Reddet'))],
    )));
    controller.dispose();
    if (reason != null && mounted) await _complete(approved: false, reason: reason);
  }

  Future<void> _complete({required bool approved, String? reason}) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(verificationServiceProvider);
      if (approved) {
        await service.approveVerification(verificationId: widget.request.id, adminId: adminId);
      } else {
        await service.rejectVerification(verificationId: widget.request.id, adminId: adminId, reason: reason!);
      }
      await ref.read(adminServiceProvider).logAdminAction(AdminAction(
        adminId: adminId,
        actionType: approved ? AdminActionType.approveVerification : AdminActionType.rejectVerification,
        targetType: AdminActionTargetType.verification,
        targetId: widget.request.id,
        reason: reason,
        details: {'employerId': widget.request.employerId, 'hotelName': widget.request.hotelName},
      ));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approved ? 'Doğrulama onaylandı.' : 'Doğrulama reddedildi.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem tamamlanamadı.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const CircleAvatar(child: Icon(Icons.apartment)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.hotelName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), Text('İşveren: ${request.employerId}')]))]),
      if (request.submittedAt != null) ...[const SizedBox(height: 10), Text('Gönderim: ${DateFormat('dd.MM.yyyy HH:mm').format(request.submittedAt!)}')],
      const Divider(height: 24),
      Text('Belgeler (${request.documentUrls.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
      if (request.documentUrls.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Belge eklenmemiş.')),
      for (var i = 0; i < request.documentUrls.length; i++) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.description_outlined), title: Text('Belge ${i + 1}'), trailing: const Icon(Icons.open_in_new), onTap: () => _openDocument(request.documentUrls[i])),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : _reject, icon: const Icon(Icons.close), label: const Text('Reddet'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _busy ? null : _approve, icon: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check), label: const Text('Onayla')))]),
    ])));
  }
}
