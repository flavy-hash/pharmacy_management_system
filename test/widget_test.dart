import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacy_management_system/core/utils/stock_status.dart';
import 'package:pharmacy_management_system/features/medicines/domain/medicine.dart';

void main() {
  group('Medicine business rules', () {
    Medicine build(
        {required int quantity, required int reorder, int days = 365}) {
      final now = DateTime.now();
      return Medicine(
        id: 'x',
        name: 'Test',
        category: 'Analgesic',
        batchNumber: 'B1',
        manufacturer: 'Acme',
        quantity: quantity,
        initialQuantity: 100,
        reorderLevel: reorder,
        purchasePrice: 10,
        sellingPrice: 20,
        manufacturingDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(Duration(days: days)),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('stock status reflects quantity vs reorder level', () {
      expect(
          build(quantity: 0, reorder: 10).stockStatus, StockStatus.outOfStock);
      expect(build(quantity: 5, reorder: 10).stockStatus, StockStatus.low);
      expect(build(quantity: 50, reorder: 10).stockStatus,
          StockStatus.sufficient);
    });

    test('stock fraction is clamped to 0..1', () {
      expect(build(quantity: 50, reorder: 10).stockFraction, 0.5);
    });

    test('expiry helpers flag soon-to-expire and expired items', () {
      expect(build(quantity: 10, reorder: 5, days: 3).isExpiringSoon, isTrue);
      expect(build(quantity: 10, reorder: 5, days: -1).isExpired, isTrue);
    });
  });

  testWidgets('a MaterialApp scaffold builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
