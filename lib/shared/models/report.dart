import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  scamFraud,
  spam,
  inappropriateContent,
  misleadingInformation,
  other
}

enum TargetType { listing, user }

class Report {
  final String id;
  final String reporterId;
  final TargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String description;
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
    this.createdAt,
  });

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      targetType: (data['targetType'] as String? ?? 'listing') == 'user'
          ? TargetType.user
          : TargetType.listing,
      targetId: data['targetId'] as String? ?? '',
      reason: _parseReason(data['reason'] as String?),
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'targetType': targetType == TargetType.user ? 'user' : 'listing',
        'targetId': targetId,
        'reason': _reasonToString(reason),
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ReportReason _parseReason(String? reasonStr) {
    switch (reasonStr) {
      case 'scamFraud':
        return ReportReason.scamFraud;
      case 'spam':
        return ReportReason.spam;
      case 'inappropriateContent':
        return ReportReason.inappropriateContent;
      case 'misleadingInformation':
        return ReportReason.misleadingInformation;
      case 'other':
        return ReportReason.other;
      default:
        return ReportReason.other;
    }
  }

  static String _reasonToString(ReportReason reason) {
    switch (reason) {
      case ReportReason.scamFraud:
        return 'scamFraud';
      case ReportReason.spam:
        return 'spam';
      case ReportReason.inappropriateContent:
        return 'inappropriateContent';
      case ReportReason.misleadingInformation:
        return 'misleadingInformation';
      case ReportReason.other:
        return 'other';
    }
  }
}
