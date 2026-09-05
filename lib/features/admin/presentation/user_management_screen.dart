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

final _recentUsersProvider = StreamProvider.autoDispose<List<UserProfile>>(
  (ref) => ref.watch(adminServiceProvider).watchRecentUsers(),
);

/// Standalone admin screen to search any user and suspend/ban/unsuspend/
/// unban their account directly - previously these actions were only
/// reachable by opening a report against that user first.
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  List<UserProfile>? _searchResults;
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _searching = true);
    final results = await ref.read(adminServiceProvider).searchUsers(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentUsers = ref.watch(_recentUsersProvider);
    final listToShow = _searchResults;

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'E-posta veya isimle ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = null);
                            },
                          )
                        : null),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _runSearch,
              onChanged: (value) {
                if (value.trim().isEmpty) setState(() => _searchResults = null);
              },
            ),
          ),
          Expanded(
            child: listToShow != null
                ? (listToShow.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı.'))
                    : _UserList(users: listToShow))
                : recentUsers.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('Kullanıcılar yüklenemedi.')),
                    data: (items) => items.isEmpty
                        ? const Center(child: Text('Henüz kullanıcı yok.'))
                        : _UserList(users: items),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users});
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _UserCard(user: users[index]),
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
    Future<void> Function(String adminId) action, {
    bool requireReason = false,
  }) async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;

    final reasonController = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (requireReason) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Sebep (zorunlu)',
                    errorText: error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (requireReason && reasonController.text.trim().isEmpty) {
                  setDialogState(() => error = 'Sebep girmeniz gerekiyor.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Onayla'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await action(adminId);
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
                              (adminId) async {
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
                              (adminId) async {
                                const reason = 'Admin panelinden yasaklandı';
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
                              (adminId) async {
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
                              (adminId) async {
                                const reason = 'Admin panelinden askıya alındı';
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
