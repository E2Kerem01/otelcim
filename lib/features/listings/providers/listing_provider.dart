import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';

/// Provider for the ListingService instance.
///
/// This provider creates and manages a single instance of [ListingService]
/// that can be used throughout the app to interact with listing data.
final listingServiceProvider = Provider<ListingService>((ref) {
  return ListingService(firestore: FirebaseFirestore.instance);
});

/// Provider for streaming listings created by a specific user.
///
/// This is a family provider that takes a userId as parameter and returns
/// a stream of listings for that user. The stream updates in real-time
/// whenever the user's listings change in Firestore.
///
/// Example usage:
/// ```dart
/// final userListingsAsync = ref.watch(userListingsProvider('userId123'));
/// ```
final userListingsProvider = StreamProvider.family<List<Listing>, String>(
  (ref, userId) {
    final listingService = ref.watch(listingServiceProvider);
    return listingService.watchUserListings(userId);
  },
);

/// Provider for streaming a single listing by its ID.
///
/// This is a family provider that takes a listingId as parameter and returns
/// a stream of the listing. The stream updates in real-time whenever the
/// listing changes in Firestore.
///
/// Returns `null` if the listing doesn't exist.
///
/// Example usage:
/// ```dart
/// final listingAsync = ref.watch(listingProvider('listingId123'));
/// ```
final listingProvider = StreamProvider.family<Listing?, String>(
  (ref, listingId) {
    final listingService = ref.watch(listingServiceProvider);
    return listingService.watchListing(listingId);
  },
);

/// Provider for streaming all active listings.
///
/// This provider returns a stream of all active job listings in the system,
/// ordered by creation date (newest first). Useful for displaying the job feed.
///
/// Example usage:
/// ```dart
/// final activeListingsAsync = ref.watch(activeListingsProvider);
/// ```
final activeListingsProvider = StreamProvider<List<Listing>>((ref) {
  final listingService = ref.watch(listingServiceProvider);
  return listingService.watchActiveListings();
});

/// State provider for managing the currently selected listing ID.
///
/// This is useful for tracking which listing is currently being viewed
/// or edited in the UI. Initialize with `null` to indicate no selection.
///
/// Example usage:
/// ```dart
/// // Read the selected listing ID
/// final selectedId = ref.watch(selectedListingIdProvider);
///
/// // Set a new selected listing ID
/// ref.read(selectedListingIdProvider.notifier).state = 'listingId123';
///
/// // Clear the selection
/// ref.read(selectedListingIdProvider.notifier).state = null;
/// ```
final selectedListingIdProvider = StateProvider<String?>((ref) => null);
