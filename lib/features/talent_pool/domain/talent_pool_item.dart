import 'package:cloud_firestore/cloud_firestore.dart';

class TalentPoolItem {
  final String id;
  final String candidateId;
  final String candidateName;
  final String? note;
  final String? conversationId;
  final DateTime? addedAt;

  const TalentPoolItem({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    this.note,
    this.conversationId,
    this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'candidateId': candidateId,
      'candidateName': candidateName,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (conversationId != null && conversationId!.isNotEmpty)
        'conversationId': conversationId,
      'addedAt': addedAt != null
          ? Timestamp.fromDate(addedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TalentPoolItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['addedAt'] as Timestamp?;
    return TalentPoolItem(
      id: doc.id,
      candidateId: data['candidateId'] as String? ?? doc.id,
      candidateName: data['candidateName'] as String? ?? 'Aday',
      note: data['note'] as String?,
      conversationId: data['conversationId'] as String?,
      addedAt: timestamp?.toDate(),
    );
  }
}
