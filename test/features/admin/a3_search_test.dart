import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/presentation/widgets/admin_global_search.dart';
import 'package:otelcim/shared/utils/search_keywords.dart';

void main() {
  group('admin global search queries', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      await db.collection('user_profiles').doc('u1').set({
        'displayName': 'Ayşe Aday',
        'email': 'ayse@example.test',
        'searchKeywords': buildSearchKeywords(['Ayşe Aday', 'ayse@example.test']),
      });
      await db.collection('user_profiles').doc('u2').set({
        'displayName': 'Mehmet Kaya',
        'email': 'mehmet@example.test',
        'searchKeywords': buildSearchKeywords(['Mehmet Kaya', 'mehmet@example.test']),
      });
      await db.collection('listings').doc('l1').set({
        'title': 'Ayşe Otel Resepsiyonisti',
        'posterName': 'Otel A.Ş.',
        'searchKeywords': buildSearchKeywords(['Ayşe Otel Resepsiyonisti', 'Otel A.Ş.']),
      });
    });

    Future<List<String>> ids(Query<Map<String, dynamic>>? query) async {
      if (query == null) return [];
      return (await query.get()).docs.map((doc) => doc.id).toList();
    }

    test('user search is a Turkish-insensitive prefix query capped at eight', () async {
      expect(await ids(adminGlobalUserQuery(db, 'AYŞE')), ['u1']);
      expect(await ids(adminGlobalUserQuery(db, 'mehm')), ['u2']);
    });

    test('listing search uses the same search token query', () async {
      expect(await ids(adminGlobalListingQuery(db, 'reseps')), ['l1']);
      expect(await ids(adminGlobalListingQuery(db, 'otel')), ['l1']);
    });

    test('queries are absent until a two-character token exists', () async {
      expect(adminGlobalUserQuery(db, 'a'), isNull);
      expect(adminGlobalListingQuery(db, ' '), isNull);
    });

    test('each collection query is limited to eight documents', () async {
      for (var i = 0; i < 10; i++) {
        await db.collection('user_profiles').doc('bulk$i').set({
          'searchKeywords': buildSearchKeywords(['Arama Kullanıcısı $i']),
        });
      }

      final results = await adminGlobalUserQuery(db, 'arama')!.get();
      expect(results.docs, hasLength(8));
    });
  });
}
