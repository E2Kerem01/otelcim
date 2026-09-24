import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/reports_moderation_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/shared/models/report.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/report_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('ReportsModerationScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockModerationService mockModerationService;
    late MockAdminService mockAdminService;
    late MockReportService mockReportService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockModerationService = MockModerationService();
      mockAdminService = MockAdminService();
      mockReportService = MockReportService();

      final adminUser = createDummyAdminUser(uid: 'admin_uid_1');
      when(() => mockAuthService.currentUser).thenReturn(adminUser);
      when(() => mockAdminService.logAdminAction(any())).thenAnswer((_) async => 'action_id_1');
    });

    Widget buildReportsScreen({
      required Stream<List<Report>> reportsStream,
    }) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          moderationServiceProvider.overrideWith((ref) => mockModerationService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
          reportServiceProvider.overrideWith((ref) => mockReportService),
          pendingReportsProvider.overrideWith((ref) => reportsStream),
        ],
        child: const ReportsModerationScreen(),
      );
    }

    testWidgets('displays loading indicator while reports are loading', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<Report>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildReportsScreen(reportsStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when stream emits error', (tester) async {
      await configureTestScreenSize(tester);

      final reportsStream = Stream<List<Report>>.error(Exception('Firestore stream error'));

      await tester.pumpWidget(buildReportsScreen(reportsStream: reportsStream));
      await tester.pumpAndSettle();

      expect(find.text('Şikâyetler yüklenemedi.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays empty state message when no pending reports exist', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Bekleyen şikâyet bulunmuyor.'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
    });

    testWidgets('renders report cards for user and listing targets', (tester) async {
      await configureTestScreenSize(tester);

      final reports = [
        createDummyReport(
          id: 'rep_user',
          reporterId: 'reporter_1',
          targetId: 'target_u1',
          targetType: ReportTargetType.user,
          reason: ReportReason.inappropriate,
          description: 'Profilde hakaret içeren ifadeler var.',
        ),
        createDummyReport(
          id: 'rep_listing',
          reporterId: 'reporter_2',
          targetId: 'target_l1',
          targetType: ReportTargetType.listing,
          reason: ReportReason.scam,
          description: 'Sahte iş ilanı, kapora isteniyor.',
        ),
      ];

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value(reports)));
      await tester.pumpAndSettle();

      // Card 1: User target
      expect(find.text('Uygunsuz İçerik'), findsOneWidget);
      expect(find.text('Hedef: Kullanıcı • target_u1'), findsOneWidget);
      expect(find.text('Profilde hakaret içeren ifadeler var.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Uyar'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Askıya al'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Yasakla'), findsOneWidget);

      // Card 2: Listing target
      expect(find.text('Dolandırıcılık / Sahtekarlık'), findsOneWidget);
      expect(find.text('Hedef: İlan • target_l1'), findsOneWidget);
      expect(find.text('Sahte iş ilanı, kapora isteniyor.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'İlanı kaldır'), findsOneWidget);
    });

    testWidgets('dismissReport: opens dialog, submits reason and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_1', targetId: 'u1');
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      // Tap 'Reddet'
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      expect(find.text('Şikayeti Reddet'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Asılsız ihbar');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.dismissReport(
            reportId: 'rep_1',
            adminId: 'admin_uid_1',
            reason: 'Asılsız ihbar',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.dismissReport)
                .having((a) => a.targetId, 'targetId', 'rep_1')
                .having((a) => a.reason, 'reason', 'Asılsız ihbar'),
          ))).called(1);

      expect(find.text('Şikayeti Reddet işlemi tamamlandı.'), findsOneWidget);
    });

    testWidgets('dismissReport: cancels dialog without calling moderation service', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_cancel', targetId: 'u1');
      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
      await tester.pumpAndSettle();

      verifyNever(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));
    });

    testWidgets('warnUser: sends warning, logs action and dismisses report', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_warn', targetId: 'user_warn_1');
      when(() => mockModerationService.warnUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Uyar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'İlk uyarı');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.warnUser(
            userId: 'user_warn_1',
            adminId: 'admin_uid_1',
            reason: 'İlk uyarı',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.warnUser)
                .having((a) => a.targetId, 'targetId', 'user_warn_1'),
          ))).called(1);

      verify(() => mockModerationService.dismissReport(
            reportId: 'rep_warn',
            adminId: 'admin_uid_1',
            reason: 'Kullanıcıyı Uyar işlemi uygulandı',
          )).called(1);

      expect(find.text('Kullanıcıyı Uyar işlemi tamamlandı.'), findsOneWidget);
    });

    testWidgets('suspendUser: suspends target user and dismisses report', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_susp', targetId: 'user_susp_1');
      when(() => mockModerationService.suspendUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Askıya al'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '7 gün askı');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.suspendUser(
            userId: 'user_susp_1',
            adminId: 'admin_uid_1',
            reason: '7 gün askı',
          )).called(1);

      verify(() => mockModerationService.dismissReport(
            reportId: 'rep_susp',
            adminId: 'admin_uid_1',
            reason: 'Kullanıcıyı Askıya Al işlemi uygulandı',
          )).called(1);
    });

    testWidgets('banUser: validates required reason and bans target user', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_ban', targetId: 'user_ban_1');
      when(() => mockModerationService.banUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Yasakla'));
      await tester.pumpAndSettle();

      // Attempt to submit empty reason for ban (requiredReason = true)
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      expect(find.text('Sebep girmeniz gerekiyor.'), findsOneWidget);
      verifyNever(() => mockModerationService.banUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          ));

      // Enter valid reason and submit
      await tester.enterText(find.byType(TextField), 'Ciddi kural ihlali ve dolandırıcılık');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.banUser(
            userId: 'user_ban_1',
            adminId: 'admin_uid_1',
            reason: 'Ciddi kural ihlali ve dolandırıcılık',
          )).called(1);

      verify(() => mockModerationService.dismissReport(
            reportId: 'rep_ban',
            adminId: 'admin_uid_1',
            reason: 'Kullanıcıyı Yasakla işlemi uygulandı',
          )).called(1);

      expect(find.text('Kullanıcıyı Yasakla işlemi tamamlandı.'), findsOneWidget);
    });

    testWidgets('removeListing: removes target listing and dismisses report', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(
        id: 'rep_list',
        targetId: 'list_123',
        targetType: ReportTargetType.listing,
        reason: ReportReason.misleading,
      );
      when(() => mockModerationService.removeListing(
            listingId: any(named: 'listingId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'İlanı kaldır'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Yanıltıcı maaş bilgisi');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.removeListing(
            listingId: 'list_123',
            adminId: 'admin_uid_1',
            reason: 'Yanıltıcı maaş bilgisi',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.removeListing)
                .having((a) => a.targetId, 'targetId', 'list_123')
                .having((a) => a.targetType, 'targetType', AdminActionTargetType.listing),
          ))).called(1);

      expect(find.text('İlanı Kaldır işlemi tamamlandı.'), findsOneWidget);
    });

    testWidgets('displays SnackBar error when moderation service throws', (tester) async {
      await configureTestScreenSize(tester);

      final report = createDummyReport(id: 'rep_err', targetId: 'u_err');
      when(() => mockModerationService.dismissReport(
            reportId: any(named: 'reportId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenThrow(Exception('İşlem sırasında hata oluştu'));

      await tester.pumpWidget(buildReportsScreen(reportsStream: Stream.value([report])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reddet'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
