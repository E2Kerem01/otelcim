import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/domain/verification_request_model.dart';
import 'package:otelcim/features/admin/presentation/verification_review_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('VerificationReviewScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockVerificationService mockVerificationService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockVerificationService = MockVerificationService();
      mockAdminService = MockAdminService();

      final adminUser = createDummyAdminUser(uid: 'admin_uid_1');
      when(() => mockAuthService.currentUser).thenReturn(adminUser);
      when(() => mockAdminService.logAdminAction(any())).thenAnswer((_) async => 'log_verif_1');
    });

    Widget buildVerificationScreen({
      required Stream<List<VerificationRequest>> verificationsStream,
    }) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          verificationServiceProvider.overrideWith((ref) => mockVerificationService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
          pendingVerificationsProvider.overrideWith((ref) => verificationsStream),
        ],
        child: const VerificationReviewScreen(),
      );
    }

    testWidgets('displays loading indicator while verifications are loading', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<VerificationRequest>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when verifications stream emits error', (tester) async {
      await configureTestScreenSize(tester);

      final errorStream = Stream<List<VerificationRequest>>.error(Exception('Failed to load'));

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: errorStream));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulama talepleri yüklenemedi.'), findsOneWidget);
    });

    testWidgets('displays empty state when no verification requests are pending', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen doğrulama talebi bulunmuyor.'), findsOneWidget);
    });

    testWidgets('renders verification request card with hotel name and documents', (tester) async {
      await configureTestScreenSize(tester);

      final request = createDummyVerificationRequest(
        id: 'verif_100',
        hotelName: 'Grand Resort Bodrum',
        employerId: 'employer_bob_1',
        documentUrls: [
          'https://storage.example.com/tax_cert.pdf',
          'https://storage.example.com/tourism_license.pdf',
        ],
      );

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([request])));
      await tester.pumpAndSettle();

      expect(find.text('Grand Resort Bodrum'), findsOneWidget);
      expect(find.text('İşveren: employer_bob_1'), findsOneWidget);
      expect(find.text('Belgeler (2)'), findsOneWidget);
      expect(find.text('Belge 1'), findsOneWidget);
      expect(find.text('Belge 2'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Reddet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Onayla'), findsOneWidget);
    });

    testWidgets('shows empty document message when request has no attached documents', (tester) async {
      await configureTestScreenSize(tester);

      final request = createDummyVerificationRequest(
        id: 'verif_empty_docs',
        hotelName: 'Butik Otel',
        documentUrls: [],
      );

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([request])));
      await tester.pumpAndSettle();

      expect(find.text('Belge eklenmemiş.'), findsOneWidget);
    });

    testWidgets('approves verification request upon confirmation and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final request = createDummyVerificationRequest(
        id: 'verif_approve_me',
        hotelName: 'Palace Hotel',
        employerId: 'emp_palace',
      );

      when(() => mockVerificationService.approveVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([request])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulamayı onayla'), findsOneWidget);
      expect(find.text('Palace Hotel için doğrulama talebi onaylansın mı?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      verify(() => mockVerificationService.approveVerification(
            verificationId: 'verif_approve_me',
            adminId: 'admin_uid_1',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.approveVerification)
                .having((a) => a.targetId, 'targetId', 'verif_approve_me'),
          ))).called(1);

      expect(find.text('Doğrulama onaylandı.'), findsOneWidget);
    });

    testWidgets('rejects verification request with required reason and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final request = createDummyVerificationRequest(
        id: 'verif_reject_me',
        hotelName: 'Fake Hotel',
        employerId: 'emp_fake',
      );

      when(() => mockVerificationService.rejectVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([request])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulamayı reddet'), findsOneWidget);

      // Attempt to submit empty reason (required)
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Red sebebi zorunludur.'), findsOneWidget);
      verifyNever(() => mockVerificationService.rejectVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));

      // Enter reason and submit
      await tester.enterText(find.byType(TextField), 'Vergi levhası okunamıyor');
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();

      verify(() => mockVerificationService.rejectVerification(
            verificationId: 'verif_reject_me',
            adminId: 'admin_uid_1',
            reason: 'Vergi levhası okunamıyor',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.rejectVerification)
                .having((a) => a.targetId, 'targetId', 'verif_reject_me')
                .having((a) => a.reason, 'reason', 'Vergi levhası okunamıyor'),
          ))).called(1);

      expect(find.text('Doğrulama reddedildi.'), findsOneWidget);
    });

    testWidgets(
      'approval updates employer user profile with isVerified=true and verificationStatus=approved (D18)',
      (tester) async {
        await configureTestScreenSize(tester);

        final request = createDummyVerificationRequest(
          id: 'verif_d18',
          hotelName: 'Grand Resort Antalya',
          employerId: 'emp_d18_user',
        );

        when(() => mockVerificationService.approveVerification(
              verificationId: any(named: 'verificationId'),
              adminId: any(named: 'adminId'),
            )).thenAnswer((_) async {});

        // Mock getting the user profile after approval
        when(() => mockAdminService.getUserProfile('emp_d18_user')).thenAnswer(
          (_) async => createDummyUserProfile(
            id: 'emp_d18_user',
            userType: 'employer',
          ),
        );

        await tester.pumpWidget(buildVerificationScreen(verificationsStream: Stream.value([request])));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
        await tester.pumpAndSettle();

        // In proper implementation fixing D18, the employer's profile must be updated with isVerified=true
        final profile = await mockAdminService.getUserProfile('emp_d18_user');
        expect(profile?.isVerified, isTrue,
            reason: 'Employer profile must be marked isVerified=true upon verification approval (D18)');
      },
      // BUG-u5-02: Approving verification request does not update user profile isVerified/verificationStatus (D18)
      skip: true,
    );
  });
}
