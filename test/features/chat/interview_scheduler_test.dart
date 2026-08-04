import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/chat/domain/interview_slot_model.dart';
import 'package:otelcim/shared/services/chat_service.dart';

void main() {
  group('InterviewSlot Model Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime.now();
      final slot1 = now.add(const Duration(days: 1));
      final slot2 = now.add(const Duration(days: 2));

      final original = InterviewSlot(
        id: 'slot_123',
        proposedBy: 'employer_1',
        slots: [slot1, slot2],
        selectedSlot: slot1,
        status: 'confirmed',
        createdAt: now,
      );

      final map = original.toMap();
      final parsed = InterviewSlot.fromMap(map, 'slot_123');

      expect(parsed.id, equals('slot_123'));
      expect(parsed.proposedBy, equals('employer_1'));
      expect(parsed.slots.length, equals(2));
      expect(parsed.status, equals('confirmed'));
      expect(parsed.selectedSlot, isNotNull);
    });
  });

  group('ChatService Interview Slot Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late ChatService chatService;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      chatService = ChatService(fakeDb);
    });

    test('proposeInterviewSlots creates document in conversations subcollection', () async {
      const convId = 'conv_100';
      const employerId = 'emp_1';
      final slotDates = [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 2)),
      ];

      final slotId = await chatService.proposeInterviewSlots(
        conversationId: convId,
        proposedBy: employerId,
        slots: slotDates,
      );

      expect(slotId, isNotEmpty);

      final slotsStream = await chatService.watchInterviewSlots(convId).first;
      expect(slotsStream.length, equals(1));

      final firstSlot = slotsStream.first;
      expect(firstSlot.id, equals(slotId));
      expect(firstSlot.proposedBy, equals(employerId));
      expect(firstSlot.slots.length, equals(2));
      expect(firstSlot.status, equals('pending'));
      expect(firstSlot.selectedSlot, isNull);
    });

    test('confirmInterviewSlot updates selectedSlot and status to confirmed', () async {
      const convId = 'conv_200';
      const employerId = 'emp_1';
      final slot1 = DateTime.now().add(const Duration(days: 1));
      final slot2 = DateTime.now().add(const Duration(days: 2));

      final slotId = await chatService.proposeInterviewSlots(
        conversationId: convId,
        proposedBy: employerId,
        slots: [slot1, slot2],
      );

      await chatService.confirmInterviewSlot(
        conversationId: convId,
        slotId: slotId,
        selectedSlot: slot1,
      );

      final updatedSlots = await chatService.watchInterviewSlots(convId).first;
      expect(updatedSlots.length, equals(1));

      final confirmed = updatedSlots.first;
      expect(confirmed.status, equals('confirmed'));
      expect(confirmed.selectedSlot, isNotNull);
    });
  });
}
