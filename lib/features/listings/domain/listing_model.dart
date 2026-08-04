import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/constants/listing_filters.dart';

enum ListingStatus { active, closed }

class Listing {
  final String id;
  final String posterId;
  final String posterName;
  final bool posterVerified;
  final bool isUrgent;
  final String title;
  final String description;
  final String category;
  final String location;
  final String salary;
  final String? city;
  final String? region;
  final double? lat;
  final double? lng;
  final int? minSalaryTl;
  final int? maxSalaryTl;
  final EmploymentType? employmentType;
  final String? experienceLevel;
  final String? educationLevel;
  final String? season;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final String contactInfo;
  final List<String> images;
  final String? housingRoomType;
  final bool? housingHasAc;
  final bool? housingHasWifi;
  final int? housingMealsIncluded;
  final List<String> housingImages;
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
    this.isUrgent = false,
    required this.title,
    required this.description,
    required this.category,
    this.season,
    this.contractStartDate,
    this.contractEndDate,
    required this.location,
    required this.salary,
    this.city,
    this.region,
    this.lat,
    this.lng,
    this.minSalaryTl,
    this.maxSalaryTl,
    this.employmentType,
    this.experienceLevel,
    this.educationLevel,
    required this.contactInfo,
    this.images = const [],
    this.housingRoomType,
    this.housingHasAc,
    this.housingHasWifi,
    this.housingMealsIncluded,
    this.housingImages = const [],
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
      isUrgent: data['isUrgent'] as bool? ?? false,
      season: data['season'] as String?,
      contractStartDate: (data['contractStartDate'] as Timestamp?)?.toDate(),
      contractEndDate: (data['contractEndDate'] as Timestamp?)?.toDate(),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'diger',
      location: data['location'] as String? ?? '',
      salary: data['salary'] as String? ?? '',
      city: data['city'] as String?,
      region: data['region'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      minSalaryTl: (data['minSalaryTl'] as num?)?.toInt(),
      maxSalaryTl: (data['maxSalaryTl'] as num?)?.toInt(),
      employmentType: _employmentTypeFromString(
        data['employmentType'] as String?,
      ),
      experienceLevel: data['experienceLevel'] as String?,
      educationLevel: data['educationLevel'] as String?,
      contactInfo: data['contactInfo'] as String? ?? '',
      images:
          (data['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      housingRoomType: data['housingRoomType'] as String?,
      housingHasAc: data['housingHasAc'] as bool?,
      housingHasWifi: data['housingHasWifi'] as bool?,
      housingMealsIncluded: (data['housingMealsIncluded'] as num?)?.toInt(),
      housingImages:
          (data['housingImages'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      status: (data['status'] as String? ?? 'active') == 'closed'
          ? ListingStatus.closed
          : ListingStatus.active,
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
    'isUrgent': isUrgent,
    'title': title,
    'description': description,
    'season': season,
    'contractStartDate': contractStartDate != null
        ? Timestamp.fromDate(contractStartDate!)
        : null,
    'contractEndDate': contractEndDate != null
        ? Timestamp.fromDate(contractEndDate!)
        : null,
    'category': category,
    'location': location,
    'salary': salary,
    'city': city,
    'region': region,
    'lat': lat,
    'lng': lng,
    'minSalaryTl': minSalaryTl,
    'maxSalaryTl': maxSalaryTl,
    'employmentType': employmentType?.name,
    'experienceLevel': experienceLevel,
    'educationLevel': educationLevel,
    'contactInfo': contactInfo,
    'images': images,
    'housingRoomType': housingRoomType,
    'housingHasAc': housingHasAc,
    'housingHasWifi': housingHasWifi,
    'housingMealsIncluded': housingMealsIncluded,
    'housingImages': housingImages,
    'status': status == ListingStatus.closed ? 'closed' : 'active',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'isBoosted': isBoosted,
    'boostExpiresAt': boostExpiresAt != null
        ? Timestamp.fromDate(boostExpiresAt!)
        : null,
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
