import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/auth_service.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import '../services/moderation_service.dart';
import '../../../shared/utils/search_keywords.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';
import 'widgets/reason_dialog.dart';
import '../../../shared/providers/firestore_provider.dart';

/// Standalone admin screen to find any user and suspend/ban/unsuspend/unban
/// them. Server-side pagination (20 per page), filter tabs and prefix search
/// over `searchKeywords` keep it usable with any number of users.
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

const _userFilters = <AdminFilter>[
  AdminFilter('all', 'Tümü'),
  AdminFilter('jobseeker', 'İş arayan', icon: Icons.person_search_outlined),
  AdminFilter('employer', 'İşveren', icon: Icons.apartment_outlined),
  AdminFilter('verified', 'Doğrulanmış', icon: Icons.verified_outlined),
  AdminFilter('banned', 'Yasaklı', icon: Icons.block),
  AdminFilter('suspended', 'Askıda', icon: Icons.pause_circle_outline),
  AdminFilter('admin', 'Admin', icon: Icons.admin_panel_settings_outlined),
];

/// The Firestore query for a filter tab and optional search text. Exposed for
/// tests; composite indexes for every combination are in
/// firestore.indexes.json.
Query<Map<String, dynamic>> adminUsersQuery(
  FirebaseFirestore db, {
  required String filter,
  String search = '',
}) {
  Query<Map<String, dynamic>> query = db.collection('user_profiles');
  query = switch (filter) {
    'jobseeker' => query.where('userType', isEqualTo: 'jobseeker'),
    'employer' => query.where('userType', isEqualTo: 'employer'),
    'verified' => query.where('isVerified', isEqualTo: true),
    'banned' => query.where('isBanned', isEqualTo: true),
    'suspended' => query.where('isSuspended', isEqualTo: true),
    'admin' => query.where('isAdmin', isEqualTo: true),
    _ => query,
  };
  final token = searchToken(search);
  // Searching drops the createdAt ordering: relevance matters more than
  // recency there, and it keeps the index set small.
  return token != null
      ? query.where('searchKeywords', arrayContains: token)
      : query.orderBy('createdAt', descending: true);
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  late final AdminPagedController<UserProfile> _users = AdminPagedController(
    fromDoc: UserProfile.fromFirestore,
    idOf: (user) => user.id,
  );
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _users.dispose();
    super.dispose();
  }

  void _reload() {
    unawaited(_users.setQuery(adminUsersQuery(
      ref.read(firestoreProvider),
      filter: _filter,
      search: _searchController.text,
    )));
  }

  Future<void> _openUser(UserProfile user) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(child: _UserCard(user: user)),
        ),
      ),
    );
    await _users.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'İsim, e-posta, otel veya telefonla ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _reload();
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              onChanged: (value) {
                if (value.isEmpty) _reload();
                setState(() {});
              },
            ),
          ),
          AdminFilterBar(
            filters: _userFilters,
            selectedId: _filter,
            onSelected: (id) {
              setState(() => _filter = id);
              _reload();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AdminPagedView<UserProfile>(
              controller: _users,
              emptyText: 'Bu filtreyle kullanıcı bulunamadı.',
              cardBuilder: (_, user) => _UserCard(user: user),
              onRowTap: (user) => unawaited(_openUser(user)),
              columns: [
                AdminColumn(
                  label: 'Ad',
                  flex: 2,
                  cell: (_, u) => Text(u.displayName ?? '—', overflow: TextOverflow.ellipsis),
                ),
                AdminColumn(
                  label: 'E-posta',
                  flex: 3,
                  cell: (_, u) => Text(u.email, overflow: TextOverflow.ellipsis),
                ),
                AdminColumn(
                  label: 'Rol',
                  cell: (_, u) => Text(u.isAdmin
                      ? 'Admin'
                      : u.userType == 'employer'
                          ? 'İşveren'
                          : 'İş arayan'),
                ),
                AdminColumn(label: 'Durum', cell: (_, u) => _StatusChip(user: u)),
                AdminColumn(
                  label: 'Kayıt',
                  cell: (_, u) => Text(dateFormat.format(u.createdAt)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final (label, color) = user.isBanned
        ? ('Yasaklı', Colors.red)
        : user.isSuspended
            ? ('Askıda', Colors.orange)
            : user.isVerified
                ? ('Doğrulanmış', Colors.green)
                : ('Aktif', Colors.blueGrey);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerStatefulWidget {
  const _UserCard({required this.user});
  final UserProfile user;

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _busy = false;

  Future<void> _confirmAndRun(
    String title,
    String message,
    Future<void> Function(String adminId, String reason) action, {
    bool requireReason = false,
  }) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;

    final reason = await showReasonDialog(
      context,
      title: title,
      message: message,
      showReasonField: requireReason,
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await action(adminId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlandı.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'UserManagementScreen._runAction');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final moderation = ref.read(moderationServiceProvider);
    final name = (user.displayName?.isNotEmpty ?? false) ? user.displayName! : user.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            if (user.isBanned || user.isSuspended) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (user.isBanned)
                    Chip(
                      label: const Text('Yasaklı'),
                      backgroundColor: Colors.red.shade50,
                      labelStyle: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    ),
                  if (user.isSuspended)
                    Chip(
                      label: Text(
                        user.suspensionEnd != null
                            ? 'Askıda (${DateFormat('dd.MM.yyyy').format(user.suspensionEnd!)} kadar)'
                            : 'Askıda',
                      ),
                      backgroundColor: Colors.orange.shade50,
                      labelStyle: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.isBanned)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _confirmAndRun(
                              'Yasağı Kaldır',
                              '${user.email} kullanıcısının yasağını kaldırmak istiyor musunuz?',
                              (adminId, reason) async {
                                await moderation.unbanUser(userId: user.id, adminId: adminId);
                                await ref.read(adminServiceProvider).logAdminAction(
                                      AdminAction(
                                        adminId: adminId,
                                        actionType: AdminActionType.unbanUser,
                                        targetType: AdminActionTargetType.user,
                                        targetId: user.id,
                                        details: {'userEmail': user.email},
                                      ),
                                    );
                              },
                            ),
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Yasağı Kaldır'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => _confirmAndRun(
                              'Kullanıcıyı Yasakla',
                              '${user.email} kalıcı olarak yasaklanacak.',
                              (adminId, reason) async {
                                await moderation.banUser(
                                  userId: user.id,
                                  adminId: adminId,
                                  reason: reason,
                                );
                                await ref.read(adminServiceProvider).logAdminAction(
                                      AdminAction(
                                        adminId: adminId,
                                        actionType: AdminActionType.banUser,
                                        targetType: AdminActionTargetType.user,
                                        targetId: user.id,
                                        reason: reason,
                                        details: {'userEmail': user.email},
                                      ),
                                    );
                              },
                              requireReason: true,
                            ),
                    icon: const Icon(Icons.block),
                    label: const Text('Yasakla'),
                  ),
                if (user.isSuspended)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _confirmAndRun(
                              'Askıyı Kaldır',
                              '${user.email} kullanıcısının askısını kaldırmak istiyor musunuz?',
                              (adminId, reason) async {
                                await moderation.unsuspendUser(userId: user.id, adminId: adminId);
                                await ref.read(adminServiceProvider).logAdminAction(
                                      AdminAction(
                                        adminId: adminId,
                                        actionType: AdminActionType.unsuspendUser,
                                        targetType: AdminActionTargetType.user,
                                        targetId: user.id,
                                        details: {'userEmail': user.email},
                                      ),
                                    );
                              },
                            ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Askıyı Kaldır'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: (_busy || user.isBanned)
                        ? null
                        : () => _confirmAndRun(
                              'Kullanıcıyı Askıya Al',
                              '${user.email} 7 gün süreyle askıya alınacak.',
                              (adminId, reason) async {
                                await moderation.suspendUser(
                                  userId: user.id,
                                  adminId: adminId,
                                  reason: reason,
                                  suspensionEnd: DateTime.now().add(const Duration(days: 7)),
                                );
                                await ref.read(adminServiceProvider).logAdminAction(
                                      AdminAction(
                                        adminId: adminId,
                                        actionType: AdminActionType.suspendUser,
                                        targetType: AdminActionTargetType.user,
                                        targetId: user.id,
                                        reason: reason,
                                        details: {'userEmail': user.email},
                                      ),
                                    );
                              },
                              requireReason: true,
                            ),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Askıya Al (7 gün)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
