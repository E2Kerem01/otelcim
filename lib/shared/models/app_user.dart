/// Admin role types for platform management
enum AdminRole {
  superAdmin,
  contentModerator,
  supportAgent,
}

/// Extension to convert AdminRole to/from string for Firestore
extension AdminRoleExtension on AdminRole {
  String toFirestore() {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.contentModerator:
        return 'content_moderator';
      case AdminRole.supportAgent:
        return 'support_agent';
    }
  }

  static AdminRole fromFirestore(String value) {
    switch (value) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'content_moderator':
        return AdminRole.contentModerator;
      case 'support_agent':
        return AdminRole.supportAgent;
      default:
        throw ArgumentError('Invalid admin role: $value');
    }
  }
}

class AppUser {
  final String uid;
  final String email;
  final String? phoneNumber;

  /// Whether this user has admin privileges
  final bool isAdmin;

  /// Admin role (only set if isAdmin is true)
  final AdminRole? adminRole;

  const AppUser({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.isAdmin = false,
    this.adminRole,
  });
}
