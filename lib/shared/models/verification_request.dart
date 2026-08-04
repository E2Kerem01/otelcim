import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a verification request submitted by a hotel employer.
///
/// Contains hotel details, document URLs, and review status for manual admin verification.
class VerificationRequest {
  /// Unique identifier for the verification request
  final String id;

  /// ID of the user who submitted the request
  final String userId;

  /// Email of the user who submitted the request
  final String userEmail;

  /// Name of the hotel being verified
  final String hotelName;

  /// Physical address of the hotel
  final String hotelAddress;

  /// List of URLs to uploaded verification documents (tax ID, tourism license, etc.)
  final List<String> documentUrls;

  /// Status of the verification request: 'pending', 'approved', or 'rejected'
  final String status;

  /// Timestamp when the verification was requested
  final DateTime requestedAt;

  /// Timestamp when the request was reviewed by an admin (null if not yet reviewed)
  final DateTime? reviewedAt;

  /// ID of the admin who reviewed the request (null if not yet reviewed)
  final String? reviewedBy;

  /// Reason for rejection if status is 'rejected' (null otherwise)
  final String? rejectionReason;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.hotelName,
    required this.hotelAddress,
    required this.documentUrls,
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  /// Creates a VerificationRequest from a Firestore DocumentSnapshot
  factory VerificationRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VerificationRequest(
      id: doc.id,
      userId: (data['employerId'] ?? data['userId']) as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      hotelName: data['hotelName'] as String? ?? '',
      hotelAddress: data['hotelAddress'] as String? ?? '',
      documentUrls: List<String>.from(data['documentUrls'] as List? ?? []),
      status: data['status'] as String? ?? 'pending',
      requestedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : (data['requestedAt'] != null
              ? (data['requestedAt'] as Timestamp).toDate()
              : DateTime.now()),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// Converts this VerificationRequest to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'employerId': userId,
      'submittedAt': Timestamp.fromDate(requestedAt),
      'userId': userId,
      'userEmail': userEmail,
      'hotelName': hotelName,
      'hotelAddress': hotelAddress,
      'documentUrls': documentUrls,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Creates a copy of this VerificationRequest with the given fields replaced
  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? hotelName,
    String? hotelAddress,
    List<String>? documentUrls,
    String? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerificationRequest &&
        other.id == id &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        other.hotelName == hotelName &&
        other.hotelAddress == hotelAddress &&
        _listEquals(other.documentUrls, documentUrls) &&
        other.status == status &&
        other.requestedAt == requestedAt &&
        other.reviewedAt == reviewedAt &&
        other.reviewedBy == reviewedBy &&
        other.rejectionReason == rejectionReason;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userEmail,
      hotelName,
      hotelAddress,
      Object.hashAll(documentUrls),
      status,
      requestedAt,
      reviewedAt,
      reviewedBy,
      rejectionReason,
    );
  }

  @override
  String toString() {
    return 'VerificationRequest(id: $id, userId: $userId, userEmail: $userEmail, '
        'hotelName: $hotelName, hotelAddress: $hotelAddress, '
        'documentUrls: $documentUrls, status: $status, requestedAt: $requestedAt, '
        'reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, '
        'rejectionReason: $rejectionReason)';
  }

  /// Helper method to compare lists
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
