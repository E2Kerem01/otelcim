import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/listing_service.dart';
import '../domain/nearby_listing.dart';
import '../services/location_service.dart';

enum NearbyViewMode { split, list, map }

class NearbyListingsScreen extends ConsumerStatefulWidget {
  const NearbyListingsScreen({super.key});

  @override
  ConsumerState<NearbyListingsScreen> createState() =>
      _NearbyListingsScreenState();
}

class _NearbyListingsScreenState extends ConsumerState<NearbyListingsScreen> {
  static const _radii = <double>[25, 50, 100];
  double _radiusKm = 25;
  Position? _position;
  LocationFailure? _failure;
  bool _loading = false;

  String? _hoveredListingId;
  NearbyViewMode _viewMode = NearbyViewMode.split;
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.nearbyPermissionTitle),
        content: Text(l10n.nearbyPermissionExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
    if (!mounted || consent != true) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _position = result.position;
      _failure = result.failure;
    });
  }

  String _failureText(AppLocalizations l10n) => switch (_failure) {
        LocationFailure.servicesDisabled => l10n.nearbyServicesDisabled,
        LocationFailure.denied => l10n.nearbyLocationDenied,
        LocationFailure.deniedForever => l10n.nearbyLocationDeniedForever,
        _ => l10n.nearbyLocationUnavailable,
      };

  void _scrollToListing(String listingId, List<NearbyListing> results) {
    final index = results.indexWhere((r) => r.listing.id == listingId);
    if (index != -1 &&
        _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      final targetOffset =
          (index * 92.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(targetOffset);
    }
  }

  void _setHoveredListing(
    String? listingId, {
    bool scroll = false,
    List<NearbyListing>? results,
  }) {
    if (_hoveredListingId != listingId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hoveredListingId != listingId) {
          setState(() {
            _hoveredListingId = listingId;
          });
          if (listingId != null && scroll && results != null) {
            _scrollToListing(listingId, results);
          }
        }
      });
    }
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 25) return 11.0;
    if (radiusKm <= 50) return 9.8;
    return 8.6;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SegmentedButton<NearbyViewMode>(
              key: const ValueKey('nearby_view_mode_segmented_button'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: NearbyViewMode.split,
                  icon: Icon(Icons.vertical_split_rounded),
                  tooltip: 'Bölünmüş',
                ),
                ButtonSegment(
                  value: NearbyViewMode.list,
                  icon: Icon(Icons.view_list_rounded),
                  tooltip: 'Liste',
                ),
                ButtonSegment(
                  value: NearbyViewMode.map,
                  icon: Icon(Icons.map_rounded),
                  tooltip: 'Harita',
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) {
                if (mounted) {
                  setState(() => _viewMode = selection.first);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('${l10n.radiusLabel}:'),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<double>(
                    segments: _radii
                        .map(
                          (radius) => ButtonSegment(
                            value: radius,
                            label: Text('${radius.toInt()} km'),
                          ),
                        )
                        .toList(),
                    selected: {_radiusKm},
                    onSelectionChanged: (selection) {
                      if (mounted) {
                        setState(() {
                          _radiusKm = selection.first;
                        });
                        if (_position != null) {
                          _mapController.move(
                            LatLng(_position!.latitude, _position!.longitude),
                            _zoomForRadius(_radiusKm),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildContent(l10n)),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_position == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(
                _failure == null
                    ? l10n.nearbyPermissionExplanation
                    : _failureText(l10n),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _requestLocation,
                icon: const Icon(Icons.my_location),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }
    return StreamBuilder(
      stream: ref.read(listingServiceProvider).watchActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l10n.nearbyLocationUnavailable));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = nearbyListings(
          listings: snapshot.data!,
          userLat: _position!.latitude,
          userLng: _position!.longitude,
          radiusKm: _radiusKm,
        );

        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.nearbyEmpty, textAlign: TextAlign.center),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 768;

            if (_viewMode == NearbyViewMode.list) {
              return _buildList(results, l10n);
            }

            if (_viewMode == NearbyViewMode.map) {
              return _buildMap(results, l10n);
            }

            if (isWide) {
              return Row(
                children: [
                  SizedBox(width: 380, child: _buildList(results, l10n)),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: _buildMap(results, l10n)),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(flex: 4, child: _buildMap(results, l10n)),
                  const Divider(height: 1, thickness: 1),
                  Expanded(flex: 5, child: _buildList(results, l10n)),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildList(List<NearbyListing> results, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      key: const PageStorageKey('nearby_list_view'),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        final isHovered = _hoveredListingId == item.listing.id;

        return MouseRegion(
          key: ValueKey('nearby_card_${item.listing.id}'),
          onEnter: (_) => _setHoveredListing(item.listing.id),
          onExit: (_) => _setHoveredListing(null),
          child: Material(
            color: isHovered
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isHovered ? colorScheme.primary : colorScheme.outlineVariant,
                width: isHovered ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => context.push('/listing/${item.listing.id}'),
              leading: CircleAvatar(
                backgroundColor: isHovered
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                foregroundColor: isHovered
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimaryContainer,
                child: const Icon(Icons.hotel_outlined),
              ),
              title: Text(
                item.listing.title,
                style: TextStyle(
                  fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
                  color: isHovered ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '${item.listing.location}\n${item.listing.salary}',
              ),
              isThreeLine: true,
              trailing: Text(
                l10n.distanceKm(item.distanceKm.toStringAsFixed(1)),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(List<NearbyListing> results, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final userCenter = LatLng(_position!.latitude, _position!.longitude);

    final markers = <Marker>[];

    // User location marker
    markers.add(
      Marker(
        point: userCenter,
        width: 48,
        height: 48,
        child: Tooltip(
          message: 'Konumunuz',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Listing markers
    for (final item in results) {
      if (item.listing.lat == null || item.listing.lng == null) continue;

      final isHovered = _hoveredListingId == item.listing.id;
      final point = LatLng(item.listing.lat!, item.listing.lng!);

      markers.add(
        Marker(
          point: point,
          width: isHovered ? 160 : 44,
          height: isHovered ? 80 : 44,
          child: MouseRegion(
            onEnter: (_) => _setHoveredListing(
              item.listing.id,
              scroll: true,
              results: results,
            ),
            onExit: (_) => _setHoveredListing(null),
            child: InkWell(
              onTap: () => context.push('/listing/${item.listing.id}'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHovered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.primary, width: 1.5),
                        boxShadow: const [
                          BoxShadow(blurRadius: 6, color: Colors.black26),
                        ],
                      ),
                      child: Text(
                        item.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  Container(
                    width: isHovered ? 40 : 32,
                    height: isHovered ? 40 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHovered
                          ? colorScheme.primary
                          : colorScheme.secondaryContainer,
                      border: Border.all(
                        color: isHovered ? Colors.white : colorScheme.surface,
                        width: isHovered ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: isHovered ? 8 : 4,
                          color: isHovered
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : Colors.black26,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.hotel_outlined,
                      size: isHovered ? 22 : 18,
                      color: isHovered
                          ? colorScheme.onPrimary
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      key: const PageStorageKey('nearby_flutter_map'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userCenter,
        initialZoom: _zoomForRadius(_radiusKm),
        minZoom: 4,
        maxZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.otelcim.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
