import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/presentation/user_management_screen.dart';
import 'package:otelcim/features/admin/presentation/widgets/admin_paged_controller.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/utils/search_keywords.dart';

void main() {
  group('AdminPagedController', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      for (var i = 0; i < 45; i++) {
        await db.collection('items').doc('d${i.toString().padLeft(2, '0')}').set({
          'n': i,
          'kind': i.isEven ? 'even' : 'odd',
        });
      }
    });

    AdminPagedController<int> controller() => AdminPagedController<int>(
          fromDoc: (doc) => doc.data()!['n'] as int,
          idOf: (n) => '$n',
        );

    test('loads 20 per page and stops after the last page', () async {
      final c = controller();
      await c.setQuery(db.collection('items').orderBy('n'));
      expect(c.items, List.generate(20, (i) => i));
      expect(c.hasMore, isTrue);
      await c.loadMore();
      expect(c.items.length, 40);
      await c.loadMore();
      expect(c.items.length, 45);
      expect(c.items.last, 44);
      expect(c.hasMore, isFalse);
      await c.loadMore(); // no-op at the end
      expect(c.items.length, 45);
    });

    test('a new query replaces the list and the selection', () async {
      final c = controller();
      await c.setQuery(db.collection('items').orderBy('n'));
      c.toggleSelected(3);
      expect(c.selectedIds, {'3'});
      await c.setQuery(db.collection('items').where('kind', isEqualTo: 'odd').orderBy('n'));
      expect(c.selectedIds, isEmpty);
      expect(c.items.every((n) => n.isOdd), isTrue);
    });

    test('a slow response for an old query never lands in the new list', () async {
      final c = controller();
      final stale = c.setQuery(db.collection('items').orderBy('n'));
      final fresh = c.setQuery(db.collection('items').where('kind', isEqualTo: 'even').orderBy('n'));
      await Future.wait([stale, fresh]);
      expect(c.items.every((n) => n.isEven), isTrue);
      expect(c.items.length, 20);
    });

    test('bulk helpers: select all loaded, removeWhere drops selection too', () async {
      final c = controller();
      await c.setQuery(db.collection('items').orderBy('n'));
      c.selectAllLoaded();
      expect(c.selectedIds.length, 20);
      c.removeWhere((n) => n < 5);
      expect(c.items.first, 5);
      expect(c.selectedIds.length, 15);
      c.clearSelection();
      expect(c.selectedItems, isEmpty);
    });
  });

  group('adminUsersQuery', () {
    late FakeFirebaseFirestore db;

    Future<void> addUser(String id, String name, String email, String type,
        {bool banned = false, int daysAgo = 0}) {
      return db.collection('user_profiles').doc(id).set({
        'displayName': name,
        'email': email,
        'userType': type,
        'isBanned': banned,
        'searchKeywords': buildSearchKeywords([name, email]),
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 24).subtract(Duration(days: daysAgo))),
      });
    }

    setUp(() async {
      db = FakeFirebaseFirestore();
      await addUser('u1', 'Ayşe Aday', 'ayse@x.test', 'jobseeker', daysAgo: 3);
      await addUser('u2', 'Ayşegül Otelci', 'agul@x.test', 'employer', daysAgo: 1);
      await addUser('u3', 'Mehmet Kaya', 'mk@x.test', 'employer', banned: true, daysAgo: 2);
    });

    Future<List<String>> ids(Query<Map<String, dynamic>> q) async =>
        (await q.get()).docs.map((d) => d.id).toList();

    test('no filter: newest first', () async {
      expect(await ids(adminUsersQuery(db, filter: 'all')), ['u2', 'u3', 'u1']);
    });

    test('filter tabs narrow the result', () async {
      expect(await ids(adminUsersQuery(db, filter: 'employer')), ['u2', 'u3']);
      expect(await ids(adminUsersQuery(db, filter: 'banned')), ['u3']);
    });

    test('search is prefix, case- and Turkish-insensitive, and combines with filters', () async {
      expect((await ids(adminUsersQuery(db, filter: 'all', search: 'AYSE'))).toSet(), {'u1', 'u2'});
      expect(await ids(adminUsersQuery(db, filter: 'employer', search: 'ayş')), ['u2']);
      expect(await ids(adminUsersQuery(db, filter: 'all', search: 'mk@x.test')), ['u3']);
    });

    test('UserProfile.toFirestore writes searchKeywords', () {
      final profile = UserProfile(
        id: 'u9',
        email: 'Zeynep@Otel.test',
        displayName: 'Zeynep Otelci',
        userType: 'employer',
        hotelName: 'Kaya Butik',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final keywords = profile.toFirestore()['searchKeywords'] as List<String>;
      expect(keywords, containsAll(['zeynep', 'otelci', 'kaya', 'butik', 'zeynep@otel.test']));
    });
  });
}
