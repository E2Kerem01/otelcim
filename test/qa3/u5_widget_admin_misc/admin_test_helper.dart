import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/domain/verification_request_model.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/analytics_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/features/seasonal/domain/seasonal_subscription_model.dart';
import 'package:otelcim/features/seasonal/services/seasonal_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/report_service.dart';

// --- Mocks ---

class MockAuthService extends Mock implements AuthService {}

class MockAdminService extends Mock implements AdminService {}

class MockAdminAnalyticsService extends Mock implements AdminAnalyticsService {}

class MockModerationService extends Mock implements ModerationService {}

class MockVerificationService extends Mock implements VerificationService {}

class MockCertificateService extends Mock implements CertificateService {}

class MockBannerAdService extends Mock implements BannerAdService {}

class MockSeasonalService extends Mock implements SeasonalService {}

class MockReportService extends Mock implements ReportService {}

class MockListingService extends Mock implements ListingService {}

// --- Fallback Registration ---

bool _fallbacksRegistered = false;

void registerAdminFallbackValues() {
  if (_fallbacksRegistered) return;
  _fallbacksRegistered = true;

  registerFallbackValue(
    const AdminAction(
      adminId: 'fallback_admin',
      actionType: AdminActionType.warnUser,
      targetType: AdminActionTargetType.user,
      targetId: 'fallback_target',
    ),
  );
  registerFallbackValue(AdminActionType.warnUser);
  registerFallbackValue(AdminActionTargetType.user);
  registerFallbackValue(
    UserProfile(
      id: 'fallback_user',
      email: 'fallback@example.com',
      userType: 'jobseeker',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  );
  registerFallbackValue(
    const Listing(
      id: 'fallback_listing',
      posterId: 'fallback_poster',
      posterName: 'Fallback Poster',
      title: 'Fallback Listing',
      description: 'Fallback Description',
      category: 'resepsiyon',
      location: 'Antalya',
      salary: '35.000 TL',
      contactInfo: '5551234567',
    ),
  );
  registerFallbackValue(
    const Report(
      id: 'fallback_report',
      reporterId: 'fallback_reporter',
      targetId: 'fallback_target',
      targetType: ReportTargetType.user,
      reason: ReportReason.spam,
    ),
  );
  registerFallbackValue(
    const VerificationRequest(
      id: 'fallback_verification',
      employerId: 'fallback_employer',
      hotelName: 'Fallback Hotel',
      documentUrls: [],
      status: VerificationStatus.pending,
    ),
  );
  registerFallbackValue(
    Certificate(
      id: 'fallback_cert',
      userId: 'fallback_user',
      type: CertificateType.hijyen,
      fileUrl: 'https://example.com/cert.pdf',
      status: CertificateStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    ),
  );
  registerFallbackValue(
    const BannerAd(
      id: 'fallback_ad',
      title: 'Fallback Ad',
      advertiserName: 'Fallback Advertiser',
      imageUrl: 'https://example.com/banner.png',
      targetUrl: 'https://example.com',
    ),
  );
  registerFallbackValue(
    const SeasonalSubscription(
      id: 'fallback_sub',
      userId: 'fallback_user',
    ),
  );
  registerFallbackValue(DateTime(2026, 1, 1));
  registerFallbackValue(Uri.parse('https://example.com'));
}

// --- Dummy Data Generators ---

AppUser createDummyAdminUser({
  String uid = 'admin_uid_1',
  String email = 'admin@otelcim.com',
  bool isAdmin = true,
  AdminRole adminRole = AdminRole.superAdmin,
}) {
  return AppUser(
    uid: uid,
    email: email,
    isAdmin: isAdmin,
    adminRole: adminRole,
  );
}

UserProfile createDummyUserProfile({
  String id = 'user_1',
  String email = 'user1@example.com',
  String displayName = 'Ahmet Yılmaz',
  String userType = 'jobseeker',
  bool isBanned = false,
  bool isSuspended = false,
  DateTime? suspensionEnd,
  bool isAdmin = false,
}) {
  final now = DateTime(2026, 6, 1);
  return UserProfile(
    id: id,
    email: email,
    displayName: displayName,
    userType: userType,
    isBanned: isBanned,
    isSuspended: isSuspended,
    suspensionEnd: suspensionEnd,
    isAdmin: isAdmin,
    createdAt: now,
    updatedAt: now,
  );
}

Report createDummyReport({
  String id = 'report_1',
  String reporterId = 'reporter_user_1',
  String targetId = 'target_user_2',
  ReportTargetType targetType = ReportTargetType.user,
  ReportReason reason = ReportReason.inappropriate,
  String? description = 'Uygunsuz içerik paylaşıldı.',
  DateTime? createdAt,
}) {
  return Report(
    id: id,
    reporterId: reporterId,
    targetId: targetId,
    targetType: targetType,
    reason: reason,
    description: description,
    createdAt: createdAt ?? DateTime(2026, 6, 15, 10, 30),
  );
}

Listing createDummyListing({
  String id = 'listing_1',
  String posterId = 'employer_1',
  String posterName = 'Grand Hotel Bodrum',
  String title = 'Resepsiyonist Aranıyor',
  String description = 'Sezonluk çalışacak 5 yıldızlı otel deneyimli resepsiyonist.',
  String category = 'resepsiyon',
  String location = 'Bodrum, Muğla',
  String salary = '45.000 TL',
  ListingStatus status = ListingStatus.active,
  DateTime? createdAt,
}) {
  return Listing(
    id: id,
    posterId: posterId,
    posterName: posterName,
    title: title,
    description: description,
    category: category,
    location: location,
    salary: salary,
    status: status,
    contactInfo: 'info@grandhotel.com',
    createdAt: createdAt ?? DateTime(2026, 5, 20, 14, 0),
  );
}

VerificationRequest createDummyVerificationRequest({
  String id = 'verif_1',
  String employerId = 'employer_100',
  String hotelName = 'Bodrum Resort & Spa',
  List<String> documentUrls = const ['https://storage.example.com/tax_plate.pdf'],
  VerificationStatus status = VerificationStatus.pending,
  DateTime? submittedAt,
}) {
  return VerificationRequest(
    id: id,
    employerId: employerId,
    hotelName: hotelName,
    documentUrls: documentUrls,
    status: status,
    submittedAt: submittedAt ?? DateTime(2026, 6, 10, 9, 0),
  );
}

Certificate createDummyCertificate({
  String id = 'cert_1',
  String userId = 'seeker_50',
  String userName = 'Mehmet Demir',
  String userEmail = 'mehmet@example.com',
  CertificateType type = CertificateType.hijyen,
  String? title = 'MEB Onaylı Hijyen Belgesi',
  String fileUrl = 'https://storage.example.com/cert1.pdf',
  CertificateStatus status = CertificateStatus.pending,
  DateTime? createdAt,
}) {
  return Certificate(
    id: id,
    userId: userId,
    userName: userName,
    userEmail: userEmail,
    type: type,
    title: title,
    fileUrl: fileUrl,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 6, 5, 11, 20),
  );
}

AdminAction createDummyAdminAction({
  String id = 'action_1',
  String adminId = 'admin_uid_1',
  AdminActionType actionType = AdminActionType.warnUser,
  AdminActionTargetType targetType = AdminActionTargetType.user,
  String targetId = 'user_99',
  String? reason = 'Kural ihlali tespit edildi.',
  DateTime? timestamp,
  Map<String, dynamic>? details,
}) {
  return AdminAction(
    id: id,
    adminId: adminId,
    actionType: actionType,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    timestamp: timestamp ?? DateTime(2026, 6, 12, 16, 45),
    details: details,
  );
}

BannerAd createDummyBannerAd({
  String id = 'banner_1',
  String title = 'Yaz İndirimi Kampanyası',
  String advertiserName = 'Otel Tedarik A.Ş.',
  String imageUrl = 'https://storage.example.com/banner.png',
  String targetUrl = 'https://oteltedarik.com',
  int order = 1,
  bool isActive = true,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? createdAt,
}) {
  return BannerAd(
    id: id,
    title: title,
    advertiserName: advertiserName,
    imageUrl: imageUrl,
    targetUrl: targetUrl,
    order: order,
    isActive: isActive,
    startDate: startDate ?? DateTime(2026, 5, 1),
    endDate: endDate ?? DateTime(2026, 9, 30),
    createdAt: createdAt ?? DateTime(2026, 4, 15),
  );
}

SeasonalSubscription createDummySeasonalSubscription({
  String id = 'sub_1',
  String userId = 'user_seeker_1',
  String? city = 'Antalya',
  String? category = 'resepsiyon',
  String? season = 'yaz_2025',
  bool enabled = true,
  DateTime? createdAt,
}) {
  return SeasonalSubscription(
    id: id,
    userId: userId,
    city: city,
    category: category,
    season: season,
    enabled: enabled,
    createdAt: createdAt ?? DateTime(2026, 4, 1),
  );
}

// --- Widget Test Wrapper ---

Widget createAdminTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', ''), Locale('en', '')],
      home: child,
    ),
  );
}

Future<void> configureTestScreenSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
