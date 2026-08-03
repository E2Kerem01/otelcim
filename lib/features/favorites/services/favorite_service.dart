import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/listing_service.dart';
import '../../listings/domain/listing_model.dart';

class FavoriteService {
  FavoriteService(this._db, this._listingService);

  final FirebaseFirestore _db;
  final ListingService _listingService;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _db.collection('user_profiles').doc(uid).collection('favorites');

  Future<void> toggleFavorite(String uid, String listingId) async {
    final favorite = _favorites(uid).doc(listingId);
    final snapshot = await favorite.get();
    if (snapshot.exists) {
      await favorite.delete();
    } else {
      await favorite.set({
        'listingId': listingId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isFavorite(String uid, String listingId) async {
    return (await _favorites(uid).doc(listingId).get()).exists;
  }

  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _favorites(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['listingId'] as String? ?? doc.id)
              .toSet(),
        );
  }

  Stream<List<Listing>> watchFavoriteListings(String uid) {
    return _favorites(uid).snapshots().asyncMap((snapshot) async {
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['addedAt'] as Timestamp?;
          final bDate = b.data()['addedAt'] as Timestamp?;
          return (bDate?.millisecondsSinceEpoch ?? 0)
              .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
        });
      return Future.wait(docs.map((favorite) async {
        final id = favorite.data()['listingId'] as String? ?? favorite.id;
        return await _listingService.getListing(id) ??
            Listing(
              id: id,
              posterId: '',
              posterName: '',
              title: 'Bu ilan artık mevcut değil',
              description: '',
              category: 'diger',
              location: '',
              salary: '',
              contactInfo: '',
              status: ListingStatus.closed,
            );
      }));
    });
  }
}

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(FirebaseFirestore.instance, ref.watch(listingServiceProvider));
});

final favoriteIdsProvider = StreamProvider.family<Set<String>, String>((ref, uid) {
  return ref.watch(favoriteServiceProvider).watchFavoriteIds(uid);
});

final favoriteListingsProvider = StreamProvider.family<List<Listing>, String>((ref, uid) {
  return ref.watch(favoriteServiceProvider).watchFavoriteListings(uid);
});
