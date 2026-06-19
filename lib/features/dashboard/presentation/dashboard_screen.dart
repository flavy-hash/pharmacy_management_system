import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../medicines/presentation/medicine_providers.dart';
import '../../notifications/presentation/alerts_screen.dart';
import '../../sales/domain/sale.dart';
import '../../sales/presentation/sales_providers.dart';
import 'dashboard_providers.dart';

/// The home dashboard: greeting, key metrics, weekly sales chart and recent
/// transactions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onSeeAllSales});

  /// Optional callback to jump to the sales history tab.
  final VoidCallback? onSeeAllSales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(inventoryStatsProvider);
    final revenue = ref.watch(totalRevenueProvider).valueOrNull ?? 0;
    final today = ref.watch(todaysRevenueProvider).valueOrNull ?? 0;
    final recent = ref.watch(recentSalesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
            icon: Badge(
              isLabelVisible: (stats.expiredCount +
                      stats.expiringSoonCount +
                      stats.lowStockCount +
                      stats.outOfStockCount) >
                  0,
              label: Text('${stats.expiredCount + stats.expiringSoonCount + stats.lowStockCount + stats.outOfStockCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(medicinesProvider.notifier).reload();
          ref.invalidate(recentSalesProvider);
          ref.invalidate(totalRevenueProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Hello, ${user?.fullName.split(' ').first ?? 'there'} 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              "Here's how your pharmacy is doing today.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.32,
              children: [
                StatCard(
                  title: 'Total Medicines',
                  value: '${stats.totalMedicines}',
                  subtitle: '${stats.totalUnits} units',
                  icon: Icons.medication_outlined,
                  color: const Color(0xFF00897B),
                ),
                StatCard(
                  title: "Today's Sales",
                  value: Formatters.compactMoney(today),
                  subtitle: 'Total: ${Formatters.compactMoney(revenue)}',
                  icon: Icons.point_of_sale_outlined,
                  color: const Color(0xFF3949AB),
                ),
                StatCard(
                  title: 'Low Stock',
                  value: '${stats.lowStockCount}',
                  subtitle: '${stats.outOfStockCount} out of stock',
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFF9A825),
                ),
                StatCard(
                  title: 'Expired',
                  value: '${stats.expiredCount}',
                  subtitle: '${stats.expiringSoonCount} expiring soon',
                  icon: Icons.event_busy_outlined,
                  color: const Color(0xFFC62828),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InventoryValueCard(value: stats.inventoryValue),
            const SizedBox(height: 20),
            Text('Sales — last 7 days',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const _WeeklySalesChart(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent transactions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (onSeeAllSales != null)
                  TextButton(
                      onPressed: onSeeAllSales, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 4),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No transactions yet.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...recent.take(5).map((s) => _RecentSaleRow(sale: s)),
          ],
        ),
      ),
    );
  }
}

class _InventoryValueCard extends StatelessWidget {
  const _InventoryValueCard({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.onPrimary, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventory value (at cost)',
                    style: TextStyle(
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(Formatters.money(value),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySalesChart extends ConsumerWidget {
  const _WeeklySalesChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(weeklySalesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (days) {
              final maxY = days
                  .map((d) => d.total)
                  .fold<double>(0, (m, v) => v > m ? v : m);
              final safeMax = maxY <= 0 ? 1000.0 : maxY * 1.25;
              return BarChart(
                BarChartData(
                  maxY: safeMax,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: safeMax / 4,
                        getTitlesWidget: (value, meta) => Text(
                          NumberFormat.compact().format(value),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(DateFormat('E').format(days[i].day),
                                style: theme.textTheme.labelSmall),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        Formatters.money(rod.toY),
                        TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < days.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: days[i].total,
                          width: 16,
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  const _RecentSaleRow({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(Icons.receipt_outlined,
            color: theme.colorScheme.onSecondaryContainer, size: 20),
      ),
      title: Text(sale.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${Formatters.time(sale.createdAt)} • ${sale.paymentMethod.label}'),
      trailing: Text(Formatters.money(sale.total),
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
