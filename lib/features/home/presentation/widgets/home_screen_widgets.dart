import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/listing_service.dart';
import '../../../../shared/utils/match_score.dart';
import '../../../boosts/presentation/widgets/boost_badge.dart';
import '../../../favorites/services/favorite_service.dart';
import '../../../listings/domain/listing_model.dart';
import '../../../listings/presentation/season_utils.dart';
import 'listing_filters_panel.dart';

export 'listing_filters_panel.dart';

/// Widgets used by [HomeScreen] (see that file) split out to keep it
/// focused on the feed's own layout/state: the advanced filters model and
/// bottom sheet, the loading skeleton, and the listing card shown in both
/// grid and list view.

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key, required this.initial, required this.listingService});
  final HomeAdvancedFilters initial;
  final ListingService listingService;

  @override
  Widget build(BuildContext context) {
    return ListingFiltersPanel(
      initial: initial,
      listingService: listingService,
      onApply: (filters) => Navigator.pop(context, filters),
      onReset: () => Navigator.pop(context, const HomeAdvancedFilters()),
    );
  }
}

/// Skeleton placeholder cards shown while the initial page of listings loads.
class ListingsSkeletonSliver extends StatelessWidget {
  const ListingsSkeletonSliver({super.key, this.columnCount = 1});

  final int columnCount;

  @override
  Widget build(BuildContext context) {
    if (columnCount == 1) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonCard(columnCount: 1),
            ),
            childCount: 4,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columnCount == 2
              ? 0.80
              : columnCount == 3
                  ? 0.88
                  : 1.05,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => SkeletonCard(columnCount: columnCount),
          childCount: columnCount * 2,
        ),
      ),
    );
  }
}

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.columnCount = 1});
  final int columnCount;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGrid = widget.columnCount > 1;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.3);
        return Opacity(opacity: opacity, child: child);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(color: Colors.grey.shade300),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: double.infinity,
                            height: 12,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: 80,
                            height: 10,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 160,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing, this.columnCount = 1});

  final Listing listing;
  final int columnCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final uid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = uid == null
        ? false
        : ref
                  .watch(favoriteIdsProvider(uid))
                  .valueOrNull
                  ?.contains(listing.id) ??
              false;
    final profile = uid == null
        ? null
        : ref.watch(currentUserProfileProvider).valueOrNull;
    final matchScore = profile?.userType == 'jobseeker'
        ? calculateMatchScore(listing: listing, profile: profile!)
        : null;

    final isGrid = columnCount > 1;

    if (isGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: isBoostedActive ? 3 : 1,
        shape: isBoostedActive
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade400, width: 1.5),
              )
            : null,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}'),
          child: Container(
            decoration: isBoostedActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50.withValues(alpha: 0.35),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: Colors.grey.shade200,
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    listingCategoryColor(listing.category),
                                    listingCategoryColor(
                                      listing.category,
                                    ).withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  listingCategoryIcon(listing.category),
                                  size: 34,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 16,
                          tooltip: isFavorite
                              ? l10n.removeFromFavorites
                              : l10n.addToFavorites,
                          onPressed: () {
                            if (uid == null) {
                              unawaited(context.push('/login'));
                              return;
                            }
                            unawaited(ref
                                .read(favoriteServiceProvider)
                                .toggleFavorite(uid, listing.id));
                          },
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    if (isBoostedActive)
                      const Positioned(
                        top: 4,
                        left: 4,
                        child: BoostBadge(isCompact: true),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      listingCategoryLabel(listing.category),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                if (listing.isUrgent) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.urgentBadge,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: columnCount >= 3 ? 12 : 13,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF495057),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    listing.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF495057),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing.salary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: columnCount >= 3 ? 12 : 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isBoostedActive ? 3 : 1,
      shape: isBoostedActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amber.shade400, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Container(
          decoration: isBoostedActive
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade50.withValues(alpha: 0.35),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap, not a fixed Row: with large text (font scale 2.0)
                    // the badges used to overflow and push the favourite
                    // button and date off-screen (QA D31).
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listingCategoryLabel(listing.category),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isBoostedActive) ...[
                            const BoostBadge(isCompact: true),
                          ],
                          if (isSeasonalContract(listing.season)) ...[
                            SeasonBadge(season: listing.season!),
                          ],
                          if (matchScore != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '%$matchScore ${AppLocalizations.of(context)!.matchLabel}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          if (listing.isUrgent) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.urgentBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedScale(
                      scale: isFavorite ? 1.15 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite
                            ? l10n.removeFromFavorites
                            : l10n.addToFavorites,
                        onPressed: () {
                          if (uid == null) {
                            unawaited(context.push('/login'));
                            return;
                          }
                          unawaited(ref
                              .read(favoriteServiceProvider)
                              .toggleFavorite(uid, listing.id));
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (listing.createdAt != null)
                      Text(
                        '${listing.createdAt!.day}.${listing.createdAt!.month}.${listing.createdAt!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: Colors.grey.shade200,
                                width: 60,
                                height: 60,
                              ),
                              errorWidget: (_, _, _) => const Icon(
                                Icons.broken_image,
                                size: 24,
                                color: Colors.grey,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    listingCategoryColor(listing.category),
                                    listingCategoryColor(
                                      listing.category,
                                    ).withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  listingCategoryIcon(listing.category),
                                  size: 26,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listing.salary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Column header row for [ListingTableRow], mirroring a classifieds-style
/// table (image + title, category, location, price, date columns).
/// Hidden on mobile widths where the row itself stacks those fields instead.
class ListingTableHeader extends StatelessWidget {
  const ListingTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          const SizedBox(width: 56 + 12),
          Expanded(flex: 4, child: Text(l10n.columnListingTitle, style: style)),
          Expanded(flex: 2, child: Text(l10n.columnCategory, style: style)),
          Expanded(flex: 2, child: Text(l10n.columnLocation, style: style)),
          Expanded(
            flex: 2,
            child: Text(
              l10n.columnSalary,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              l10n.columnListingDate,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

/// A dense, single-row listing entry laid out in columns on wider screens
/// (thumbnail + title | category | location | salary | date), collapsing to
/// a stacked mobile row when there isn't room for separate columns.
class ListingTableRow extends ConsumerWidget {
  const ListingTableRow({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final uid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = uid == null
        ? false
        : ref
                  .watch(favoriteIdsProvider(uid))
                  .valueOrNull
                  ?.contains(listing.id) ??
              false;

    final dateLabel = listing.createdAt == null
        ? ''
        : '${listing.createdAt!.day.toString().padLeft(2, '0')}.'
              '${listing.createdAt!.month.toString().padLeft(2, '0')}.'
              '${listing.createdAt!.year}';

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: listing.images.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: listing.images.first,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(width: 56, height: 56, color: Colors.grey.shade200),
              errorWidget: (_, _, _) => const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.broken_image, size: 20, color: Colors.grey),
              ),
            )
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    listingCategoryColor(listing.category),
                    listingCategoryColor(listing.category)
                        .withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  listingCategoryIcon(listing.category),
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
    );

    final titleRow = Row(
      children: [
        Expanded(
          child: Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        if (listing.isUrgent) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context)!.urgentBadge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    final favoriteButton = SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        onPressed: () {
          if (uid == null) {
            unawaited(context.push('/login'));
            return;
          }
          unawaited(
            ref.read(favoriteServiceProvider).toggleFavorite(uid, listing.id),
          );
        },
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: isFavorite ? Colors.red : Colors.grey.shade500,
        ),
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isBoostedActive
              ? Colors.amber.shade400
              : Colors.grey.shade200,
          width: isBoostedActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: context.isMobile
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    thumbnail,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  listing.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  listing.salary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              if (dateLabel.isNotEmpty)
                                Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    favoriteButton,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    thumbnail,
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: titleRow),
                    Expanded(
                      flex: 2,
                      child: Text(
                        listingCategoryLabel(listing.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: listingCategoryColor(listing.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        listing.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        listing.salary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    favoriteButton,
                  ],
                ),
        ),
      ),
    );
  }
}
