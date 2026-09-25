import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../domain/boost_purchase_model.dart';
import '../services/boost_service.dart';
import 'widgets/boost_badge.dart';

final _userBoostPurchasesProvider = StreamProvider.family<List<BoostPurchase>, String>((ref, userId) {
  return ref.watch(boostServiceProvider).watchUserBoostPurchases(userId);
});

class MyBoostsScreen extends ConsumerWidget {
  const MyBoostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(authStateProvider).value?.uid;
    if (userId == null) {
      return Scaffold(
        body: Center(child: Text(l10n.listingBoostLoginRequired)),
      );
    }

    final boostsAsync = ref.watch(_userBoostPurchasesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listingMyBoostsTitle),
      ),
      body: boostsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.listingMyBoostsError('$err'))),
        data: (purchases) {
          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.listingMyBoostsEmptyTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.listingMyBoostsEmptyBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/my-listings'),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: Text(l10n.listingMyBoostsAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return _BoostPurchaseCard(purchase: purchase);
            },
          );
        },
      ),
    );
  }
}

class _BoostPurchaseCard extends ConsumerWidget {
  final BoostPurchase purchase;

  const _BoostPurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(singleListingProvider(purchase.listingId));

    final purchasedAt = purchase.purchasedAt;
    final dateStr = purchasedAt != null
        ? '${purchasedAt.day}.${purchasedAt.month}.${purchasedAt.year}'
        : '-';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BoostBadge(isCompact: true),
                const SizedBox(width: 8),
                Text(
                  l10n.listingBoostPackage(purchase.durationType),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '₺${purchase.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            listingAsync.when(
              loading: () => Text(l10n.listingBoostLoading),
              error: (err, stack) => Text(l10n.listingBoostInfoError),
              data: (listing) {
                if (listing == null) return Text(l10n.listingBoostMissing);

                final isBoostedActive = BoostBadge.isBoostActive(listing);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBoostedActive ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isBoostedActive ? Colors.green.shade300 : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            isBoostedActive ? l10n.listingBoostActive : l10n.listingBoostExpired,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isBoostedActive ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        l10n.listingBoostPurchaseDate(dateStr),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (listing.boostExpiresAt != null && isBoostedActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.listingBoostExpiryDate('${listing.boostExpiresAt!.day}.${listing.boostExpiresAt!.month}.${listing.boostExpiresAt!.year}'),
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/listing/${listing.id}'),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: Text(l10n.listingBoostGoToListing),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/listing/${listing.id}/boost'),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                          label: Text(isBoostedActive ? l10n.listingBoostExtend : l10n.listingBoostRenew),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
