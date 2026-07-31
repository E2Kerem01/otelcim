import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listing.dart';
import '../models/listing_status.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_form.dart';

/// Screen for editing an existing job listing.
///
/// This screen allows employers to:
/// - Update listing details (title, description, category, location, salary, images)
/// - Mark a listing as 'filled' (position hired)
/// - Mark a listing as 'closed' (no longer accepting applications)
///
/// Only the listing creator can edit their own listings. The screen verifies
/// ownership before allowing any modifications.
///
/// Route parameters:
/// - [listingId]: The ID of the listing to edit
///
/// Example navigation:
/// ```dart
/// context.go('/listings/$listingId/edit');
/// ```
class EditListingScreen extends ConsumerStatefulWidget {
  /// The ID of the listing to edit
  final String listingId;

  const EditListingScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  bool _isUpdating = false;

  /// Shows a dialog to confirm marking the listing with a specific status
  Future<void> _showStatusChangeDialog(
    BuildContext context,
    Listing listing,
    ListingStatus newStatus,
  ) async {
    final statusText = newStatus == ListingStatus.filled ? 'dolduruldu' : 'kapalı';
    final statusAction = newStatus == ListingStatus.filled ? 'Dolduruldu' : 'Kapalı';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İlanı $statusAction Olarak İşaretle'),
        content: Text(
          'Bu ilanı "$statusText" olarak işaretlemek istediğinizden emin misiniz?\n\n'
          '${newStatus == ListingStatus.filled ? 'İlan artık başvuru kabul etmeyecektir.' : 'İlan kapatılacaktır.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(statusAction),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _updateListingStatus(listing, newStatus);
    }
  }

  /// Updates the listing status in Firestore
  Future<void> _updateListingStatus(Listing listing, ListingStatus newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final listingService = ref.read(listingServiceProvider);
      await listingService.updateListingStatus(widget.listingId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan durumu güncellendi: ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  /// Handles form submission to save listing changes
  Future<void> _handleSaveListing(Map<String, dynamic> data, Listing currentListing) async {
    try {
      final listingService = ref.read(listingServiceProvider);

      // TODO: Handle image uploads to Firebase Storage
      // For now, we'll keep existing image URLs and skip new image files
      final imageUrls = List<String>.from(data['existingImageUrls'] as List);

      // Create updated listing
      final updatedListing = currentListing.copyWith(
        title: data['title'] as String,
        description: data['description'] as String,
        category: data['category'] as String,
        location: data['location'] as String,
        salary: data['salary'] as String,
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      await listingService.updateListing(updatedListing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;

    // Watch the listing data
    final listingAsync = ref.watch(listingProvider(widget.listingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        elevation: 0,
      ),
      body: listingAsync.when(
        data: (listing) {
          // Check if listing exists
          if (listing == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'İlan bulunamadı',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Verify user is the listing creator
          if (currentUser == null || listing.createdBy != currentUser.uid) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu ilanı düzenleme yetkiniz yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sadece ilan sahibi düzenleme yapabilir',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }

          // Build the edit form with status change buttons
          return Column(
            children: [
              // Status buttons section
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlan Durumu: ${listing.status.displayName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Mark as Filled button
                        if (listing.status == ListingStatus.active)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _showStatusChangeDialog(
                                        context,
                                        listing,
                                        ListingStatus.filled,
                                      ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Dolduruldu'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (listing.status == ListingStatus.active) const SizedBox(width: 8),
                        // Mark as Closed button
                        if (listing.status == ListingStatus.active)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _showStatusChangeDialog(
                                        context,
                                        listing,
                                        ListingStatus.closed,
                                      ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Kapat'),
                            ),
                          ),
                        // Reactivate button (if listing is closed or filled)
                        if (listing.status != ListingStatus.active)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateListingStatus(
                                        listing,
                                        ListingStatus.active,
                                      ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Aktifleştir'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit form
              Expanded(
                child: ListingForm(
                  initialListing: listing,
                  onSubmit: (data) => _handleSaveListing(data, listing),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'İlan yüklenirken hata oluştu',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Invalidate the provider to retry
                  ref.invalidate(listingProvider(widget.listingId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
