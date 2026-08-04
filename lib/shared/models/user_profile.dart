import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'app_user.dart';

const Object _undefined = Object();

/// Represents a user's profile information in the application.
///
/// Contains personal details and role-specific fields (hotel name and position for employers).
class UserProfile {
  /// Default notification preferences map
  static const Map<String, bool> defaultNotificationPreferences = {
    'messages': true,
    'listingAlerts': true,
    'seasonalReminders': false,
    'urgentListings': true,
    'marketing': false,
  };

  /// Unique identifier for the user (matches Firebase Auth UID)
  final String id;

  /// User's email address
  final String email;

  /// User's display name (replaces email as the visible name throughout the app)
  final String? displayName;

  /// User's phone number for out-of-app contact
  final String? phoneNumber;

  /// Short bio or description about the user
  final String? bio;

  /// URL to the user's profile photo stored in Firebase Storage
  final String? photoUrl;

  /// Hotel name (only for employer users)
  final String? hotelName;

  /// Job position/title (only for employer users)
  final String? position;

  /// Type of user: 'employer' or 'jobseeker'
  final String userType;

  /// Whether this user has admin privileges
  final bool isAdmin;

  /// Admin role (only set if isAdmin is true)
  final AdminRole? adminRole;

  /// Whether the employer has been verified (only for employer users)
  final bool isVerified;

  /// Verification status: 'pending', 'approved', or 'rejected' (only for employer users)
  final String? verificationStatus;

  /// Timestamp when the employer was verified (only for verified employers)
  final DateTime? verifiedAt;

  /// Notification preferences map ('messages', 'listingAlerts', 'seasonalReminders', 'marketing')
  final Map<String, bool> notificationPreferences;

  /// Quiet hours start time in "HH:mm" format
  final String? quietHoursStart;

  /// Quiet hours end time in "HH:mm" format
  final String? quietHoursEnd;

  /// Whether the user is immediately available for work (only for jobseekers)
  final bool availableImmediately;

  final String? preferredExperienceLevel;
  final String? preferredEducationLevel;
  final String? preferredRegion;

  /// URL to the user's intro video stored in Firebase Storage (only for jobseekers)
  final String? introVideoUrl;

  /// Timestamp when the profile was created
  final DateTime createdAt;

  /// Timestamp when the profile was last updated
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.bio,
    this.photoUrl,
    this.hotelName,
    this.position,
    required this.userType,
    this.isAdmin = false,
    this.adminRole,
    this.isVerified = false,
    this.verificationStatus,
    this.verifiedAt,
    this.notificationPreferences = defaultNotificationPreferences,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.availableImmediately = false,
    this.preferredExperienceLevel,
    this.preferredEducationLevel,
    this.preferredRegion,
    this.introVideoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfile from a Firestore DocumentSnapshot
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final adminRoleString = data['adminRole'] as String?;

    final rawPrefs = data['notificationPreferences'] as Map<String, dynamic>?;
    final preferences = <String, bool>{
      'messages':
          rawPrefs?['messages'] as bool? ??
          defaultNotificationPreferences['messages']!,
      'listingAlerts':
          rawPrefs?['listingAlerts'] as bool? ??
          defaultNotificationPreferences['listingAlerts']!,
      'seasonalReminders':
          rawPrefs?['seasonalReminders'] as bool? ??
          defaultNotificationPreferences['seasonalReminders']!,
      'urgentListings':
          rawPrefs?['urgentListings'] as bool? ??
          defaultNotificationPreferences['urgentListings']!,
      'marketing':
          rawPrefs?['marketing'] as bool? ??
          defaultNotificationPreferences['marketing']!,
    };

    return UserProfile(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      hotelName: data['hotelName'] as String?,
      position: data['position'] as String?,
      userType: data['userType'] as String,
      isAdmin: data['isAdmin'] as bool? ?? false,
      adminRole: adminRoleString != null
          ? AdminRoleExtension.fromFirestore(adminRoleString)
          : null,
      isVerified: data['isVerified'] as bool? ?? false,
      verificationStatus: data['verificationStatus'] as String?,
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      notificationPreferences: preferences,
      quietHoursStart: data['quietHoursStart'] as String?,
      quietHoursEnd: data['quietHoursEnd'] as String?,
      availableImmediately: data['availableImmediately'] as bool? ?? false,
      preferredExperienceLevel: data['preferredExperienceLevel'] as String?,
      preferredEducationLevel: data['preferredEducationLevel'] as String?,
      preferredRegion: data['preferredRegion'] as String?,
      introVideoUrl: data['introVideoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this UserProfile to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'photoUrl': photoUrl,
      'hotelName': hotelName,
      'position': position,
      'userType': userType,
      'isAdmin': isAdmin,
      'adminRole': adminRole?.toFirestore(),
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'notificationPreferences': notificationPreferences,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'availableImmediately': availableImmediately,
      'preferredExperienceLevel': preferredExperienceLevel,
      'preferredEducationLevel': preferredEducationLevel,
      'preferredRegion': preferredRegion,
      'introVideoUrl': introVideoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this UserProfile with the given fields replaced
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? photoUrl,
    String? hotelName,
    String? position,
    String? userType,
    bool? isAdmin,
    AdminRole? adminRole,
    bool? isVerified,
    String? verificationStatus,
    DateTime? verifiedAt,
    Map<String, bool>? notificationPreferences,
    Object? quietHoursStart = _undefined,
    Object? quietHoursEnd = _undefined,
    bool? availableImmediately,
    Object? preferredExperienceLevel = _undefined,
    Object? preferredEducationLevel = _undefined,
    Object? preferredRegion = _undefined,
    Object? introVideoUrl = _undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      hotelName: hotelName ?? this.hotelName,
      position: position ?? this.position,
      userType: userType ?? this.userType,
      isAdmin: isAdmin ?? this.isAdmin,
      adminRole: adminRole ?? this.adminRole,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      quietHoursStart: quietHoursStart == _undefined
          ? this.quietHoursStart
          : quietHoursStart as String?,
      quietHoursEnd: quietHoursEnd == _undefined
          ? this.quietHoursEnd
          : quietHoursEnd as String?,
      availableImmediately: availableImmediately ?? this.availableImmediately,
      preferredExperienceLevel: preferredExperienceLevel == _undefined
          ? this.preferredExperienceLevel
          : preferredExperienceLevel as String?,
      preferredEducationLevel: preferredEducationLevel == _undefined
          ? this.preferredEducationLevel
          : preferredEducationLevel as String?,
      preferredRegion: preferredRegion == _undefined
          ? this.preferredRegion
          : preferredRegion as String?,
      introVideoUrl: introVideoUrl == _undefined
          ? this.introVideoUrl
          : introVideoUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.phoneNumber == phoneNumber &&
        other.bio == bio &&
        other.photoUrl == photoUrl &&
        other.hotelName == hotelName &&
        other.position == position &&
        other.userType == userType &&
        other.isAdmin == isAdmin &&
        other.adminRole == adminRole &&
        other.isVerified == isVerified &&
        other.verificationStatus == verificationStatus &&
        other.verifiedAt == verifiedAt &&
        mapEquals(other.notificationPreferences, notificationPreferences) &&
        other.quietHoursStart == quietHoursStart &&
        other.quietHoursEnd == quietHoursEnd &&
        other.availableImmediately == availableImmediately &&
        other.preferredExperienceLevel == preferredExperienceLevel &&
        other.preferredEducationLevel == preferredEducationLevel &&
        other.preferredRegion == preferredRegion &&
        other.introVideoUrl == introVideoUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      email,
      displayName,
      phoneNumber,
      bio,
      photoUrl,
      hotelName,
      position,
      userType,
      isAdmin,
      adminRole,
      isVerified,
      verificationStatus,
      verifiedAt,
      notificationPreferences.entries.fold<int>(
        0,
        (acc, e) => acc ^ Object.hash(e.key, e.value),
      ),
      quietHoursStart,
      quietHoursEnd,
      availableImmediately,
      preferredExperienceLevel,
      preferredEducationLevel,
      preferredRegion,
      introVideoUrl,
      createdAt,
      updatedAt,
    ]);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, '
        'phoneNumber: $phoneNumber, bio: $bio, photoUrl: $photoUrl, '
        'hotelName: $hotelName, position: $position, userType: $userType, '
        'isAdmin: $isAdmin, adminRole: $adminRole, '
        'isVerified: $isVerified, verificationStatus: $verificationStatus, '
        'verifiedAt: $verifiedAt, notificationPreferences: $notificationPreferences, '
        'quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd, '
        'availableImmediately: $availableImmediately, '
        'preferredExperienceLevel: $preferredExperienceLevel, '
        'preferredEducationLevel: $preferredEducationLevel, '
        'preferredRegion: $preferredRegion, introVideoUrl: $introVideoUrl, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
