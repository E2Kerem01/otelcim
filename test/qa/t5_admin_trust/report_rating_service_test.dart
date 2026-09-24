import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ratings/domain/rating_model.dart';
import 'package:otelcim/features/ratings/services/rating_service.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/services/report_service.dart';

Rating rating({
  String id = '',
  String conversationId = 'conversation-1',
  String raterId = 'rater-1',
  String ratedUserId = 'user-1',
  int stars = 5,
  String? reviewText,
  RatingModerationStatus moderationStatus = RatingModerationStatus.approved,
}) {
  return Rating(
    id: id,
    conversationId: conversationId,
    raterId: raterId,
    ratedUserId: ratedUserId,
    stars: stars,
    reviewText: reviewText,
    moderationStatus: moderationStatus,
  );
}

void main() {
  group('ReportService', () {
    late FakeFirebaseFirestore db;
    late ReportService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = ReportService(db);
    });

    test(
      'pending stream includes missing status and excludes reviewed reports',
      () async {
        final now = DateTime(2026, 9, 23);
        await db.collection('reports').doc('pending').set({
          'reporterId': 'r1',
          'targetId': 'l1',
          'targetType': 'listing',
          'reason': 'spam',
          'createdAt': now,
        });
        await db.collection('reports').doc('dismissed').set({
          'reporterId': 'r2',
          'targetId': 'l2',
          'targetType': 'listing',
          'reason': 'spam',
          'status': 'dismissed',
          'createdAt': now.subtract(const Duration(minutes: 1)),
        });

        final reports = await service.watchPendingReports().first;

        expect(reports.map((report) => report.id), ['pending']);
      },
    );

    test(
      'report serialization preserves Arabic text and target type',
      () async {
        await service.submitReport(
          const Report(
            reporterId: 'r1',
            targetId: 'u1',
            targetType: ReportTargetType.user,
            reason: ReportReason.other,
            description: 'محتوى غير مناسب',
          ),
        );

        final doc = (await db.collection('reports').get()).docs.single;
        expect(doc.data()['targetType'], 'user');
        expect(doc.data()['description'], 'محتوى غير مناسب');
      },
    );

    test(
      'target type must be part of duplicate detection',
      () async {
        await service.submitReport(
          const Report(
            reporterId: 'r1',
            targetId: 'same-id',
            targetType: ReportTargetType.listing,
            reason: ReportReason.spam,
          ),
        );

        expect(
          await service.hasUserReportedTarget(
            reporterId: 'r1',
            targetType: ReportTargetType.user,
            targetId: 'same-id',
          ),
          isFalse,
        );
      },
      skip:
          'BUG-t5-001: hasUserReportedTarget ignores targetType and mixes listing/user reports',
    );
  });

  group('RatingService', () {
    late FakeFirebaseFirestore db;
    late RatingService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = RatingService(db);
    });

    test('accepts boundary stars and a 500-character review', () async {
      await service.submitRating(rating(stars: 1, reviewText: 'a' * 500));
      await service.submitRating(
        rating(conversationId: 'conversation-2', raterId: 'rater-2', stars: 5),
      );

      expect(
        (await db.collection('ratings').doc('conversation-1_rater-1').get())
            .exists,
        isTrue,
      );
      expect(
        (await db.collection('ratings').doc('conversation-2_rater-2').get())
            .exists,
        isTrue,
      );
    });

    test('rejects reviews longer than 500 characters before writing', () async {
      await expectLater(
        service.submitRating(rating(reviewText: 'a' * 501)),
        throwsA(isA<ArgumentError>()),
      );
      expect((await db.collection('ratings').get()).docs, isEmpty);
    });

    test(
      'same conversation and rater cannot submit twice with the canonical id',
      () async {
        await service.submitRating(rating());

        await expectLater(
          service.submitRating(rating(stars: 4)),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'a caller-supplied rating id cannot bypass the one-rating rule',
      () async {
        await service.submitRating(rating(id: 'first-id'));

        await expectLater(
          service.submitRating(rating(id: 'second-id', stars: 4)),
          throwsA(isA<StateError>()),
        );
      },
      skip:
          'BUG-t5-002: submitRating uses a caller-supplied id without checking conversationId and raterId',
    );

    test('user stream and average include only approved ratings', () async {
      await service.submitRating(rating(stars: 5));
      await service.submitRating(
        rating(
          conversationId: 'conversation-2',
          raterId: 'rater-2',
          stars: 1,
          moderationStatus: RatingModerationStatus.pending,
        ),
      );
      await db.collection('ratings').doc('flagged').set({
        'conversationId': 'conversation-3',
        'raterId': 'rater-3',
        'ratedUserId': 'user-1',
        'stars': 3,
        'moderationStatus': 'flagged',
        'createdAt': Timestamp.now(),
      });

      final visible = await service.watchUserRatings('user-1').first;

      expect(visible, hasLength(1));
      expect(visible.single.stars, 5);
      expect(await service.getAverageRating('user-1'), 5);
      expect(await service.getAverageRating('missing-user'), 0);
    });

    test(
      'unknown moderation status is not treated as approved',
      () async {
        await db.collection('ratings').doc('malformed').set({
          'conversationId': 'conversation-1',
          'raterId': 'rater-1',
          'ratedUserId': 'user-1',
          'stars': 5,
          'moderationStatus': 'unexpected-value',
          'createdAt': Timestamp.now(),
        });

        final visible = await service.watchUserRatings('user-1').first;

        expect(visible, isEmpty);
      },
      skip:
          'BUG-t5-003: Rating.fromDoc falls back to approved for an unknown moderation status',
    );
  });
}
