import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/certificate_review_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('CertificateReviewScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockCertificateService mockCertificateService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockCertificateService = MockCertificateService();
      mockAdminService = MockAdminService();

      final adminUser = createDummyAdminUser(uid: 'admin_uid_1');
      when(() => mockAuthService.currentUser).thenReturn(adminUser);
      when(() => mockAdminService.logAdminAction(any())).thenAnswer((_) async => 'log_cert_1');
    });

    Widget buildCertificateScreen({
      required Stream<List<Certificate>> certificatesStream,
    }) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          certificateServiceProvider.overrideWith((ref) => mockCertificateService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
          pendingCertificatesProvider.overrideWith((ref) => certificatesStream),
        ],
        child: const CertificateReviewScreen(),
      );
    }

    testWidgets('displays loading indicator while certificates are loading', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<Certificate>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when stream emits error', (tester) async {
      await configureTestScreenSize(tester);

      final errorStream = Stream<List<Certificate>>.error(Exception('Connection failure'));

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: errorStream));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bekleyen belgeler yüklenemedi:'), findsOneWidget);
    });

    testWidgets('displays empty state when no certificates are pending', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen belge / sertifika bulunmuyor.'), findsOneWidget);
    });

    testWidgets('renders certificate cards with type icons, titles and user info', (tester) async {
      await configureTestScreenSize(tester);

      final certificates = [
        createDummyCertificate(
          id: 'cert_hijyen_1',
          type: CertificateType.hijyen,
          title: 'Hijyen Eğitimi Sertifikası',
          userName: 'Zeynep Yıldız',
          userEmail: 'zeynep@example.com',
        ),
        createDummyCertificate(
          id: 'cert_cankurtaran_1',
          type: CertificateType.cankurtaran,
          title: 'Gümüş Cankurtaran',
          userName: 'Murat Arslan',
          userEmail: 'murat@example.com',
        ),
      ];

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: Stream.value(certificates)));
      await tester.pumpAndSettle();

      expect(find.text('Hijyen Eğitimi Sertifikası'), findsOneWidget);
      expect(find.text('Kullanıcı: Zeynep Yıldız (zeynep@example.com)'), findsOneWidget);

      expect(find.text('Gümüş Cankurtaran'), findsOneWidget);
      expect(find.text('Kullanıcı: Murat Arslan (murat@example.com)'), findsOneWidget);

      expect(find.widgetWithText(OutlinedButton, 'Reddet'), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Onayla'), findsNWidgets(2));
    });

    testWidgets('approves certificate upon confirmation dialog and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final cert = createDummyCertificate(
        id: 'cert_approve_me',
        type: CertificateType.ehliyet,
        title: 'B Sınıfı Ehliyet',
      );

      when(() => mockCertificateService.approveCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: Stream.value([cert])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeyi Onayla'), findsOneWidget);
      expect(
        find.text('B Sınıfı Ehliyet belgesi onaylansın mı? Kullanıcının profilinde onay rozeti gösterilecek.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      verify(() => mockCertificateService.approveCertificate(
            certId: 'cert_approve_me',
            adminId: 'admin_uid_1',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.approveCertificate)
                .having((a) => a.targetId, 'targetId', 'cert_approve_me'),
          ))).called(1);

      expect(find.text('Belge onaylandı.'), findsOneWidget);
    });

    testWidgets('rejects certificate with required reason dialog and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final cert = createDummyCertificate(
        id: 'cert_reject_me',
        type: CertificateType.dil,
        title: 'TOEFL Belgesi',
      );

      when(() => mockCertificateService.rejectCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: Stream.value([cert])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeyi Reddet'), findsOneWidget);

      // Attempt to submit empty reason (required)
      await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Red sebebi zorunludur.'), findsOneWidget);
      verifyNever(() => mockCertificateService.rejectCertificate(
            certId: any(named: 'certId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));

      // Enter valid reason and confirm
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
                .having((a) => a.actionType, 'actionType', AdminActionType.rejectCertificate)
                .having((a) => a.targetId, 'targetId', 'cert_reject_me'),
          ))).called(1);

      expect(find.text('Belge reddedildi.'), findsOneWidget);
    });

    testWidgets('cancels rejection dialog without calling service', (tester) async {
      await configureTestScreenSize(tester);

      final cert = createDummyCertificate(id: 'cert_cancel_reject');

      await tester.pumpWidget(buildCertificateScreen(certificatesStream: Stream.value([cert])));
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
