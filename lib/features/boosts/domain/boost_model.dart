import 'package:cloud_firestore/cloud_firestore.dart';

enum BoostDurationType { days7, days14, days30 }

enum BoostStatus { active, expired, cancelled }

class Boost {
  final String id;
  final String listingId;
  final String userId;
  final BoostDurationType durationType;
  final int durationDays;
  final double price;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final String platform;
  final String transactionId;
  final BoostStatus status;

  const Boost({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.durationType,
    required this.durationDays,
    required this.price,
    this.purchasedAt,
    this.expiresAt,
    required this.platform,
    required this.transactionId,
    this.status = BoostStatus.active,
  });

  factory Boost.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    // Parse durationType
    BoostDurationType parsedDurationType;
    final durationTypeStr = data['durationType'] as String? ?? '7';
    switch (durationTypeStr) {
      case '14':
        parsedDurationType = BoostDurationType.days14;
        break;
      case '30':
        parsedDurationType = BoostDurationType.days30;
        break;
      case '7':
      default:
        parsedDurationType = BoostDurationType.days7;
        break;
    }

    // Parse status
    BoostStatus parsedStatus;
    final statusStr = data['status'] as String? ?? 'active';
    switch (statusStr) {
      case 'expired':
        parsedStatus = BoostStatus.expired;
        break;
      case 'cancelled':
        parsedStatus = BoostStatus.cancelled;
        break;
      case 'active':
      default:
        parsedStatus = BoostStatus.active;
        break;
    }

    return Boost(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      durationType: parsedDurationType,
      durationDays: data['durationDays'] as int? ?? 7,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      platform: data['platform'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toMap() {
    // Convert durationType enum to string
    String durationTypeStr;
    switch (durationType) {
      case BoostDurationType.days7:
        durationTypeStr = '7';
        break;
      case BoostDurationType.days14:
        durationTypeStr = '14';
        break;
      case BoostDurationType.days30:
        durationTypeStr = '30';
        break;
    }

    // Convert status enum to string
    String statusStr;
    switch (status) {
      case BoostStatus.active:
        statusStr = 'active';
        break;
      case BoostStatus.expired:
        statusStr = 'expired';
        break;
      case BoostStatus.cancelled:
        statusStr = 'cancelled';
        break;
    }

    return {
      'listingId': listingId,
      'userId': userId,
      'durationType': durationTypeStr,
      'durationDays': durationDays,
      'price': price,
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'platform': platform,
      'transactionId': transactionId,
      'status': statusStr,
    };
  }
}
