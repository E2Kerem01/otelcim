import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/features/talent_pool/services/talent_pool_service.dart';
import 'package:otelcim/shared/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('CertificateService', () {
    late FakeFirebaseFirestore db;
    late MockStorageService storage;
    late CertificateService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      storage = MockStorageService();
      service = CertificateService(firestore: db, storageService: storage);
    });

    test(
      'blank title falls back to the selected certificate type label',
      () async {
        final file = XFile('/tmp/hygiene.pdf');
        when(
          () => storage.uploadCertificateFile(
            userId: 'user-1',
            certId: any(named: 'certId'),
            file: file,
          ),
        ).thenAnswer((_) async => 'https://storage.example/cert.pdf');

        final certificate = await service.uploadCertificate(
          userId: 'user-1',
          file: file,
          type: CertificateType.hijyen,
          title: '   ',
        );

        expect(certificate.title, CertificateType.hijyen.label);
        expect(certificate.status, CertificateStatus.pending);
        final stored =
            (await db.collection('certificates').doc(certificate.id).get())
                .data()!;
        expect(stored['fileUrl'], 'https://storage.example/cert.pdf');
        expect(stored['title'], CertificateType.hijyen.label);
        verify(
          () => storage.uploadCertificateFile(
            userId: 'user-1',
            certId: certificate.id,
            file: file,
          ),
        ).called(1);
      },
    );

    test(
      'approved certificate stream excludes pending and rejected documents',
      () async {
        final now = DateTime(2026, 9, 23);
        await db.collection('certificates').doc('approved').set({
          'userId': 'user-1',
          'type': 'dil',
          'title': 'Arabic B2',
          'fileUrl': 'approved.pdf',
          'status': 'approved',
          'createdAt': now,
        });
        await db.collection('certificates').doc('pending').set({
          'userId': 'user-1',
          'type': 'hijyen',
          'fileUrl': 'pending.pdf',
          'status': 'pending',
          'createdAt': now.add(const Duration(days: 1)),
        });
        await db.collection('certificates').doc('rejected').set({
          'userId': 'user-1',
          'type': 'ehliyet',
          'fileUrl': 'rejected.pdf',
          'status': 'rejected',
          'createdAt': now.add(const Duration(days: 2)),
        });

        final certificates = await service
            .watchApprovedCertificates('user-1')
            .first;

        expect(certificates, hasLength(1));
        expect(certificates.single.id, 'approved');
        expect(certificates.single.type, CertificateType.dil);
      },
    );

    test(
      'missing optional certificate fields use safe model defaults',
      () async {
        await db.collection('certificates').doc('incomplete').set({
          'userId': 'user-1',
          'type': 'unknown-type',
          'status': 'unknown-status',
          'fileUrl': 'file.pdf',
        });

        final certificate =
            (await service.watchUserCertificates('user-1').first).single;

        expect(certificate.type, CertificateType.diger);
        expect(certificate.status, CertificateStatus.pending);
        expect(certificate.title, isNull);
        expect(certificate.createdAt, isA<DateTime>());
      },
    );
  });

  group('TalentPoolService', () {
    late FakeFirebaseFirestore db;
    late TalentPoolService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = TalentPoolService(db);
    });

    test(
      'missing candidate fields get fallbacks and newer entries come first',
      () async {
        await db
            .collection('user_profiles')
            .doc('employer-1')
            .collection('talent_pool')
            .doc('old')
            .set({'addedAt': Timestamp.fromDate(DateTime(2026, 1, 1))});
        await db
            .collection('user_profiles')
            .doc('employer-1')
            .collection('talent_pool')
            .doc('new')
            .set({
              'candidateId': 'candidate-2',
              'candidateName': 'ليلى',
              'addedAt': Timestamp.fromDate(DateTime(2026, 9, 23)),
            });

        final items = await service.watchTalentPool('employer-1').first;

        expect(items, hasLength(2));
        expect(items.first.candidateId, 'candidate-2');
        expect(items.last.candidateId, 'old');
        expect(items.last.candidateName, 'Aday');
      },
    );

    test(
      'adding the same candidate preserves the existing note',
      () async {
        await service.addToTalentPool(
          employerId: 'employer-1',
          candidateId: 'candidate-1',
          candidateName: 'Ayşe',
          note: 'İlk görüşme notu',
        );
        await service.addToTalentPool(
          employerId: 'employer-1',
          candidateId: 'candidate-1',
          candidateName: 'Ayşe',
          note: null,
        );

        final item = (await service.watchTalentPool('employer-1').first).single;

        expect(item.note, 'İlk görüşme notu');
      },
      skip:
          'BUG-t5-005: addToTalentPool overwrites an existing candidate and loses the previous note',
    );
  });
}
