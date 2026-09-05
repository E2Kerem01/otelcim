import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/storage_service.dart';
import '../domain/certificate_model.dart';

final certificateServiceProvider = Provider<CertificateService>((ref) {
  return CertificateService(
    firestore: FirebaseFirestore.instance,
    storageService: ref.watch(storageServiceProvider),
  );
});

final userCertificatesProvider =
    StreamProvider.family.autoDispose<List<Certificate>, String>((ref, userId) {
  return ref.watch(certificateServiceProvider).watchUserCertificates(userId);
});

final userApprovedCertificatesProvider =
    StreamProvider.family.autoDispose<List<Certificate>, String>((ref, userId) {
  return ref.watch(certificateServiceProvider).watchApprovedCertificates(userId);
});

final pendingCertificatesProvider =
    StreamProvider.autoDispose<List<Certificate>>((ref) {
  return ref.watch(certificateServiceProvider).watchPendingCertificates();
});

class CertificateService {
  CertificateService({
    FirebaseFirestore? firestore,
    required StorageService storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        // ignore: prefer_initializing_formals, a private field can't be a named formal
        _storageService = storageService;

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _certificatesRef =>
      _firestore.collection('certificates');

  /// Uploads a new certificate for a jobseeker.
  Future<Certificate> uploadCertificate({
    required String userId,
    String? userName,
    String? userEmail,
    required XFile file,
    required CertificateType type,
    String? title,
  }) async {
    final docRef = _certificatesRef.doc();
    final certId = docRef.id;

    final fileUrl = await _storageService.uploadCertificateFile(
      userId: userId,
      certId: certId,
      file: file,
    );

    final certificate = Certificate(
      id: certId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: type,
      title: title?.trim().isNotEmpty == true ? title!.trim() : type.label,
      fileUrl: fileUrl,
      status: CertificateStatus.pending,
      createdAt: DateTime.now(),
    );

    await docRef.set(certificate.toMap());
    return certificate;
  }

  /// Watch user's certificates (all statuses).
  Stream<List<Certificate>> watchUserCertificates(String userId) {
    return _certificatesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Certificate.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Watch approved certificates for a user.
  Stream<List<Certificate>> watchApprovedCertificates(String userId) {
    return _certificatesRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: CertificateStatus.approved.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Certificate.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Watch all pending certificates (for admin review).
  Stream<List<Certificate>> watchPendingCertificates() {
    return _certificatesRef
        .where('status', isEqualTo: CertificateStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Certificate.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Approve a certificate.
  Future<void> approveCertificate({
    required String certId,
    required String adminId,
  }) async {
    await _certificatesRef.doc(certId).update({
      'status': CertificateStatus.approved.name,
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a certificate with a reason.
  Future<void> rejectCertificate({
    required String certId,
    required String adminId,
    required String reason,
  }) async {
    await _certificatesRef.doc(certId).update({
      'status': CertificateStatus.rejected.name,
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  /// Delete a certificate by ID.
  Future<void> deleteCertificate({
    required String certId,
  }) async {
    await _certificatesRef.doc(certId).delete();
  }
}
