/// Represents the status of a job listing.
///
/// - [active]: The listing is currently open and accepting applications.
/// - [closed]: The listing has been closed but the position was not filled.
/// - [filled]: The position has been hired/filled.
enum ListingStatus {
  /// The listing is currently open and accepting applications
  active,

  /// The listing has been closed but the position was not filled
  closed,

  /// The position has been hired/filled
  filled;

  /// Converts the enum to a string value for Firestore storage
  String toFirestore() {
    return name;
  }

  /// Creates a ListingStatus from a Firestore string value
  static ListingStatus fromFirestore(String value) {
    return ListingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ListingStatus.active,
    );
  }

  /// Returns a human-readable display name for the status
  String get displayName {
    switch (this) {
      case ListingStatus.active:
        return 'Aktif';
      case ListingStatus.closed:
        return 'Kapalı';
      case ListingStatus.filled:
        return 'Dolduruldu';
    }
  }

  /// Returns true if the listing is accepting applications
  bool get isAcceptingApplications {
    return this == ListingStatus.active;
  }
}
