import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';

void main() {
  final newest = DateTime(2026, 9, 24, 12);
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<List<String>> ids(Query<Map<String, dynamic>> query) async =>
      (await query.get()).docs.map((doc) => doc.id).toList();

  group('adminVerificationQuery', () {
    setUp(() async {
      await db.collection('verification_requests').doc('old-pending').set({
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(newest.subtract(const Duration(days: 2))),
      });
      await db.collection('verification_requests').doc('new-approved').set({
        'status': 'approved',
        'submittedAt': Timestamp.fromDate(newest),
      });
      await db.collection('verification_requests').doc('new-pending').set({
        'status': 'pending',
        'submittedAt': Timestamp.fromDate(newest.subtract(const Duration(days: 1))),
      });
    });

    test('filters status and sorts submittedAt descending', () async {
      expect(
        await ids(adminVerificationQuery(db, filter: 'pending')),
        ['new-pending', 'old-pending'],
      );
      expect(
        await ids(adminVerificationQuery(db, filter: 'all')),
        ['new-approved', 'new-pending', 'old-pending'],
      );
    });
  });

  group('adminCertificatesQuery', () {
    setUp(() async {
      await db.collection('certificates').doc('rejected-old').set({
        'status': 'rejected',
        'createdAt': Timestamp.fromDate(newest.subtract(const Duration(days: 3))),
      });
      await db.collection('certificates').doc('pending-new').set({
        'status': 'pending',
        'createdAt': Timestamp.fromDate(newest),
      });
      await db.collection('certificates').doc('pending-old').set({
        'status': 'pending',
        'createdAt': Timestamp.fromDate(newest.subtract(const Duration(days: 1))),
      });
    });

    test('filters status and sorts createdAt descending', () async {
      expect(
        await ids(adminCertificatesQuery(db, filter: 'pending')),
        ['pending-new', 'pending-old'],
      );
      expect(
        await ids(adminCertificatesQuery(db, filter: 'all')),
        ['pending-new', 'pending-old', 'rejected-old'],
      );
    });
  });

  group('adminAuditLogQuery', () {
    setUp(() async {
      await db.collection('admin_audit_log').doc('old').set({
        'adminId': 'admin-a',
        'actionType': AdminActionType.banUser.name,
        'timestamp': Timestamp.fromDate(newest.subtract(const Duration(hours: 2))),
      });
      await db.collection('admin_audit_log').doc('new-other').set({
        'adminId': 'admin-b',
        'actionType': AdminActionType.banUser.name,
        'timestamp': Timestamp.fromDate(newest),
      });
      await db.collection('admin_audit_log').doc('new-match').set({
        'adminId': 'admin-a',
        'actionType': AdminActionType.warnUser.name,
        'timestamp': Timestamp.fromDate(newest.subtract(const Duration(minutes: 1))),
      });
    });

    test('keeps admin filter, action filter, and timestamp ordering', () async {
      expect(
        await ids(adminAuditLogQuery(db, adminId: 'admin-a')),
        ['new-match', 'old'],
      );
      expect(
        await ids(adminAuditLogQuery(
          db,
          adminId: 'admin-a',
          actionType: AdminActionType.warnUser,
        )),
        ['new-match'],
      );
    });
  });

  group('adminBannerAdsQuery', () {
    setUp(() async {
      await db.collection('banner_ads').doc('active-late').set({
        'isActive': true,
        'order': 2,
        'createdAt': Timestamp.fromDate(newest),
      });
      await db.collection('banner_ads').doc('active-first').set({
        'isActive': true,
        'order': 1,
        'createdAt': Timestamp.fromDate(newest.subtract(const Duration(days: 1))),
      });
      await db.collection('banner_ads').doc('inactive').set({
        'isActive': false,
        'order': 1,
        'createdAt': Timestamp.fromDate(newest.subtract(const Duration(days: 2))),
      });
    });

    test('filters active state and sorts order then creation date', () async {
      expect(
        await ids(adminBannerAdsQuery(db, filter: 'active')),
        ['active-first', 'active-late'],
      );
      expect(
        await ids(adminBannerAdsQuery(db, filter: 'inactive')),
        ['inactive'],
      );
      expect(
        await ids(adminBannerAdsQuery(db, filter: 'all')),
        ['active-first', 'inactive', 'active-late'],
      );
    });
  });
}
