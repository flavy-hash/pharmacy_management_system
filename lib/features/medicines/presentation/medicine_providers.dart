import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/medicine_repository.dart';
import '../domain/medicine.dart';

/// Loads and caches the full medicine inventory, exposing mutation helpers
/// that refresh the list afterwards.
class MedicinesNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() => _repo.getAll();

  MedicineRepository get _repo => ref.read(medicineRepositoryProvider);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> add(Medicine medicine) async {
    await _repo.insert(medicine);
    await reload();
  }

  Future<void> edit(Medicine medicine) async {
    await _repo.update(medicine);
    await reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await reload();
  }
}

final medicinesProvider =
    AsyncNotifierProvider<MedicinesNotifier, List<Medicine>>(
  MedicinesNotifier.new,
);

/// Free-text search query for the inventory list.
final medicineSearchProvider = StateProvider<String>((ref) => '');

/// Optional category filter ('' = all).
final medicineCategoryFilterProvider = StateProvider<String>((ref) => '');

/// The inventory list after applying search + category filters.
final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final all = ref.watch(medicinesProvider).valueOrNull ?? const <Medicine>[];
  final query = ref.watch(medicineSearchProvider).trim().toLowerCase();
  final category = ref.watch(medicineCategoryFilterProvider);

  return all.where((m) {
    final matchesQuery = query.isEmpty ||
        m.name.toLowerCase().contains(query) ||
        m.batchNumber.toLowerCase().contains(query) ||
        m.manufacturer.toLowerCase().contains(query) ||
        m.category.toLowerCase().contains(query);
    final matchesCategory = category.isEmpty || m.category == category;
    return matchesQuery && matchesCategory;
  }).toList();
});

/// Aggregate inventory metrics for the dashboard and notification badges.
class InventoryStats {
  const InventoryStats({
    required this.totalMedicines,
    required this.totalUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.inventoryValue,
  });

  final int totalMedicines;
  final int totalUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double inventoryValue;
}

final inventoryStatsProvider = Provider<InventoryStats>((ref) {
  final all = ref.watch(medicinesProvider).valueOrNull ?? const <Medicine>[];
  return InventoryStats(
    totalMedicines: all.length,
    totalUnits: all.fold(0, (s, m) => s + m.quantity),
    lowStockCount: all.where((m) => m.isLowStock).length,
    outOfStockCount: all.where((m) => m.isOutOfStock).length,
    expiredCount: all.where((m) => m.isExpired).length,
    expiringSoonCount: all.where((m) => m.isExpiringSoon).length,
    inventoryValue: all.fold(0.0, (s, m) => s + m.inventoryValue),
  );
});
