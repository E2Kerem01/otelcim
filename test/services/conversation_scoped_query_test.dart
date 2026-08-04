import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/services/chat_service.dart';

void main() {
  group('ChatService watchConversations Filter.or scoped queries', () {
    late FakeFirebaseFirestore db;
    late ChatService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = ChatService(db);
    });

    test('watchConversations filters conversations server-side for poster or seeker', () async {
      final now = DateTime.now();

      // Conversation where user_1 is poster
      await db.collection('conversations').doc('conv_1').set({
        'id': 'conv_1',
        'listingId': 'list_1',
        'listingTitle': 'Resepsiyon',
        'posterId': 'user_1',
        'seekerId': 'user_2',
        'createdAt': now.subtract(const Duration(hours: 2)),
        'updatedAt': now.subtract(const Duration(hours: 1)),
      });

      // Conversation where user_1 is seeker
      await db.collection('conversations').doc('conv_2').set({
        'id': 'conv_2',
        'listingId': 'list_2',
        'listingTitle': 'Garson',
        'posterId': 'user_3',
        'seekerId': 'user_1',
        'createdAt': now.subtract(const Duration(hours: 3)),
        'updatedAt': now,
      });

      // Conversation between user_2 and user_3 (user_1 is not involved)
      await db.collection('conversations').doc('conv_3').set({
        'id': 'conv_3',
        'listingId': 'list_3',
        'listingTitle': 'Aşçı',
        'posterId': 'user_2',
        'seekerId': 'user_3',
        'createdAt': now.subtract(const Duration(hours: 4)),
        'updatedAt': now.subtract(const Duration(hours: 4)),
      });

      // Query for user_1
      final user1Convs = await service.watchConversations('user_1').first;
      expect(user1Convs.length, equals(2));
      final user1Ids = user1Convs.map((c) => c.id).toList();
      expect(user1Ids, containsAll(['conv_1', 'conv_2']));
      expect(user1Ids, isNot(contains('conv_3')));

      // Order should be newest updatedAt first (conv_2 updated 'now', conv_1 updated '1 hour ago')
      expect(user1Convs.first.id, equals('conv_2'));
      expect(user1Convs.last.id, equals('conv_1'));

      // Query for user_2
      final user2Convs = await service.watchConversations('user_2').first;
      expect(user2Convs.length, equals(2));
      final user2Ids = user2Convs.map((c) => c.id).toList();
      expect(user2Ids, containsAll(['conv_1', 'conv_3']));

      // Query for user_4 (no conversations)
      final user4Convs = await service.watchConversations('user_4').first;
      expect(user4Convs, isEmpty);
    });
  });
}
