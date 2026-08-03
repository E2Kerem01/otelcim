import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rating_model.dart';

class RatingService {
  RatingService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _db.collection('ratings');

  Future<void> submitRating(Rating rating) async {
    if (rating.stars < 1 || rating.stars > 5) {
      throw ArgumentError.value(rating.stars, 'stars', '1 ile 5 arasında olmalı');
    }
    if ((rating.reviewText?.length ?? 0) > 500) {
      throw ArgumentError.value(
        rating.reviewText,
        'reviewText',
        'En fazla 500 karakter olabilir',
      );
    }

    final documentId = rating.id.isEmpty
        ? '${rating.conversationId}_${rating.raterId}'
        : rating.id;
    final reference = _ratings.doc(documentId);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw StateError('Bu görüşme için zaten değerlendirme yaptınız.');
      }
      transaction.set(reference, rating.toMap());
    });
  }

  Stream<List<Rating>> watchUserRatings(String userId) {
    return _ratings.where('ratedUserId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(Rating.fromDoc)
              .where(
                (rating) =>
                    rating.moderationStatus == RatingModerationStatus.approved,
              )
              .toList(),
        );
  }

  Future<double> getAverageRating(String userId) async {
    final snapshot = await _ratings
        .where('ratedUserId', isEqualTo: userId)
        .get();
    final ratings = snapshot.docs
        .map(Rating.fromDoc)
        .where(
          (rating) =>
              rating.moderationStatus == RatingModerationStatus.approved,
        )
        .toList();
    if (ratings.isEmpty) return 0;
    return ratings.fold<int>(0, (total, rating) => total + rating.stars) /
        ratings.length;
  }
}

final ratingServiceProvider = Provider<RatingService>(
  (ref) => RatingService(FirebaseFirestore.instance),
);

final userRatingsProvider =
    StreamProvider.family<List<Rating>, String>((ref, userId) {
  return ref.watch(ratingServiceProvider).watchUserRatings(userId);
});
