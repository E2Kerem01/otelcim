import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import '../domain/admin_action_model.dart';

/// Service for admin-related operations including audit logging and permission checks
class AdminService {
  AdminService(this._db);

  final FirebaseFirestore _db;

  /// Log an admin action to the audit log
  Future<String> logAdminAction(AdminAction action) async {
    try {
      final ref = await _db.collection('admin_audit_log').add(action.toMap());
      return ref.id;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminService.logAdminAction');
      throw mapToFailure(error);
    }
  }

  /// Watch the audit log with optional filtering
  ///
  /// Returns a stream of admin actions ordered by timestamp (most recent first).
  /// Optionally filter by adminId or actionType.
  Stream<List<AdminAction>> watchAuditLog({
    String? adminId,
    AdminActionType? actionType,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('admin_audit_log');

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }

    if (actionType != null) {
      query = query.where('actionType', isEqualTo: actionType.name);
    }

    query = query.orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snap) {
      return snap.docs.map(AdminAction.fromDoc).toList();
    }).handleError((Object error, StackTrace stackTrace) {
      logError(error, stackTrace, context: 'AdminService.watchAuditLog');
      return <AdminAction>[];
    });
  }

  /// Check if a user is an admin
  bool isAdmin(AppUser? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if a user has the required admin permission based on their role
  ///
  /// Permission hierarchy:
  /// - super_admin: Can perform all actions
  /// - content_moderator: Can moderate content (reports, listings, users)
  /// - support_agent: Can view and dismiss reports only
  bool checkAdminPermission({
    required AppUser? user,
    required AdminActionType actionType,
  }) {
    if (user == null || !user.isAdmin || user.adminRole == null) {
      return false;
    }

    switch (user.adminRole!) {
      case AdminRole.superAdmin:
        // Super admin can do everything
        return true;

      case AdminRole.contentModerator:
        // Content moderator can do most things except manage other admins
        return actionType == AdminActionType.dismissReport ||
            actionType == AdminActionType.warnUser ||
            actionType == AdminActionType.removeListing ||
            actionType == AdminActionType.restoreListing ||
            actionType == AdminActionType.suspendUser ||
            actionType == AdminActionType.unsuspendUser ||
            actionType == AdminActionType.banUser ||
            actionType == AdminActionType.unbanUser ||
            actionType == AdminActionType.approveVerification ||
            actionType == AdminActionType.rejectVerification;

      case AdminRole.supportAgent:
        // Support agent can only dismiss reports
        return actionType == AdminActionType.dismissReport;
    }
  }

  /// Lists the most recently created user profiles, for the admin user
  /// management screen's default (no search query) view.
  Stream<List<UserProfile>> watchRecentUsers({int limit = 50}) {
    return _db
        .collection('user_profiles')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(UserProfile.fromFirestore).toList())
        .handleError((Object error, StackTrace stackTrace) {
          logError(error, stackTrace, context: 'AdminService.watchRecentUsers');
          return <UserProfile>[];
        });
  }

  /// Searches users by exact-prefix match on email or display name.
  /// Firestore has no full-text search, so this only matches from the
  /// start of the string (case-sensitive) - good enough for an admin
  /// looking up a specific known user.
  Future<List<UserProfile>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    try {
      final results = await Future.wait([
        _db
            .collection('user_profiles')
            .orderBy('email')
            .startAt([trimmed])
            .endAt(['$trimmed'])
            .limit(20)
            .get(),
        _db
            .collection('user_profiles')
            .orderBy('displayName')
            .startAt([trimmed])
            .endAt(['$trimmed'])
            .limit(20)
            .get(),
      ]);
      final byId = <String, UserProfile>{};
      for (final snap in results) {
        for (final doc in snap.docs) {
          byId[doc.id] = UserProfile.fromFirestore(doc);
        }
      }
      return byId.values.toList();
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminService.searchUsers');
      return [];
    }
  }

  /// Get a user's profile with admin fields
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _db
          .collection('user_profiles')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserProfile.fromFirestore(doc);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminService.getUserProfile');
      return null;
    }
  }

  /// Check if a user profile has admin access
  bool isAdminProfile(UserProfile? profile) {
    return profile?.isAdmin ?? false;
  }

  /// Get admin action by ID
  Future<AdminAction?> getAdminAction(String actionId) async {
    try {
      final doc = await _db.collection('admin_audit_log').doc(actionId).get();
      if (!doc.exists) return null;
      return AdminAction.fromDoc(doc);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminService.getAdminAction');
      return null;
    }
  }

  /// Get recent audit log entries (last 50)
  Future<List<AdminAction>> getRecentAuditLog({int limit = 50}) async {
    try {
      final snap = await _db
          .collection('admin_audit_log')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map(AdminAction.fromDoc).toList();
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminService.getRecentAuditLog');
      return [];
    }
  }
}

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(FirebaseFirestore.instance),
);
