import 'package:cloud_firestore/cloud_firestore.dart';

class BannerAd {
  final String id;
  final String title;
  final String advertiserName;
  final String imageUrl;
  final String targetUrl;
  final int order;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  const BannerAd({
    required this.id,
    required this.title,
    required this.advertiserName,
    required this.imageUrl,
    required this.targetUrl,
    this.order = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  factory BannerAd.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return BannerAd(
      id: doc.id,
      title: data['title'] as String? ?? '',
      advertiserName: data['advertiserName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      targetUrl: data['targetUrl'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'advertiserName': advertiserName,
        'imageUrl': imageUrl,
        'targetUrl': targetUrl,
        'order': order,
        'isActive': isActive,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  BannerAd copyWith({
    String? id,
    String? title,
    String? advertiserName,
    String? imageUrl,
    String? targetUrl,
    int? order,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return BannerAd(
      id: id ?? this.id,
      title: title ?? this.title,
      advertiserName: advertiserName ?? this.advertiserName,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
