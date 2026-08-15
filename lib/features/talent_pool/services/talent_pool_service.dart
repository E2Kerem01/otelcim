import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/talent_pool_item.dart';

class TalentPoolService {
  TalentPoolService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _talentPoolRef(String employerId) =>
      _db.collection('user_profiles').doc(employerId).collection('talent_pool');

  Future<void> addToTalentPool({
    required String employerId,
    required String candidateId,
    required String candidateName,
    String? note,
    String? conversationId,
  }) async {
    try {
      final item = TalentPoolItem(
        id: candidateId,
        candidateId: candidateId,
        candidateName: candidateName,
        note: note,
        conversationId: conversationId,
        addedAt: DateTime.now(),
      );
      await _talentPoolRef(employerId).doc(candidateId).set(item.toMap());
    } catch (e) {
      debugPrint('Error adding to talent pool: $e');
      rethrow;
    }
  }

  Future<void> removeFromTalentPool({
    required String employerId,
    required String candidateId,
  }) async {
    try {
      await _talentPoolRef(employerId).doc(candidateId).delete();
    } catch (e) {
      debugPrint('Error removing from talent pool: $e');
      rethrow;
    }
  }

  Future<bool> isInTalentPool({
    required String employerId,
    required String candidateId,
  }) async {
    try {
      final doc = await _talentPoolRef(employerId).doc(candidateId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking talent pool membership: $e');
      return false;
    }
  }

  Stream<List<TalentPoolItem>> watchTalentPool(String employerId) {
    return _talentPoolRef(employerId).snapshots().map((snap) {
      final items = snap.docs.map(TalentPoolItem.fromDoc).toList();
      items.sort((a, b) {
        final tA = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return items;
    }).handleError((Object error) {
      debugPrint('Error watching talent pool: $error');
      return <TalentPoolItem>[];
    });
  }
}

final talentPoolServiceProvider = Provider<TalentPoolService>(
  (ref) => TalentPoolService(FirebaseFirestore.instance),
);

final talentPoolStreamProvider =
    StreamProvider.family<List<TalentPoolItem>, String>((ref, employerId) {
  return ref.watch(talentPoolServiceProvider).watchTalentPool(employerId);
});
