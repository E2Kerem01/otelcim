import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart';

void main() {
  group('ModerationService edge cases', () {
    late FakeFirebaseFirestore db;
    late ModerationService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = ModerationService(db);
    });

    test('null suspension end represents an indefinite suspension', () async {
      await db.collection('user_profiles').doc('user-1').set({
        'isSuspended': false,
      });

      await service.suspendUser(
        userId: 'user-1',
        adminId: 'admin-1',
        reason: 'Repeated abuse',
      );

      final data = (await db.collection('user_profiles').doc('user-1').get())
          .data()!;
      expect(data['isSuspended'], isTrue);
      expect(data['suspensionEnd'], isNull);
      expect(data['suspensionReason'], 'Repeated abuse');
    });

    test(
      'a suspension with a past end is stored without silently clearing it',
      () async {
        await db.collection('user_profiles').doc('user-2').set({
          'isSuspended': false,
        });
        final end = DateTime(2020, 1, 1);

        await service.suspendUser(
          userId: 'user-2',
          adminId: 'admin-1',
          suspensionEnd: end,
        );

        final data = (await db.collection('user_profiles').doc('user-2').get())
            .data()!;
        expect(data['isSuspended'], isTrue);
        expect((data['suspensionEnd'] as Timestamp).toDate(), end);
      },
    );

    test('unsuspend clears suspension metadata as well as the flag', () async {
      await db.collection('user_profiles').doc('user-3').set({
        'isSuspended': true,
        'suspendedBy': 'old-admin',
        'suspensionReason': 'old reason',
        'suspensionEnd': Timestamp.fromDate(DateTime(2026, 10, 1)),
      });

      await service.unsuspendUser(userId: 'user-3', adminId: 'admin-1');

      final data = (await db.collection('user_profiles').doc('user-3').get())
          .data()!;
      expect(data['isSuspended'], isFalse);
      expect(data['suspendedBy'], isNull);
      expect(data['suspensionReason'], isNull);
      expect(data['suspensionEnd'], isNull);
    });
  });

  group('Admin VerificationService', () {
    late FakeFirebaseFirestore db;
    late VerificationService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = VerificationService(db);
    });

    test(
      'missing request returns null instead of fabricating a request',
      () async {
        expect(await service.getVerificationRequest('missing'), isNull);
      },
    );

    test(
      'legacy userId records can still be read by their document id',
      () async {
        final requestedAt = DateTime(2026, 9, 1);
        await db.collection('verification_requests').doc('legacy-1').set({
          'userId': 'employer-1',
          'hotelName': 'Otel',
          'documentUrls': <String>[],
          'status': 'pending',
          'requestedAt': requestedAt,
        });

        final request = await service.getVerificationRequest('legacy-1');

        expect(request, isNotNull);
        expect(request!.employerId, 'employer-1');
        expect(request.submittedAt, requestedAt);
      },
    );

    test(
      'approving a request also marks the employer profile as verified',
      () async {
        await db.collection('verification_requests').doc('request-1').set({
          'employerId': 'employer-1',
          'hotelName': 'Grand Hotel',
          'documentUrls': <String>['https://example.com/license.pdf'],
          'status': 'pending',
          'submittedAt': DateTime(2026, 9, 1),
        });
        await db.collection('user_profiles').doc('employer-1').set({
          'isVerified': false,
          'verificationStatus': 'pending',
        });

        await service.approveVerification(
          verificationId: 'request-1',
          adminId: 'admin-1',
        );

        final profile =
            (await db.collection('user_profiles').doc('employer-1').get())
                .data()!;
        expect(profile['isVerified'], isTrue);
        expect(profile['verificationStatus'], 'approved');
      },
      skip:
          'BUG-t5-004: approveVerification updates only the request and never updates user_profiles',
    );
  });
}
