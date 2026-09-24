import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/audit_log_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('AuditLogScreen Widget Tests', () {
    late MockAdminService mockAdminService;

    setUp(() {
      mockAdminService = MockAdminService();
    });

    Widget buildAuditLogScreen({
      required Stream<List<AdminAction>> auditStream,
    }) {
      when(() => mockAdminService.watchAuditLog(
            adminId: any(named: 'adminId'),
            actionType: any(named: 'actionType'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) => auditStream);

      return createAdminTestApp(
        overrides: [
          adminServiceProvider.overrideWith((ref) => mockAdminService),
        ],
        child: const AuditLogScreen(),
      );
    }

    testWidgets('displays loading indicator while audit log stream is waiting', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<AdminAction>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildAuditLogScreen(auditStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when audit log stream fails', (tester) async {
      await configureTestScreenSize(tester);

      final errorStream = Stream<List<AdminAction>>.error(Exception('Index required'));

      await tester.pumpWidget(buildAuditLogScreen(auditStream: errorStream));
      await tester.pumpAndSettle();

      expect(
        find.text('İşlem geçmişi yüklenemedi. Filtreler için Firestore dizini gerekebilir.'),
        findsOneWidget,
      );
    });

    testWidgets('displays empty state when no actions match filters', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildAuditLogScreen(auditStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtrelerle eşleşen işlem bulunmuyor.'), findsOneWidget);
    });

    testWidgets('renders action cards with action types, targets, admin IDs and reasons', (tester) async {
      await configureTestScreenSize(tester);

      final actions = [
        createDummyAdminAction(
          id: 'act_1',
          adminId: 'admin_super_1',
          actionType: AdminActionType.banUser,
          targetType: AdminActionTargetType.user,
          targetId: 'bad_user_99',
          reason: 'Spam mesajlar',
        ),
        createDummyAdminAction(
          id: 'act_2',
          adminId: 'admin_mod_2',
          actionType: AdminActionType.removeListing,
          targetType: AdminActionTargetType.listing,
          targetId: 'listing_bad_77',
          reason: 'Hatalı fiyat',
        ),
      ];

      await tester.pumpWidget(buildAuditLogScreen(auditStream: Stream.value(actions)));
      await tester.pumpAndSettle();

      // Card 1
      expect(find.text('Kullanıcıyı Yasakla'), findsOneWidget);
      expect(find.text('Kullanıcı: bad_user_99'), findsOneWidget);
      expect(find.text('Yönetici: admin_super_1'), findsOneWidget);
      expect(find.text('Sebep: Spam mesajlar'), findsOneWidget);

      // Card 2
      expect(find.text('İlanı Kaldır'), findsOneWidget);
      expect(find.text('İlan: listing_bad_77'), findsOneWidget);
      expect(find.text('Yönetici: admin_mod_2'), findsOneWidget);
      expect(find.text('Sebep: Hatalı fiyat'), findsOneWidget);
    });

    testWidgets('filters audit log by action type using dropdown', (tester) async {
      await configureTestScreenSize(tester);

      when(() => mockAdminService.watchAuditLog(
            adminId: any(named: 'adminId'),
            actionType: any(named: 'actionType'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildAuditLogScreen(auditStream: Stream.value([])));
      await tester.pumpAndSettle();

      // Tap action type dropdown
      await tester.tap(find.text('Tüm işlemler'));
      await tester.pumpAndSettle();

      // Select 'Kullanıcıyı Uyar'
      await tester.tap(find.text('Kullanıcıyı Uyar').last);
      await tester.pumpAndSettle();

      verify(() => mockAdminService.watchAuditLog(
            adminId: null,
            actionType: AdminActionType.warnUser,
            limit: 100,
          )).called(1);
    });

    testWidgets('filters audit log by adminId via dialog and clears filter via chip', (tester) async {
      await configureTestScreenSize(tester);

      when(() => mockAdminService.watchAuditLog(
            adminId: any(named: 'adminId'),
            actionType: any(named: 'actionType'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildAuditLogScreen(auditStream: Stream.value([])));
      await tester.pumpAndSettle();

      // Tap admin filter button
      await tester.tap(find.byTooltip('Yönetici filtresi'));
      await tester.pumpAndSettle();

      expect(find.text('Yöneticiye göre filtrele'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'admin_target_42');
      await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
      await tester.pumpAndSettle();

      // Verify filter chip is shown
      expect(find.text('Yönetici: admin_target_42'), findsOneWidget);

      verify(() => mockAdminService.watchAuditLog(
            adminId: 'admin_target_42',
            actionType: any(named: 'actionType'),
            limit: 100,
          )).called(1);

      // Delete chip to clear filter
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      chip.onDeleted?.call();
      await tester.pumpAndSettle();

      expect(find.text('Yönetici: admin_target_42'), findsNothing);

      verify(() => mockAdminService.watchAuditLog(
            adminId: null,
            actionType: any(named: 'actionType'),
            limit: 100,
          )).called(1);
    });
  });
}
