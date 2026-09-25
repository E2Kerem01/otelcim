import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/search_keywords.dart';
import '../../listings/domain/listing_model.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import '../services/moderation_service.dart';
import 'widgets/admin_paged_controller.dart';
import 'widgets/admin_paged_view.dart';
import 'widgets/reason_dialog.dart';
import '../../../shared/providers/firestore_provider.dart';

const _listingFilters = <AdminFilter>[
  AdminFilter('all', 'Tümü'),
  AdminFilter('active', 'Aktif', icon: Icons.check_circle_outline),
  AdminFilter('closed', 'Kapalı', icon: Icons.pause_circle_outline),
  AdminFilter('removed', 'Kaldırılmış', icon: Icons.delete_outline),
  AdminFilter('urgent', 'Acil', icon: Icons.priority_high),
  AdminFilter('featured', 'Öne çıkan', icon: Icons.star_outline),
];

/// Firestore query used by the paginated admin listing screen.
///
/// Search intentionally omits an orderBy, as in the user management screen:
/// Firestore can then use the array-contains search index together with the
/// selected equality filter. The normal list is newest first.
Query<Map<String, dynamic>> adminListingsQuery(
  FirebaseFirestore db, {
  required String filter,
  String search = '',
}) {
  Query<Map<String, dynamic>> query = db.collection('listings');
  query = switch (filter) {
    'active' => query.where('status', isEqualTo: 'active'),
    'closed' => query.where('status', isEqualTo: 'closed'),
    'removed' => query.where('status', isEqualTo: 'removed'),
    'urgent' => query.where('isUrgent', isEqualTo: true),
    'featured' => query.where('isBoosted', isEqualTo: true),
    _ => query,
  };

  final token = searchToken(search);
  return token != null
      ? query.where('searchKeywords', arrayContains: token)
      : query.orderBy('createdAt', descending: true);
}

class ListingManagementScreen extends ConsumerStatefulWidget {
  const ListingManagementScreen({super.key});

  @override
  ConsumerState<ListingManagementScreen> createState() =>
      _ListingManagementScreenState();
}

class _ListingManagementScreenState
    extends ConsumerState<ListingManagementScreen> {
  final _searchController = TextEditingController();
  late final AdminPagedController<Listing> _listings = AdminPagedController(
    fromDoc: Listing.fromDoc,
    idOf: (listing) => listing.id,
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
    _listings.dispose();
    super.dispose();
  }

  void _reload() {
    unawaited(
      _listings.setQuery(
        adminListingsQuery(
          ref.read(firestoreProvider),
          filter: _filter,
          search: _searchController.text,
        ),
      ),
    );
  }

  Future<void> _openListing(Listing listing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: _ListingCard(
              listing: listing,
              onChanged: () => unawaited(_listings.refresh()),
            ),
          ),
        ),
      ),
    );
    await _listings.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Başlık, işveren veya konumla ara',
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
            filters: _listingFilters,
            selectedId: _filter,
            onSelected: (id) {
              setState(() => _filter = id);
              _reload();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AdminPagedView<Listing>(
              controller: _listings,
              emptyText: 'Bu filtreyle ilan bulunamadı.',
              cardBuilder: (_, listing) => _ListingCard(
                listing: listing,
                onChanged: () => unawaited(_listings.refresh()),
              ),
              onRowTap: (listing) => unawaited(_openListing(listing)),
              columns: [
                AdminColumn(
                  label: 'Başlık',
                  flex: 2,
                  cell: (_, listing) => Text(
                    listing.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'İşveren',
                  flex: 2,
                  cell: (_, listing) => Text(
                    listing.posterName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Konum',
                  flex: 2,
                  cell: (_, listing) => Text(
                    listing.city ?? listing.location,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminColumn(
                  label: 'Durum',
                  cell: (_, listing) => _ListingStatusChip(listing: listing),
                ),
                AdminColumn(
                  label: 'Oluşturma',
                  cell: (_, listing) => Text(
                    listing.createdAt == null
                        ? '—'
                        : dateFormat.format(listing.createdAt!),
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

class _ListingStatusChip extends StatelessWidget {
  const _ListingStatusChip({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (listing.status) {
      ListingStatus.active => ('Aktif', Colors.green),
      ListingStatus.closed => ('Kapalı', Colors.grey),
      ListingStatus.removed => ('Kaldırılmış', Colors.red),
    };
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
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends ConsumerStatefulWidget {
  const _ListingCard({required this.listing, this.onChanged});

  final Listing listing;
  final VoidCallback? onChanged;

  @override
  ConsumerState<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<_ListingCard> {
  bool _busy = false;

  Future<void> _remove() async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;
    final reason = await showReasonDialog(
      context,
      title: 'İlanı Kaldır',
      message: '"${widget.listing.title}" ilanı kaldırılacak.',
      confirmLabel: 'Kaldır',
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(moderationServiceProvider).removeListing(
            listingId: widget.listing.id,
            adminId: adminId,
            reason: reason,
          );
      await ref.read(adminServiceProvider).logAdminAction(
            AdminAction(
              adminId: adminId,
              actionType: AdminActionType.removeListing,
              targetType: AdminActionTargetType.listing,
              targetId: widget.listing.id,
              reason: reason,
              details: {'listingTitle': widget.listing.title},
            ),
          );
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan kaldırıldı.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingManagementScreen._remove');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(moderationServiceProvider).restoreListing(
            listingId: widget.listing.id,
            adminId: adminId,
          );
      await ref.read(adminServiceProvider).logAdminAction(
            AdminAction(
              adminId: adminId,
              actionType: AdminActionType.restoreListing,
              targetType: AdminActionTargetType.listing,
              targetId: widget.listing.id,
              details: {'listingTitle': widget.listing.title},
            ),
          );
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan geri yüklendi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingManagementScreen._restore');
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
    final listing = widget.listing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _ListingStatusChip(listing: listing),
                if (_busy) ...[
                  const SizedBox(width: 8),
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.posterName} • ${listing.city ?? listing.location}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (listing.createdAt != null)
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(listing.createdAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/listing/${listing.id}'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('İlanı Aç'),
                ),
                const Spacer(),
                if (listing.status == ListingStatus.removed)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Geri Yükle'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _remove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Kaldır'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
