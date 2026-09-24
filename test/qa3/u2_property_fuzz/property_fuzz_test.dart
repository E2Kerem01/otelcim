import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/admin/domain/verification_request_model.dart';
import 'package:otelcim/features/boosts/domain/boost_model.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/season_utils.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/message.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';
import 'package:otelcim/shared/utils/referral_code.dart';

const _seed = 20260924;
const _examples = 250;

final _randomWords = <String>[
  'Antalya',
  'Bodrum',
  'İzmir',
  'Muğla',
  'resepsiyon',
  'Aşçı',
  'otel',
  '候補',
  'مرحبا',
  '🙂',
];

T _pick<T>(Random random, List<T> values) => values[random.nextInt(values.length)];

String _text(Random random, {int maxLength = 18}) {
  final length = random.nextInt(maxLength + 1);
  return List<String>.generate(length, (_) => _pick(random, _randomWords)).join();
}

DateTime _date(Random random, {int dayOffset = 0}) => DateTime(
      2026,
      1 + random.nextInt(12),
      1 + random.nextInt(27),
      random.nextInt(24),
      random.nextInt(60),
    ).add(Duration(days: dayOffset));

Future<DocumentSnapshot<Map<String, dynamic>>> _put(
  FakeFirebaseFirestore db,
  String collection,
  String id,
  Map<String, dynamic> data,
) async {
  final ref = db.collection(collection).doc(id);
  await ref.set(data);
  return ref.get();
}

dynamic _wrongValue(Random random) {
  switch (random.nextInt(7)) {
    case 0:
      return random.nextInt(10);
    case 1:
      return random.nextDouble();
    case 2:
      return random.nextBool();
    case 3:
      return _text(random);
    case 4:
      return <dynamic>[random.nextInt(10), _text(random)];
    case 5:
      return <String, dynamic>{'nested': random.nextBool()};
    default:
      return Timestamp.fromDate(_date(random));
  }
}

Listing _listing(Random random, String id, {DateTime? createdAt}) {
  final minSalary = random.nextBool() ? 10 + random.nextInt(90) * 1000 : null;
  final maxSalary = minSalary == null
      ? null
      : minSalary + random.nextInt(40) * 1000;
  return Listing(
    id: id,
    posterId: 'user-${random.nextInt(5)}',
    posterName: _text(random),
    posterVerified: random.nextBool(),
    isUrgent: random.nextBool(),
    title: _text(random),
    description: _text(random),
    category: _pick(random, <String>['resepsiyon', 'mutfak', 'servis']),
    location: _pick(random, <String>['Antalya', 'Bodrum', 'İzmir']),
    salary: '${maxSalary ?? 0} TL',
    city: _pick(random, <String?>['Antalya', 'Muğla', null]),
    region: _pick(random, <String?>['akdeniz', 'ege', null]),
    lat: random.nextDouble() * 180 - 90,
    lng: random.nextDouble() * 360 - 180,
    minSalaryTl: minSalary,
    maxSalaryTl: maxSalary,
    employmentType: _pick(random, EmploymentType.values),
    experienceLevel: ExperienceLevel.values[random.nextInt(ExperienceLevel.values.length)].name,
    educationLevel: EducationLevel.values[random.nextInt(EducationLevel.values.length)].name,
    season: _pick(random, <String?>['yaz_2025', 'kis_2025_26', 'tum_yil', null]),
    contractStartDate: _date(random),
    contractEndDate: _date(random, dayOffset: 30),
    contactInfo: 'contact-${random.nextInt(1000)}',
    images: <String>['https://example.com/${random.nextInt(1000)}.jpg'],
    housingRoomType: _pick(random, <String?>['single', 'shared', null]),
    housingHasAc: random.nextBool(),
    housingHasWifi: random.nextBool(),
    housingMealsIncluded: random.nextInt(4),
    housingImages: <String>['https://example.com/room-${random.nextInt(1000)}.jpg'],
    staffShuttleRoute: _text(random),
    status: ListingStatus.active,
    createdAt: createdAt ?? _date(random),
    updatedAt: _date(random),
    isBoosted: random.nextBool(),
    boostExpiresAt: _date(random, dayOffset: 10),
    boostType: _pick(random, <String?>['7_days', '14_days', null]),
    boostPurchaseId: _pick(random, <String?>['purchase-1', null]),
    viewCount: random.nextInt(100),
    messageCount: random.nextInt(20),
  );
}

Map<String, dynamic> _listingDocument(Random random, int index) {
  final minSalary = random.nextBool() ? 10 + random.nextInt(9) * 1000 : null;
  final maxSalary = minSalary == null ? null : minSalary + random.nextInt(5) * 1000;
  return <String, dynamic>{
    'posterId': 'u-$index',
    'posterName': 'Hotel $index',
    'title': 'Listing $index',
    'description': 'description $index',
    'category': _pick(random, <String>['resepsiyon', 'mutfak', 'servis']),
    'location': _pick(random, <String>['Antalya', 'Bodrum', 'İzmir']),
    'salary': '${maxSalary ?? 0} TL',
    'city': _pick(random, <String?>['Antalya', 'Muğla', null]),
    'region': _pick(random, <String?>['akdeniz', 'ege', null]),
    'minSalaryTl': minSalary,
    'maxSalaryTl': maxSalary,
    'employmentType': _pick(random, EmploymentType.values).name,
    'status': _pick(random, <String>['active', 'closed', 'removed']),
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1).subtract(Duration(days: index))),
    'images': <String>[],
    'housingImages': <String>[],
  };
}

Map<String, dynamic> _listingStable(Listing listing) => <String, dynamic>{
      'posterId': listing.posterId,
      'posterName': listing.posterName,
      'posterVerified': listing.posterVerified,
      'isUrgent': listing.isUrgent,
      'title': listing.title,
      'description': listing.description,
      'category': listing.category,
      'season': listing.season,
      'location': listing.location,
      'salary': listing.salary,
      'city': listing.city,
      'region': listing.region,
      'lat': listing.lat,
      'lng': listing.lng,
      'minSalaryTl': listing.minSalaryTl,
      'maxSalaryTl': listing.maxSalaryTl,
      'employmentType': listing.employmentType,
      'experienceLevel': listing.experienceLevel,
      'educationLevel': listing.educationLevel,
      'images': listing.images,
      'housingRoomType': listing.housingRoomType,
      'housingHasAc': listing.housingHasAc,
      'housingHasWifi': listing.housingHasWifi,
      'housingMealsIncluded': listing.housingMealsIncluded,
      'housingImages': listing.housingImages,
      'staffShuttleRoute': listing.staffShuttleRoute,
      'status': listing.status,
      'isBoosted': listing.isBoosted,
      'boostExpiresAt': listing.boostExpiresAt,
      'boostType': listing.boostType,
      'boostPurchaseId': listing.boostPurchaseId,
      'viewCount': listing.viewCount,
      'messageCount': listing.messageCount,
    };

void main() {
  group('D2 tolerant deserializer fuzzing', () {
    test('missing-field fuzz keeps all model deserializers alive', () async {
      final random = Random(_seed);
      final db = FakeFirebaseFirestore();

      for (var i = 0; i < _examples; i++) {
        final suffix = '$i-${random.nextInt(1 << 30)}';
        final listing = Listing.fromDoc(await _put(db, 'listings', suffix, {}));
        final profile = UserProfile.fromFirestore(
          await _put(db, 'user_profiles', suffix, {}),
        );
        final conversation = Conversation.fromDoc(
          await _put(db, 'conversations', suffix, {}),
        );
        final message = Message.fromDoc(await _put(db, 'messages', suffix, {}));
        final boost = Boost.fromDoc(await _put(db, 'boosts', suffix, {}));
        final certificate = Certificate.fromDoc(
          await _put(db, 'certificates', suffix, {}),
        );
        final verification = VerificationRequest.fromDoc(
          await _put(db, 'verification_requests', suffix, {}),
        );
        final banner = BannerAd.fromDoc(await _put(db, 'banner_ads', suffix, {}));

        expect(listing.id, suffix, reason: 'seed=$_seed example=$i');
        expect(profile.id, suffix, reason: 'seed=$_seed example=$i');
        expect(conversation.id, suffix, reason: 'seed=$_seed example=$i');
        expect(message.id, suffix, reason: 'seed=$_seed example=$i');
        expect(boost.id, suffix, reason: 'seed=$_seed example=$i');
        expect(certificate.id, suffix, reason: 'seed=$_seed example=$i');
        expect(verification.id, suffix, reason: 'seed=$_seed example=$i');
        expect(banner.id, suffix, reason: 'seed=$_seed example=$i');
      }
    });

    test(
      'wrong-type maps never crash any D2 deserializer',
      () async {
        final random = Random(_seed + 1);
        final db = FakeFirebaseFirestore();
        for (var i = 0; i < _examples; i++) {
          final suffix = 'wrong-$i';
          final listingMap = <String, dynamic>{
            'posterId': _wrongValue(random),
            'isUrgent': _wrongValue(random),
            'images': <dynamic>[_wrongValue(random)],
            'lat': _wrongValue(random),
            'viewCount': _wrongValue(random),
          };
          final profileMap = <String, dynamic>{
            'email': _wrongValue(random),
            'isVerified': _wrongValue(random),
            'notificationPreferences': _wrongValue(random),
            'verifiedAt': _wrongValue(random),
            'referralCount': _wrongValue(random),
          };
          final conversationMap = <String, dynamic>{
            'listingId': _wrongValue(random),
            'updatedAt': _wrongValue(random),
            'hired': _wrongValue(random),
          };
          final messageMap = <String, dynamic>{
            'senderId': _wrongValue(random),
            'sentAt': _wrongValue(random),
          };
          final boostMap = <String, dynamic>{
            'durationDays': _wrongValue(random),
            'price': _wrongValue(random),
            'purchasedAt': _wrongValue(random),
          };
          final certificateMap = <String, dynamic>{
            'userId': _wrongValue(random),
            'type': _wrongValue(random),
            'createdAt': _wrongValue(random),
          };
          final verificationMap = <String, dynamic>{
            'employerId': _wrongValue(random),
            'documentUrls': <dynamic>[_wrongValue(random)],
            'submittedAt': _wrongValue(random),
          };
          final bannerMap = <String, dynamic>{
            'title': _wrongValue(random),
            'order': _wrongValue(random),
            'isActive': _wrongValue(random),
          };

          final listingDoc = await _put(db, 'listings', suffix, listingMap);
          final profileDoc = await _put(db, 'user_profiles', suffix, profileMap);
          final conversationDoc = await _put(
            db,
            'conversations',
            suffix,
            conversationMap,
          );
          final messageDoc = await _put(db, 'messages', suffix, messageMap);
          final boostDoc = await _put(db, 'boosts', suffix, boostMap);
          final certificateDoc = await _put(
            db,
            'certificates',
            suffix,
            certificateMap,
          );
          final verificationDoc = await _put(
            db,
            'verification_requests',
            suffix,
            verificationMap,
          );
          final bannerDoc = await _put(db, 'banner_ads', suffix, bannerMap);

          expect(
            () => Listing.fromDoc(listingDoc),
            returnsNormally,
            reason: 'Listing seed=$_seed example=$i',
          );
          expect(
            () => UserProfile.fromFirestore(
              profileDoc,
            ),
            returnsNormally,
            reason: 'UserProfile seed=$_seed example=$i',
          );
          expect(
            () => Conversation.fromDoc(
              conversationDoc,
            ),
            returnsNormally,
            reason: 'Conversation seed=$_seed example=$i',
          );
          expect(
            () => Message.fromDoc(messageDoc),
            returnsNormally,
            reason: 'Message seed=$_seed example=$i',
          );
          expect(
            () => Boost.fromDoc(boostDoc),
            returnsNormally,
            reason: 'Boost seed=$_seed example=$i',
          );
          expect(
            () => Certificate.fromDoc(
              certificateDoc,
            ),
            returnsNormally,
            reason: 'Certificate seed=$_seed example=$i',
          );
          expect(
            () => VerificationRequest.fromDoc(
              verificationDoc,
            ),
            returnsNormally,
            reason: 'VerificationRequest seed=$_seed example=$i',
          );
          expect(
            () => BannerAd.fromDoc(bannerDoc),
            returnsNormally,
            reason: 'BannerAd seed=$_seed example=$i',
          );
        }
      },
      skip:
          'BUG-u2-01: D2 deserializers use unchecked casts; generated wrong-type fields throw TypeError instead of falling back safely',
    );
  });

  group('Deserializer round-trip properties', () {
    test('valid generated models preserve non-server fields through Firestore', () async {
      final random = Random(_seed + 2);
      final db = FakeFirebaseFirestore();

      for (var i = 0; i < _examples; i++) {
        final id = 'round-$i';
        final sourceListing = _listing(random, id);
        final parsedListing = Listing.fromDoc(
          await _put(db, 'round_listings', id, sourceListing.toMap()),
        );
        expect(_listingStable(parsedListing), _listingStable(sourceListing), reason: 'Listing seed=$_seed example=$i');

        final sourceProfile = UserProfile(
          id: id,
          email: '$i@example.com',
          displayName: _text(random),
          phoneNumber: '+90555$i',
          bio: _text(random),
          photoUrl: 'https://example.com/profile-$i.jpg',
          hotelName: _text(random),
          position: _text(random),
          userType: _pick(random, <String>['jobseeker', 'employer']),
          isVerified: random.nextBool(),
          verificationStatus: _pick(random, <String?>['pending', 'approved', null]),
          verifiedAt: _date(random),
          notificationPreferences: <String, bool>{
            'messages': random.nextBool(),
            'listingAlerts': random.nextBool(),
            'seasonalReminders': random.nextBool(),
            'urgentListings': random.nextBool(),
            'marketing': random.nextBool(),
          },
          quietHoursStart: '23:00',
          quietHoursEnd: '07:00',
          availableImmediately: random.nextBool(),
          preferredExperienceLevel: ExperienceLevel.values[random.nextInt(ExperienceLevel.values.length)].name,
          preferredEducationLevel: EducationLevel.values[random.nextInt(EducationLevel.values.length)].name,
          preferredRegion: 'akdeniz',
          introVideoUrl: 'https://example.com/intro-$i.mp4',
          referralCode: 'REF$i',
          referredBy: 'parent-$i',
          createdAt: _date(random),
          updatedAt: _date(random),
        );
        final parsedProfile = UserProfile.fromFirestore(
          await _put(db, 'round_profiles', id, sourceProfile.toFirestore()),
        );
        expect(parsedProfile.id, sourceProfile.id, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.email, sourceProfile.email, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.displayName, sourceProfile.displayName, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.phoneNumber, sourceProfile.phoneNumber, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.bio, sourceProfile.bio, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.photoUrl, sourceProfile.photoUrl, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.hotelName, sourceProfile.hotelName, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.position, sourceProfile.position, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.userType, sourceProfile.userType, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.isVerified, sourceProfile.isVerified, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.verificationStatus, sourceProfile.verificationStatus, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.verifiedAt, sourceProfile.verifiedAt, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.notificationPreferences, sourceProfile.notificationPreferences, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.quietHoursStart, sourceProfile.quietHoursStart, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.quietHoursEnd, sourceProfile.quietHoursEnd, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.availableImmediately, sourceProfile.availableImmediately, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.preferredExperienceLevel, sourceProfile.preferredExperienceLevel, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.preferredEducationLevel, sourceProfile.preferredEducationLevel, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.preferredRegion, sourceProfile.preferredRegion, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.introVideoUrl, sourceProfile.introVideoUrl, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.referralCode, sourceProfile.referralCode, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.referredBy, sourceProfile.referredBy, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.createdAt, sourceProfile.createdAt, reason: 'UserProfile seed=$_seed example=$i');
        expect(parsedProfile.updatedAt, sourceProfile.updatedAt, reason: 'UserProfile seed=$_seed example=$i');

        final sourceConversation = Conversation(
          id: id,
          listingId: 'listing-$i',
          listingTitle: _text(random),
          posterId: 'poster-$i',
          seekerId: 'seeker-$i',
          lastMessage: _text(random),
          lastSenderId: 'sender-$i',
          updatedAt: _date(random),
          createdAt: _date(random),
          hired: random.nextBool(),
          hiredAt: _date(random),
        );
        final parsedConversation = Conversation.fromDoc(
          await _put(db, 'round_conversations', id, sourceConversation.toMap()),
        );
        expect(parsedConversation.listingId, sourceConversation.listingId, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.listingTitle, sourceConversation.listingTitle, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.posterId, sourceConversation.posterId, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.seekerId, sourceConversation.seekerId, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.lastMessage, sourceConversation.lastMessage, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.lastSenderId, sourceConversation.lastSenderId, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.hired, sourceConversation.hired, reason: 'Conversation seed=$_seed example=$i');
        expect(parsedConversation.hiredAt, sourceConversation.hiredAt, reason: 'Conversation seed=$_seed example=$i');

        final sourceMessage = Message(
          id: id,
          senderId: 'sender-$i',
          text: _text(random),
          sentAt: _date(random),
        );
        final parsedMessage = Message.fromDoc(
          await _put(db, 'round_messages', id, sourceMessage.toMap()),
        );
        expect(parsedMessage.senderId, sourceMessage.senderId, reason: 'Message seed=$_seed example=$i');
        expect(parsedMessage.text, sourceMessage.text, reason: 'Message seed=$_seed example=$i');

        final sourceBoost = Boost(
          id: id,
          listingId: 'listing-$i',
          userId: 'user-$i',
          durationType: _pick(random, BoostDurationType.values),
          durationDays: _pick(random, <int>[7, 14, 30]),
          price: random.nextDouble() * 100,
          purchasedAt: _date(random),
          expiresAt: _date(random, dayOffset: 30),
          platform: _pick(random, <String>['apple', 'google_play', 'referral_reward']),
          transactionId: 'tx-$i',
          status: _pick(random, BoostStatus.values),
        );
        final parsedBoost = Boost.fromDoc(
          await _put(db, 'round_boosts', id, sourceBoost.toMap()),
        );
        expect(parsedBoost.listingId, sourceBoost.listingId, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.userId, sourceBoost.userId, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.durationType, sourceBoost.durationType, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.durationDays, sourceBoost.durationDays, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.price, closeTo(sourceBoost.price, 0.000001), reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.purchasedAt, sourceBoost.purchasedAt, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.expiresAt, sourceBoost.expiresAt, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.platform, sourceBoost.platform, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.transactionId, sourceBoost.transactionId, reason: 'Boost seed=$_seed example=$i');
        expect(parsedBoost.status, sourceBoost.status, reason: 'Boost seed=$_seed example=$i');

        final sourceCertificate = Certificate(
          id: id,
          userId: 'user-$i',
          userName: _text(random),
          userEmail: '$i@example.com',
          type: _pick(random, CertificateType.values),
          title: _text(random),
          fileUrl: 'https://example.com/cert-$i.pdf',
          status: _pick(random, CertificateStatus.values),
          createdAt: _date(random),
          reviewedBy: 'admin-$i',
          reviewedAt: _date(random),
          rejectionReason: _pick(random, <String?>['not readable', null]),
        );
        final parsedCertificate = Certificate.fromDoc(
          await _put(db, 'round_certificates', id, sourceCertificate.toMap()),
        );
        expect(parsedCertificate.userId, sourceCertificate.userId, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.userName, sourceCertificate.userName, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.userEmail, sourceCertificate.userEmail, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.type, sourceCertificate.type, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.title, sourceCertificate.title, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.fileUrl, sourceCertificate.fileUrl, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.status, sourceCertificate.status, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.createdAt, sourceCertificate.createdAt, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.reviewedBy, sourceCertificate.reviewedBy, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.reviewedAt, sourceCertificate.reviewedAt, reason: 'Certificate seed=$_seed example=$i');
        expect(parsedCertificate.rejectionReason, sourceCertificate.rejectionReason, reason: 'Certificate seed=$_seed example=$i');

        final sourceVerification = VerificationRequest(
          id: id,
          employerId: 'employer-$i',
          hotelName: _text(random),
          documentUrls: <String>['https://example.com/doc-$i.pdf'],
          status: _pick(random, VerificationStatus.values),
          submittedAt: _date(random),
          reviewedBy: 'admin-$i',
          reviewedAt: _date(random),
          rejectionReason: _pick(random, <String?>['missing page', null]),
        );
        final parsedVerification = VerificationRequest.fromDoc(
          await _put(db, 'round_verifications', id, sourceVerification.toMap()),
        );
        expect(parsedVerification.employerId, sourceVerification.employerId, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.hotelName, sourceVerification.hotelName, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.documentUrls, sourceVerification.documentUrls, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.status, sourceVerification.status, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.submittedAt, sourceVerification.submittedAt, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.reviewedBy, sourceVerification.reviewedBy, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.reviewedAt, sourceVerification.reviewedAt, reason: 'Verification seed=$_seed example=$i');
        expect(parsedVerification.rejectionReason, sourceVerification.rejectionReason, reason: 'Verification seed=$_seed example=$i');

        final sourceBanner = BannerAd(
          id: id,
          title: _text(random),
          advertiserName: _text(random),
          imageUrl: 'https://example.com/banner-$i.jpg',
          targetUrl: 'https://example.com/$i',
          order: random.nextInt(20),
          isActive: random.nextBool(),
          startDate: _date(random),
          endDate: _date(random, dayOffset: 30),
          createdAt: _date(random),
        );
        final parsedBanner = BannerAd.fromDoc(
          await _put(db, 'round_banners', id, sourceBanner.toMap()),
        );
        expect(parsedBanner.title, sourceBanner.title, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.advertiserName, sourceBanner.advertiserName, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.imageUrl, sourceBanner.imageUrl, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.targetUrl, sourceBanner.targetUrl, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.order, sourceBanner.order, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.isActive, sourceBanner.isActive, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.startDate, sourceBanner.startDate, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.endDate, sourceBanner.endDate, reason: 'BannerAd seed=$_seed example=$i');
        expect(parsedBanner.createdAt, sourceBanner.createdAt, reason: 'BannerAd seed=$_seed example=$i');
      }
    });
  });

  group('ListingService filter and sort invariants', () {
    test('200 generated listing sets preserve subset, active, category, and salary invariants', () async {
      final random = Random(_seed + 3);

      for (var example = 0; example < _examples; example++) {
        final db = FakeFirebaseFirestore();
        final service = ListingService(db);
        final documents = <String, Map<String, dynamic>>{};
        final batch = db.batch();
        for (var index = 0; index < 12; index++) {
          final id = 'fuzz-$example-$index';
          final data = _listingDocument(random, index);
          documents[id] = data;
          batch.set(db.collection('listings').doc(id), data);
        }
        await batch.commit();

        final activeIds = documents.entries
            .where((entry) => entry.value['status'] == 'active')
            .map((entry) => entry.key)
            .toSet();
        final noFilters = await service.getPaginatedListings(limit: 100);
        expect(
          noFilters.listings.map((listing) => listing.id).toSet(),
          activeIds,
          reason: 'all filters off must return active subset; seed=$_seed example=$example',
        );

        final category = _pick(random, <String>['resepsiyon', 'mutfak', 'servis']);
        final categoryOnce = await service.getPaginatedListings(
          limit: 100,
          category: category,
        );
        final categoryTwice = await service.getPaginatedListings(
          limit: 100,
          category: category,
        );
        expect(
          categoryOnce.listings.map((listing) => listing.id).toSet(),
          categoryTwice.listings.map((listing) => listing.id).toSet(),
          reason: 'category filter must be idempotent; seed=$_seed example=$example',
        );
        expect(
          categoryOnce.listings.every((listing) =>
              activeIds.contains(listing.id) && listing.category == category),
          isTrue,
          reason: 'category result must be an active input subset; seed=$_seed example=$example',
        );

        final minimum = 10 + random.nextInt(9) * 1000;
        final salaryFiltered = await service.getPaginatedListings(
          limit: 100,
          minSalaryTl: minimum,
        );
        expect(
          salaryFiltered.listings.every((listing) {
            final maxSalary = listing.maxSalaryTl;
            return activeIds.contains(listing.id) &&
                maxSalary != null &&
                maxSalary >= minimum;
          }),
          isTrue,
          reason: 'salary filter result must be an input subset; seed=$_seed example=$example',
        );

        final highToLow = await service.getPaginatedListings(
          limit: 100,
          sortOrder: ListingSortOrder.salaryHighToLow,
        );
        final highValues = highToLow.listings
            .map((listing) => listing.maxSalaryTl ?? listing.minSalaryTl ?? 0)
            .toList();
        for (var i = 1; i < highValues.length; i++) {
          expect(
            highValues[i - 1] >= highValues[i],
            isTrue,
            reason: 'salary descending order broke; seed=$_seed example=$example index=$i',
          );
        }
      }
    });
  });

  group('Region topic, referral, and season helper properties', () {
    test('regionTopicName is deterministic and emits only topic-safe characters', () {
      final random = Random(_seed + 4);
      const alphabet = ' abcXYZİıüğşç/!?-_.';
      final allowed = RegExp(r'^region_[a-zA-Z0-9_.~%_-]*$');

      for (var example = 0; example < 300; example++) {
        final input = String.fromCharCodes(
          List<int>.generate(
            random.nextInt(20),
            (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ),
        );
        final first = regionTopicName(input);
        expect(first, matches(allowed), reason: 'seed=$_seed example=$example input=$input');
        expect(regionTopicName(input), first, reason: 'topic must be stable; seed=$_seed example=$example');
      }
    });

    test('referral code is deterministic and is the uppercase eight-character prefix', () {
      final random = Random(_seed + 5);
      for (var example = 0; example < 300; example++) {
        final uid = List<String>.generate(
          random.nextInt(25),
          (_) => _pick(random, <String>['a', 'B', 'ç', '9', '-']),
        ).join();
        final expected = uid.substring(0, min(8, uid.length)).toUpperCase();
        expect(generateReferralCode(uid), expected, reason: 'seed=$_seed example=$example uid=$uid');
        expect(generateReferralCode(uid), generateReferralCode(uid), reason: 'seed=$_seed example=$example');
      }
    });

    test('season and contract-date helpers are total over generated values', () {
      final random = Random(_seed + 6);
      final tr = lookupAppLocalizations(const Locale('tr'));
      for (var example = 0; example < 300; example++) {
        final known = _pick(random, <String?>[
          ...ListingSeason.values.map((season) => season.code),
          null,
          'unknown-${random.nextInt(50)}',
        ]);
        final parsed = ListingSeason.fromCode(known);
        if (known == null || !listingSeasonValues.contains(known)) {
          expect(parsed, isNull, reason: 'seed=$_seed example=$example');
        } else {
          expect(parsed!.code, known, reason: 'season inverse failed; seed=$_seed example=$example');
        }

        expect(isSeasonalContract(null), isFalse);
        expect(isSeasonalContract('tum_yil'), isFalse);
        expect(isSeasonalContract('yaz_2025'), isTrue);
        expect(isSeasonalContract('kis_2025_26'), isTrue);

        final date = DateTime(2020 + random.nextInt(12), 1 + random.nextInt(12), 1 + random.nextInt(27));
        final formatted = formatContractDate(date, tr);
        expect(formatted, '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}', reason: 'date format failed; seed=$_seed example=$example');
        expect(formatContractDate(null, tr), tr.selectDate, reason: 'null date failed; seed=$_seed example=$example');
      }
    });

    test(
      'Dart and TypeScript region topic normalization agree for Turkish dotted-I',
      () {
        expect(regionTopicName('İzmir'), 'region_i_zmir');
      },
      skip:
          'BUG-u2-02: Dart lowerCase produces region_izmir while functions/src/index.ts JavaScript lowerCase produces region_i_zmir',
    );
  });
}
