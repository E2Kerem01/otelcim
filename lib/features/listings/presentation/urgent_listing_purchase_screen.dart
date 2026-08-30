import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/payment_service.dart';
import '../services/urgent_listing_service.dart';

/// Paid "acil ihtiyaç" purchase for a listing whose owner has already used
/// their one free urgent slot. The first urgent listing per account is free
/// (consumed server-side in grantReferralRewardOnListingCreated); this screen
/// is only reached for the 2nd urgent listing onwards.
class UrgentListingPurchaseScreen extends ConsumerStatefulWidget {
  const UrgentListingPurchaseScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<UrgentListingPurchaseScreen> createState() =>
      _UrgentListingPurchaseScreenState();
}

class _UrgentListingPurchaseScreenState
    extends ConsumerState<UrgentListingPurchaseScreen> {
  static const _fallbackPrice = '₺149,99';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(() async {
      final paymentService = ref.read(paymentServiceProvider);
      if (paymentService.products.isEmpty && !paymentService.isLoading) {
        await paymentService.fetchProducts();
      }
    }));
  }

  String _price(PaymentService paymentService) {
    try {
      return paymentService.products
          .firstWhere(
            (p) => p.id == UrgentListingService.urgentListingProductId,
          )
          .price;
    } catch (_) {
      return _fallbackPrice;
    }
  }

  Future<void> _handlePurchase() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      _snack('Lütfen önce giriş yapın.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final urgentService = ref.read(urgentListingServiceProvider);

      ProductDetails? product;
      try {
        product = paymentService.products.firstWhere(
          (p) => p.id == UrgentListingService.urgentListingProductId,
        );
      } catch (_) {
        product = null;
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'app_store'
          : 'google_play';

      var purchaseSuccess = false;
      String? purchaseToken;
      String? verificationData;

      if (paymentService.isAvailable && product != null) {
        final purchaseDetails = await paymentService.purchaseProduct(product);
        purchaseSuccess = purchaseDetails != null;
        if (purchaseDetails != null) {
          final receipt =
              purchaseDetails.verificationData.serverVerificationData;
          purchaseToken = platform == 'google_play' ? receipt : null;
          verificationData = platform == 'app_store' ? receipt : null;
        }
      } else {
        _snack('Satın alma mağazası şu an kullanılamıyor.');
        return;
      }

      if (!purchaseSuccess) {
        _snack('Satın alma tamamlanamadı veya iptal edildi.');
        return;
      }

      await urgentService.processUrgentListingPurchase(
        listingId: widget.listingId,
        productId: UrgentListingService.urgentListingProductId,
        purchaseToken: purchaseToken,
        verificationData: verificationData,
        platform: platform,
      );

      if (!mounted) return;
      ref.invalidate(listingServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: const Text(
            'İlanınız acil olarak işaretlendi.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      _leave();
    } catch (e) {
      _snack('İşlem sırasında bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my-listings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = ref.watch(paymentServiceProvider);
    final listingAsync = ref.watch(singleListingProvider(widget.listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Acil İlan')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('İlan yüklenirken hata: $err')),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('İlan bulunamadı.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${listing.location} · ${listing.salary}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.deepOrange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Ücretsiz acil ilan hakkınızı daha önce kullandınız',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acil ilanlar, bölgedeki adaylara anlık bildirim '
                        'gönderilir ve listede acil rozetiyle öne çıkar. '
                        'Bu ilanı acil yapmak için tek seferlik ücret alınır.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (paymentService.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Acil İlan (tek seferlik)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          _price(paymentService),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Satın Al ve Acil Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isProcessing ? null : _leave,
                    child: const Text('Şimdilik acil yapmadan devam et'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Ödeme güvenli şekilde Google Play / App Store üzerinden '
                    'tamamlanır.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
