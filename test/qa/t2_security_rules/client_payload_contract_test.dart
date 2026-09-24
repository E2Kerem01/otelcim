// Dart half of the client <-> security-rules contract.
//
// The rules tests in this folder (specs/*.spec.ts, run against the Firebase
// emulators with `node run.mjs`) build their payloads from
// fixtures/client_payload_keys.json. These tests pin that file to what the
// real models write, and check the model-level invariants firestore.rules
// depends on - so a model change can't silently invalidate the rules tests.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/chat/domain/interview_slot_model.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/ratings/domain/rating_model.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/message.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/models/verification_request.dart';

final _now = DateTime.utc(2026, 9, 23, 10);

UserProfile _profile() => UserProfile(
      id: 'u1',
      email: 'u1@example.com',
      userType: 'employer',
      createdAt: _now,
      updatedAt: _now,
      // Server-controlled state set on the model must never be echoed back.
      isAdmin: true,
      adminRole: AdminRole.superAdmin,
      freeBoostCredits: 3,
      referralCount: 2,
      hasUsedFreeUrgentListing: true,
      isSuspended: true,
      suspensionEnd: _now,
      suspensionReason: 'spam',
      isBanned: true,
      banReason: 'fraud',
    );

Listing _listing() => const Listing(
      id: 'l1',
      posterId: 'u1',
      posterName: 'Otel Deniz',
      title: 'Garson',
      description: 'Sezonluk',
      category: 'servis',
      location: 'Antalya',
      salary: '30.000 TL',
      contactInfo: '+90 555 000 11 22',
    );

Rating _rating({int stars = 5}) => Rating(
      id: '',
      conversationId: 'l1_seeker',
      raterId: 'u1',
      ratedUserId: 'seeker',
      stars: stars,
    );

void main() {
  late Map<String, dynamic> contract;

  setUpAll(() {
    final file = File('test/qa/t2_security_rules/fixtures/client_payload_keys.json');
    contract = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  Set<String> keysFor(String model) =>
      (contract[model] as List<dynamic>).cast<String>().toSet();

  group('model payload key sets match fixtures/client_payload_keys.json', () {
    final payloads = <String, Map<String, dynamic> Function()>{
      'UserProfile.toFirestore': () => _profile().toFirestore(),
      'Listing.toMap': () => _listing().toMap(),
      'Conversation.toMap': () => const Conversation(
            id: 'l1_seeker',
            listingId: 'l1',
            listingTitle: 'Garson',
            posterId: 'u1',
            seekerId: 'seeker',
          ).toMap(),
      'Message.toMap': () =>
          const Message(id: '', senderId: 'u1', text: 'Merhaba').toMap(),
      'Report.toMap': () => const Report(
            reporterId: 'u1',
            targetId: 'l1',
            targetType: ReportTargetType.listing,
            reason: ReportReason.scam,
          ).toMap(),
      'Rating.toMap': () => _rating().toMap(),
      'Certificate.toMap': () => Certificate(
            id: 'c1',
            userId: 'u1',
            type: CertificateType.hijyen,
            fileUrl: 'https://example/c1.pdf',
            status: CertificateStatus.pending,
            createdAt: _now,
          ).toMap(),
      'VerificationRequest.toFirestore': () => VerificationRequest(
            id: 'v1',
            userId: 'u1',
            userEmail: 'u1@example.com',
            hotelName: 'Otel Deniz',
            hotelAddress: 'Lara',
            documentUrls: const [],
            requestedAt: _now,
          ).toFirestore(),
      'InterviewSlot.toMap': () => InterviewSlot(
            id: 's1',
            proposedBy: 'u1',
            slots: [_now],
            status: 'pending',
            createdAt: _now,
          ).toMap(),
    };

    for (final entry in payloads.entries) {
      test('${entry.key} writes exactly the recorded keys', () {
        expect(entry.value().keys.toSet(), keysFor(entry.key));
      });
    }
  });

  group('model invariants firestore.rules relies on', () {
    test(
        'UserProfile.toFirestore never writes isAdmin, referral/boost counters or moderation state, even when set on the model',
        () {
      final data = _profile().toFirestore();
      for (final key in [
        'isAdmin',
        'adminRole',
        'freeBoostCredits',
        'referralCount',
        'referralRewardGranted',
        'hasUsedFreeUrgentListing',
        'isSuspended',
        'suspensionEnd',
        'suspensionReason',
        'isBanned',
        'banReason',
        'warnings',
        'fcmToken',
      ]) {
        expect(data.containsKey(key), isFalse, reason: key);
      }
    });

    test('Listing.toMap keeps contactInfo off the publicly readable listing doc', () {
      expect(_listing().toMap().containsKey('contactInfo'), isFalse);
    });

    test('Listing.toMap defaults isUrgent and posterVerified to false', () {
      final data = _listing().toMap();
      expect(data['isUrgent'], isFalse);
      expect(data['posterVerified'], isFalse);
      expect(data['isBoosted'], isFalse);
    });

    test('Message.toMap stamps sentAt with the server time (rules require sentAt == request.time)', () {
      final data = const Message(id: '', senderId: 'u1', text: 'x').toMap();
      expect(data['sentAt'], isA<FieldValue>());
    });

    test('Conversation.toMap writes both participant ids the rules check', () {
      final data = const Conversation(
        id: 'l1_seeker',
        listingId: 'l1',
        listingTitle: 'Garson',
        posterId: 'u1',
        seekerId: 'seeker',
      ).toMap();
      expect(data['posterId'], 'u1');
      expect(data['seekerId'], 'seeker');
      expect(data['hired'], isFalse);
    });

    test('shared VerificationRequest.toFirestore writes employerId (the field the rules scope on) equal to userId', () {
      final data = VerificationRequest(
        id: 'v1',
        userId: 'u1',
        userEmail: 'u1@example.com',
        hotelName: 'Otel Deniz',
        hotelAddress: 'Lara',
        documentUrls: const [],
        requestedAt: _now,
      ).toFirestore();
      expect(data['employerId'], 'u1');
      expect(data['userId'], 'u1');
      expect(data['status'], 'pending');
    });

    test(
      'a newly submitted Rating waits for moderation instead of being published as approved',
      () {
        expect(_rating().moderationStatus, RatingModerationStatus.pending);
        expect(_rating().toMap()['moderationStatus'], 'pending');
      },
      skip:
          'BUG-t2-22: Rating defaults moderationStatus to approved and the rules accept it, so every rating is self-approved',
    );
  });
}
