import '../../../core/constants/app_constants.dart';
import '../../../core/utils/stock_status.dart';

/// A medicine/product held in the pharmacy inventory.
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.batchNumber,
    required this.manufacturer,
    required this.quantity,
    required this.initialQuantity,
    required this.reorderLevel,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String batchNumber;
  final String manufacturer;
  final int quantity;

  /// Baseline quantity used to compute the stock availability percentage.
  final int initialQuantity;

  /// Threshold at or below which the item is considered low stock.
  final int reorderLevel;
  final double purchasePrice;
  final double sellingPrice;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockStatus get stockStatus =>
      stockStatusOf(quantity: quantity, reorderLevel: reorderLevel);

  /// Availability as a 0..1 fraction of the baseline quantity.
  double get stockFraction {
    if (initialQuantity <= 0) return quantity > 0 ? 1 : 0;
    return (quantity / initialQuantity).clamp(0, 1);
  }

  int get daysToExpiry {
    final now = DateTime.now();
    return DateTime(expiryDate.year, expiryDate.month, expiryDate.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  bool get isExpired => daysToExpiry < 0;

  bool get isExpiringSoon =>
      !isExpired && daysToExpiry <= AppConstants.expiryWarningDays;

  bool get isLowStock => stockStatus == StockStatus.low;
  bool get isOutOfStock => stockStatus == StockStatus.outOfStock;

  /// Total cost value of the remaining stock at purchase price.
  double get inventoryValue => quantity * purchasePrice;

  Medicine copyWith({
    String? name,
    String? category,
    String? batchNumber,
    String? manufacturer,
    int? quantity,
    int? initialQuantity,
    int? reorderLevel,
    double? purchasePrice,
    double? sellingPrice,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      quantity: quantity ?? this.quantity,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'batch_number': batchNumber,
        'manufacturer': manufacturer,
        'quantity': quantity,
        'initial_quantity': initialQuantity,
        'reorder_level': reorderLevel,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'manufacturing_date': manufacturingDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Medicine.fromMap(Map<String, Object?> map) => Medicine(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        batchNumber: map['batch_number'] as String? ?? '',
        manufacturer: map['manufacturer'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        initialQuantity: (map['initial_quantity'] as num?)?.toInt() ?? 0,
        reorderLevel: (map['reorder_level'] as num?)?.toInt() ?? 0,
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
        manufacturingDate:
            DateTime.parse(map['manufacturing_date'] as String),
        expiryDate: DateTime.parse(map['expiry_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
