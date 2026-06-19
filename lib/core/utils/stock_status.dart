import 'package:flutter/material.dart';

/// Classification of a medicine's stock level, used to drive colour coding
/// across the dashboard and inventory screens.
enum StockStatus { sufficient, low, outOfStock }

extension StockStatusX on StockStatus {
  String get label => switch (this) {
        StockStatus.sufficient => 'In Stock',
        StockStatus.low => 'Low Stock',
        StockStatus.outOfStock => 'Out of Stock',
      };

  Color get color => switch (this) {
        StockStatus.sufficient => const Color(0xFF2E7D32), // green
        StockStatus.low => const Color(0xFFF9A825), // amber
        StockStatus.outOfStock => const Color(0xFFC62828), // red
      };

  IconData get icon => switch (this) {
        StockStatus.sufficient => Icons.check_circle_outline,
        StockStatus.low => Icons.warning_amber_outlined,
        StockStatus.outOfStock => Icons.remove_shopping_cart_outlined,
      };
}

/// Derives stock status from the current quantity and reorder threshold.
StockStatus stockStatusOf({required int quantity, required int reorderLevel}) {
  if (quantity <= 0) return StockStatus.outOfStock;
  if (quantity <= reorderLevel) return StockStatus.low;
  return StockStatus.sufficient;
}
