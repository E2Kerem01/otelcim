import 'package:otelcim/features/admin/domain/admin_action_model.dart';

/// Re-export AdminActionType as ModerationActionType for consistency
typedef ModerationActionType = AdminActionType;

/// Helper class for building moderation action parameters
class ModerationActionParams {
  const ModerationActionParams({
    required this.actionType,
    required this.targetId,
    required this.targetType,
    this.reason,
    this.details,
  });

  final ModerationActionType actionType;
  final String targetId;
  final AdminActionTargetType targetType;
  final String? reason;
  final Map<String, dynamic>? details;

  /// Create params for dismissing a report
  factory ModerationActionParams.dismissReport({
    required String reportId,
    String? reason,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.dismissReport,
        targetId: reportId,
        targetType: AdminActionTargetType.report,
        reason: reason,
      );

  /// Create params for warning a user
  factory ModerationActionParams.warnUser({
    required String userId,
    String? reason,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.warnUser,
        targetId: userId,
        targetType: AdminActionTargetType.user,
        reason: reason,
      );

  /// Create params for removing a listing
  factory ModerationActionParams.removeListing({
    required String listingId,
    String? reason,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.removeListing,
        targetId: listingId,
        targetType: AdminActionTargetType.listing,
        reason: reason,
      );

  /// Create params for suspending a user
  factory ModerationActionParams.suspendUser({
    required String userId,
    String? reason,
    Map<String, dynamic>? details,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.suspendUser,
        targetId: userId,
        targetType: AdminActionTargetType.user,
        reason: reason,
        details: details,
      );

  /// Create params for banning a user
  factory ModerationActionParams.banUser({
    required String userId,
    required String reason,
    Map<String, dynamic>? details,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.banUser,
        targetId: userId,
        targetType: AdminActionTargetType.user,
        reason: reason,
        details: details,
      );

  /// Create params for approving a verification request
  factory ModerationActionParams.approveVerification({
    required String verificationId,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.approveVerification,
        targetId: verificationId,
        targetType: AdminActionTargetType.verification,
      );

  /// Create params for rejecting a verification request
  factory ModerationActionParams.rejectVerification({
    required String verificationId,
    required String reason,
  }) =>
      ModerationActionParams(
        actionType: ModerationActionType.rejectVerification,
        targetId: verificationId,
        targetType: AdminActionTargetType.verification,
        reason: reason,
      );

  /// Convert to AdminAction for logging
  AdminAction toAdminAction(String adminId) => AdminAction(
        adminId: adminId,
        actionType: actionType,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        details: details,
      );
}

/// Helper extension for ModerationActionType
extension ModerationActionTypeExtension on ModerationActionType {
  /// Check if this action requires a reason
  bool get requiresReason {
    switch (this) {
      case ModerationActionType.banUser:
      case ModerationActionType.rejectVerification:
        return true;
      case ModerationActionType.dismissReport:
      case ModerationActionType.warnUser:
      case ModerationActionType.removeListing:
      case ModerationActionType.suspendUser:
      case ModerationActionType.approveVerification:
        return false;
    }
  }

  /// Check if this action is destructive (requires confirmation)
  bool get isDestructive {
    switch (this) {
      case ModerationActionType.removeListing:
      case ModerationActionType.suspendUser:
      case ModerationActionType.banUser:
        return true;
      case ModerationActionType.dismissReport:
      case ModerationActionType.warnUser:
      case ModerationActionType.approveVerification:
      case ModerationActionType.rejectVerification:
        return false;
    }
  }

  /// Get confirmation message for destructive actions
  String get confirmationMessage {
    switch (this) {
      case ModerationActionType.removeListing:
        return 'Bu ilanı kaldırmak istediğinizden emin misiniz?';
      case ModerationActionType.suspendUser:
        return 'Bu kullanıcıyı askıya almak istediğinizden emin misiniz?';
      case ModerationActionType.banUser:
        return 'Bu kullanıcıyı kalıcı olarak yasaklamak istediğinizden emin misiniz? Bu işlem geri alınamaz.';
      default:
        return 'Bu işlemi gerçekleştirmek istediğinizden emin misiniz?';
    }
  }

  /// Get success message after action completion
  String get successMessage {
    switch (this) {
      case ModerationActionType.dismissReport:
        return 'Şikayet reddedildi';
      case ModerationActionType.warnUser:
        return 'Kullanıcı uyarıldı';
      case ModerationActionType.removeListing:
        return 'İlan kaldırıldı';
      case ModerationActionType.suspendUser:
        return 'Kullanıcı askıya alındı';
      case ModerationActionType.banUser:
        return 'Kullanıcı yasaklandı';
      case ModerationActionType.approveVerification:
        return 'Doğrulama onaylandı';
      case ModerationActionType.rejectVerification:
        return 'Doğrulama reddedildi';
    }
  }
}
