import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/constants/listing_filters.dart';

enum ListingStatus { active, closed }

class Listing {
  final String id;
  final String posterId;
  final String posterName;
  final bool posterVerified;
  final String title;
  final String description;
  final String category;
  final String location;
  final String salary;
  final String? city;
  final int? minSalaryTl;
  final int? maxSalaryTl;
  final EmploymentType? employmentType;
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
    this.posterVerified = false,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.salary,
    this.city,
    this.minSalaryTl,
    this.maxSalaryTl,
    this.employmentType,
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
      posterVerified: data['posterVerified'] as bool? ?? false,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'diger',
      location: data['location'] as String? ?? '',
      salary: data['salary'] as String? ?? '',
      city: data['city'] as String?,
      minSalaryTl: (data['minSalaryTl'] as num?)?.toInt(),
      maxSalaryTl: (data['maxSalaryTl'] as num?)?.toInt(),
      employmentType: _employmentTypeFromString(data['employmentType'] as String?),
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
        'posterVerified': posterVerified,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'salary': salary,
        'city': city,
        'minSalaryTl': minSalaryTl,
        'maxSalaryTl': maxSalaryTl,
        'employmentType': employmentType?.name,
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

  static EmploymentType? _employmentTypeFromString(String? value) {
    for (final type in EmploymentType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
