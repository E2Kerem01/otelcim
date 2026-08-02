import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    } catch (e) {
      debugPrint('Error logging admin action: $e');
      rethrow;
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
    }).handleError((error) {
      debugPrint('Firestore watchAuditLog warning: $error');
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
            actionType == AdminActionType.suspendUser ||
            actionType == AdminActionType.banUser ||
            actionType == AdminActionType.approveVerification ||
            actionType == AdminActionType.rejectVerification;

      case AdminRole.supportAgent:
        // Support agent can only dismiss reports
        return actionType == AdminActionType.dismissReport;
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

      return UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
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
    } catch (e) {
      debugPrint('Error getting admin action: $e');
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
    } catch (e) {
      debugPrint('Error getting recent audit log: $e');
      return [];
    }
  }
}

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(FirebaseFirestore.instance),
);
