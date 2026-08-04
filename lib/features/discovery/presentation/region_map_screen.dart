import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/region_map_data.dart';
import '../domain/tourism_region.dart';
import 'regions_screen.dart';

class RegionMapScreen extends ConsumerWidget {
  const RegionMapScreen({super.key});

  static const _turkeyCenter = LatLng(39.0, 35.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listings = ref.watch(activeRegionListingsProvider);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionMapTitle)),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.regionsLoadError)),
        data: (activeListings) {
          final counts = countRegionListings(activeListings);
          return FlutterMap(
            options: MapOptions(
              initialCenter: _turkeyCenter,
              initialZoom: 5.4,
              minZoom: 4,
              maxZoom: 12,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(LatLng(34.5, 24.0), LatLng(43.0, 46.0)),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otelcim.app',
              ),
              MarkerLayer(
                markers: tourismRegions.map((region) {
                  final count = counts[region.id] ?? 0;
                  final diameter = regionMarkerDiameter(count);
                  return Marker(
                    point: LatLng(region.latitude, region.longitude),
                    width: diameter + 36,
                    height: diameter + 28,
                    child: Semantics(
                      button: true,
                      label:
                          '${isEnglish ? region.nameEn : region.nameTr}, '
                          '${l10n.activeListingCount(count)}',
                      child: InkWell(
                        onTap: () => context.push('/regions/${region.id}'),
                        customBorder: const CircleBorder(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: diameter,
                              height: diameter,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  Theme.of(context).colorScheme.primary,
                                  (count / 15).clamp(0, 1),
                                ),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 5,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              isEnglish ? region.nameEn : region.nameTr,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(l10n.regionMapAttribution),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
