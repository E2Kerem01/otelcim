import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import '../models/listing_status.dart';

/// Service for managing job listings in Firestore.
///
/// Provides CRUD operations for job listings including:
/// - Creating new listings
/// - Updating existing listings
/// - Fetching listings by ID or user
/// - Streaming real-time updates
/// - Deleting listings
class ListingService {
  final FirebaseFirestore _firestore;

  /// Collection name for listings in Firestore
  static const String _collectionName = 'listings';

  /// Creates a new ListingService instance.
  ///
  /// If [firestore] is not provided, uses the default FirebaseFirestore instance.
  ListingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a reference to the listings collection.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// Creates a new listing in Firestore.
  ///
  /// The [listing] parameter should have all required fields populated.
  /// Returns the ID of the created listing.
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<String> createListing(Listing listing) async {
    try {
      final docRef = await _collection.add(listing.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  /// Updates an existing listing in Firestore.
  ///
  /// The [listing] parameter should include the ID of the listing to update
  /// and any fields that need to be changed. The [updatedAt] field is
  /// automatically set to the current timestamp.
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> updateListing(Listing listing) async {
    try {
      // Ensure updatedAt is set to current time
      final updatedListing = listing.copyWith(
        updatedAt: DateTime.now(),
      );

      await _collection.doc(listing.id).update(updatedListing.toMap());
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Updates the status of a listing.
  ///
  /// This is a convenience method for changing only the status field
  /// (e.g., marking as 'filled' or 'closed').
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    try {
      await _collection.doc(listingId).update({
        'status': status.toFirestore(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update listing status: $e');
    }
  }

  /// Fetches a single listing by its ID.
  ///
  /// Returns the [Listing] if found, or `null` if the listing doesn't exist.
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<Listing?> getListing(String listingId) async {
    try {
      final doc = await _collection.doc(listingId).get();

      if (!doc.exists) {
        return null;
      }

      return Listing.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get listing: $e');
    }
  }

  /// Fetches all listings created by a specific user.
  ///
  /// Returns a list of [Listing] objects ordered by creation date (newest first).
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<List<Listing>> getUserListings(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Listing.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user listings: $e');
    }
  }

  /// Streams all listings created by a specific user.
  ///
  /// Returns a [Stream] that emits a list of [Listing] objects whenever
  /// the user's listings change in Firestore. Listings are ordered by
  /// creation date (newest first).
  ///
  /// Useful for real-time updates in the UI.
  Stream<List<Listing>> watchUserListings(String userId) {
    try {
      return _collection
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Listing.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to watch user listings: $e');
    }
  }

  /// Streams a single listing by its ID.
  ///
  /// Returns a [Stream] that emits the [Listing] whenever it changes
  /// in Firestore, or `null` if the listing doesn't exist.
  ///
  /// Useful for real-time updates on the listing detail screen.
  Stream<Listing?> watchListing(String listingId) {
    try {
      return _collection.doc(listingId).snapshots().map((doc) {
        if (!doc.exists) {
          return null;
        }
        return Listing.fromMap(doc.data()!, doc.id);
      });
    } catch (e) {
      throw Exception('Failed to watch listing: $e');
    }
  }

  /// Fetches all active listings.
  ///
  /// Returns a list of [Listing] objects with status 'active',
  /// ordered by creation date (newest first).
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<List<Listing>> getActiveListings() async {
    try {
      final querySnapshot = await _collection
          .where('status', isEqualTo: ListingStatus.active.toFirestore())
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Listing.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active listings: $e');
    }
  }

  /// Streams all active listings.
  ///
  /// Returns a [Stream] that emits a list of active [Listing] objects
  /// whenever active listings change in Firestore. Listings are ordered
  /// by creation date (newest first).
  ///
  /// Useful for the job feed screen.
  Stream<List<Listing>> watchActiveListings() {
    try {
      return _collection
          .where('status', isEqualTo: ListingStatus.active.toFirestore())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Listing.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to watch active listings: $e');
    }
  }

  /// Deletes a listing from Firestore.
  ///
  /// This permanently removes the listing. Consider using [updateListingStatus]
  /// to mark it as 'closed' instead if you want to preserve the data.
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> deleteListing(String listingId) async {
    try {
      await _collection.doc(listingId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }
}
