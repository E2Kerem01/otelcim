import '../../features/listings/domain/listing_model.dart';
import '../constants/listing_filters.dart';
import '../models/user_profile.dart';

int calculateMatchScore({
  required Listing listing,
  required UserProfile profile,
}) {
  var score = 0;
  score += _orderedScore(
    _experienceIndex(profile.preferredExperienceLevel),
    _experienceIndex(listing.experienceLevel),
    34,
  );
  score += _orderedScore(
    _educationIndex(profile.preferredEducationLevel),
    _educationIndex(listing.educationLevel),
    33,
  );
  if (profile.preferredRegion != null &&
      listing.region != null &&
      profile.preferredRegion == listing.region) {
    score += 33;
  }
  return score;
}

int _orderedScore(int? candidate, int? requirement, int fullScore) {
  if (candidate == null || requirement == null) return 0;
  if (candidate >= requirement) return fullScore;
  if (candidate + 1 == requirement) return fullScore ~/ 2;
  return 0;
}

int? _experienceIndex(String? value) {
  final level = ExperienceLevel.fromName(value);
  return level == null ? null : ExperienceLevel.values.indexOf(level);
}

int? _educationIndex(String? value) {
  final level = EducationLevel.fromName(value);
  return level == null ? null : EducationLevel.values.indexOf(level);
}
