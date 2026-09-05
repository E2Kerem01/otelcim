import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/payment_service.dart';
import '../../listings/domain/listing_model.dart';
import '../services/boost_service.dart';
import 'widgets/boost_badge.dart';

class BoostPurchaseScreen extends ConsumerStatefulWidget {
  final String listingId;

  const BoostPurchaseScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<BoostPurchaseScreen> createState() => _BoostPurchaseScreenState();
}

class _BoostPurchaseScreenState extends ConsumerState<BoostPurchaseScreen> {
  String _selectedProductId = 'boost_14_days';
  bool _isProcessing = false;
  bool _isRedeemingFreeBoost = false;

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

  Future<void> _handlePurchase(Listing listing, List<ProductDetails> products) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce giriş yapın.')),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final boostService = ref.read(boostServiceProvider);

      ProductDetails? product;
      try {
        product = products.firstWhere((p) => p.id == _selectedProductId);
      } catch (_) {
        product = null;
      }

      bool purchaseSuccess = false;
      String transactionId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      String? purchaseToken;
      String? verificationData;
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'app_store' : 'google_play';

      if (paymentService.isAvailable && product != null) {
        final purchaseDetails = await paymentService.purchaseProduct(product);
        purchaseSuccess = purchaseDetails != null;
        if (purchaseDetails != null) {
          transactionId = purchaseDetails.purchaseID ?? transactionId;
          final receipt = purchaseDetails.verificationData.serverVerificationData;
          purchaseToken = platform == 'google_play' ? receipt : null;
          verificationData = platform == 'app_store' ? receipt : null;
        }
      } else if (kDebugMode) {
        // Fallback / Demo purchase flow ONLY in debug mode for testing.
        // Note: verifyAndProcessBoostPurchase requires a real store receipt
        // and will reject this with an error even in debug builds, since
        // there is no store-side verification to satisfy locally.
        await Future<void>.delayed(const Duration(milliseconds: 800));
        purchaseSuccess = true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satın alma mağazası şu an kullanılamıyor.')),
          );
        }
        return;
      }


      if (purchaseSuccess) {
        double price = 49.99;
        if (_selectedProductId == 'boost_14_days') price = 89.99;
        if (_selectedProductId == 'boost_30_days') price = 149.99;

        await boostService.processBoostPurchase(
          listingId: listing.id,
          userId: user.uid,
          productId: _selectedProductId,
          transactionId: transactionId,
          priceOverride: product != null ? _parsePrice(product.price) : price,
          purchaseToken: purchaseToken,
          verificationData: verificationData,
          platform: platform,
        );

        if (mounted) {
          // Invalidate listing providers so feeds update immediately
          ref.invalidate(listingServiceProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tebrikler! İlanınız başarıyla öne çıkarıldı.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satın alma işlemi tamamlanamadı veya iptal edildi.')),
          );
        }
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_BoostPurchaseScreenState._handlePurchase');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRedeemFreeBoost(String listingId) async {
    final user = ref.read(authServiceProvider).currentUser;
    final l10n = AppLocalizations.of(context);
    if (user == null) return;

    setState(() => _isRedeemingFreeBoost = true);
    try {
      final boostService = ref.read(boostServiceProvider);
      await boostService.redeemFreeBoost(listingId: listingId, userId: user.uid);

      if (mounted) {
        ref.invalidate(listingServiceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              l10n?.freeBoostRedeemedMessage ?? 'Ücretsiz boost uygulandı!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: '_BoostPurchaseScreenState._handleRedeemFreeBoost',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mapToFailure(error).message),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeemingFreeBoost = false);
      }
    }
  }

  double _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 49.99;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentService = ref.watch(paymentServiceProvider);
    final listingAsync = ref.watch(singleListingProvider(widget.listingId));
    final freeBoostCredits = ref.watch(currentUserProfileProvider).value?.freeBoostCredits ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Öne Çıkar'),
        centerTitle: true,
      ),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('İlan yüklenirken hata: $err')),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('İlan bulunamadı.'));
          }

          final isCurrentlyBoosted = BoostBadge.isBoostActive(listing);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Listing Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentlyBoosted) ...[
                              const SizedBox(width: 8),
                              const BoostBadge(isCompact: true),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${listing.location} · ${listing.salary}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (isCurrentlyBoosted && listing.boostExpiresAt != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bu ilan zaten öne çıkarılmıştır. Bitiş: ${listing.boostExpiresAt!.day}.${listing.boostExpiresAt!.month}.${listing.boostExpiresAt!.year}',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (freeBoostCredits > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: Colors.green.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n?.freeBoostBannerText(freeBoostCredits) ??
                                    '$freeBoostCredits ücretsiz boost hakkınız var',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isRedeemingFreeBoost || _isProcessing
                                ? null
                                : () => _handleRedeemFreeBoost(widget.listingId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: _isRedeemingFreeBoost
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n?.useFreeBoostAction ?? 'Ücretsiz Kullan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Benefits Header
                const Text(
                  'Neden Öne Çıkarmalısınız?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Benefits Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitItem(
                        icon: Icons.trending_up_rounded,
                        title: 'Üst Sıralarda Görünün',
                        subtitle: 'İlanınız tüm aramalarda ve kategorilerde en tepede yer alır.',
                      ),
                      const Divider(height: 20),
                      _buildBenefitItem(
                        icon: Icons.visibility_rounded,
                        title: '10 Kat Daha Fazla Etkileşim',
                        subtitle: 'Daha fazla adaya ulaşın ve hızlıca aradığınız elemanı bulun.',
                      ),
                      const Divider(height: 20),
                      _buildBenefitItem(
                        icon: Icons.stars_rounded,
                        title: 'Özel Görsel Rozet',
                        subtitle: 'İlan kartlarında dikkat çeken "Öne Çıkan" rozeti eklenir.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Package Selection Header
                const Text(
                  'Boost Paketini Seçin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (paymentService.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  RadioGroup<String>(
                    groupValue: _selectedProductId,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProductId = val);
                    },
                    child: Column(
                      children: [
                        _buildPackageOption(
                          productId: 'boost_7_days',
                          title: '7 Günlük Öne Çıkarma',
                          durationText: '7 Gün boyunca aktif',
                          priceText: _getFormattedPrice(paymentService.products, 'boost_7_days', '₺49,99'),
                          badgeText: null,
                        ),
                        const SizedBox(height: 12),
                        _buildPackageOption(
                          productId: 'boost_14_days',
                          title: '14 Günlük Öne Çıkarma',
                          durationText: '14 Gün boyunca aktif',
                          priceText: _getFormattedPrice(paymentService.products, 'boost_14_days', '₺89,99'),
                          badgeText: 'EN POPÜLER',
                          isPopular: true,
                        ),
                        const SizedBox(height: 12),
                        _buildPackageOption(
                          productId: 'boost_30_days',
                          title: '30 Günlük Öne Çıkarma',
                          durationText: '30 Gün boyunca aktif',
                          priceText: _getFormattedPrice(paymentService.products, 'boost_30_days', '₺149,99'),
                          badgeText: 'EN AVANTAJLI',
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handlePurchase(listing, paymentService.products),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch_rounded),
                              SizedBox(width: 8),
                              Text(
                                'Satın Al ve Öne Çıkar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Ödeme güvenli şekilde Google Play / App Store üzerinden tamamlanır.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getFormattedPrice(List<ProductDetails> products, String productId, String fallback) {
    try {
      final p = products.firstWhere((element) => element.id == productId);
      return p.price;
    } catch (_) {
      return fallback;
    }
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageOption({
    required String productId,
    required String title,
    required String durationText,
    required String priceText,
    String? badgeText,
    bool isPopular = false,
  }) {
    final isSelected = _selectedProductId == productId;

    return InkWell(
      onTap: () => setState(() => _selectedProductId = productId),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Radio<String>(
              value: productId,
              activeColor: Colors.amber.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? Colors.amber.shade900 : Colors.black87,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPopular ? Colors.orange.shade700 : Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durationText,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.amber.shade900 : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
