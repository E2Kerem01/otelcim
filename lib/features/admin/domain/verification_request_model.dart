import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Beklemede';
      case VerificationStatus.approved:
        return 'Onaylandı';
      case VerificationStatus.rejected:
        return 'Reddedildi';
    }
  }
}

class VerificationRequest {
  const VerificationRequest({
    this.id = '',
    required this.employerId,
    required this.hotelName,
    required this.documentUrls,
    required this.status,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String employerId;
  final String hotelName;
  final List<String> documentUrls;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  factory VerificationRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return VerificationRequest(
      id: doc.id,
      employerId: (data['employerId'] ?? data['userId']) as String? ?? '',
      hotelName: data['hotelName'] as String? ?? '',
      documentUrls: (data['documentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: _parseStatus(data['status'] as String?),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ??
          (data['requestedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'employerId': employerId,
        'userId': employerId,
        'hotelName': hotelName,
        'documentUrls': documentUrls,
        'status': status.name,
        'submittedAt': submittedAt != null
            ? Timestamp.fromDate(submittedAt!)
            : FieldValue.serverTimestamp(),
        'requestedAt': submittedAt != null
            ? Timestamp.fromDate(submittedAt!)
            : FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'rejectionReason': rejectionReason,
      };

  static VerificationStatus _parseStatus(String? str) {
    switch (str) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }
}
