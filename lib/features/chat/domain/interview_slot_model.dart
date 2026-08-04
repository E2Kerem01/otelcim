import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewSlot {
  const InterviewSlot({
    required this.id,
    required this.proposedBy,
    required this.slots,
    this.selectedSlot,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String proposedBy;
  final List<DateTime> slots;
  final DateTime? selectedSlot;
  final String status; // 'pending' | 'confirmed'
  final DateTime? createdAt;

  factory InterviewSlot.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InterviewSlot.fromMap(data, doc.id);
  }

  factory InterviewSlot.fromMap(Map<String, dynamic> map, String id) {
    final rawSlots = map['slots'] as List<dynamic>? ?? [];
    final parsedSlots = rawSlots.map((e) {
      if (e is Timestamp) return e.toDate();
      if (e is String) return DateTime.parse(e);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }).toList();

    DateTime? parsedSelectedSlot;
    if (map['selectedSlot'] != null) {
      final rawSelected = map['selectedSlot'];
      if (rawSelected is Timestamp) {
        parsedSelectedSlot = rawSelected.toDate();
      } else if (rawSelected is String) {
        parsedSelectedSlot = DateTime.parse(rawSelected);
      }
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      final rawCreated = map['createdAt'];
      if (rawCreated is Timestamp) {
        parsedCreatedAt = rawCreated.toDate();
      } else if (rawCreated is String) {
        parsedCreatedAt = DateTime.parse(rawCreated);
      }
    }

    return InterviewSlot(
      id: id,
      proposedBy: map['proposedBy'] as String? ?? '',
      slots: parsedSlots,
      selectedSlot: parsedSelectedSlot,
      status: map['status'] as String? ?? 'pending',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proposedBy': proposedBy,
      'slots': slots.map((d) => Timestamp.fromDate(d)).toList(),
      'selectedSlot': selectedSlot != null ? Timestamp.fromDate(selectedSlot!) : null,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  InterviewSlot copyWith({
    String? id,
    String? proposedBy,
    List<DateTime>? slots,
    DateTime? selectedSlot,
    String? status,
    DateTime? createdAt,
  }) {
    return InterviewSlot(
      id: id ?? this.id,
      proposedBy: proposedBy ?? this.proposedBy,
      slots: slots ?? this.slots,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
