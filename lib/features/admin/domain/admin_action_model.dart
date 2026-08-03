import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminActionType {
  dismissReport,
  warnUser,
  removeListing,
  suspendUser,
  banUser,
  approveVerification,
  rejectVerification;

  String get label {
    switch (this) {
      case AdminActionType.dismissReport:
        return 'Şikayeti Reddet';
      case AdminActionType.warnUser:
        return 'Kullanıcıyı Uyar';
      case AdminActionType.removeListing:
        return 'İlanı Kaldır';
      case AdminActionType.suspendUser:
        return 'Kullanıcıyı Askıya Al';
      case AdminActionType.banUser:
        return 'Kullanıcıyı Yasakla';
      case AdminActionType.approveVerification:
        return 'Doğrulamayı Onayla';
      case AdminActionType.rejectVerification:
        return 'Doğrulamayı Reddet';
    }
  }
}

enum AdminActionTargetType {
  user,
  listing,
  report,
  verification;

  String get label {
    switch (this) {
      case AdminActionTargetType.user:
        return 'Kullanıcı';
      case AdminActionTargetType.listing:
        return 'İlan';
      case AdminActionTargetType.report:
        return 'Şikayet';
      case AdminActionTargetType.verification:
        return 'Doğrulama';
    }
  }
}

class AdminAction {
  const AdminAction({
    this.id = '',
    required this.adminId,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    this.reason,
    this.timestamp,
    this.details,
  });

  final String id;
  final String adminId;
  final AdminActionType actionType;
  final AdminActionTargetType targetType;
  final String targetId;
  final String? reason;
  final DateTime? timestamp;
  final Map<String, dynamic>? details;

  factory AdminAction.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return AdminAction(
      id: doc.id,
      adminId: data['adminId'] as String? ?? '',
      actionType: _parseActionType(data['actionType'] as String?),
      targetType: _parseTargetType(data['targetType'] as String?),
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      details: data['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'adminId': adminId,
        'actionType': actionType.name,
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason,
        'timestamp': timestamp != null
            ? Timestamp.fromDate(timestamp!)
            : FieldValue.serverTimestamp(),
        'details': details,
      };

  static AdminActionType _parseActionType(String? str) {
    switch (str) {
      case 'dismissReport':
        return AdminActionType.dismissReport;
      case 'warnUser':
        return AdminActionType.warnUser;
      case 'removeListing':
        return AdminActionType.removeListing;
      case 'suspendUser':
        return AdminActionType.suspendUser;
      case 'banUser':
        return AdminActionType.banUser;
      case 'approveVerification':
        return AdminActionType.approveVerification;
      case 'rejectVerification':
        return AdminActionType.rejectVerification;
      default:
        return AdminActionType.dismissReport;
    }
  }

  static AdminActionTargetType _parseTargetType(String? str) {
    switch (str) {
      case 'user':
        return AdminActionTargetType.user;
      case 'listing':
        return AdminActionTargetType.listing;
      case 'report':
        return AdminActionTargetType.report;
      case 'verification':
        return AdminActionTargetType.verification;
      default:
        return AdminActionTargetType.report;
    }
  }
}
