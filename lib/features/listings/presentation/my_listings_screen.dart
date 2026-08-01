import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../domain/listing_model.dart';

final _myListingsProvider = StreamProvider.family<List<Listing>, String>((ref, uid) {
  return ref.watch(listingServiceProvider).watchMyListings(uid);
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final listingsAsync = ref.watch(_myListingsProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('İlanlarım')),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('Henüz ilan vermediniz.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                child: ListTile(
                  title: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${listingCategoryLabel(listing.category)} · ${listing.status == ListingStatus.active ? 'Aktif' : 'Kapalı'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Düzenle',
                        onPressed: () => context.push('/listing/${listing.id}/edit'),
                      ),
                      if (listing.status == ListingStatus.active)
                        TextButton(
                          onPressed: () => ref.read(listingServiceProvider).closeListing(listing.id),
                          child: const Text('Kapat'),
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
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }
}
