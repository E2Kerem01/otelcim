import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../error/error_reporter.dart';

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
      unawaited(_initialize());
    }
  }

  final InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  bool _isLoading = false;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isLoading => _isLoading;

  static const Set<String> _productIds = {
    'boost_7_days',
    'boost_14_days',
    'boost_30_days',
    'urgent_listing',
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
        onError: (Object error) {
          debugPrint('IAP purchase stream error: $error');
        },
      );

      await fetchProducts();
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'PaymentService._initialize');
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
        unawaited(_iap!.completePurchase(purchase));
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
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'PaymentService.fetchProducts');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Launches the platform purchase flow for [product] and waits for the
  /// store to report a terminal result for it via [purchaseStream].
  ///
  /// Returns the completed [PurchaseDetails] (which carries the real store
  /// transaction id and receipt/token in `verificationData`) on success, or
  /// `null` if the purchase was cancelled, failed, or timed out. Callers
  /// must forward `verificationData.serverVerificationData` to the backend
  /// for server-side verification — never fabricate a transaction id.
  Future<PurchaseDetails?> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('IAP not available, cannot purchase');
      return null;
    }

    final iap = _iap!;
    final completer = Completer<PurchaseDetails?>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID != product.id) continue;
        if (completer.isCompleted) continue;
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          completer.complete(purchase);
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          completer.complete(null);
        }
      }
    });

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final requestSent = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!requestSent) {
        return null;
      }

      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => null,
      );
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'PaymentService.purchaseProduct');
      return null;
    } finally {
      await subscription.cancel();
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
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'PaymentService.restorePurchases');
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
    unawaited(_purchaseSub?.cancel() ?? Future.value());
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
