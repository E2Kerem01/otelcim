import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/presentation/listing_management_screen.dart';
import 'package:otelcim/features/admin/presentation/reports_moderation_screen.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/utils/search_keywords.dart';

void main() {
  group('adminListingsQuery', () {
    late FakeFirebaseFirestore db;

    Future<void> addListing(
      String id,
      String title, {
      String status = 'active',
      bool urgent = false,
      bool featured = false,
      int daysAgo = 0,
    }) {
      return db.collection('listings').doc(id).set({
        'title': title,
        'posterName': id == 'l1' ? 'Ayşe Otel' : 'Mehmet Kaya',
        'city': id == 'l3' ? 'İzmir' : 'Antalya',
        'location': id == 'l3' ? 'İzmir' : 'Antalya merkez',
        'status': status,
        'isUrgent': urgent,
        'isBoosted': featured,
        'searchKeywords': buildSearchKeywords([
          title,
          id == 'l1' ? 'Ayşe Otel' : 'Mehmet Kaya',
          id == 'l3' ? 'İzmir' : 'Antalya',
        ]),
        'createdAt': Timestamp.fromDate(
          DateTime.utc(2026, 9, 24).subtract(Duration(days: daysAgo)),
        ),
      });
    }

    setUp(() async {
      db = FakeFirebaseFirestore();
      await addListing('l1', 'Resepsiyonist', daysAgo: 3);
      await addListing(
        'l2',
        'Kat Şefi',
        status: 'removed',
        featured: true,
        daysAgo: 1,
      );
      await addListing(
        'l3',
        'Aşçı',
        status: 'closed',
        urgent: true,
        daysAgo: 2,
      );
    });

    Future<List<String>> ids(Query<Map<String, dynamic>> query) async =>
        (await query.get()).docs.map((doc) => doc.id).toList();

    test('lists newest first and applies status, urgent, and featured filters',
        () async {
      expect(await ids(adminListingsQuery(db, filter: 'all')), ['l2', 'l3', 'l1']);
      expect(await ids(adminListingsQuery(db, filter: 'active')), ['l1']);
      expect(await ids(adminListingsQuery(db, filter: 'removed')), ['l2']);
      expect(await ids(adminListingsQuery(db, filter: 'urgent')), ['l3']);
      expect(await ids(adminListingsQuery(db, filter: 'featured')), ['l2']);
    });

    test('searches keywords case- and Turkish-insensitively with filters',
        () async {
      expect(
        (await ids(adminListingsQuery(db, filter: 'all', search: 'AYSE')))
            .toSet(),
        {'l1'},
      );
      expect(
        await ids(adminListingsQuery(db, filter: 'removed', search: 'kat')),
        ['l2'],
      );
      expect(
        await ids(adminListingsQuery(db, filter: 'all', search: 'izmir')),
        ['l3'],
      );
    });
  });

  group('adminReportsQuery', () {
    late FakeFirebaseFirestore db;

    Future<void> addReport(
      String id, {
      required String status,
      required String targetType,
      int daysAgo = 0,
    }) {
      return db.collection('reports').doc(id).set({
        'reporterId': 'reporter-$id',
        'targetId': 'target-$id',
        'targetType': targetType,
        'reason': 'spam',
        'description': 'Açıklama',
        'status': status,
        'createdAt': Timestamp.fromDate(
          DateTime.utc(2026, 9, 24).subtract(Duration(days: daysAgo)),
        ),
      });
    }

    setUp(() async {
      db = FakeFirebaseFirestore();
      await addReport('r1', status: 'pending', targetType: 'listing', daysAgo: 3);
      await addReport('r2', status: 'dismissed', targetType: 'user', daysAgo: 1);
      await addReport('r3', status: 'pending', targetType: 'user', daysAgo: 2);
    });

    Future<List<String>> ids(Query<Map<String, dynamic>> query) async =>
        (await query.get()).docs.map((doc) => doc.id).toList();

    test('filters pending, dismissed, all, and target type in newest order',
        () async {
      expect(await ids(adminReportsQuery(db, filter: 'pending')), ['r3', 'r1']);
      expect(await ids(adminReportsQuery(db, filter: 'dismissed')), ['r2']);
      expect(await ids(adminReportsQuery(db, filter: 'all')), ['r2', 'r3', 'r1']);
      expect(
        await ids(
          adminReportsQuery(
            db,
            filter: 'pending',
            targetType: ReportTargetType.user,
          ),
        ),
        ['r3'],
      );
    });
  });

  test('dismissReports updates reports and writes one audit entry per id',
      () async {
    final db = FakeFirebaseFirestore();
    await db.collection('reports').doc('r1').set({'status': 'pending'});
    await db.collection('reports').doc('r2').set({'status': 'pending'});

    await ModerationService(db).dismissReports(
          ids: ['r1', 'r2', 'r1'],
          adminId: 'admin-1',
          reason: 'İnceleme sonucu reddedildi',
        );

    expect((await db.collection('reports').doc('r1').get()).data()?['status'], 'dismissed');
    expect((await db.collection('reports').doc('r2').get()).data()?['reviewedBy'], 'admin-1');
    final audit = await db.collection('admin_audit_log').get();
    expect(audit.docs, hasLength(2));
    expect(audit.docs.map((doc) => doc.data()['targetId']).toSet(), {'r1', 'r2'});
  });
}
