import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/listing_service.dart';
import '../domain/nearby_listing.dart';
import '../services/location_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbyTitle)),
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
                    onSelectionChanged: (selection) =>
                        setState(() => _radiusKm = selection.first),
                  ),
                ),
              ],
            ),
          ),
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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = results[index];
            return Card(
              child: ListTile(
                onTap: () => context.push('/listing/${item.listing.id}'),
                leading: const CircleAvatar(child: Icon(Icons.hotel_outlined)),
                title: Text(item.listing.title),
                subtitle: Text(
                  '${item.listing.location}\n${item.listing.salary}',
                ),
                isThreeLine: true,
                trailing: Text(
                  l10n.distanceKm(item.distanceKm.toStringAsFixed(1)),
                  textAlign: TextAlign.end,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
