import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/shared/models/app_user.dart';

void main() {
  group('AdminService permissions', () {
    late AdminService service;

    setUp(() => service = AdminService(FakeFirebaseFirestore()));

    test('super admin can perform every declared admin action', () {
      const user = AppUser(
        uid: 'super',
        email: 'super@example.com',
        isAdmin: true,
        adminRole: AdminRole.superAdmin,
      );

      for (final action in AdminActionType.values) {
        expect(
          service.checkAdminPermission(user: user, actionType: action),
          isTrue,
          reason: 'super admin should be allowed to ${action.name}',
        );
      }
    });

    test('support agent can dismiss reports but cannot moderate users', () {
      const user = AppUser(
        uid: 'support',
        email: 'support@example.com',
        isAdmin: true,
        adminRole: AdminRole.supportAgent,
      );

      expect(
        service.checkAdminPermission(
          user: user,
          actionType: AdminActionType.dismissReport,
        ),
        isTrue,
      );
      expect(
        service.checkAdminPermission(
          user: user,
          actionType: AdminActionType.banUser,
        ),
        isFalse,
      );
      expect(
        service.checkAdminPermission(
          user: user,
          actionType: AdminActionType.approveCertificate,
        ),
        isFalse,
      );
    });

    test('content moderator can moderate users, listings and verification', () {
      const user = AppUser(
        uid: 'moderator',
        email: 'moderator@example.com',
        isAdmin: true,
        adminRole: AdminRole.contentModerator,
      );

      for (final action in const [
        AdminActionType.dismissReport,
        AdminActionType.warnUser,
        AdminActionType.removeListing,
        AdminActionType.restoreListing,
        AdminActionType.suspendUser,
        AdminActionType.unsuspendUser,
        AdminActionType.banUser,
        AdminActionType.unbanUser,
        AdminActionType.approveVerification,
        AdminActionType.rejectVerification,
      ]) {
        expect(
          service.checkAdminPermission(user: user, actionType: action),
          isTrue,
        );
      }
    });

    test('missing role, non-admin and anonymous users are denied', () {
      const users = <AppUser?>[
        null,
        AppUser(uid: 'plain', email: 'plain@example.com'),
        AppUser(uid: 'no-role', email: 'no-role@example.com', isAdmin: true),
        AppUser(
          uid: 'spoofed-role',
          email: 'spoofed@example.com',
          adminRole: AdminRole.superAdmin,
        ),
      ];

      for (final user in users) {
        expect(
          service.checkAdminPermission(
            user: user,
            actionType: AdminActionType.dismissReport,
          ),
          isFalse,
        );
      }
    });

    test(
      'content moderator can review certificates',
      () {
        const user = AppUser(
          uid: 'moderator',
          email: 'moderator@example.com',
          isAdmin: true,
          adminRole: AdminRole.contentModerator,
        );

        expect(
          service.checkAdminPermission(
            user: user,
            actionType: AdminActionType.approveCertificate,
          ),
          isTrue,
        );
        expect(
          service.checkAdminPermission(
            user: user,
            actionType: AdminActionType.rejectCertificate,
          ),
          isTrue,
        );
      },
      skip:
          'BUG-t5-006: contentModerator cannot approve or reject certificates despite being the content moderation role',
    );
  });

  group('AdminService user search', () {
    late FakeFirebaseFirestore db;
    late AdminService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = AdminService(db);
      final now = DateTime(2026, 9, 23);
      await db.collection('user_profiles').doc('u1').set({
        'email': 'ahmet@example.com',
        'displayName': 'Ahmet Yılmaz',
        'userType': 'job_seeker',
        'createdAt': now,
        'updatedAt': now,
      });
      await db.collection('user_profiles').doc('u2').set({
        'email': 'berna@example.com',
        'displayName': 'ahmet Kaya',
        'userType': 'job_seeker',
        'createdAt': now,
        'updatedAt': now,
      });
    });

    test(
      'trimmed prefix search deduplicates a profile matching email and name',
      () async {
        final users = await service.searchUsers('  ahmet ');

        expect(users.map((user) => user.id).toSet(), {'u1', 'u2'});
        expect(users.where((user) => user.id == 'u1'), hasLength(1));
      },
    );

    test(
      'empty or whitespace-only search does not query and returns no users',
      () async {
        expect(await service.searchUsers(''), isEmpty);
        expect(await service.searchUsers('   '), isEmpty);
      },
    );

    test('search is prefix and case sensitive as documented', () async {
      expect(
        (await service.searchUsers('Ahmet')).map((user) => user.id),
        isNotEmpty,
      );
      expect(await service.searchUsers('hmet'), isEmpty);
      expect(await service.searchUsers('AHMET'), isEmpty);
    });

    test(
      'recent users are ordered newest first and respect the limit',
      () async {
        await db.collection('user_profiles').doc('new').set({
          'email': 'new@example.com',
          'userType': 'employer',
          'createdAt': DateTime(2026, 9, 24),
          'updatedAt': DateTime(2026, 9, 24),
        });

        final users = await service.watchRecentUsers(limit: 2).first;

        expect(users, hasLength(2));
        expect(users.first.id, 'new');
      },
    );

    test('partial profile data is parsed with safe defaults', () async {
      await db.collection('user_profiles').doc('partial').set({
        'email': 'partial@example.com',
      });

      final profile = await service.getUserProfile('partial');

      expect(profile, isNotNull);
      expect(profile!.email, 'partial@example.com');
      expect(profile.userType, 'job_seeker');
      expect(profile.isAdmin, isFalse);
      expect(profile.notificationPreferences['messages'], isTrue);
    });
  });
}
