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
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.description,
  });

  final String reporterId;
  final String targetId;
  final ReportTargetType targetType;
  final ReportReason reason;
  final String? description;

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType.name,
        'reason': reason.name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
