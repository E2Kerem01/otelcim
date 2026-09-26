import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/utils/match_score.dart';
import '../../../boosts/presentation/widgets/boost_badge.dart';
import '../../../favorites/services/favorite_service.dart';
import '../../../listings/domain/listing_model.dart';
import '../../../listings/presentation/listing_filter_labels.dart';
import '../../../listings/presentation/season_utils.dart';

/// Text-first feed card: the job title, employer, location and pay lead;
/// perks (housing, meals, shuttle) are chips; the category is a small icon.
/// A real listing photo, when there is one, shows as a small thumbnail -
/// no large placeholder blocks, so a phone shows 4-5 listings per screen.
///
/// Used for both the single-column list and the multi-column grid.
class ListingFeedCard extends ConsumerWidget {
  const ListingFeedCard({
    super.key,
    required this.listing,
    this.onTap,
    this.isSelected = false,
  });

  final Listing listing;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = uid != null &&
        (ref.watch(favoriteIdsProvider(uid)).valueOrNull?.contains(listing.id) ?? false);
    final profile = uid == null ? null : ref.watch(currentUserProfileProvider).valueOrNull;
    final matchScore = profile?.userType == 'jobseeker'
        ? calculateMatchScore(listing: listing, profile: profile!)
        : null;
    final isBoosted = BoostBadge.isBoostActive(listing);
    final place = [listing.city, listing.location]
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    final created = listing.createdAt;

    final perks = <Widget>[
      if (listing.housingRoomType != null)
        _PerkChip(icon: Icons.home_outlined, label: l10n.perkHousing),
      if ((listing.housingMealsIncluded ?? 0) > 0)
        _PerkChip(
          icon: Icons.restaurant_outlined,
          label: l10n.perkMeals(listing.housingMealsIncluded!),
        ),
      if ((listing.staffShuttleRoute ?? '').trim().isNotEmpty)
        _PerkChip(icon: Icons.directions_bus_outlined, label: l10n.perkShuttle),
      if (listing.employmentType != null)
        _PerkChip(
          icon: Icons.schedule_outlined,
          label: employmentTypeLabel(l10n, listing.employmentType!),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : isBoosted
            ? BorderSide(color: theme.colorScheme.tertiary, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/listing/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Leading(listing: listing),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                [listing.posterName, if (place.isNotEmpty) place]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            if (listing.posterVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: theme.colorScheme.primary,
                                semanticLabel: l10n.verifiedEmployer,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
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
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (created != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Text(
                            '${created.day}.${created.month}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (listing.salary.trim().isNotEmpty)
                      Text(
                        listing.salary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (listing.isUrgent) _UrgentBadge(label: l10n.urgentBadge),
                    if (isBoosted) const BoostBadge(isCompact: true),
                    if (isSeasonalContract(listing.season))
                      SeasonBadge(season: listing.season!),
                    if (matchScore != null && matchScore > 0)
                      Text(
                        '%$matchScore ${l10n.matchLabel}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (perks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Wrap(spacing: 6, runSpacing: 6, children: perks),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A real photo thumbnail when the listing has one, otherwise a small
/// category icon - never a large placeholder.
class _Leading extends StatelessWidget {
  const _Leading({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final color = listingCategoryColor(listing.category);
    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(listingCategoryIcon(listing.category), color: color, size: 24),
    );
    if (listing.images.isEmpty) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: listing.images.first,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, _) => icon,
        errorWidget: (_, _, _) => icon,
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onError,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
