import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/domain/verification_request_model.dart';
import 'package:otelcim/features/admin/presentation/verification_review_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/verification_service.dart';
import 'package:otelcim/shared/providers/firestore_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(registerAdminFallbackValues);

  group('VerificationReviewScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockVerificationService mockVerificationService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockVerificationService = MockVerificationService();
      mockAdminService = MockAdminService();

      when(() => mockAuthService.currentUser)
          .thenReturn(createDummyAdminUser(uid: 'admin_uid_1'));
      when(() => mockAdminService.logAdminAction(any()))
          .thenAnswer((_) async => 'log_verif_1');
    });

    Future<void> seedVerification(
      FakeFirebaseFirestore db,
      VerificationRequest request,
    ) {
      return db
          .collection('verification_requests')
          .doc(request.id)
          .set(request.toMap());
    }

    Widget buildVerificationScreen(FirebaseFirestore db) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          firestoreProvider.overrideWithValue(db),
          verificationServiceProvider
              .overrideWith((ref) => mockVerificationService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
        ],
        child: const VerificationReviewScreen(),
      );
    }

    testWidgets('displays the current filtered empty state', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildVerificationScreen(FakeFirebaseFirestore()));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtreyle doğrulama talebi bulunamadı.'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Bekleyen'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Onaylanan'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Reddedilen'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tümü'), findsOneWidget);
    });

    testWidgets('renders verification request card with hotel name and documents',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedVerification(
        db,
        createDummyVerificationRequest(
          id: 'verif_100',
          hotelName: 'Grand Resort Bodrum',
          employerId: 'employer_bob_1',
          documentUrls: [
            'https://storage.example.com/tax_cert.pdf',
            'https://storage.example.com/tourism_license.pdf',
          ],
        ),
      );

      await tester.pumpWidget(buildVerificationScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Grand Resort Bodrum'), findsOneWidget);
      expect(find.text('İşveren: employer_bob_1'), findsOneWidget);
      expect(find.text('Belgeler (2)'), findsOneWidget);
      expect(find.text('Belge 1'), findsOneWidget);
      expect(find.text('Belge 2'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Reddet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Onayla'), findsOneWidget);
    });

    testWidgets('shows empty document message when request has no attached documents',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedVerification(
        db,
        createDummyVerificationRequest(
          id: 'verif_empty_docs',
          hotelName: 'Butik Otel',
          documentUrls: [],
        ),
      );

      await tester.pumpWidget(buildVerificationScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Belge eklenmemiş.'), findsOneWidget);
    });

    testWidgets('approves verification request upon confirmation and logs action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedVerification(
        db,
        createDummyVerificationRequest(
          id: 'verif_approve_me',
          hotelName: 'Palace Hotel',
          employerId: 'emp_palace',
        ),
      );
      when(() => mockVerificationService.approveVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildVerificationScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulamayı onayla'), findsOneWidget);
      expect(find.text('Palace Hotel için doğrulama talebi onaylansın mı?'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Onayla'),
      ));
      await tester.pumpAndSettle();

      verify(() => mockVerificationService.approveVerification(
            verificationId: 'verif_approve_me',
            adminId: 'admin_uid_1',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.approveVerification)
                .having((a) => a.targetId, 'targetId', 'verif_approve_me'),
          ))).called(1);
      expect(find.text('Doğrulama onaylandı.'), findsOneWidget);
    });

    testWidgets('rejects verification request with required reason and logs action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedVerification(
        db,
        createDummyVerificationRequest(
          id: 'verif_reject_me',
          hotelName: 'Fake Hotel',
          employerId: 'emp_fake',
        ),
      );
      when(() => mockVerificationService.rejectVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildVerificationScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulamayı reddet'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();
      expect(find.text('Red sebebi zorunludur.'), findsOneWidget);
      verifyNever(() => mockVerificationService.rejectVerification(
            verificationId: any(named: 'verificationId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));

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
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.rejectVerification)
                .having((a) => a.targetId, 'targetId', 'verif_reject_me')
                .having((a) => a.reason, 'reason', 'Vergi levhası okunamıyor'),
          ))).called(1);
      expect(find.text('Doğrulama reddedildi.'), findsOneWidget);
    });
  });
}
