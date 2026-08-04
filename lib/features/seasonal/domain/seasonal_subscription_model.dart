import 'package:cloud_firestore/cloud_firestore.dart';

class SeasonalSubscription {
  final String id;
  final String userId;
  final String? city;
  final String? category;
  final String? season;
  final bool enabled;
  final DateTime? createdAt;

  const SeasonalSubscription({
    required this.id,
    required this.userId,
    this.city,
    this.category,
    this.season,
    this.enabled = true,
    this.createdAt,
  });

  factory SeasonalSubscription.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SeasonalSubscription(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      city: data['city'] as String?,
      category: data['category'] as String?,
      season: data['season'] as String?,
      enabled: data['enabled'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'city': city,
        'category': category,
        'season': season,
        'enabled': enabled,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
