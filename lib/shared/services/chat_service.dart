import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/domain/interview_slot_model.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  ChatService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Conversation>> watchConversations(String uid) {
    final posterConversations = <String, Conversation>{};
    final seekerConversations = <String, Conversation>{};
    var hasPosterSnapshot = false;
    var hasSeekerSnapshot = false;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? posterSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? seekerSubscription;
    late final StreamController<List<Conversation>> controller;

    void emitConversations() {
      if (!hasPosterSnapshot || !hasSeekerSnapshot || controller.isClosed) {
        return;
      }

      final conversations = <Conversation>[
        ...posterConversations.values,
        ...seekerConversations.values.where(
          (conversation) => !posterConversations.containsKey(conversation.id),
        ),
      ];
      conversations.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final tB = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return tB.compareTo(tA);
      });
      controller.add(conversations);
    }

    void handleError(Object error, StackTrace stackTrace) {
      debugPrint('Firestore watchConversations warning: $error');
    }

    controller = StreamController<List<Conversation>>(
      onListen: () {
        posterSubscription = _db
            .collection('conversations')
            .where('posterId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
          posterConversations
            ..clear()
            ..addEntries(snapshot.docs.map((doc) {
              final conversation = Conversation.fromDoc(doc);
              return MapEntry(doc.id, conversation);
            }));
          hasPosterSnapshot = true;
          emitConversations();
        }, onError: handleError);

        seekerSubscription = _db
            .collection('conversations')
            .where('seekerId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
          seekerConversations
            ..clear()
            ..addEntries(snapshot.docs.map((doc) {
              final conversation = Conversation.fromDoc(doc);
              return MapEntry(doc.id, conversation);
            }));
          hasSeekerSnapshot = true;
          emitConversations();
        }, onError: handleError);
      },
      onPause: () {
        posterSubscription?.pause();
        seekerSubscription?.pause();
      },
      onResume: () {
        posterSubscription?.resume();
        seekerSubscription?.resume();
      },
      onCancel: () async {
        await posterSubscription?.cancel();
        await seekerSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _db.collection('conversations').doc(conversationId).get();
    if (!doc.exists) return null;
    return Conversation.fromDoc(doc);
  }

  Stream<Conversation?> watchConversation(String conversationId) {
    return _db.collection('conversations').doc(conversationId).snapshots().map(
          (doc) => doc.exists ? Conversation.fromDoc(doc) : null,
        );
  }

  Future<void> markConversationHired(String conversationId) async {
    final reference = _db.collection('conversations').doc(conversationId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data()?['hired'] == true) return;
      transaction.update(reference, {
        'hired': true,
        'hiredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Message>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snap) {
      var messages = snap.docs.map(Message.fromDoc).toList();
      messages.sort((a, b) {
        final tA = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tA.compareTo(tB);
      });
      return messages;
    }).handleError((Object error) {
      debugPrint('Firestore watchMessages warning: $error');
      return <Message>[];
    });
  }

  Future<({String conversationId, bool isNew})> getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    required String posterId,
    required String seekerId,
  }) async {
    final conversationId = '${listingId}_$seekerId';
    final ref = _db.collection('conversations').doc(conversationId);
    final existing = await ref.get();
    final isNew = !existing.exists;
    if (isNew) {
      await ref.set(
        Conversation(
          id: conversationId,
          listingId: listingId,
          listingTitle: listingTitle,
          posterId: posterId,
          seekerId: seekerId,
        ).toMap(),
      );
    }
    return (conversationId: conversationId, isNew: isNew);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final conversationRef = _db.collection('conversations').doc(conversationId);
    await conversationRef.collection('messages').add(
          Message(id: '', senderId: senderId, text: text).toMap(),
        );
    await conversationRef.update({
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> proposeInterviewSlots({
    required String conversationId,
    required String proposedBy,
    required List<DateTime> slots,
  }) async {
    final docRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('interview_slots')
        .doc();

    final item = InterviewSlot(
      id: docRef.id,
      proposedBy: proposedBy,
      slots: slots,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(item.toMap());
    return docRef.id;
  }

  Future<void> confirmInterviewSlot({
    required String conversationId,
    required String slotId,
    required DateTime selectedSlot,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('interview_slots')
        .doc(slotId)
        .update({
      'selectedSlot': Timestamp.fromDate(selectedSlot),
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<InterviewSlot>> watchInterviewSlots(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('interview_slots')
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(InterviewSlot.fromDoc).toList();
      items.sort((a, b) {
        final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return items;
    }).handleError((Object error) {
      debugPrint('Firestore watchInterviewSlots error: $error');
      return <InterviewSlot>[];
    });
  }
}

final chatServiceProvider = Provider<ChatService>((ref) => ChatService(FirebaseFirestore.instance));

final currentChatIdProvider = StateProvider<String?>((ref) => null);
