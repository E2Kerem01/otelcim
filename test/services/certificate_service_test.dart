import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/profile/domain/certificate_model.dart';
import 'package:otelcim/features/profile/services/certificate_service.dart';
import 'package:otelcim/shared/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('Certificate model tests', () {
    test('Certificate serialization and deserialization', () {
      final now = DateTime.now();
      final cert = Certificate(
        id: 'cert_1',
        userId: 'user_123',
        userName: 'Ahmet Yılmaz',
        userEmail: 'ahmet@example.com',
        type: CertificateType.hijyen,
        title: 'Hijyen Belgesi 2025',
        fileUrl: 'https://storage.example.com/cert.pdf',
        status: CertificateStatus.pending,
        createdAt: now,
      );

      final map = cert.toMap();
      expect(map['userId'], 'user_123');
      expect(map['type'], 'hijyen');
      expect(map['status'], 'pending');
      expect(map['title'], 'Hijyen Belgesi 2025');

      final parsed = Certificate.fromMap(map, 'cert_1');
      expect(parsed.id, 'cert_1');
      expect(parsed.userId, 'user_123');
      expect(parsed.type, CertificateType.hijyen);
      expect(parsed.status, CertificateStatus.pending);
      expect(parsed.isPending, isTrue);
      expect(parsed.isApproved, isFalse);
      expect(parsed.isRejected, isFalse);
    });

    test('CertificateType and CertificateStatus enum labels and fallback', () {
      expect(CertificateType.fromString('hijyen'), CertificateType.hijyen);
      expect(CertificateType.fromString('cankurtaran'), CertificateType.cankurtaran);
      expect(CertificateType.fromString('ehliyet'), CertificateType.ehliyet);
      expect(CertificateType.fromString('dil'), CertificateType.dil);
      expect(CertificateType.fromString('invalid'), CertificateType.diger);

      expect(CertificateStatus.fromString('approved'), CertificateStatus.approved);
      expect(CertificateStatus.fromString('rejected'), CertificateStatus.rejected);
      expect(CertificateStatus.fromString('unknown'), CertificateStatus.pending);

      expect(CertificateType.hijyen.label, 'Hijyen Belgesi');
      expect(CertificateStatus.approved.label, 'Onaylandı');
    });
  });

  group('CertificateService tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockStorageService mockStorageService;
    late CertificateService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorageService = MockStorageService();
      service = CertificateService(
        firestore: fakeFirestore,
        storageService: mockStorageService,
      );
    });

    test('watchUserCertificates returns certificates for user', () async {
      await fakeFirestore.collection('certificates').doc('cert_1').set({
        'userId': 'user_1',
        'type': 'hijyen',
        'fileUrl': 'http://test.com/file1.pdf',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });
      await fakeFirestore.collection('certificates').doc('cert_2').set({
        'userId': 'user_2',
        'type': 'cankurtaran',
        'fileUrl': 'http://test.com/file2.pdf',
        'status': 'approved',
        'createdAt': DateTime.now(),
      });

      final stream = service.watchUserCertificates('user_1');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.id, 'cert_1');
      expect(result.first.type, CertificateType.hijyen);
    });

    test('watchPendingCertificates returns pending certificates for admin', () async {
      await fakeFirestore.collection('certificates').doc('cert_1').set({
        'userId': 'user_1',
        'type': 'hijyen',
        'fileUrl': 'http://test.com/file1.pdf',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });
      await fakeFirestore.collection('certificates').doc('cert_2').set({
        'userId': 'user_2',
        'type': 'ehliyet',
        'fileUrl': 'http://test.com/file2.pdf',
        'status': 'approved',
        'createdAt': DateTime.now(),
      });

      final pending = await service.watchPendingCertificates().first;
      expect(pending.length, 1);
      expect(pending.first.id, 'cert_1');
    });

    test('approveCertificate updates status to approved', () async {
      await fakeFirestore.collection('certificates').doc('cert_1').set({
        'userId': 'user_1',
        'type': 'hijyen',
        'fileUrl': 'http://test.com/file1.pdf',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      await service.approveCertificate(certId: 'cert_1', adminId: 'admin_99');

      final doc = await fakeFirestore.collection('certificates').doc('cert_1').get();
      expect(doc.data()?['status'], 'approved');
      expect(doc.data()?['reviewedBy'], 'admin_99');
    });

    test('rejectCertificate updates status and sets rejectionReason', () async {
      await fakeFirestore.collection('certificates').doc('cert_1').set({
        'userId': 'user_1',
        'type': 'hijyen',
        'fileUrl': 'http://test.com/file1.pdf',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      await service.rejectCertificate(
        certId: 'cert_1',
        adminId: 'admin_99',
        reason: 'Belge okunamıyor',
      );

      final doc = await fakeFirestore.collection('certificates').doc('cert_1').get();
      expect(doc.data()?['status'], 'rejected');
      expect(doc.data()?['rejectionReason'], 'Belge okunamıyor');
    });

    test('deleteCertificate removes document', () async {
      await fakeFirestore.collection('certificates').doc('cert_1').set({
        'userId': 'user_1',
        'type': 'hijyen',
        'fileUrl': 'http://test.com/file1.pdf',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      await service.deleteCertificate(certId: 'cert_1');

      final doc = await fakeFirestore.collection('certificates').doc('cert_1').get();
      expect(doc.exists, isFalse);
    });
  });
}
