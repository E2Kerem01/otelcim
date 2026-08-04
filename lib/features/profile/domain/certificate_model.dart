import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificateType {
  hijyen,
  cankurtaran,
  ehliyet,
  dil,
  diger;

  String get label {
    switch (this) {
      case CertificateType.hijyen:
        return 'Hijyen Belgesi';
      case CertificateType.cankurtaran:
        return 'Cankurtaran Sertifikası';
      case CertificateType.ehliyet:
        return 'Sürücü Belgesi (Ehliyet)';
      case CertificateType.dil:
        return 'Yabancı Dil Belgesi';
      case CertificateType.diger:
        return 'Diğer Sertifika';
    }
  }

  static CertificateType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'hijyen':
        return CertificateType.hijyen;
      case 'cankurtaran':
        return CertificateType.cankurtaran;
      case 'ehliyet':
        return CertificateType.ehliyet;
      case 'dil':
        return CertificateType.dil;
      case 'diger':
      default:
        return CertificateType.diger;
    }
  }
}

enum CertificateStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case CertificateStatus.pending:
        return 'Beklemede';
      case CertificateStatus.approved:
        return 'Onaylandı';
      case CertificateStatus.rejected:
        return 'Reddedildi';
    }
  }

  static CertificateStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return CertificateStatus.approved;
      case 'rejected':
        return CertificateStatus.rejected;
      case 'pending':
      default:
        return CertificateStatus.pending;
    }
  }
}

class Certificate {
  const Certificate({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.type,
    this.title,
    required this.fileUrl,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final CertificateType type;
  final String? title;
  final String fileUrl;
  final CertificateStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  bool get isApproved => status == CertificateStatus.approved;
  bool get isPending => status == CertificateStatus.pending;
  bool get isRejected => status == CertificateStatus.rejected;

  factory Certificate.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return Certificate(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      type: CertificateType.fromString(data['type'] as String?),
      title: data['title'] as String?,
      fileUrl: data['fileUrl'] as String? ?? '',
      status: CertificateStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  factory Certificate.fromMap(Map<String, dynamic> data, String id) {
    return Certificate(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      type: CertificateType.fromString(data['type'] as String?),
      title: data['title'] as String?,
      fileUrl: data['fileUrl'] as String? ?? '',
      status: CertificateStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'title': title,
      'fileUrl': fileUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  Certificate copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    CertificateType? type,
    String? title,
    String? fileUrl,
    CertificateStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return Certificate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      title: title ?? this.title,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
