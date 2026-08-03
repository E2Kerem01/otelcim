import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/analytics_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart' as admin;
import 'package:otelcim/features/admin/domain/verification_request_model.dart' as admin;
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/services/chat_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/report_service.dart';

void main() {
  group('Admin and moderation services', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('logs, watches and filters admin actions', () async {
      final service = AdminService(db);
      await service.logAdminAction(const AdminAction(adminId: 'a1', actionType: AdminActionType.warnUser, targetType: AdminActionTargetType.user, targetId: 'u1'));
      await service.logAdminAction(const AdminAction(adminId: 'a2', actionType: AdminActionType.banUser, targetType: AdminActionTargetType.user, targetId: 'u2'));
      final actions = await service.watchAuditLog(adminId: 'a1').first;
      expect(actions, hasLength(1));
      expect(actions.single.actionType, AdminActionType.warnUser);
      expect(service.isAdmin(const AppUser(uid: 'a', email: 'a@x', isAdmin: true)), isTrue);
      expect(service.checkAdminPermission(user: const AppUser(uid: 'a', email: 'a@x', isAdmin: true, adminRole: AdminRole.supportAgent), actionType: AdminActionType.dismissReport), isTrue);
      expect(service.checkAdminPermission(user: const AppUser(uid: 'a', email: 'a@x', isAdmin: true, adminRole: AdminRole.supportAgent), actionType: AdminActionType.banUser), isFalse);
      expect((await service.getAdminAction(actions.single.id))!.adminId, 'a1');
      expect(await service.getRecentAuditLog(limit: 1), hasLength(1));
      expect(await service.getAdminAction('missing'), isNull);
      final now = Timestamp.now();
      await db.collection('user_profiles').doc('a1').set({'email': 'a@x', 'userType': 'employer', 'isAdmin': true, 'adminRole': 'super_admin', 'createdAt': now, 'updatedAt': now});
      final profile = await service.getUserProfile('a1');
      expect(service.isAdminProfile(profile), isTrue);
    });

    test('moderation methods update reports, listings and users', () async {
      final service = ModerationService(db);
      await db.collection('reports').doc('r').set({'status': 'pending'});
      await db.collection('listings').doc('l').set({'status': 'active'});
      await db.collection('user_profiles').doc('u').set({'warnings': <dynamic>[]});
      await service.dismissReport(reportId: 'r', adminId: 'a', reason: 'yok');
      expect((await db.collection('reports').doc('r').get()).data()!['status'], 'dismissed');
      await service.warnUser(userId: 'u', adminId: 'a', reason: 'uyarı');
      expect((await db.collection('user_profiles').doc('u').get()).data()!['warnings'], hasLength(1));
      await service.removeListing(listingId: 'l', adminId: 'a', reason: 'spam');
      expect((await db.collection('listings').doc('l').get()).data()!['status'], 'removed');
      await service.suspendUser(userId: 'u', adminId: 'a', reason: 'spam');
      expect((await db.collection('user_profiles').doc('u').get()).data()!['isSuspended'], isTrue);
      await service.banUser(userId: 'u', adminId: 'a', reason: 'spam');
      expect((await db.collection('user_profiles').doc('u').get()).data()!['isBanned'], isTrue);
      await service.unsuspendUser(userId: 'u', adminId: 'a');
      expect((await db.collection('user_profiles').doc('u').get()).data()!['isSuspended'], isFalse);
      await service.unbanUser(userId: 'u', adminId: 'a');
      expect((await db.collection('user_profiles').doc('u').get()).data()!['isBanned'], isFalse);
      await service.restoreListing(listingId: 'l', adminId: 'a');
      expect((await db.collection('listings').doc('l').get()).data()!['status'], 'active');
    });

    test('verification service watches, approves and rejects requests', () async {
      final service = admin.VerificationService(db);
      await db.collection('verification_requests').doc('v1').set({'employerId': 'e', 'hotelName': 'A', 'documentUrls': [], 'status': 'pending', 'submittedAt': Timestamp.now()});
      expect(await service.watchPendingVerifications().first, hasLength(1));
      await service.approveVerification(verificationId: 'v1', adminId: 'a');
      expect((await db.collection('verification_requests').doc('v1').get()).data()!['status'], 'approved');
      await db.collection('verification_requests').doc('v2').set({'status': 'pending'});
      await service.rejectVerification(verificationId: 'v2', adminId: 'a', reason: 'eksik');
      expect((await db.collection('verification_requests').doc('v2').get()).data()!['rejectionReason'], 'eksik');
      final submittedId = await service.submitVerificationRequest(const admin.VerificationRequest(employerId: 'e2', hotelName: 'B', documentUrls: [], status: admin.VerificationStatus.pending));
      expect(await service.getVerificationRequest(submittedId), isNotNull);
      expect(await service.watchEmployerVerifications('e2').first, hasLength(1));
    });

    test('analytics returns counts and dashboard metrics', () async {
      final now = Timestamp.now();
      await db.collection('listings').add({'status': 'active'});
      await db.collection('listings').add({'status': 'closed'});
      await db.collection('user_profiles').add({'createdAt': now});
      await db.collection('reports').add({'status': 'pending'});
      await db.collection('verification_requests').add({'status': 'pending'});
      final service = AdminAnalyticsService(db);
      expect(await service.getActiveListingsCount(), 1);
      expect(await service.getNewUsersCount(), 1);
      expect(await service.getOpenReportsCount(), 1);
      expect(await service.getPendingVerificationsCount(), 1);
      expect(await service.watchActiveListingsCount().first, 1);
      expect(await service.watchNewUsersCount().first, 1);
      expect(await service.watchOpenReportsCount().first, 1);
      expect(await service.watchPendingVerificationsCount().first, 1);
      final metrics = await service.getDashboardMetrics();
      expect(metrics.activeListings, 1);
      expect(metrics.pendingVerifications, 1);
    });
  });

  group('Ads and boosts', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('banner CRUD and active date filtering work', () async {
      final service = BannerAdService(db);
      final now = DateTime.now();
      final activeId = await service.createBannerAd(BannerAd(id: '', title: 'A', advertiserName: 'X', imageUrl: 'i', targetUrl: 'u', order: 2, startDate: now.subtract(const Duration(days: 1)), endDate: now.add(const Duration(days: 1))));
      await service.createBannerAd(BannerAd(id: '', title: 'Gelecek', advertiserName: 'X', imageUrl: 'i', targetUrl: 'u', order: 1, startDate: now.add(const Duration(days: 1))));
      await service.createBannerAd(const BannerAd(id: '', title: 'Pasif', advertiserName: 'X', imageUrl: 'i', targetUrl: 'u', isActive: false));
      expect(await service.watchAllBannerAds().first, hasLength(3));
      expect((await service.watchActiveBannerAds().first).map((e) => e.title), ['A']);
      await service.toggleActive(activeId, false);
      expect(await service.watchActiveBannerAds().first, isEmpty);
      await service.updateBannerAd(BannerAd(id: activeId, title: 'Yeni', advertiserName: 'X', imageUrl: 'i', targetUrl: 'u'));
      expect((await db.collection('banner_ads').doc(activeId).get()).data()!['title'], 'Yeni');
      await service.deleteBannerAd(activeId);
      expect((await db.collection('banner_ads').doc(activeId).get()).exists, isFalse);
    });

    test('boost products create matching durations/prices and user streams', () async {
      final service = BoostService(db);
      for (final entry in {'boost_7_days': 7, 'boost_14_days': 14, 'boost_30_days': 30}.entries) {
        final listingId = 'l${entry.value}';
        await db.collection('listings').doc(listingId).set({'status': 'active'});
        await service.processBoostPurchase(listingId: listingId, userId: 'u', productId: entry.key, transactionId: 'tx${entry.value}');
      }
      final boosts = await service.watchUserBoosts('u').first;
      expect(boosts.map((e) => e.durationDays).toSet(), {7, 14, 30});
      final purchases = await service.watchUserBoostPurchases('u').first;
      expect(purchases, hasLength(3));
      expect(purchases.first.price, isPositive);
    });
  });

  group('Report and chat services', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('report submission, duplicate detection and pending stream work', () async {
      final service = ReportService(db);
      await service.submitReport(const Report(reporterId: 'r', targetId: 'l', targetType: ReportTargetType.listing, reason: ReportReason.spam));
      expect(await service.hasAlreadyReported(reporterId: 'r', targetId: 'l'), isTrue);
      expect(await service.hasUserReportedTarget(reporterId: 'r', targetType: ReportTargetType.listing, targetId: 'l'), isTrue);
      expect(await service.watchPendingReports().first, hasLength(1));
    });

    test('chat creates once, sends, watches and fetches conversations/messages', () async {
      final service = ChatService(db);
      final result = await service.getOrCreateConversation(listingId: 'l', listingTitle: 'İş', posterId: 'p', seekerId: 's');
      final id = result.conversationId;
      expect(result.isNew, isTrue);
      expect(await service.getConversation(id), isA<Conversation>());
      expect(await service.watchConversations('p').first, hasLength(1));
      await service.sendMessage(conversationId: id, senderId: 's', text: 'Merhaba');
      final messages = await service.watchMessages(id).first;
      expect(messages.single.text, 'Merhaba');
      expect((await service.getConversation(id))!.lastMessage, 'Merhaba');
      expect(await service.getConversation('missing'), isNull);
    });
  });

  group('Listing service filters and pagination', () {
    late FakeFirebaseFirestore db;
    late ListingService service;
    setUp(() async {
      db = FakeFirebaseFirestore();
      service = ListingService(db);
      await _addListing(db, '1', title: 'Garson', category: 'servisGarson', city: 'Muğla', min: 30000, max: 35000, type: EmploymentType.seasonal, createdAt: DateTime.now());
      await _addListing(db, '2', title: 'Resepsiyon', category: 'resepsiyon', city: 'Antalya', min: 45000, max: 50000, type: EmploymentType.fullTime, createdAt: DateTime.now().subtract(const Duration(days: 10)));
      await _addListing(db, '3', title: 'Kapalı', category: 'resepsiyon', city: 'Antalya', min: 20000, max: 25000, type: EmploymentType.partTime, createdAt: DateTime.now(), status: 'closed');
    });

    test('watchActiveListings and watchMyListings filter and order', () async {
      expect(await service.watchActiveListings(category: 'resepsiyon').first, hasLength(1));
      expect(await service.watchActiveListings(searchQuery: 'gar').first, hasLength(1));
      expect(await service.watchMyListings('owner').first, hasLength(3));
    });

    test('each advanced pagination filter returns matching listing', () async {
      expect((await service.getPaginatedListings(category: 'servisGarson')).listings.single.id, '1');
      expect((await service.getPaginatedListings(searchQuery: 'reseps')).listings.single.id, '2');
      expect((await service.getPaginatedListings(city: 'Muğla')).listings.single.id, '1');
      expect((await service.getPaginatedListings(minSalaryTl: 40000)).listings.single.id, '2');
      expect((await service.getPaginatedListings(maxSalaryTl: 40000)).listings.single.id, '1');
      expect((await service.getPaginatedListings(employmentType: EmploymentType.seasonal)).listings.single.id, '1');
      expect((await service.getPaginatedListings(dateFilter: ListingDateFilter.lastWeek)).listings.single.id, '1');
      expect((await service.getPaginatedListings(sortOrder: ListingSortOrder.salaryHighToLow)).listings.first.id, '2');
      expect((await service.getPaginatedListings(sortOrder: ListingSortOrder.salaryLowToHigh)).listings.first.id, '1');
    });

    test('getNextPage continues from cursor', () async {
      final first = await service.getPaginatedListings(limit: 1);
      expect(first.hasMore, isTrue);
      final second = await service.getNextPage(lastDocument: first.lastDocument!, limit: 1);
      expect(second.listings.single.id, isNot(first.listings.single.id));
    });

    test('listing CRUD and status transitions work', () async {
      final createdId = await service.createListing(Listing(id: '', posterId: 'u', posterName: 'Otel', title: 'Yeni', description: 'D', category: 'diger', location: 'İzmir', salary: '30 TL', contactInfo: 'x'));
      final created = await service.getListing(createdId);
      expect(created!.title, 'Yeni');
      await service.updateListing(Listing(id: createdId, posterId: 'u', posterName: 'Otel', title: 'Güncel', description: 'D', category: 'diger', location: 'İzmir', salary: '30 TL', contactInfo: 'x'));
      expect((await service.getListing(createdId))!.title, 'Güncel');
      await service.closeListing(createdId);
      expect((await service.getListing(createdId))!.status, ListingStatus.closed);
      await service.reactivateListing(createdId);
      expect((await service.getListing(createdId))!.status, ListingStatus.active);
      expect(await service.getListing('missing'), isNull);
    });
  });
}

Future<void> _addListing(FakeFirebaseFirestore db, String id, {required String title, required String category, required String city, required int min, required int max, required EmploymentType type, required DateTime createdAt, String status = 'active'}) => db.collection('listings').doc(id).set({
  'posterId': 'owner', 'posterName': 'Otel', 'title': title, 'description': '$title açıklaması', 'category': category, 'location': city, 'salary': '$min TL', 'city': city, 'minSalaryTl': min, 'maxSalaryTl': max, 'employmentType': type.name, 'contactInfo': 'x', 'status': status, 'createdAt': Timestamp.fromDate(createdAt), 'updatedAt': Timestamp.fromDate(createdAt),
});
