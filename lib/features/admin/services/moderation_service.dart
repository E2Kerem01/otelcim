import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../domain/admin_action_model.dart';
import 'admin_service.dart';

class ModerationService {
  ModerationService(this._db);

  final FirebaseFirestore _db;

  void _rejectSelfModeration({
    required String userId,
    required String adminId,
  }) {
    if (userId == adminId) {
      throw StateError('Yönetici kendi hesabında moderasyon işlemi yapamaz.');
    }
  }

  /// Dismiss a report without taking action
  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _db.collection('reports').doc(reportId).update({
        'status': 'dismissed',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'dismissalReason': reason,
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.dismissReport');
      throw mapToFailure(error);
    }
  }

  /// Dismisses many reports and records one audit entry per report.
  ///
  /// Firestore batches accept at most 500 writes. Keeping the operational
  /// updates below 450 leaves room for small future changes while avoiding
  /// the limit. Audit entries are written through the existing audit API so
  /// they retain the same shape as single-report moderation actions.
  Future<void> dismissReports({
    required List<String> ids,
    required String adminId,
    String? reason,
  }) async {
    final reportIds = ids.toSet().toList();
    if (reportIds.isEmpty) return;

    try {
      for (var start = 0; start < reportIds.length; start += 450) {
        final end = start + 450 < reportIds.length
            ? start + 450
            : reportIds.length;
        final batch = _db.batch();
        for (final reportId in reportIds.sublist(start, end)) {
          batch.update(_db.collection('reports').doc(reportId), {
            'status': 'dismissed',
            'reviewedBy': adminId,
            'reviewedAt': FieldValue.serverTimestamp(),
            'dismissalReason': reason,
          });
        }
        await batch.commit();
      }

      final adminService = AdminService(_db);
      for (final reportId in reportIds) {
        await adminService.logAdminAction(
          AdminAction(
            adminId: adminId,
            actionType: AdminActionType.dismissReport,
            targetType: AdminActionTargetType.report,
            targetId: reportId,
            reason: reason,
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.dismissReports');
      throw mapToFailure(error);
    }
  }

  /// Warn a user for violating platform rules
  Future<void> warnUser({
    required String userId,
    required String adminId,
    String? reason,
  }) async {
    _rejectSelfModeration(userId: userId, adminId: adminId);
    try {
      await _db.collection('user_profiles').doc(userId).update({
        'warnings': FieldValue.arrayUnion([
          {
            'adminId': adminId,
            'reason': reason ?? 'Platform kurallarını ihlal',
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.warnUser');
      throw mapToFailure(error);
    }
  }

  /// Remove a listing from the platform
  Future<void> removeListing({
    required String listingId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _db.collection('listings').doc(listingId).update({
        'status': 'removed',
        'removedBy': adminId,
        'removedAt': FieldValue.serverTimestamp(),
        'removalReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.removeListing');
      throw mapToFailure(error);
    }
  }

  /// Suspend a user account temporarily
  Future<void> suspendUser({
    required String userId,
    required String adminId,
    String? reason,
    DateTime? suspensionEnd,
  }) async {
    _rejectSelfModeration(userId: userId, adminId: adminId);
    try {
      await _db.collection('user_profiles').doc(userId).update({
        'isSuspended': true,
        'suspendedBy': adminId,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspensionReason': reason ?? 'Platform kurallarını ihlal',
        'suspensionEnd': suspensionEnd != null
            ? Timestamp.fromDate(suspensionEnd)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.suspendUser');
      throw mapToFailure(error);
    }
  }

  /// Ban a user account permanently
  Future<void> banUser({
    required String userId,
    required String adminId,
    required String reason,
  }) async {
    _rejectSelfModeration(userId: userId, adminId: adminId);
    try {
      await _db.collection('user_profiles').doc(userId).update({
        'isBanned': true,
        'bannedBy': adminId,
        'bannedAt': FieldValue.serverTimestamp(),
        'banReason': reason,
        'isSuspended': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.banUser');
      throw mapToFailure(error);
    }
  }

  /// Unsuspend a user account
  Future<void> unsuspendUser({
    required String userId,
    required String adminId,
  }) async {
    _rejectSelfModeration(userId: userId, adminId: adminId);
    try {
      await _db.collection('user_profiles').doc(userId).update({
        'isSuspended': false,
        'suspendedBy': null,
        'suspendedAt': null,
        'suspensionReason': null,
        'suspensionEnd': null,
        'unsuspendedBy': adminId,
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.unsuspendUser');
      throw mapToFailure(error);
    }
  }

  /// Unban a user account
  Future<void> unbanUser({
    required String userId,
    required String adminId,
  }) async {
    _rejectSelfModeration(userId: userId, adminId: adminId);
    try {
      await _db.collection('user_profiles').doc(userId).update({
        'isBanned': false,
        'bannedBy': null,
        'bannedAt': null,
        'banReason': null,
        'unbannedBy': adminId,
        'unbannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.unbanUser');
      throw mapToFailure(error);
    }
  }

  /// Restore a removed listing
  Future<void> restoreListing({
    required String listingId,
    required String adminId,
  }) async {
    try {
      await _db.collection('listings').doc(listingId).update({
        'status': 'active',
        'removedBy': null,
        'removedAt': null,
        'removalReason': null,
        'restoredBy': adminId,
        'restoredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ModerationService.restoreListing');
      throw mapToFailure(error);
    }
  }
}

final moderationServiceProvider = Provider<ModerationService>(
  (ref) => ModerationService(FirebaseFirestore.instance),
);
