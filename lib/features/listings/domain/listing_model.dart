import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String contactInfo;
  final ListingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    required this.contactInfo,
    this.status = ListingStatus.active,
    this.createdAt,
    this.updatedAt,
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
      contactInfo: data['contactInfo'] as String? ?? '',
      status: (data['status'] as String? ?? 'active') == 'closed' ? ListingStatus.closed : ListingStatus.active,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
        'contactInfo': contactInfo,
        'status': status == ListingStatus.closed ? 'closed' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
