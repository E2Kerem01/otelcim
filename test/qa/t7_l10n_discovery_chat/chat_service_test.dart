import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/services/chat_service.dart';

void main() {
  group('ChatService Unit & Edge Case Tests', () {
    late FakeFirebaseFirestore db;
    late ChatService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = ChatService(db);
    });

    test('watchConversations merges and deduplicates poster and seeker conversations', () async {
      final now = DateTime.now();

      // Conversation where user_1 is poster
      await db.collection('conversations').doc('conv_1').set({
        'id': 'conv_1',
        'listingId': 'list_1',
        'listingTitle': 'Resepsiyonist',
        'posterId': 'user_1',
        'seekerId': 'user_2',
        'lastMessage': 'Merhaba',
        'createdAt': now.subtract(const Duration(hours: 2)),
        'updatedAt': now.subtract(const Duration(hours: 1)),
      });

      // Conversation where user_1 is seeker
      await db.collection('conversations').doc('conv_2').set({
        'id': 'conv_2',
        'listingId': 'list_2',
        'listingTitle': 'Aşçı',
        'posterId': 'user_3',
        'seekerId': 'user_1',
        'lastMessage': 'CV gönderdim',
        'createdAt': now.subtract(const Duration(hours: 3)),
        'updatedAt': now,
      });

      // Unrelated conversation
      await db.collection('conversations').doc('conv_3').set({
        'id': 'conv_3',
        'listingId': 'list_3',
        'listingTitle': 'Garson',
        'posterId': 'user_4',
        'seekerId': 'user_5',
        'lastMessage': 'Selam',
        'createdAt': now,
        'updatedAt': now,
      });

      final stream = service.watchConversations('user_1');
      final list = await stream.first;

      expect(list.length, equals(2));
      final ids = list.map((c) => c.id).toList();
      expect(ids, containsAll(['conv_1', 'conv_2']));
      expect(ids, isNot(contains('conv_3')));

      // Order should be newest updatedAt first (conv_2, then conv_1)
      expect(list[0].id, equals('conv_2'));
      expect(list[1].id, equals('conv_1'));
    });

    test(
      'watchConversations emits error or empty list rather than hanging when a subquery fails',
      () async {
        // If one of the streams encounters an error or doesn't fire,
        // hasPosterSnapshot && hasSeekerSnapshot is never satisfied.
        // We assert that an error is forwarded to the controller.
        final stream = service.watchConversations('user_error');
        // Currently onError in listen() simply debugPrints and does not call controller.addError()
        expect(
          stream,
          emitsError(isA<FirebaseException>()),
        );
      },
      skip:
          'BUG-t7-06: ChatService.watchConversations hangs indefinitely without emitting or erroring if one sub-query errors (chat_service.dart:44-78)',
    );

    test(
      'watchConversations sort comparator does not call DateTime.now() dynamically for null timestamps',
      () async {
        // Both updatedAt and createdAt null
        await db.collection('conversations').doc('conv_null_1').set({
          'id': 'conv_null_1',
          'listingId': 'list_1',
          'listingTitle': 'İş 1',
          'posterId': 'user_test',
          'seekerId': 'user_other',
        });
        await db.collection('conversations').doc('conv_null_2').set({
          'id': 'conv_null_2',
          'listingId': 'list_2',
          'listingTitle': 'İş 2',
          'posterId': 'user_test',
          'seekerId': 'user_other_2',
        });

        final list = await service.watchConversations('user_test').first;
        expect(list.length, equals(2));
        // Calling DateTime.now() inside sort violates strict weak ordering contract.
      },
      skip:
          'BUG-t7-07: ChatService.watchConversations uses DateTime.now() in sort comparator causing unstable ordering (chat_service.dart:37-38)',
    );

    test('getConversation returns null for nonexistent conversation', () async {
      final conv = await service.getConversation('nonexistent_id');
      expect(conv, isNull);
    });

    test('getConversation returns parsed Conversation when document exists', () async {
      await db.collection('conversations').doc('conv_test').set({
        'id': 'conv_test',
        'listingId': 'l1',
        'listingTitle': 'Kat Görevlisi',
        'posterId': 'p1',
        'seekerId': 's1',
        'lastMessage': 'Görüşebilir miyiz?',
      });

      final conv = await service.getConversation('conv_test');
      expect(conv, isNotNull);
      expect(conv!.id, equals('conv_test'));
      expect(conv.listingTitle, equals('Kat Görevlisi'));
      expect(conv.lastMessage, equals('Görüşebilir miyiz?'));
    });

    test('getOrCreateConversation returns existing conversation without overwriting', () async {
      await db.collection('conversations').doc('l1_s1').set({
        'id': 'l1_s1',
        'listingId': 'l1',
        'listingTitle': 'Eski Başlık',
        'posterId': 'p1',
        'seekerId': 's1',
        'lastMessage': 'Önceki mesaj',
      });

      final result = await service.getOrCreateConversation(
        listingId: 'l1',
        listingTitle: 'Yeni Başlık',
        posterId: 'p1',
        seekerId: 's1',
      );

      expect(result.conversationId, equals('l1_s1'));
      expect(result.isNew, isFalse);

      final doc = await db.collection('conversations').doc('l1_s1').get();
      // Should preserve existing title
      expect(doc.data()?['listingTitle'], equals('Eski Başlık'));
    });

    test('getOrCreateConversation creates new conversation when not exists', () async {
      final result = await service.getOrCreateConversation(
        listingId: 'l2',
        listingTitle: 'Barmen',
        posterId: 'p2',
        seekerId: 's2',
      );

      expect(result.conversationId, equals('l2_s2'));
      expect(result.isNew, isTrue);

      final doc = await db.collection('conversations').doc('l2_s2').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['listingTitle'], equals('Barmen'));
      expect(doc.data()?['posterId'], equals('p2'));
      expect(doc.data()?['seekerId'], equals('s2'));
    });

    test(
      'getOrCreateConversation rejects self-conversation where posterId equals seekerId',
      () async {
        // A user shouldn't be allowed to chat with themselves on their own listing
        expect(
          () => service.getOrCreateConversation(
            listingId: 'l_self',
            listingTitle: 'My Own Listing',
            posterId: 'user_same',
            seekerId: 'user_same',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
      skip:
          'BUG-t7-08: ChatService.getOrCreateConversation allows self-conversations (posterId == seekerId)',
    );

    test('sendMessage adds message to subcollection and updates parent conversation', () async {
      await db.collection('conversations').doc('conv_send').set({
        'id': 'conv_send',
        'listingId': 'l1',
        'listingTitle': 'Garson',
        'posterId': 'p1',
        'seekerId': 's1',
        'lastMessage': '',
        'lastSenderId': '',
      });

      await service.sendMessage(
        conversationId: 'conv_send',
        senderId: 's1',
        text: 'Merhaba, ilan hala güncel mi?',
      );

      final messagesSnap = await db
          .collection('conversations')
          .doc('conv_send')
          .collection('messages')
          .get();
      expect(messagesSnap.docs.length, equals(1));
      expect(messagesSnap.docs.first.data()['text'], equals('Merhaba, ilan hala güncel mi?'));
      expect(messagesSnap.docs.first.data()['senderId'], equals('s1'));

      final convDoc = await db.collection('conversations').doc('conv_send').get();
      expect(convDoc.data()?['lastMessage'], equals('Merhaba, ilan hala güncel mi?'));
      expect(convDoc.data()?['lastSenderId'], equals('s1'));
      expect(convDoc.data()?['updatedAt'], isNotNull);
    });

    test(
      'sendMessage rejects empty or whitespace-only messages',
      () async {
        expect(
          () => service.sendMessage(
            conversationId: 'conv_empty',
            senderId: 's1',
            text: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
      skip:
          'BUG-t7-09: ChatService.sendMessage accepts empty and whitespace-only text (chat_service.dart:166-180)',
    );

    test('markConversationHired updates conversation with hired flag and timestamp in transaction', () async {
      await db.collection('conversations').doc('conv_hire').set({
        'id': 'conv_hire',
        'listingId': 'l1',
        'listingTitle': 'Resepsiyon',
        'posterId': 'p1',
        'seekerId': 's1',
        'hired': false,
      });

      await service.markConversationHired('conv_hire');

      final updated = await db.collection('conversations').doc('conv_hire').get();
      expect(updated.data()?['hired'], isTrue);
      expect(updated.data()?['hiredAt'], isNotNull);
      expect(updated.data()?['updatedAt'], isNotNull);

      // Calling a second time is a safe no-op
      await service.markConversationHired('conv_hire');
      expect((await db.collection('conversations').doc('conv_hire').get()).data()?['hired'], isTrue);
    });

    test(
      'watchMessages orders pending messages with null sentAt at the end, not at epoch 0',
      () async {
        final convRef = db.collection('conversations').doc('conv_msgs');
        await convRef.set({'id': 'conv_msgs'});

        final past = DateTime.now().subtract(const Duration(minutes: 5));
        // Existing confirmed message
        await convRef.collection('messages').doc('msg_1').set({
          'senderId': 'p1',
          'text': 'Önceki mesaj',
          'sentAt': past,
        });
        // Optimistic / pending local message without server timestamp
        await convRef.collection('messages').doc('msg_2').set({
          'senderId': 's1',
          'text': 'Yeni mesaj (henüz timestamp yok)',
          'sentAt': null,
        });

        final messages = await service.watchMessages('conv_msgs').first;
        expect(messages.length, equals(2));

        // The newly sent message should be at index 1 (end of conversation),
        // but current implementation falls back to epoch 0 placing it at index 0!
        expect(messages.last.id, equals('msg_2'),
            reason: 'Newly sent pending message must appear at the bottom of the chat list');
      },
      skip:
          'BUG-t7-10: ChatService.watchMessages places pending messages with null sentAt at epoch 0 (top of chat) (chat_service.dart:131-132)',
    );

    test('proposeInterviewSlots creates pending slot document', () async {
      final now = DateTime.now();
      final slot1 = now.add(const Duration(days: 1));
      final slot2 = now.add(const Duration(days: 2));

      final slotId = await service.proposeInterviewSlots(
        conversationId: 'conv_slots',
        proposedBy: 'employer_1',
        slots: [slot1, slot2],
      );

      expect(slotId, isNotEmpty);
      final doc = await db
          .collection('conversations')
          .doc('conv_slots')
          .collection('interview_slots')
          .doc(slotId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['status'], equals('pending'));
      expect(doc.data()?['proposedBy'], equals('employer_1'));
    });

    test(
      'confirmInterviewSlot validates that selectedSlot was among proposed slots',
      () async {
        final now = DateTime.now();
        final slot1 = now.add(const Duration(days: 1));
        final unlistedSlot = now.add(const Duration(days: 10));

        final slotId = await service.proposeInterviewSlots(
          conversationId: 'conv_slots_2',
          proposedBy: 'employer_1',
          slots: [slot1],
        );

        // Attempting to confirm a slot that was not offered
        expect(
          () => service.confirmInterviewSlot(
            conversationId: 'conv_slots_2',
            slotId: slotId,
            selectedSlot: unlistedSlot,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
      skip:
          'BUG-t7-11: ChatService.confirmInterviewSlot does not validate selectedSlot was in proposed slots (chat_service.dart:205-220)',
    );

    test('watchInterviewSlots sorts slots by createdAt descending', () async {
      final now = DateTime.now();
      final slotsRef = db
          .collection('conversations')
          .doc('conv_watch_slots')
          .collection('interview_slots');

      await slotsRef.doc('s1').set({
        'proposedBy': 'emp1',
        'slots': [now],
        'status': 'pending',
        'createdAt': now.subtract(const Duration(hours: 1)),
      });
      await slotsRef.doc('s2').set({
        'proposedBy': 'emp1',
        'slots': [now],
        'status': 'confirmed',
        'createdAt': now,
      });

      final items = await service.watchInterviewSlots('conv_watch_slots').first;
      expect(items.length, equals(2));
      expect(items.first.id, equals('s2')); // newest first
      expect(items.last.id, equals('s1'));
    });
  });
}
