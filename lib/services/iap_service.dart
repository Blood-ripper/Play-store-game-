import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/app_config.dart';
import '../models/iap_product.dart';

/// Result handed back to the app after a purchase so it can grant currency /
/// VIP and update the UI.
class PurchaseResult {
  PurchaseResult(this.product, {this.success = true, this.error});
  final IapProduct product;
  final bool success;
  final String? error;
}

/// Wraps Google Play Billing via the `in_app_purchase` plugin.
///
/// With [AppConfig.billingEnabled] == false (emulator / pre-store), purchases
/// resolve instantly in a sandbox so the shop UI, frames and grants are fully
/// testable without a configured store.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  final StreamController<PurchaseResult> _results =
      StreamController<PurchaseResult>.broadcast();
  Stream<PurchaseResult> get purchaseResults => _results.stream;

  Map<String, ProductDetails> _storeDetails = <String, ProductDetails>{};

  /// Localized price for a product, or its fallback label.
  String priceFor(IapProduct p) =>
      _storeDetails[p.storeId]?.price ?? p.fallbackPrice;

  Future<void> init() async {
    if (!AppConfig.billingEnabled) return;
    final bool available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) =>
          _results.add(PurchaseResult(kIapProducts.first,
              success: false, error: e.toString())),
    );

    final ProductDetailsResponse resp = await _iap.queryProductDetails(
      kIapProducts.map((IapProduct p) => p.storeId).toSet(),
    );
    _storeDetails = <String, ProductDetails>{
      for (final ProductDetails d in resp.productDetails) d.id: d,
    };
  }

  Future<void> buy(IapProduct product) async {
    if (!AppConfig.billingEnabled) {
      // Sandbox grant for development.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _results.add(PurchaseResult(product));
      return;
    }
    final ProductDetails? details = _storeDetails[product.storeId];
    if (details == null) {
      _results.add(PurchaseResult(product,
          success: false, error: 'Product not found in store.'));
      return;
    }
    final PurchaseParam param = PurchaseParam(productDetails: details);
    if (product.kind == IapKind.coins ||
        product.kind == IapKind.gems ||
        product.kind == IapKind.bundle) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restorePurchases() async {
    if (!AppConfig.billingEnabled) return;
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails pd in purchases) {
      switch (pd.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final IapProduct product = kIapProducts.firstWhere(
            (IapProduct p) => p.storeId == pd.productID,
            orElse: () => kIapProducts.first,
          );
          // IMPORTANT: a Cloud Function should verify pd.verificationData
          // server-side before granting. See functions/index.js.
          _results.add(PurchaseResult(product));
          if (pd.pendingCompletePurchase) {
            _iap.completePurchase(pd);
          }
          break;
        case PurchaseStatus.error:
          _results.add(PurchaseResult(kIapProducts.first,
              success: false, error: pd.error?.message ?? 'Purchase failed.'));
          break;
        case PurchaseStatus.canceled:
          _results.add(PurchaseResult(kIapProducts.first,
              success: false, error: 'Purchase cancelled.'));
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _results.close();
  }
}
