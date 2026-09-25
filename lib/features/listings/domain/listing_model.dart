import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/constants/listing_filters.dart';
import '../../../shared/utils/search_keywords.dart';

enum ListingStatus { active, closed, removed }

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
  final String? staffShuttleRoute;
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
    this.staffShuttleRoute,
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
    final rawData = doc.data();
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return Listing(
      id: doc.id,
      posterId: _string(data['posterId']) ?? '',
      posterName: _string(data['posterName']) ?? '',
      posterVerified: _bool(data['posterVerified']) ?? false,
      isUrgent: _bool(data['isUrgent']) ?? false,
      season: _string(data['season']),
      contractStartDate: _dateTime(data['contractStartDate']),
      contractEndDate: _dateTime(data['contractEndDate']),
      title: _string(data['title']) ?? '',
      description: _string(data['description']) ?? '',
      category: _string(data['category']) ?? 'diger',
      location: _string(data['location']) ?? '',
      salary: _string(data['salary']) ?? '',
      city: _string(data['city']),
      region: _string(data['region']),
      lat: _double(data['lat']),
      lng: _double(data['lng']),
      minSalaryTl: _int(data['minSalaryTl']),
      maxSalaryTl: _int(data['maxSalaryTl']),
      employmentType: _employmentTypeFromString(
        _string(data['employmentType']),
      ),
      experienceLevel: _string(data['experienceLevel']),
      educationLevel: _string(data['educationLevel']),
      contactInfo: _string(data['contactInfo']) ?? '',
      images:
          _stringList(data['images']) ??
          _stringList(data['imageUrls']) ??
          const [],
      housingRoomType: _string(data['housingRoomType']),
      housingHasAc: _bool(data['housingHasAc']),
      housingHasWifi: _bool(data['housingHasWifi']),
      housingMealsIncluded: _int(data['housingMealsIncluded']),
      housingImages: _stringList(data['housingImages']) ?? const [],
      staffShuttleRoute: _string(data['staffShuttleRoute']),
      status: switch (_string(data['status']) ?? 'active') {
        'closed' => ListingStatus.closed,
        'removed' => ListingStatus.removed,
        _ => ListingStatus.active,
      },
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
      isBoosted: _bool(data['isBoosted']) ?? false,
      boostExpiresAt: _dateTime(data['boostExpiresAt']),
      boostType: _string(data['boostType']),
      boostPurchaseId: _string(data['boostPurchaseId']),
      viewCount: _int(data['viewCount']) ?? 0,
      messageCount: _int(data['messageCount']) ?? 0,
    );
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    return value is String ? value : value.toString();
  }

  static bool? _bool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return switch (value.trim().toLowerCase()) {
        'true' || '1' || 'yes' => true,
        'false' || '0' || 'no' => false,
        _ => null,
      };
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ??
        double.tryParse(value.toString().trim())?.toInt();
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String>? _stringList(Object? value) {
    if (value is! Iterable) return null;
    return value.whereType<String>().toList();
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
    // contactInfo is deliberately NOT written here - it lives in the
    // listings/{id}/private/contact subcollection instead (see
    // ListingService), because this listing doc is publicly readable and
    // contactInfo must not be. Callers still read/write it through this
    // model's contactInfo field; ListingService handles routing it to the
    // right place.
    'images': images,
    'housingRoomType': housingRoomType,
    'housingHasAc': housingHasAc,
    'housingHasWifi': housingHasWifi,
    'housingMealsIncluded': housingMealsIncluded,
    'housingImages': housingImages,
    'staffShuttleRoute': staffShuttleRoute,
    'status': switch (status) {
      ListingStatus.closed => 'closed',
      ListingStatus.removed => 'removed',
      ListingStatus.active => 'active',
    },
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'isBoosted': isBoosted,
    'boostExpiresAt': boostExpiresAt != null
        ? Timestamp.fromDate(boostExpiresAt!)
        : null,
    'boostType': boostType,
    'boostPurchaseId': boostPurchaseId,
    'viewCount': viewCount,
    // Prefix tokens for admin search (lib/shared/utils/search_keywords.dart).
    'searchKeywords':
        buildSearchKeywords([title, posterName, city, location, region]),
    'messageCount': messageCount,
  };

  /// Used by ListingService.getListing to merge in the contactInfo value
  /// fetched separately from listings/{id}/private/contact.
  Listing copyWithContactInfo(String contactInfo) => Listing(
    id: id,
    posterId: posterId,
    posterName: posterName,
    posterVerified: posterVerified,
    isUrgent: isUrgent,
    title: title,
    description: description,
    category: category,
    season: season,
    contractStartDate: contractStartDate,
    contractEndDate: contractEndDate,
    location: location,
    salary: salary,
    city: city,
    region: region,
    lat: lat,
    lng: lng,
    minSalaryTl: minSalaryTl,
    maxSalaryTl: maxSalaryTl,
    employmentType: employmentType,
    experienceLevel: experienceLevel,
    educationLevel: educationLevel,
    contactInfo: contactInfo,
    images: images,
    housingRoomType: housingRoomType,
    housingHasAc: housingHasAc,
    housingHasWifi: housingHasWifi,
    housingMealsIncluded: housingMealsIncluded,
    housingImages: housingImages,
    staffShuttleRoute: staffShuttleRoute,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isBoosted: isBoosted,
    boostExpiresAt: boostExpiresAt,
    boostType: boostType,
    boostPurchaseId: boostPurchaseId,
    viewCount: viewCount,
    messageCount: messageCount,
  );

  static EmploymentType? _employmentTypeFromString(String? value) {
    for (final type in EmploymentType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
