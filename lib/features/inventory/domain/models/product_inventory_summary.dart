import 'product_variant.dart';

enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
  trackingDisabled;

  // Backward compatibility alias for earlier code
  static const StockStatus healthy = StockStatus.inStock;
}

class ProductInventorySummary {
  final String productId;
  final int variantCount;
  final int availableQty;
  final int committedQty;
  final int damagedQty;
  final int? lowStockThreshold;
  final bool trackStockLevels;
  final StockStatus stockStatus;
  final List<ProductVariant> variants;

  const ProductInventorySummary({
    required this.productId,
    required this.variantCount,
    required this.availableQty,
    required this.committedQty,
    this.damagedQty = 0,
    this.lowStockThreshold,
    this.trackStockLevels = true,
    required this.stockStatus,
    this.variants = const [],
  });

  String get stockStatusLabel {
    switch (stockStatus) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.trackingDisabled:
        return 'Tracking Disabled';
    }
  }

  static StockStatus calculateStockStatus({
    required int availableQty,
    int? lowStockThreshold,
    bool trackStockLevels = true,
  }) {
    if (!trackStockLevels) {
      return StockStatus.trackingDisabled;
    }
    if (availableQty <= 0) {
      return StockStatus.outOfStock;
    }
    if (lowStockThreshold != null && availableQty <= lowStockThreshold) {
      return StockStatus.lowStock;
    }
    return StockStatus.inStock;
  }
}
