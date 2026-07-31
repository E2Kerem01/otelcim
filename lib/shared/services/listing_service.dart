import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listings/domain/listing_model.dart';

class ListingService {
  ListingService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Listing>> watchActiveListings({String? category, String? searchQuery}) {
    Query<Map<String, dynamic>> query =
        _db.collection('listings').where('status', isEqualTo: 'active').orderBy('createdAt', descending: true);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snap) {
      var listings = snap.docs.map(Listing.fromDoc).toList();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        listings = listings.where((l) => l.title.toLowerCase().contains(q)).toList();
      }
      return listings;
    }).handleError((error) {
      debugPrint('Firestore watchActiveListings warning: $error');
      return <Listing>[];
    });
  }

  Stream<List<Listing>> watchMyListings(String uid) {
    return _db
        .collection('listings')
        .where('posterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromDoc).toList())
        .handleError((error) {
      debugPrint('Firestore watchMyListings warning: $error');
      return <Listing>[];
    });
  }

  Future<String> createListing(Listing listing) async {
    final ref = await _db.collection('listings').add(listing.toMap());
    return ref.id;
  }

  Future<void> updateListing(Listing listing) {
    return _db.collection('listings').doc(listing.id).update(listing.toMap());
  }

  Future<void> closeListing(String listingId) {
    return _db.collection('listings').doc(listingId).update({'status': 'closed'});
  }

  Future<Listing?> getListing(String listingId) async {
    try {
      final doc = await _db.collection('listings').doc(listingId).get();
      if (!doc.exists) return null;
      return Listing.fromDoc(doc);
    } catch (e) {
      debugPrint('Firestore getListing error: $e');
      return null;
    }
  }
}

final listingServiceProvider = Provider<ListingService>((ref) => ListingService(FirebaseFirestore.instance));
