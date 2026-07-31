import 'package:cloud_firestore/cloud_firestore.dart';

import 'listing_status.dart';

/// Represents a job listing in the Otelcim platform.
///
/// A listing contains all the information about a job posting including
/// title, description, location, salary, and images. It tracks who created it,
/// when it was created/updated, and its current status (active, closed, filled).
class Listing {
  /// Unique identifier for the listing
  final String id;

  /// Job title/position name
  final String title;

  /// Detailed description of the job requirements and responsibilities
  final String description;

  /// Job category (e.g., "Resepsiyon", "Mutfak", "Kat Hizmetleri")
  final String category;

  /// Work location (city, hotel name, etc.)
  final String location;

  /// Salary information (can be a range or specific amount)
  final String salary;

  /// List of image URLs for the job listing
  final List<String> imageUrls;

  /// Current status of the listing
  final ListingStatus status;

  /// User ID of the person who created this listing
  final String createdBy;

  /// Timestamp when the listing was created
  final DateTime createdAt;

  /// Timestamp when the listing was last updated
  final DateTime updatedAt;

  /// Creates a new Listing instance.
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.salary,
    required this.imageUrls,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Listing instance from a Firestore document map.
  ///
  /// The [map] should contain all required fields. The [id] parameter
  /// is typically the document ID from Firestore.
  factory Listing.fromMap(Map<String, dynamic> map, String id) {
    return Listing(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      location: map['location'] as String? ?? '',
      salary: map['salary'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      status: ListingStatus.fromFirestore(
        map['status'] as String? ?? 'active',
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the Listing instance to a map for Firestore storage.
  ///
  /// The returned map excludes the [id] field as it's stored separately
  /// as the document ID in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'salary': salary,
      'imageUrls': imageUrls,
      'status': status.toFirestore(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this Listing with the specified fields replaced.
  Listing copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? salary,
    List<String>? imageUrls,
    ListingStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Listing &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.location == location &&
        other.salary == salary &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.status == status &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      location,
      salary,
      Object.hashAll(imageUrls),
      status,
      createdBy,
      createdAt,
      updatedAt,
    );
  }

  /// Helper function to compare two lists for equality
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
