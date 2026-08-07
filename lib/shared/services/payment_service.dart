import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PaymentService extends ChangeNotifier {
  PaymentService(this._iap) {
    // in_app_purchase has no Flutter Web platform implementation (only
    // in_app_purchase_android / in_app_purchase_storekit are registered in
    // pubspec.yaml, both mobile-only). Touching InAppPurchase.instance or
    // any of its methods on web either throws or hangs waiting on a
    // platform channel that will never respond - this froze the boost
    // purchase screen on web (isLoading never resets, spinner never
    // clears). Skip initialization entirely on web; isAvailable stays
    // false and the UI falls back to its "store unavailable" path.
    if (_iap != null) {
      _initialize();
    }
  }

  final InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isLoading = false;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isLoading => _isLoading;

  static const Set<String> _productIds = {
    'boost_7_days',
    'boost_14_days',
    'boost_30_days',
  };

  Future<void> _initialize() async {
    final iap = _iap;
    if (iap == null) return;
    try {
      _isAvailable = await iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('IAP not available on this device');
        return;
      }

      _purchaseSub = iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) {
          debugPrint('IAP purchase stream error: $error');
        },
      );

      await fetchProducts();
    } catch (e) {
      debugPrint('IAP initialization error: $e');
      _isAvailable = false;
    }
    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        debugPrint('Purchase successful: ${purchase.productID}');
        _purchases.add(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        _iap!.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    if (!_isAvailable) {
      debugPrint('IAP not available, cannot fetch products');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _iap!.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('IAP product query error: ${response.error}');
        _products = [];
      } else if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
        _products = response.productDetails;
      } else {
        _products = response.productDetails;
        debugPrint('IAP products fetched: ${_products.length}');
      }
    } catch (e) {
      debugPrint('IAP fetch products error: $e');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('IAP not available, cannot purchase');
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _iap!.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('IAP purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('IAP not available, cannot restore purchases');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _iap!.restorePurchases();
      debugPrint('IAP purchases restored');
    } catch (e) {
      debugPrint('IAP restore purchases error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      debugPrint('IAP product not found: $productId');
      return null;
    }
  }

  bool verifyPurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      return true;
    }
    return false;
  }

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap?.purchaseStream ?? const Stream.empty();

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

final paymentServiceProvider = ChangeNotifierProvider<PaymentService>(
  (ref) => PaymentService(kIsWeb ? null : InAppPurchase.instance),
);

final productsProvider = Provider<List<ProductDetails>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.products;
});

final purchaseStreamProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.purchaseStream;
});
