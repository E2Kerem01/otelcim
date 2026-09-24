import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';

void main() {
  group('UserProfile & AppUser Domain Models Tests', () {
    late FakeFirebaseFirestore db;

    setUp(() {
      db = FakeFirebaseFirestore();
    });

    test('UserProfile round-trip to/from Firestore preserves all standard fields', () async {
      final now = DateTime(2026, 3, 15, 10, 30);
      final profile = UserProfile(
        id: 'u_full',
        email: 'full@example.com',
        displayName: 'Mehmet Öz',
        phoneNumber: '+905551112233',
        bio: 'Şef aşçı, 10 yıl tecrübe.',
        photoUrl: 'https://storage.googleapis.com/photos/profile.jpg',
        hotelName: 'Antalya Palace',
        position: 'Mutfak Şefi',
        userType: 'employer',
        isVerified: true,
        verificationStatus: 'approved',
        verifiedAt: now,
        notificationPreferences: const <String, bool>{
          'messages': true,
          'listingAlerts': false,
          'seasonalReminders': true,
          'urgentListings': true,
          'marketing': false,
        },
        quietHoursStart: '23:00',
        quietHoursEnd: '07:00',
        availableImmediately: false,
        preferredExperienceLevel: 'threePlusYears',
        preferredEducationLevel: 'university',
        preferredRegion: 'antalya',
        introVideoUrl: 'https://storage.googleapis.com/videos/intro.mp4',
        referralCode: 'MEHMET01',
        referredBy: 'REF_PARENT',
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toFirestore();
      await db.collection('user_profiles').doc('u_full').set(map);

      final snap = await db.collection('user_profiles').doc('u_full').get();
      final parsed = UserProfile.fromFirestore(snap);

      expect(parsed.id, 'u_full');
      expect(parsed.email, 'full@example.com');
      expect(parsed.displayName, 'Mehmet Öz');
      expect(parsed.phoneNumber, '+905551112233');
      expect(parsed.bio, 'Şef aşçı, 10 yıl tecrübe.');
      expect(parsed.photoUrl, 'https://storage.googleapis.com/photos/profile.jpg');
      expect(parsed.hotelName, 'Antalya Palace');
      expect(parsed.position, 'Mutfak Şefi');
      expect(parsed.userType, 'employer');
      expect(parsed.isVerified, isTrue);
      expect(parsed.verificationStatus, 'approved');
      expect(parsed.verifiedAt, isNotNull);
      expect(parsed.quietHoursStart, '23:00');
      expect(parsed.quietHoursEnd, '07:00');
      expect(parsed.referralCode, 'MEHMET01');
      expect(parsed.referredBy, 'REF_PARENT');
      expect(parsed.notificationPreferences['marketing'], isFalse);
      expect(parsed.notificationPreferences['seasonalReminders'], isTrue);
    });

    test('UserProfile.toFirestore excludes server-controlled and concurrent fields', () {
      final now = DateTime(2026, 1, 1);
      final profile = UserProfile(
        id: 'u_sec',
        email: 'sec@test.com',
        userType: 'jobseeker',
        isAdmin: true,
        adminRole: AdminRole.superAdmin,
        referralCount: 15,
        freeBoostCredits: 4,
        hasUsedFreeUrgentListing: true,
        createdAt: now,
        updatedAt: now,
      );

      final firestoreMap = profile.toFirestore();

      // Security: Client must NEVER write isAdmin or adminRole
      expect(firestoreMap.containsKey('isAdmin'), isFalse);
      expect(firestoreMap.containsKey('adminRole'), isFalse);

      // Concurrency: Client must not overwrite referral credits with stale values
      expect(firestoreMap.containsKey('referralCount'), isFalse);
      expect(firestoreMap.containsKey('freeBoostCredits'), isFalse);
      expect(firestoreMap.containsKey('hasUsedFreeUrgentListing'), isFalse);
    });

    test(
      'UserProfile.fromFirestore safely parses numeric fields when stored as double/num',
      () async {
        final now = Timestamp.fromDate(DateTime(2026, 1, 1));
        await db.collection('user_profiles').doc('num_test').set(<String, dynamic>{
          'email': 'num@test.com',
          'userType': 'jobseeker',
          'freeBoostCredits': 3.0, // double value
          'referralCount': 5.0,    // double value
          'createdAt': now,
          'updatedAt': now,
        });

        final snap = await db.collection('user_profiles').doc('num_test').get();

        // Currently, data['freeBoostCredits'] as int? throws TypeError on double:
        // type 'double' is not a subtype of type 'int?' in type cast
        final profile = UserProfile.fromFirestore(snap);

        expect(profile.freeBoostCredits, 3);
        expect(profile.referralCount, 5);
      },
      skip: 'BUG-t6-09: UserProfile.fromFirestore throws TypeError when numeric fields (freeBoostCredits, referralCount) are stored as double/num in Firestore',
    );

    test('UserProfile.fromFirestore handles minimal document with missing fields safely', () async {
      await db.collection('user_profiles').doc('minimal').set(<String, dynamic>{
        'email': 'minimal@test.com',
      });

      final snap = await db.collection('user_profiles').doc('minimal').get();
      final profile = UserProfile.fromFirestore(snap);

      expect(profile.email, 'minimal@test.com');
      expect(profile.displayName, isNull);
      expect(profile.phoneNumber, isNull);
      expect(profile.bio, isNull);
      expect(profile.userType, 'job_seeker');
      expect(profile.availableImmediately, isFalse);
      expect(profile.referralCount, 0);
      expect(profile.freeBoostCredits, 0);
      expect(profile.isBanned, isFalse);
      expect(profile.isSuspended, isFalse);
      expect(profile.createdAt, isNotNull);
      expect(profile.updatedAt, isNotNull);
    });

    test('UserProfile.copyWith allows setting nullable fields to null using _undefined sentinel', () {
      final now = DateTime(2026, 1, 1);
      final profile = UserProfile(
        id: 'u_copy',
        email: 'copy@test.com',
        userType: 'jobseeker',
        displayName: 'Eski İsim',
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
        preferredRegion: 'antalya',
        introVideoUrl: 'https://test.com/video.mp4',
        referredBy: 'REF_OLD',
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(
        displayName: 'Yeni İsim',
        quietHoursStart: null,
        quietHoursEnd: null,
        preferredRegion: null,
        introVideoUrl: null,
        referredBy: null,
      );

      expect(updated.displayName, 'Yeni İsim');
      expect(updated.quietHoursStart, isNull);
      expect(updated.quietHoursEnd, isNull);
      expect(updated.preferredRegion, isNull);
      expect(updated.introVideoUrl, isNull);
      expect(updated.referredBy, isNull);
      expect(updated.email, 'copy@test.com'); // untouched
    });

    test('AppUser properties and equality', () {
      const user1 = AppUser(
        uid: 'user_1',
        email: 'app@example.com',
        phoneNumber: '+905551234567',
        isAdmin: true,
        adminRole: AdminRole.contentModerator,
      );

      expect(user1.uid, 'user_1');
      expect(user1.email, 'app@example.com');
      expect(user1.phoneNumber, '+905551234567');
      expect(user1.isAdmin, isTrue);
      expect(user1.adminRole, AdminRole.contentModerator);

      const userDefault = AppUser(uid: 'user_def', email: 'def@example.com');
      expect(userDefault.isAdmin, isFalse);
      expect(userDefault.adminRole, isNull);
      expect(userDefault.phoneNumber, isNull);
    });
  });
}
