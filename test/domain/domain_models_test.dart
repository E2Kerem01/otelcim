import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/domain/moderation_action.dart';
import 'package:otelcim/features/admin/domain/verification_request_model.dart' as admin;
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/boosts/domain/boost_model.dart';
import 'package:otelcim/features/boosts/domain/boost_purchase_model.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/message.dart';
import 'package:otelcim/shared/models/onboarding_slide_data.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/models/verification_request.dart' as shared;

void main() {
  group('Firestore domain models', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('AdminAction round-trips and moderation helpers map correctly', () async {
      final action = AdminAction(adminId: 'admin', actionType: AdminActionType.banUser, targetType: AdminActionTargetType.user, targetId: 'u1', reason: 'spam');
      final ref = await db.collection('actions').add(action.toMap());
      final parsed = AdminAction.fromDoc(await ref.get());
      expect(parsed.adminId, 'admin');
      expect(parsed.actionType, AdminActionType.banUser);
      expect(parsed.targetType, AdminActionTargetType.user);
      expect(AdminActionType.banUser.label, isNotEmpty);
      final params = ModerationActionParams.banUser(userId: 'u1', reason: 'spam');
      expect(params.actionType.requiresReason, isTrue);
      expect(params.actionType.isDestructive, isTrue);
      expect(params.toAdminAction('admin').targetId, 'u1');
    });

    test('admin VerificationRequest round-trips and uses defaults', () async {
      final request = admin.VerificationRequest(employerId: 'e1', hotelName: 'Otel', documentUrls: const ['a'], status: admin.VerificationStatus.pending, submittedAt: DateTime(2026));
      final ref = await db.collection('verification').add(request.toMap());
      final parsed = admin.VerificationRequest.fromDoc(await ref.get());
      expect(parsed.employerId, 'e1');
      expect(parsed.documentUrls, ['a']);
      await db.collection('verification').doc('empty').set({});
      expect(admin.VerificationRequest.fromDoc(await db.collection('verification').doc('empty').get()).status, admin.VerificationStatus.pending);
    });

    test('BannerAd copyWith and Firestore conversion preserve values', () async {
      final ad = BannerAd(id: 'a', title: 'Başlık', advertiserName: 'Firma', imageUrl: 'img', targetUrl: 'url', order: 2, startDate: DateTime(2026));
      expect(ad.copyWith(title: 'Yeni').title, 'Yeni');
      final ref = await db.collection('ads').add(ad.toMap());
      final parsed = BannerAd.fromDoc(await ref.get());
      expect(parsed.order, 2);
      expect(parsed.isActive, isTrue);
    });

    test('Boost and BoostPurchase serialize enum and numeric fields', () async {
      final boost = Boost(id: 'b', listingId: 'l', userId: 'u', durationType: BoostDurationType.days14, durationDays: 14, price: 89.99, platform: 'test', transactionId: 'tx');
      final boostRef = await db.collection('boosts').add(boost.toMap());
      final parsedBoost = Boost.fromDoc(await boostRef.get());
      expect(parsedBoost.durationType, BoostDurationType.days14);
      expect(parsedBoost.price, 89.99);
      final purchase = BoostPurchase(id: 'p', userId: 'u', listingId: 'l', durationType: '30', price: 149.99, platform: 'test', transactionId: 'tx', productId: 'boost_30_days', status: PurchaseStatus.completed);
      final purchaseRef = await db.collection('purchases').add(purchase.toMap());
      expect(BoostPurchase.fromDoc(await purchaseRef.get()).status, PurchaseStatus.completed);
    });

    test('Listing preserves legacy and structured fields', () async {
      final listing = Listing(id: 'l', posterId: 'u', posterName: 'User', title: 'İş', description: 'Açıklama', category: 'servisGarson', location: 'Muğla / Bodrum', salary: '40.000 TL', city: 'Muğla', minSalaryTl: 40000, maxSalaryTl: 45000, employmentType: EmploymentType.seasonal, contactInfo: 'mail');
      final ref = await db.collection('listings').add(listing.toMap());
      final parsed = Listing.fromDoc(await ref.get());
      expect(parsed.salary, '40.000 TL');
      expect(parsed.city, 'Muğla');
      expect(parsed.employmentType, EmploymentType.seasonal);
      await db.collection('listings').doc('legacy').set({'title': 'Eski'});
      expect(Listing.fromDoc(await db.collection('listings').doc('legacy').get()).minSalaryTl, isNull);
    });

    test('Conversation and Message round-trip and defaults work', () async {
      final conversation = Conversation(id: 'c', listingId: 'l', listingTitle: 'İş', posterId: 'p', seekerId: 's');
      expect(conversation.otherParticipant('p'), 's');
      final cRef = await db.collection('conversations').add(conversation.toMap());
      expect(Conversation.fromDoc(await cRef.get()).lastMessage, '');
      final message = Message(id: 'm', senderId: 's', text: 'Merhaba');
      final mRef = await db.collection('messages').add(message.toMap());
      expect(Message.fromDoc(await mRef.get()).text, 'Merhaba');
    });

    test('Report parses targets/reasons and serializes', () async {
      final report = Report(reporterId: 'r', targetId: 'l', targetType: ReportTargetType.listing, reason: ReportReason.scam, description: 'Şüpheli');
      final ref = await db.collection('reports').add(report.toMap());
      final parsed = Report.fromDoc(await ref.get());
      expect(parsed.reason, ReportReason.scam);
      expect(parsed.targetType, ReportTargetType.listing);
      expect(ReportReason.scam.label, isNotEmpty);
    });
  });

  group('Value models', () {
    test('AppUser defaults and admin roles convert', () {
      const user = AppUser(uid: 'u', email: 'u@test.com');
      expect(user.isAdmin, isFalse);
      expect(AdminRole.superAdmin.toFirestore(), 'super_admin');
      expect(AdminRoleExtension.fromFirestore('support_agent'), AdminRole.supportAgent);
    });

    test('OnboardingSlideData implements value equality', () {
      const a = OnboardingSlideData(title: 'T', description: 'D', icon: Icons.search);
      const b = OnboardingSlideData(title: 'T', description: 'D', icon: Icons.search);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(OnboardingSlideData.slides, hasLength(3));
    });

    test('UserProfile copyWith, equality and Firestore round-trip', () async {
      final now = DateTime(2026, 1, 1);
      final profile = UserProfile(id: 'u', email: 'u@test.com', displayName: 'Ali', userType: 'employer', isAdmin: true, adminRole: AdminRole.contentModerator, createdAt: now, updatedAt: now);
      expect(profile.copyWith(displayName: 'Veli').displayName, 'Veli');
      expect(profile.copyWith(), profile);
      final db = FakeFirebaseFirestore();
      await db.collection('profiles').doc('u').set(profile.toFirestore());
      final parsed = UserProfile.fromFirestore(await db.collection('profiles').doc('u').get());
      expect(parsed, profile);
      expect(parsed.hashCode, profile.hashCode);
    });

    test('shared VerificationRequest copyWith, equality and round-trip', () async {
      final now = DateTime(2026, 1, 1);
      final request = shared.VerificationRequest(id: 'v', userId: 'u', userEmail: 'u@test.com', hotelName: 'Otel', hotelAddress: 'Adres', documentUrls: const ['doc'], requestedAt: now);
      expect(request.copyWith(status: 'approved').status, 'approved');
      final db = FakeFirebaseFirestore();
      await db.collection('verification').doc('v').set(request.toFirestore());
      final parsed = shared.VerificationRequest.fromFirestore(await db.collection('verification').doc('v').get());
      expect(parsed, request);
      expect(parsed.hashCode, request.hashCode);
    });
  });
}
