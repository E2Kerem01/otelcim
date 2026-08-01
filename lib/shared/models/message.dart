import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;
  final bool read;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
    this.read = false,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      };
}
