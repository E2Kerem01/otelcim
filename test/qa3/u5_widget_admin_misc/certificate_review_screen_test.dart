import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/certificate_review_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/shared/providers/firestore_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(registerAdminFallbackValues);

  group('CertificateReviewScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockCertificateService mockCertificateService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockCertificateService = MockCertificateService();
      mockAdminService = MockAdminService();

      when(() => mockAuthService.currentUser)
          .thenReturn(createDummyAdminUser(uid: 'admin_uid_1'));
      when(() => mockAdminService.logAdminAction(any()))
          .thenAnswer((_) async => 'log_cert_1');
    });

    Future<void> seedCertificate(
      FakeFirebaseFirestore db,
      Certificate certificate,
    ) {
      return db
          .collection('certificates')
          .doc(certificate.id)
          .set(certificate.toMap());
    }

    Widget buildCertificateScreen(FirebaseFirestore db) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          firestoreProvider.overrideWithValue(db),
          certificateServiceProvider
              .overrideWith((ref) => mockCertificateService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
        ],
        child: const CertificateReviewScreen(),
      );
    }

    testWidgets('displays the current filtered empty state', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildCertificateScreen(FakeFirebaseFirestore()));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtreyle belge / sertifika bulunamadı.'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Bekleyen'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Onaylanan'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Reddedilen'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tümü'), findsOneWidget);
    });

    testWidgets('renders the current certificate table/card content',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedCertificate(
        db,
        createDummyCertificate(
          id: 'cert_hijyen_1',
          type: CertificateType.hijyen,
          title: 'Hijyen Eğitimi Sertifikası',
          userName: 'Zeynep Yıldız',
          userEmail: 'zeynep@example.com',
        ),
      );
      await seedCertificate(
        db,
        createDummyCertificate(
          id: 'cert_cankurtaran_1',
          type: CertificateType.cankurtaran,
          title: 'Gümüş Cankurtaran',
          userName: 'Murat Arslan',
          userEmail: 'murat@example.com',
        ),
      );

      await tester.pumpWidget(buildCertificateScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Hijyen Eğitimi Sertifikası'), findsOneWidget);
      expect(find.text('Zeynep Yıldız · Hijyen Belgesi'), findsOneWidget);
      expect(find.text('Gümüş Cankurtaran'), findsOneWidget);
      expect(find.text('Murat Arslan · Cankurtaran Sertifikası'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Reddet'), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Onayla'), findsNWidgets(2));
    });

    testWidgets('approves certificate upon confirmation and logs action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedCertificate(
        db,
        createDummyCertificate(
          id: 'cert_approve_me',
          type: CertificateType.ehliyet,
          title: 'B Sınıfı Ehliyet',
        ),
      );
      when(() => mockCertificateService.approveCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildCertificateScreen(db));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeyi onayla'), findsOneWidget);
      expect(find.text('B Sınıfı Ehliyet belgesi onaylansın mı?'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Onayla'),
      ));
      await tester.pumpAndSettle();

      verify(() => mockCertificateService.approveCertificate(
            certId: 'cert_approve_me',
            adminId: 'admin_uid_1',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.approveCertificate)
                .having((a) => a.targetId, 'targetId', 'cert_approve_me'),
          ))).called(1);
      expect(find.text('Belge onaylandı.'), findsOneWidget);
    });

    testWidgets('rejects certificate with required reason dialog and logs action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedCertificate(
        db,
        createDummyCertificate(
          id: 'cert_reject_me',
          type: CertificateType.dil,
          title: 'TOEFL Belgesi',
        ),
      );
      when(() => mockCertificateService.rejectCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildCertificateScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeyi reddet'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();
      expect(find.text('Red sebebi zorunludur.'), findsOneWidget);
      verifyNever(() => mockCertificateService.rejectCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));

      await tester.enterText(find.byType(TextField), 'Belge geçerlilik tarihi dolmuş');
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();

      verify(() => mockCertificateService.rejectCertificate(
            certId: 'cert_reject_me',
            adminId: 'admin_uid_1',
            reason: 'Belge geçerlilik tarihi dolmuş',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.rejectCertificate)
                .having((a) => a.targetId, 'targetId', 'cert_reject_me'),
          ))).called(1);
      expect(find.text('Belge reddedildi.'), findsOneWidget);
    });

    testWidgets('cancels rejection dialog without calling service', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedCertificate(db, createDummyCertificate(id: 'cert_cancel_reject'));

      await tester.pumpWidget(buildCertificateScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
      await tester.pumpAndSettle();

      verifyNever(() => mockCertificateService.rejectCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));
    });
  });
}
