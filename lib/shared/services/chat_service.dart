import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  ChatService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Conversation>> watchConversations(String uid) {
    return _db.collection('conversations').snapshots().map((snap) {
      var conversations = snap.docs
          .map(Conversation.fromDoc)
          .where((c) => c.posterId == uid || c.seekerId == uid)
          .toList();

      conversations.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final tB = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return tB.compareTo(tA);
      });

      return conversations;
    }).handleError((error) {
      debugPrint('Firestore watchConversations warning: $error');
      return <Conversation>[];
    });
  }

  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _db.collection('conversations').doc(conversationId).get();
    if (!doc.exists) return null;
    return Conversation.fromDoc(doc);
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
    }).handleError((error) {
      debugPrint('Firestore watchMessages warning: $error');
      return <Message>[];
    });
  }

  Future<String> getOrCreateConversation({
    required String listingId,
    required String listingTitle,
    required String posterId,
    required String seekerId,
  }) async {
    final conversationId = '${listingId}_$seekerId';
    final ref = _db.collection('conversations').doc(conversationId);
    final existing = await ref.get();
    if (!existing.exists) {
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
    return conversationId;
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
}

final chatServiceProvider = Provider<ChatService>((ref) => ChatService(FirebaseFirestore.instance));

final currentChatIdProvider = StateProvider<String?>((ref) => null);
