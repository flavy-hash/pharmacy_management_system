import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/sale.dart';

/// Manages the in-progress shopping cart on the POS screen.
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  double get subtotal => state.fold(0.0, (s, l) => s + l.subtotal);
  int get itemCount => state.fold(0, (s, l) => s + l.quantity);
  bool get isEmpty => state.isEmpty;

  void add({
    required String medicineId,
    required String medicineName,
    required double unitPrice,
    required int availableStock,
  }) {
    final existing =
        state.where((l) => l.medicineId == medicineId).firstOrNull;
    if (existing != null) {
      if (existing.quantity < availableStock) {
        setQuantity(medicineId, existing.quantity + 1);
      }
      return;
    }
    state = [
      ...state,
      CartLine(
        medicineId: medicineId,
        medicineName: medicineName,
        unitPrice: unitPrice,
        availableStock: availableStock,
      ),
    ];
  }

  void setQuantity(String medicineId, int quantity) {
    state = [
      for (final line in state)
        if (line.medicineId == medicineId)
          CartLine(
            medicineId: line.medicineId,
            medicineName: line.medicineName,
            unitPrice: line.unitPrice,
            availableStock: line.availableStock,
            quantity: quantity.clamp(1, line.availableStock),
          )
        else
          line,
    ];
  }

  void remove(String medicineId) {
    state = state.where((l) => l.medicineId != medicineId).toList();
  }

  void clear() => state = const [];
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartLine>>((ref) => CartNotifier());

/// The N most recent sales, shown on the dashboard and sales history.
final recentSalesProvider = FutureProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).getRecent(limit: 50);
});

/// Lifetime revenue across all recorded sales.
final totalRevenueProvider = FutureProvider<double>((ref) {
  return ref.watch(salesRepositoryProvider).totalRevenue();
});
