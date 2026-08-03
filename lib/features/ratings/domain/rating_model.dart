import 'package:cloud_firestore/cloud_firestore.dart';

enum RatingModerationStatus { pending, approved, flagged }

class Rating {
  const Rating({
    required this.id,
    required this.conversationId,
    required this.raterId,
    required this.ratedUserId,
    required this.stars,
    this.reviewText,
    this.createdAt,
    this.moderationStatus = RatingModerationStatus.approved,
  }) : assert(stars >= 1 && stars <= 5);

  final String id;
  final String conversationId;
  final String raterId;
  final String ratedUserId;
  final int stars;
  final String? reviewText;
  final DateTime? createdAt;
  final RatingModerationStatus moderationStatus;

  factory Rating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Rating(
      id: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      raterId: data['raterId'] as String? ?? '',
      ratedUserId: data['ratedUserId'] as String? ?? '',
      stars: ((data['stars'] as num?)?.toInt() ?? 1).clamp(1, 5).toInt(),
      reviewText: data['reviewText'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      moderationStatus: RatingModerationStatus.values.firstWhere(
        (status) => status.name == data['moderationStatus'],
        orElse: () => RatingModerationStatus.approved,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'raterId': raterId,
        'ratedUserId': ratedUserId,
        'stars': stars,
        'reviewText': reviewText,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'moderationStatus': moderationStatus.name,
      };
}
