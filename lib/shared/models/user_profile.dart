import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's profile information in the application.
///
/// Contains personal details and role-specific fields (hotel name and position for employers).
class UserProfile {
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

  /// Whether the employer has been verified (only for employer users)
  final bool isVerified;

  /// Verification status: 'pending', 'approved', or 'rejected' (only for employer users)
  final String? verificationStatus;

  /// Timestamp when the employer was verified (only for verified employers)
  final DateTime? verifiedAt;

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
    this.isVerified = false,
    this.verificationStatus,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfile from a Firestore DocumentSnapshot
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
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
      isVerified: data['isVerified'] as bool? ?? false,
      verificationStatus: data['verificationStatus'] as String?,
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
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
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
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
    bool? isVerified,
    String? verificationStatus,
    DateTime? verifiedAt,
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
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
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
        other.isVerified == isVerified &&
        other.verificationStatus == verificationStatus &&
        other.verifiedAt == verifiedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      displayName,
      phoneNumber,
      bio,
      photoUrl,
      hotelName,
      position,
      userType,
      isVerified,
      verificationStatus,
      verifiedAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, '
        'phoneNumber: $phoneNumber, bio: $bio, photoUrl: $photoUrl, '
        'hotelName: $hotelName, position: $position, userType: $userType, '
        'isVerified: $isVerified, verificationStatus: $verificationStatus, '
        'verifiedAt: $verifiedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
