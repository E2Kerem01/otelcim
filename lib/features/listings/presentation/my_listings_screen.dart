import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../domain/listing_model.dart';

final _myListingsProvider = StreamProvider.family<List<Listing>, String>((ref, uid) {
  return ref.watch(listingServiceProvider).watchMyListings(uid);
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final listingsAsync = ref.watch(_myListingsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listingMyListingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: l10n.batchCreateButton,
            onPressed: () => context.push('/batch-create-listing'),
          ),
          IconButton(
            icon: const Icon(Icons.rocket_launch_outlined),
            tooltip: l10n.listingMyBoostsTitle,
            onPressed: () => context.push('/my-boosts'),
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(child: Text(l10n.listingMyListingsEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final listing = listings[index];
              final isBoostedActive = BoostBadge.isBoostActive(listing);

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: listing.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: listing.images.first,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: Colors.grey.shade200, width: 48, height: 48),
                            errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 20),
                          ),
                        )
                      : null,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBoostedActive) ...[
                        const SizedBox(width: 8),
                        const BoostBadge(isCompact: true),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${listingCategoryLabelFor(l10n, listing.category)} · ${switch (listing.status) {
                        ListingStatus.active => l10n.listingStatusActive,
                        ListingStatus.closed => l10n.listingStatusClosed,
                        ListingStatus.removed => l10n.listingStatusRemoved,
                      }}',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (listing.status == ListingStatus.active)
                        IconButton(
                          icon: Icon(
                            Icons.rocket_launch_rounded,
                            color: isBoostedActive ? Colors.amber.shade800 : Theme.of(context).primaryColor,
                          ),
                          tooltip: isBoostedActive ? l10n.listingBoostManage : l10n.listingBoostActionShort,
                          onPressed: () => context.push('/listing/${listing.id}/boost'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.listingEditAction,
                        onPressed: () => context.push('/listing/${listing.id}/edit'),
                      ),
                      if (listing.status == ListingStatus.active)
                        TextButton(
                          onPressed: () => ref.read(listingServiceProvider).closeListing(listing.id),
                          child: Text(l10n.listingCloseAction),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/listing/${listing.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.listingGenericError('$error'))),
      ),
    );
  }
}
