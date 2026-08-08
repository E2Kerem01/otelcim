import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../listings/domain/listing_model.dart';
import '../domain/admin_action_model.dart';
import '../services/admin_service.dart';
import '../services/moderation_service.dart';

final _recentListingsProvider = StreamProvider.autoDispose<List<Listing>>(
  (ref) => ref.watch(listingServiceProvider).watchRecentListingsForAdmin(),
);

/// Standalone admin screen to search any listing and remove/restore it
/// directly - previously removeListing was only reachable by opening a
/// report against that listing first.
class ListingManagementScreen extends ConsumerStatefulWidget {
  const ListingManagementScreen({super.key});

  @override
  ConsumerState<ListingManagementScreen> createState() => _ListingManagementScreenState();
}

class _ListingManagementScreenState extends ConsumerState<ListingManagementScreen> {
  final _searchController = TextEditingController();
  List<Listing>? _searchResults;
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
    final results = await ref.read(listingServiceProvider).searchListingsForAdmin(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentListings = ref.watch(_recentListingsProvider);
    final listToShow = _searchResults;

    return Scaffold(
      appBar: AppBar(title: const Text('İlan Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'İlan başlığıyla ara',
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
                    : _ListingList(listings: listToShow))
                : recentListings.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('İlanlar yüklenemedi.')),
                    data: (items) => items.isEmpty
                        ? const Center(child: Text('Henüz ilan yok.'))
                        : _ListingList(listings: items),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ListingList extends StatelessWidget {
  const _ListingList({required this.listings});
  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _ListingCard(listing: listings[index]),
    );
  }
}

class _ListingCard extends ConsumerStatefulWidget {
  const _ListingCard({required this.listing});
  final Listing listing;

  @override
  ConsumerState<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<_ListingCard> {
  bool _busy = false;

  Future<void> _remove() async {
    final adminId = ref.read(authServiceProvider).currentUser?.uid;
    if (adminId == null) return;

    final reasonController = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('İlanı Kaldır'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${widget.listing.title}" ilanı kaldırılacak.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Sebep (zorunlu)', errorText: error),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  setDialogState(() => error = 'Sebep girmeniz gerekiyor.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Kaldır'),
            ),
          ],
        ),
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan kaldırıldı.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı. Lütfen tekrar deneyin.')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan geri yüklendi.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final statusInfo = switch (listing.status) {
      ListingStatus.active => (label: 'Aktif', color: Colors.green),
      ListingStatus.closed => (label: 'Kapalı', color: Colors.grey),
      ListingStatus.removed => (label: 'Kaldırıldı', color: Colors.red),
    };

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
                Chip(
                  label: Text(statusInfo.label, style: const TextStyle(fontSize: 12)),
                  backgroundColor: statusInfo.color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: statusInfo.color),
                  visualDensity: VisualDensity.compact,
                ),
                if (_busy) ...[
                  const SizedBox(width: 8),
                  const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.posterName} • ${listingCategoryLabel(listing.category)} • ${listing.location}',
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
