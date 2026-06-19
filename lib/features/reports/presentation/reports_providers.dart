import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../sales/presentation/sales_providers.dart';

enum ReportPeriod { daily, weekly, monthly }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.daily => 'Today',
        ReportPeriod.weekly => 'This Week',
        ReportPeriod.monthly => 'This Month',
      };

  /// Inclusive start / exclusive end for the period relative to [now].
  (DateTime, DateTime) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      ReportPeriod.daily => (today, today.add(const Duration(days: 1))),
      ReportPeriod.weekly => (
          today.subtract(Duration(days: today.weekday - 1)),
          today.add(const Duration(days: 1)),
        ),
      ReportPeriod.monthly => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
        ),
    };
  }
}

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.daily);

/// Aggregated figures for a sales report over the selected period.
class SalesReport {
  const SalesReport({
    required this.transactionCount,
    required this.unitsSold,
    required this.revenue,
    required this.byPaymentMethod,
    required this.topItems,
  });

  final int transactionCount;
  final int unitsSold;
  final double revenue;
  final Map<PaymentMethod, double> byPaymentMethod;
  final List<({String name, int quantity, double revenue})> topItems;
}

final salesReportProvider = FutureProvider<SalesReport>((ref) async {
  ref.watch(recentSalesProvider); // refresh after a new sale
  final period = ref.watch(reportPeriodProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final (start, end) = period.range(DateTime.now());

  final sales = await repo.getInRange(start, end, withItems: true);

  final byMethod = <PaymentMethod, double>{};
  final itemAgg = <String, ({int qty, double rev})>{};
  var units = 0;
  var revenue = 0.0;

  for (final sale in sales) {
    revenue += sale.total;
    byMethod[sale.paymentMethod] =
        (byMethod[sale.paymentMethod] ?? 0) + sale.total;
    for (final item in sale.items) {
      units += item.quantity;
      final prev = itemAgg[item.medicineName] ?? (qty: 0, rev: 0.0);
      itemAgg[item.medicineName] =
          (qty: prev.qty + item.quantity, rev: prev.rev + item.subtotal);
    }
  }

  final top = itemAgg.entries
      .map((e) => (name: e.key, quantity: e.value.qty, revenue: e.value.rev))
      .toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));

  return SalesReport(
    transactionCount: sales.length,
    unitsSold: units,
    revenue: revenue,
    byPaymentMethod: byMethod,
    topItems: top.take(5).toList(),
  );
});
