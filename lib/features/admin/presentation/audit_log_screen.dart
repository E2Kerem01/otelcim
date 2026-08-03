import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AdminActionType? _type;
  String? _adminId;

  Stream<List<AdminAction>> _stream() => ref.read(adminServiceProvider).watchAuditLog(
        adminId: _adminId,
        actionType: _type,
        limit: 100,
      );

  Future<void> _filterAdmin() async {
    final controller = TextEditingController(text: _adminId);
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Yöneticiye göre filtrele'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Yönetici kimliği', hintText: 'UID girin')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Filtreyi temizle')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Uygula')),
      ],
    ));
    controller.dispose();
    if (!mounted) return;
    if (value != null) setState(() => _adminId = value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('İşlem Geçmişi')),
    body: Column(children: [
      Material(color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: DropdownButtonFormField<AdminActionType?>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'İşlem tipi', isDense: true),
          items: [const DropdownMenuItem<AdminActionType?>(value: null, child: Text('Tüm işlemler')), ...AdminActionType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label)))],
          onChanged: (value) => setState(() => _type = value),
        )),
        const SizedBox(width: 10),
        IconButton.filledTonal(onPressed: _filterAdmin, tooltip: 'Yönetici filtresi', icon: Badge(isLabelVisible: _adminId != null, child: const Icon(Icons.person_search_outlined))),
      ]))),
      if (_adminId != null) Container(width: double.infinity, color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: InputChip(label: Text('Yönetici: $_adminId'), onDeleted: () => setState(() => _adminId = null))),
      Expanded(child: StreamBuilder<List<AdminAction>>(
        key: ValueKey('${_type?.name}|$_adminId'),
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('İşlem geçmişi yüklenemedi. Filtreler için Firestore dizini gerekebilir.'));
          final actions = snapshot.data ?? [];
          if (actions.isEmpty) return const Center(child: Text('Bu filtrelerle eşleşen işlem bulunmuyor.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _ActionCard(action: actions[index]),
          );
        },
      )),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final AdminAction action;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: CircleAvatar(child: Icon(_icon(action.actionType))),
    title: Text(action.actionType.label, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Text('${action.targetType.label}: ${action.targetId}'),
      Text('Yönetici: ${action.adminId}'),
      if (action.reason?.isNotEmpty == true) Text('Sebep: ${action.reason}'),
      if (action.timestamp != null) Text(DateFormat('dd.MM.yyyy HH:mm').format(action.timestamp!)),
    ]),
    isThreeLine: true,
  ));

  IconData _icon(AdminActionType type) => switch (type) {
    AdminActionType.dismissReport => Icons.close,
    AdminActionType.warnUser => Icons.warning_amber,
    AdminActionType.removeListing => Icons.delete_outline,
    AdminActionType.suspendUser => Icons.pause_circle_outline,
    AdminActionType.banUser => Icons.block,
    AdminActionType.approveVerification => Icons.verified_outlined,
    AdminActionType.rejectVerification => Icons.gpp_bad_outlined,
  };
}
