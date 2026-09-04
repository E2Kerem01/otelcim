import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/listing_service.dart';

class ListingQrPosterScreen extends ConsumerWidget {
  const ListingQrPosterScreen({super.key, required this.listingId});

  final String listingId;

  String getPublicListingUrl(String id) => 'https://otelcim.app/listing/$id';

  Future<void> _sharePoster(BuildContext context, String title, String posterName, String id) async {
    final publicUrl = getPublicListingUrl(id);
    final text = '$title ($posterName)\n\nİlanı görüntülemek için tıklayın:\n$publicUrl';
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: '$title - QR Poster'),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingQrPosterScreen._sharePoster');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(singleListingProvider(listingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrPosterTitle),
      ),
      body: listingAsync.when(
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('İlan bulunamadı.'));
          }

          final publicUrl = getPublicListingUrl(listing.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel_rounded, color: Theme.of(context).primaryColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'OTELCİM İŞ İLANI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        listing.posterName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.category_outlined, size: 16),
                            label: Text(listingCategoryLabel(listing.category)),
                          ),
                          Chip(
                            avatar: const Icon(Icons.location_on_outlined, size: 16),
                            label: Text(listing.location),
                          ),
                          if (listing.salary.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.payments_outlined, size: 16),
                              label: Text(listing.salary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: publicUrl,
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.qrPosterScanInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        l10n.qrPosterFooter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sharePoster(context, listing.title, listing.posterName, listing.id),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(l10n.sharePosterAction),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
