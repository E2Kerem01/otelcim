import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { active, closed }

class Listing {
  final String id;
  final String posterId;
  final String posterName;
  final String title;
  final String description;
  final String category;
  final String location;
  final String salary;
  final String contactInfo;
  final ListingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final String? boostType;
  final String? boostPurchaseId;
  final int viewCount;
  final int messageCount;

  const Listing({
    required this.id,
    required this.posterId,
    required this.posterName,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.salary,
    required this.contactInfo,
    this.status = ListingStatus.active,
    this.createdAt,
    this.updatedAt,
    this.isBoosted = false,
    this.boostExpiresAt,
    this.boostType,
    this.boostPurchaseId,
    this.viewCount = 0,
    this.messageCount = 0,
  });

  factory Listing.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return Listing(
      id: doc.id,
      posterId: data['posterId'] as String? ?? '',
      posterName: data['posterName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'diger',
      location: data['location'] as String? ?? '',
      salary: data['salary'] as String? ?? '',
      contactInfo: data['contactInfo'] as String? ?? '',
      status: (data['status'] as String? ?? 'active') == 'closed' ? ListingStatus.closed : ListingStatus.active,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: (data['boostExpiresAt'] as Timestamp?)?.toDate(),
      boostType: data['boostType'] as String?,
      boostPurchaseId: data['boostPurchaseId'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      messageCount: data['messageCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'posterId': posterId,
        'posterName': posterName,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'salary': salary,
        'contactInfo': contactInfo,
        'status': status == ListingStatus.closed ? 'closed' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isBoosted': isBoosted,
        'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt!) : null,
        'boostType': boostType,
        'boostPurchaseId': boostPurchaseId,
        'viewCount': viewCount,
        'messageCount': messageCount,
      };
}
