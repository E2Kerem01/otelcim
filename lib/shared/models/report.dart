import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportTargetType { listing, user }

enum ReportReason {
  scam,
  spam,
  inappropriate,
  misleading,
  other;

  String get label {
    switch (this) {
      case ReportReason.scam:
        return 'Dolandırıcılık / Sahtekarlık';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriate:
        return 'Uygunsuz İçerik';
      case ReportReason.misleading:
        return 'Yanıltıcı Bilgi';
      case ReportReason.other:
        return 'Diğer';
    }
  }
}

class Report {
  const Report({
    this.id = '',
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.description,
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetId;
  final ReportTargetType targetType;
  final ReportReason reason;
  final String? description;
  final DateTime? createdAt;

  factory Report.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetType: (data['targetType'] as String? ?? 'listing') == 'user'
          ? ReportTargetType.user
          : ReportTargetType.listing,
      reason: _parseReason(data['reason'] as String?),
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType.name,
        'reason': reason.name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ReportReason _parseReason(String? str) {
    switch (str) {
      case 'scam':
      case 'scamFraud':
        return ReportReason.scam;
      case 'spam':
        return ReportReason.spam;
      case 'inappropriate':
      case 'inappropriateContent':
        return ReportReason.inappropriate;
      case 'misleading':
      case 'misleadingInformation':
        return ReportReason.misleading;
      default:
        return ReportReason.other;
    }
  }
}
