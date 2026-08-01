import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String posterId;
  final String seekerId;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const Conversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.posterId,
    required this.seekerId,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.updatedAt,
    this.createdAt,
  });

  String otherParticipant(String myUid) => myUid == posterId ? seekerId : posterId;

  factory Conversation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return Conversation(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? '',
      posterId: data['posterId'] as String? ?? '',
      seekerId: data['seekerId'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderId: data['lastSenderId'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'listingTitle': listingTitle,
        'posterId': posterId,
        'seekerId': seekerId,
        'participantIds': [posterId, seekerId],
        'lastMessage': lastMessage,
        'lastSenderId': lastSenderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
