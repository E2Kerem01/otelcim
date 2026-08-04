import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/notification_service.dart';

Listing listing({bool isUrgent = false}) => Listing(
  id: 'listing',
  posterId: 'poster',
  posterName: 'Hotel',
  title: 'Job',
  description: 'Description',
  category: 'other',
  location: 'Location',
  salary: 'Salary',
  contactInfo: 'Contact',
  isUrgent: isUrgent,
);

void main() {
  test(
    'urgent listing round-trips and legacy listings default to false',
    () async {
      final db = FakeFirebaseFirestore();
      final ref = await db
          .collection('listings')
          .add(listing(isUrgent: true).toMap());
      expect(Listing.fromDoc(await ref.get()).isUrgent, isTrue);

      await db.collection('listings').doc('legacy').set({'title': 'Legacy'});
      expect(
        Listing.fromDoc(
          await db.collection('listings').doc('legacy').get(),
        ).isUrgent,
        isFalse,
      );
    },
  );

  test('region topic names are deterministic and FCM safe', () {
    expect(regionTopicName('Bodrum'), 'region_bodrum');
    expect(regionTopicName('Ege Bölgesi'), 'region_ege_b_lgesi');
  });

  test('urgent listing notifications default to enabled', () {
    expect(
      UserProfile.defaultNotificationPreferences['urgentListings'],
      isTrue,
    );
  });
}
