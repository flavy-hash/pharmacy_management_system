import '../../../core/constants/app_constants.dart';

/// A single line in a sale (one medicine, a quantity and its price).
class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String saleId;
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  SaleItem copyWith({int? quantity}) => SaleItem(
        id: id,
        saleId: saleId,
        medicineId: medicineId,
        medicineName: medicineName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'sale_id': saleId,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };

  factory SaleItem.fromMap(Map<String, Object?> map) => SaleItem(
        id: map['id'] as String,
        saleId: map['sale_id'] as String,
        medicineId: map['medicine_id'] as String,
        medicineName: map['medicine_name'] as String,
        quantity: (map['quantity'] as num).toInt(),
        unitPrice: (map['unit_price'] as num).toDouble(),
      );
}

/// A completed sales transaction containing one or more [SaleItem]s.
class Sale {
  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentReference,
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String invoiceNumber;
  final String customerName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final String paymentReference;
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;
  final List<SaleItem> items;

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  Sale copyWith({List<SaleItem>? items}) => Sale(
        id: id,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        cashierId: cashierId,
        cashierName: cashierName,
        createdAt: createdAt,
        items: items ?? this.items,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'customer_name': customerName,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod.storageValue,
        'payment_reference': paymentReference,
        'cashier_id': cashierId,
        'cashier_name': cashierName,
        'created_at': createdAt.toIso8601String(),
      };

  factory Sale.fromMap(Map<String, Object?> map,
          {List<SaleItem> items = const []}) =>
      Sale(
        id: map['id'] as String,
        invoiceNumber: map['invoice_number'] as String,
        customerName: map['customer_name'] as String? ?? '',
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num).toDouble(),
        paymentMethod:
            PaymentMethodX.fromStorage(map['payment_method'] as String),
        paymentReference: map['payment_reference'] as String? ?? '',
        cashierId: map['cashier_id'] as String? ?? '',
        cashierName: map['cashier_name'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        items: items,
      );
}

/// A medicine added to the in-progress cart on the POS screen.
class CartLine {
  CartLine({
    required this.medicineId,
    required this.medicineName,
    required this.unitPrice,
    required this.availableStock,
    this.quantity = 1,
  });

  final String medicineId;
  final String medicineName;
  final double unitPrice;
  final int availableStock;
  int quantity;

  double get subtotal => quantity * unitPrice;
}
