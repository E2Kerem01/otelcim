import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/presentation/user_management_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/providers/firestore_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('own admin row shows Siz and disables moderation actions', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final auth = MockAuthService();
    when(() => auth.currentUser).thenReturn(
      const AppUser(uid: 'admin-1', email: 'admin@example.com'),
    );
    final now = Timestamp.fromDate(DateTime(2026, 9, 25));
    await db.collection('user_profiles').doc('admin-1').set({
      'email': 'admin@example.com',
      'displayName': 'Admin',
      'userType': 'jobseeker',
      'isAdmin': true,
      'adminRole': 'super_admin',
      'createdAt': now,
      'updatedAt': now,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          firestoreProvider.overrideWithValue(db),
          adminServiceProvider.overrideWithValue(AdminService(db)),
          moderationServiceProvider.overrideWithValue(ModerationService(db)),
        ],
        child: const MaterialApp(home: UserManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siz'), findsOneWidget);
    final banButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Yasakla'),
    );
    final suspendButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Askıya Al (7 gün)'),
    );
    expect(banButton.onPressed, isNull);
    expect(suspendButton.onPressed, isNull);
  });
}
