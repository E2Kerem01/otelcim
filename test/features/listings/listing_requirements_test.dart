import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';

Listing listing({String? experienceLevel, String? educationLevel}) => Listing(
  id: 'listing',
  posterId: 'poster',
  posterName: 'Hotel',
  title: 'Job',
  description: 'Description',
  category: 'other',
  location: 'Location',
  salary: 'Salary',
  contactInfo: 'Contact',
  experienceLevel: experienceLevel,
  educationLevel: educationLevel,
);

void main() {
  test('requirement enums expose labels and parse stored names', () {
    expect(
      ExperienceLevel.values.every((level) => level.label.isNotEmpty),
      isTrue,
    );
    expect(
      EducationLevel.values.every((level) => level.label.isNotEmpty),
      isTrue,
    );
    expect(
      ExperienceLevel.fromName('oneToThreeYears'),
      ExperienceLevel.oneToThreeYears,
    );
    expect(EducationLevel.fromName('university'), EducationLevel.university);
    expect(ExperienceLevel.fromName('unknown'), isNull);
    expect(EducationLevel.fromName(null), isNull);
  });

  test(
    'Listing round-trips optional experience and education fields',
    () async {
      final db = FakeFirebaseFirestore();
      final ref = await db
          .collection('listings')
          .add(
            listing(
              experienceLevel: ExperienceLevel.threePlusYears.name,
              educationLevel: EducationLevel.highSchool.name,
            ).toMap(),
          );
      final parsed = Listing.fromDoc(await ref.get());
      expect(parsed.experienceLevel, ExperienceLevel.threePlusYears.name);
      expect(parsed.educationLevel, EducationLevel.highSchool.name);

      await db.collection('listings').doc('legacy').set({'title': 'Legacy'});
      final legacy = Listing.fromDoc(
        await db.collection('listings').doc('legacy').get(),
      );
      expect(legacy.experienceLevel, isNull);
      expect(legacy.educationLevel, isNull);
    },
  );
}
