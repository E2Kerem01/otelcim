import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/talent_pool/domain/talent_pool_item.dart';
import 'package:otelcim/features/talent_pool/services/talent_pool_service.dart';

void main() {
  group('TalentPoolItem domain model', () {
    test('toMap and fromDoc serialization work correctly', () {
      final now = DateTime.now();
      final item = TalentPoolItem(
        id: 'candidate_1',
        candidateId: 'candidate_1',
        candidateName: 'Ahmet Yılmaz',
        note: 'Resepsiyon 2026 adayı',
        conversationId: 'conv_123',
        addedAt: now,
      );

      final map = item.toMap();
      expect(map['candidateId'], 'candidate_1');
      expect(map['candidateName'], 'Ahmet Yılmaz');
      expect(map['note'], 'Resepsiyon 2026 adayı');
      expect(map['conversationId'], 'conv_123');
    });
  });

  group('TalentPoolService CRUD operations', () {
    late FakeFirebaseFirestore db;
    late TalentPoolService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = TalentPoolService(db);
    });

    test('adds candidate to employer talent pool and watches stream', () async {
      await service.addToTalentPool(
        employerId: 'emp_100',
        candidateId: 'cand_1',
        candidateName: 'Mehmet Demir',
        note: 'Garson adayı',
        conversationId: 'conv_999',
      );

      final isInPool = await service.isInTalentPool(
        employerId: 'emp_100',
        candidateId: 'cand_1',
      );
      expect(isInPool, isTrue);

      final items = await service.watchTalentPool('emp_100').first;
      expect(items, hasLength(1));
      expect(items.first.candidateName, 'Mehmet Demir');
      expect(items.first.note, 'Garson adayı');
      expect(items.first.conversationId, 'conv_999');
    });

    test('removes candidate from talent pool', () async {
      await service.addToTalentPool(
        employerId: 'emp_100',
        candidateId: 'cand_2',
        candidateName: 'Ayşe Kaya',
      );

      expect(
        await service.isInTalentPool(
          employerId: 'emp_100',
          candidateId: 'cand_2',
        ),
        isTrue,
      );

      await service.removeFromTalentPool(
        employerId: 'emp_100',
        candidateId: 'cand_2',
      );

      expect(
        await service.isInTalentPool(
          employerId: 'emp_100',
          candidateId: 'cand_2',
        ),
        isFalse,
      );

      final items = await service.watchTalentPool('emp_100').first;
      expect(items, isEmpty);
    });
  });
}
