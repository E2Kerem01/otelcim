import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/listing_service.dart';
import '../../listings/domain/listing_model.dart';
import '../domain/tourism_region.dart';

final activeRegionListingsProvider = StreamProvider<List<Listing>>((ref) {
  return ref.watch(listingServiceProvider).watchActiveListings();
});

class RegionsScreen extends ConsumerWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listings = ref.watch(activeRegionListingsProvider);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.regionsTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/regions/map'),
            tooltip: l10n.regionMapTitle,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.regionsLoadError)),
        data: (activeListings) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tourismRegions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final region = tourismRegions[index];
            final count = activeListings
                .where((listing) => listing.region == region.id)
                .length;
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(isEnglish ? region.nameEn : region.nameTr),
                subtitle: Text(l10n.activeListingCount(count)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/regions/${region.id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
