import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';

final _auditFilters = <AdminFilter>[
  const AdminFilter('all', 'Tüm işlemler'),
  for (final type in AdminActionType.values)
    AdminFilter(type.name, type.label),
];

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  late final AdminPagedController<AdminAction> _controller =
      AdminPagedController<AdminAction>(
        fromDoc: (doc) => AdminAction.fromDoc(doc),
        idOf: (action) => action.id,
      );
  AdminActionType? _type;
  String? _adminId;

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
    unawaited(_controller.setQuery(adminAuditLogQuery(
      FirebaseFirestore.instance,
      adminId: _adminId,
      actionType: _type,
    )));
  }

  Future<void> _filterAdmin() async {
    final textController = TextEditingController(text: _adminId);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yöneticiye göre filtrele'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Yönetici kimliği',
            hintText: 'UID girin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Filtreyi temizle'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (!mounted || value == null) return;
    setState(() => _adminId = value.isEmpty ? null : value);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _type?.name ?? 'all';
    return Scaffold(
      appBar: AppBar(title: const Text('İşlem Geçmişi')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminFilterBar(
                  filters: _auditFilters,
                  selectedId: selectedId,
                  onSelected: (id) {
                    setState(() {
                      _type = id == 'all'
                          ? null
                          : AdminActionType.values.firstWhere(
                              (type) => type.name == id,
                            );
                    });
                    _reload();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: IconButton.filledTonal(
                  onPressed: _filterAdmin,
                  tooltip: 'Yönetici filtresi',
                  icon: Badge(
                    isLabelVisible: _adminId != null,
                    child: const Icon(Icons.person_search_outlined),
                  ),
                ),
              ),
            ],
          ),
          if (_adminId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InputChip(
                label: Text('Yönetici: $_adminId'),
                onDeleted: () {
                  setState(() => _adminId = null);
                  _reload();
                },
              ),
            ),
          Expanded(
            child: AdminPagedView<AdminAction>(
              controller: _controller,
              emptyText: 'Bu filtrelerle eşleşen işlem bulunmuyor.',
              cardBuilder: (_, action) => _ActionCard(action: action),
              columns: [
                AdminColumn(
                  label: 'Zaman',
                  flex: 2,
                  cell: (_, action) => Text(
                    action.timestamp == null
                        ? '—'
                        : DateFormat('dd.MM.yyyy HH:mm')
                            .format(action.timestamp!),
                  ),
                ),
                AdminColumn(
                  label: 'Admin',
                  flex: 2,
                  cell: (_, action) => Text(
                    action.adminId,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'İşlem',
                  flex: 2,
                  cell: (_, action) => Text(action.actionType.label),
                ),
                AdminColumn(
                  label: 'Hedef',
                  flex: 2,
                  cell: (_, action) => Text(
                    '${action.targetType.label}: ${action.targetId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Sebep',
                  flex: 2,
                  cell: (_, action) => Text(
                    action.reason?.isNotEmpty == true ? action.reason! : '—',
                    overflow: TextOverflow.ellipsis,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final AdminAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icon(action.actionType))),
        title: Text(
          action.actionType.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${action.targetType.label}: ${action.targetId}'),
            Text('Yönetici: ${action.adminId}'),
            if (action.reason?.isNotEmpty == true) Text('Sebep: ${action.reason}'),
            if (action.timestamp != null)
              Text(DateFormat('dd.MM.yyyy HH:mm').format(action.timestamp!)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _icon(AdminActionType type) => switch (type) {
        AdminActionType.dismissReport => Icons.close,
        AdminActionType.warnUser => Icons.warning_amber,
        AdminActionType.removeListing => Icons.delete_outline,
        AdminActionType.restoreListing => Icons.restore_outlined,
        AdminActionType.suspendUser => Icons.pause_circle_outline,
        AdminActionType.unsuspendUser => Icons.play_circle_outline,
        AdminActionType.banUser => Icons.block,
        AdminActionType.unbanUser => Icons.lock_open_outlined,
        AdminActionType.approveVerification => Icons.verified_outlined,
        AdminActionType.rejectVerification => Icons.gpp_bad_outlined,
        AdminActionType.approveCertificate => Icons.workspace_premium_outlined,
        AdminActionType.rejectCertificate => Icons.remove_moderator_outlined,
      };
}
