import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/services/auth_service.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../../listings/domain/listing_model.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: uid == null
          ? const Center(child: Text('Favorilerinizi görmek için giriş yapın.'))
          : ref.watch(favoriteListingsProvider(uid)).when(
                data: (listings) => listings.isEmpty
                    ? const _EmptyFavorites()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: listings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _FavoriteCard(listing: listings[index], uid: uid),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Favoriler yüklenemedi. Lütfen tekrar deneyin.')),
              ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Henüz favori ilanınız yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Beğendiğiniz ilanlardaki kalp simgesine dokunarak buraya ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.listing, required this.uid});

  final Listing listing;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = listing.status == ListingStatus.closed;
    final deleted = closed && listing.posterId.isEmpty;
    final boosted = !closed && BoostBadge.isBoostActive(listing);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: boosted ? 3 : 1,
      shape: boosted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amber.shade400, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: deleted ? null : () => context.push('/listing/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  listingCategoryLabel(listing.category),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
              if (boosted) ...[const SizedBox(width: 8), const BoostBadge(isCompact: true)],
              if (closed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text('Kapandı', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              AnimatedScale(
                scale: 1.15,
                duration: const Duration(milliseconds: 180),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Favorilerden çıkar',
                  onPressed: () => ref.read(favoriteServiceProvider).toggleFavorite(uid, listing.id),
                  icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (listing.images.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: listing.images.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.grey.shade200, width: 60, height: 60),
                    errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (listing.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(listing.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                  ]),
                ],
              ])),
            ]),
            if (listing.salary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(listing.salary, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ],
          ]),
        ),
      ),
    );
  }
}
