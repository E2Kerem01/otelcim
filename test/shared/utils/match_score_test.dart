import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/utils/match_score.dart';

void main() {
  Listing listing(String experience, String education, String region) => Listing(
    id: 'listing', posterId: 'employer', posterName: 'Hotel', title: 'Job',
    description: 'Description', category: 'resepsiyon', location: 'Antalya',
    salary: '40.000 TL', contactInfo: 'contact', experienceLevel: experience,
    educationLevel: education, region: region,
  );

  UserProfile profile({String? experience, String? education, String? region}) => UserProfile(
    id: 'jobseeker', email: 'jobseeker@example.com', userType: 'jobseeker',
    preferredExperienceLevel: experience, preferredEducationLevel: education,
    preferredRegion: region, createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );

  test('full match is 100', () {
    expect(calculateMatchScore(
      listing: listing(ExperienceLevel.oneToThreeYears.name, EducationLevel.highSchool.name, 'antalya'),
      profile: profile(experience: ExperienceLevel.threePlusYears.name, education: EducationLevel.university.name, region: 'antalya'),
    ), 100);
  });

  test('one level below receives deterministic partial points', () {
    expect(calculateMatchScore(
      listing: listing(ExperienceLevel.threePlusYears.name, EducationLevel.university.name, 'bodrum'),
      profile: profile(experience: ExperienceLevel.oneToThreeYears.name, education: EducationLevel.highSchool.name, region: 'antalya'),
    ), 33);
  });

  test('missing and non-matching criteria return zero', () {
    expect(calculateMatchScore(
      listing: listing(ExperienceLevel.threePlusYears.name, EducationLevel.university.name, 'bodrum'),
      profile: profile(),
    ), 0);
  });
}
