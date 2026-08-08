import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final userId = ref.watch(authStateProvider).value?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın.')),
      );
    }

    final boostsAsync = ref.watch(_userBoostPurchasesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öne Çıkarılanlarım'),
      ),
      body: boostsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
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
                    const Text(
                      'Henüz Öne Çıkarılmış İlanınız Yok',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlanlarınızı öne çıkararak 10 kata kadar daha fazla görüntülenme ve başvuru alabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/my-listings'),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('İlanlarıma Git ve Öne Çıkar'),
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
                  '${purchase.durationType} Günlük Paket',
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
              loading: () => const Text('İlan yükleniyor...'),
              error: (err, stack) => const Text('İlan bilgisi alınamadı.'),
              data: (listing) {
                if (listing == null) return const Text('İlan silinmiş veya bulunamadı.');

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
                            isBoostedActive ? 'Aktif' : 'Süresi Doldu',
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
                      'Satın Alma Tarihi: $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (listing.boostExpiresAt != null && isBoostedActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Bitiş Tarihi: ${listing.boostExpiresAt!.day}.${listing.boostExpiresAt!.month}.${listing.boostExpiresAt!.year}',
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
                          label: const Text('İlana Git'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/listing/${listing.id}/boost'),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                          label: Text(isBoostedActive ? 'Süreyi Uzat' : 'Tekrar Öne Çıkar'),
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
