import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseStatus { pending, completed, failed, refunded }

class BoostPurchase {
  final String id;
  final String userId;
  final String listingId;
  final String? boostId;
  final String durationType;
  final double price;
  final String platform;
  final String transactionId;
  final String productId;
  final String? purchaseToken;
  final String? verificationData;
  final PurchaseStatus status;
  final DateTime? purchasedAt;
  final DateTime? verifiedAt;

  const BoostPurchase({
    required this.id,
    required this.userId,
    required this.listingId,
    this.boostId,
    required this.durationType,
    required this.price,
    required this.platform,
    required this.transactionId,
    required this.productId,
    this.purchaseToken,
    this.verificationData,
    this.status = PurchaseStatus.pending,
    this.purchasedAt,
    this.verifiedAt,
  });

  factory BoostPurchase.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    // Parse status
    PurchaseStatus parsedStatus;
    final statusStr = data['status'] as String? ?? 'pending';
    switch (statusStr) {
      case 'completed':
        parsedStatus = PurchaseStatus.completed;
        break;
      case 'failed':
        parsedStatus = PurchaseStatus.failed;
        break;
      case 'refunded':
        parsedStatus = PurchaseStatus.refunded;
        break;
      case 'pending':
      default:
        parsedStatus = PurchaseStatus.pending;
        break;
    }

    return BoostPurchase(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      boostId: data['boostId'] as String?,
      durationType: data['durationType'] as String? ?? '7',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      platform: data['platform'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      purchaseToken: data['purchaseToken'] as String?,
      verificationData: data['verificationData'] as String?,
      status: parsedStatus,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convert status enum to string
    String statusStr;
    switch (status) {
      case PurchaseStatus.pending:
        statusStr = 'pending';
        break;
      case PurchaseStatus.completed:
        statusStr = 'completed';
        break;
      case PurchaseStatus.failed:
        statusStr = 'failed';
        break;
      case PurchaseStatus.refunded:
        statusStr = 'refunded';
        break;
    }

    return {
      'userId': userId,
      'listingId': listingId,
      'boostId': boostId,
      'durationType': durationType,
      'price': price,
      'platform': platform,
      'transactionId': transactionId,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'verificationData': verificationData,
      'status': statusStr,
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : FieldValue.serverTimestamp(),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}
