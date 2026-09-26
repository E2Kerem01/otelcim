import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/user_management_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/firestore_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(registerAdminFallbackValues);

  group('UserManagementScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockAdminService mockAdminService;
    late MockModerationService mockModerationService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAdminService = MockAdminService();
      mockModerationService = MockModerationService();

      when(() => mockAuthService.currentUser).thenReturn(
        createDummyAdminUser(uid: 'admin_uid_1', email: 'admin@otelcim.com'),
      );
      when(() => mockAdminService.logAdminAction(any()))
          .thenAnswer((_) async => 'log_1');
    });

    Future<void> seedUser(FakeFirebaseFirestore db, UserProfile user) {
      final data = user.toFirestore();
      data.addAll({
        'isAdmin': user.isAdmin,
        'adminRole': user.adminRole?.name,
        'isSuspended': user.isSuspended,
        'suspensionEnd': user.suspensionEnd == null
            ? null
            : Timestamp.fromDate(user.suspensionEnd!),
        'suspensionReason': user.suspensionReason,
        'isBanned': user.isBanned,
        'banReason': user.banReason,
      });
      return db.collection('user_profiles').doc(user.id).set(data);
    }

    Widget buildUserManagementScreen(FirebaseFirestore db) {
      return createAdminTestApp(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          firestoreProvider.overrideWithValue(db),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
          moderationServiceProvider
              .overrideWith((ref) => mockModerationService),
        ],
        child: const UserManagementScreen(),
      );
    }

    testWidgets('displays the current paged empty state', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildUserManagementScreen(FakeFirebaseFirestore()));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtreyle kullanıcı bulunamadı.'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tümü'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'İş arayan'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'İşveren'), findsOneWidget);
    });

    testWidgets('renders user cards with current names and status chips',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'u1',
          displayName: 'Ayşe Kaya',
          email: 'ayse@example.com',
        ),
      );
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'u2',
          displayName: 'Burak Can',
          email: 'burak@example.com',
          isBanned: true,
        ),
      );
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'u3',
          displayName: 'Cemre Demir',
          email: 'cemre@example.com',
          isSuspended: true,
          suspensionEnd: DateTime(2026, 7, 1),
        ),
      );

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Ayşe Kaya'), findsOneWidget);
      expect(find.text('ayse@example.com'), findsOneWidget);
      expect(find.text('Burak Can'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Yasaklı'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Yasağı Kaldır'), findsOneWidget);
      expect(find.text('Cemre Demir'), findsOneWidget);
      expect(find.text('Askıda (01.07.2026 kadar)'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Askıyı Kaldır'), findsOneWidget);
    });

    testWidgets('bans active user with reason dialog and logs action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'user_active',
          displayName: 'Test Kullanıcı',
          email: 'test@example.com',
        ),
      );
      when(() => mockModerationService.banUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Yasakla'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Kullanıcıyı Yasakla'),
        ),
        findsOneWidget,
      );
      expect(find.text('test@example.com kalıcı olarak yasaklanacak.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();
      expect(find.text('Sebep girmeniz gerekiyor.'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Dolandırıcılık tespiti',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.banUser(
            userId: 'user_active',
            adminId: 'admin_uid_1',
            reason: 'Dolandırıcılık tespiti',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.banUser)
                .having((a) => a.targetId, 'targetId', 'user_active'),
          ))).called(1);
      expect(find.text('İşlem tamamlandı.'), findsOneWidget);
    });

    testWidgets('unbans banned user and logs unban action', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'user_banned',
          displayName: 'Yasaklı Kişi',
          email: 'banned@example.com',
          isBanned: true,
        ),
      );
      when(() => mockModerationService.unbanUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Yasağı Kaldır'));
      await tester.pumpAndSettle();

      expect(find.text('banned@example.com kullanıcısının yasağını kaldırmak istiyor musunuz?'),
          findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Onayla'),
      ));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.unbanUser(
            userId: 'user_banned',
            adminId: 'admin_uid_1',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.unbanUser)
                .having((a) => a.targetId, 'targetId', 'user_banned'),
          ))).called(1);
      expect(find.text('İşlem tamamlandı.'), findsOneWidget);
    });

    testWidgets('suspends user for 7 days and logs suspend action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'user_to_suspend',
          email: 'suspendme@example.com',
        ),
      );
      when(() => mockModerationService.suspendUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
            suspensionEnd: any(named: 'suspensionEnd'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Askıya Al (7 gün)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Kullanıcıyı Askıya Al'),
        ),
        findsOneWidget,
      );
      expect(find.text('suspendme@example.com 7 gün süreyle askıya alınacak.'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Onayla'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sebep girmeniz gerekiyor.'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Geçici olarak askıya alındı',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.suspendUser(
            userId: 'user_to_suspend',
            adminId: 'admin_uid_1',
            reason: 'Geçici olarak askıya alındı',
            suspensionEnd: any(named: 'suspensionEnd'),
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.suspendUser)
                .having((a) => a.targetId, 'targetId', 'user_to_suspend'),
          ))).called(1);
      expect(find.text('İşlem tamamlandı.'), findsOneWidget);
    });

    testWidgets('unsuspends suspended user and logs unsuspend action',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'user_suspended',
          email: 'suspended@example.com',
          isSuspended: true,
        ),
      );
      when(() => mockModerationService.unsuspendUser(
            userId: any(named: 'userId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Askıyı Kaldır'));
      await tester.pumpAndSettle();
      expect(find.text('suspended@example.com kullanıcısının askısını kaldırmak istiyor musunuz?'),
          findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Onayla'),
      ));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.unsuspendUser(
            userId: 'user_suspended',
            adminId: 'admin_uid_1',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.unsuspendUser)
                .having((a) => a.targetId, 'targetId', 'user_suspended'),
          ))).called(1);
      expect(find.text('İşlem tamamlandı.'), findsOneWidget);
    });

    testWidgets('searches users by the current prefix query and clears it',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'search_u1',
          displayName: 'Serkan Öztürk',
          email: 'serkan@hotel.com',
        ),
      );

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'serkan');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Serkan Öztürk'), findsOneWidget);
      expect(find.text('serkan@hotel.com'), findsOneWidget);

      await tester.enterText(searchField, 'nonexistent');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Bu filtreyle kullanıcı bulunamadı.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Serkan Öztürk'), findsOneWidget);
    });

    testWidgets('prevents admin from banning or suspending their own account',
        (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        createDummyUserProfile(
          id: 'admin_uid_1',
          displayName: 'Admin User',
          email: 'admin@otelcim.com',
          isAdmin: true,
        ),
      );

      await tester.pumpWidget(buildUserManagementScreen(db));
      await tester.pumpAndSettle();

      final banButtonFinder = find.widgetWithText(FilledButton, 'Yasakla');
      expect(banButtonFinder, findsOneWidget);
      expect(tester.widget<FilledButton>(banButtonFinder).onPressed, isNull);
      final suspendButtonFinder =
          find.widgetWithText(OutlinedButton, 'Askıya Al (7 gün)');
      expect(tester.widget<OutlinedButton>(suspendButtonFinder).onPressed, isNull);
    });
  });
}
