/// Generates a deterministic, shareable referral code for a user.
///
/// Takes the first 8 characters of [uid] (or the whole [uid] if it is
/// shorter) and uppercases them. Pure and side-effect free: it does not
/// require any Firestore reads, so it can be called both at registration
/// time and whenever a fallback display value is needed (e.g. before the
/// user's profile document has finished loading).
String generateReferralCode(String uid) {
  final prefix = uid.length > 8 ? uid.substring(0, 8) : uid;
  return prefix.toUpperCase();
}
