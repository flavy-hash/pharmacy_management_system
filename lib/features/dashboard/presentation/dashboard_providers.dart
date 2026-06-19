import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../sales/presentation/sales_providers.dart';

/// Revenue for a single calendar day, used by the dashboard bar chart.
class DailySales {
  const DailySales({required this.day, required this.total});
  final DateTime day;
  final double total;
}

/// Daily revenue for the trailing 7 days (oldest first).
final weeklySalesProvider = FutureProvider<List<DailySales>>((ref) async {
  // Re-run when a new sale is recorded.
  ref.watch(recentSalesProvider);

  final repo = ref.watch(salesRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final end = today.add(const Duration(days: 1));

  final sales = await repo.getInRange(start, end);

  final buckets = <DateTime, double>{
    for (int i = 0; i < 7; i++)
      start.add(Duration(days: i)): 0.0,
  };
  for (final sale in sales) {
    final key = DateTime(
        sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
    buckets[key] = (buckets[key] ?? 0) + sale.total;
  }

  return buckets.entries
      .map((e) => DailySales(day: e.key, total: e.value))
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));
});

/// Revenue recorded today.
final todaysRevenueProvider = FutureProvider<double>((ref) async {
  ref.watch(recentSalesProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return repo.totalRevenue(start: start, end: start.add(const Duration(days: 1)));
});
