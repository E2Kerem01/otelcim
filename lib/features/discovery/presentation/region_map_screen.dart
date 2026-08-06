import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/listing_service.dart';
import '../../listings/domain/listing_model.dart';
import '../domain/region_map_data.dart';
import '../domain/tourism_region.dart';

enum MapSplitViewMode { split, list, map }

class RegionMapScreen extends ConsumerStatefulWidget {
  const RegionMapScreen({super.key});

  @override
  ConsumerState<RegionMapScreen> createState() => _RegionMapScreenState();
}

class _RegionMapScreenState extends ConsumerState<RegionMapScreen> {
  static const _turkeyCenter = LatLng(39.0, 35.0);
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  String? _hoveredRegionId;
  MapSplitViewMode _viewMode = MapSplitViewMode.split;
  bool _isHoverUpdatePending = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _scrollToRegion(String regionId) {
    final index = tourismRegions.indexWhere((r) => r.id == regionId);
    if (index != -1 &&
        _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      final targetOffset =
          (index * 76.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(targetOffset);
    }
  }

  void _setHoveredRegion(String? regionId, {bool scroll = false}) {
    if (_hoveredRegionId == regionId || _isHoverUpdatePending) return;
    _isHoverUpdatePending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isHoverUpdatePending = false;
      if (mounted && _hoveredRegionId != regionId) {
        setState(() {
          _hoveredRegionId = regionId;
        });
        if (regionId != null && scroll) {
          _scrollToRegion(regionId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.regionMapTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SegmentedButton<MapSplitViewMode>(
              key: const ValueKey('region_map_view_mode_segmented_button'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: MapSplitViewMode.split,
                  icon: Icon(Icons.vertical_split_rounded),
                  tooltip: 'Bölünmüş Ekran',
                ),
                ButtonSegment(
                  value: MapSplitViewMode.list,
                  icon: Icon(Icons.view_list_rounded),
                  tooltip: 'Liste',
                ),
                ButtonSegment(
                  value: MapSplitViewMode.map,
                  icon: Icon(Icons.map_rounded),
                  tooltip: 'Harita',
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (newSelection) {
                if (mounted) {
                  setState(() {
                    _viewMode = newSelection.first;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Listing>>(
        stream: ref.read(listingServiceProvider).watchActiveListings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.regionsLoadError));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final counts = countRegionListings(snapshot.data!);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;

              if (_viewMode == MapSplitViewMode.list) {
                return _buildRegionList(
                  context: context,
                  counts: counts,
                  isEnglish: isEnglish,
                  l10n: l10n,
                );
              }

              if (_viewMode == MapSplitViewMode.map) {
                return _buildRegionMap(
                  context: context,
                  counts: counts,
                  isEnglish: isEnglish,
                  l10n: l10n,
                );
              }

              if (isWide) {
                return Row(
                  children: [
                    SizedBox(
                      width: 360,
                      child: _buildRegionList(
                        context: context,
                        counts: counts,
                        isEnglish: isEnglish,
                        l10n: l10n,
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: _buildRegionMap(
                        context: context,
                        counts: counts,
                        isEnglish: isEnglish,
                        l10n: l10n,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildRegionMap(
                        context: context,
                        counts: counts,
                        isEnglish: isEnglish,
                        l10n: l10n,
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      flex: 5,
                      child: _buildRegionList(
                        context: context,
                        counts: counts,
                        isEnglish: isEnglish,
                        l10n: l10n,
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRegionList({
    required BuildContext context,
    required Map<String, int> counts,
    required bool isEnglish,
    required AppLocalizations l10n,
  }) {
    return ListView.separated(
      key: const PageStorageKey('region_map_list_view'),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: tourismRegions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final region = tourismRegions[index];
        final count = counts[region.id] ?? 0;
        final isHovered = _hoveredRegionId == region.id;
        final colorScheme = Theme.of(context).colorScheme;

        return MouseRegion(
          key: ValueKey('region_card_${region.id}'),
          onEnter: (_) => _setHoveredRegion(region.id),
          onExit: (_) => _setHoveredRegion(null),
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
              onTap: () => context.push('/regions/${region.id}'),
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered
                      ? colorScheme.primary
                      : colorScheme.secondaryContainer,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHovered
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: Text(
                isEnglish ? region.nameEn : region.nameTr,
                style: TextStyle(
                  fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
                  color: isHovered ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                l10n.activeListingCount(count),
                style: TextStyle(
                  color: isHovered
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isHovered ? colorScheme.primary : colorScheme.outline,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegionMap({
    required BuildContext context,
    required Map<String, int> counts,
    required bool isEnglish,
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FlutterMap(
      key: const PageStorageKey('region_flutter_map'),
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _turkeyCenter,
        initialZoom: 5.4,
        minZoom: 4,
        maxZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.otelcim.app',
          tileDisplay: const TileDisplay.instantaneous(),
        ),
        MarkerLayer(
          markers: tourismRegions.map((region) {
            final count = counts[region.id] ?? 0;
            final isHovered = _hoveredRegionId == region.id;
            final baseDiameter = regionMarkerDiameter(count);
            final diameter = isHovered ? baseDiameter + 12 : baseDiameter;

            return Marker(
              point: LatLng(region.latitude, region.longitude),
              width: 120,
              height: 100,
              child: MouseRegion(
                onEnter: (_) => _setHoveredRegion(region.id, scroll: true),
                onExit: (_) => _setHoveredRegion(null),
                child: GestureDetector(
                  onTap: () => context.push('/regions/${region.id}'),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: diameter,
                        height: diameter,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHovered
                              ? colorScheme.primary
                              : Color.lerp(
                                  colorScheme.primaryContainer,
                                  colorScheme.primary,
                                  (count / 15).clamp(0, 1),
                                ),
                          border: Border.all(
                            color: isHovered
                                ? colorScheme.onPrimary
                                : colorScheme.surface,
                            width: isHovered ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: isHovered ? 10 : 5,
                              color: isHovered
                                  ? colorScheme.primary.withValues(alpha: 0.5)
                                  : Colors.black26,
                              spreadRadius: isHovered ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isHovered
                                ? colorScheme.onPrimary
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? colorScheme.primaryContainer
                              : colorScheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isHovered
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          isEnglish ? region.nameEn : region.nameTr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isHovered
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
