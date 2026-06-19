import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/stock_status.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/presentation/medicine_providers.dart';
import 'reports_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sales', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Inventory', icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_SalesReportTab(), _InventoryReportTab()],
        ),
      ),
    );
  }
}

class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(salesReportProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<ReportPeriod>(
          segments: ReportPeriod.values
              .map((p) => ButtonSegment(value: p, label: Text(p.label)))
              .toList(),
          selected: {period},
          onSelectionChanged: (s) =>
              ref.read(reportPeriodProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 16),
        reportAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (report) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Revenue',
                      value: Formatters.money(report.revenue),
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Transactions',
                      value: '${report.transactionCount}',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricTile(
                label: 'Units sold',
                value: '${report.unitsSold}',
                icon: Icons.inventory_outlined,
                color: const Color(0xFF00897B),
              ),
              const SizedBox(height: 20),
              _SectionTitle('Revenue by payment method'),
              if (report.byPaymentMethod.isEmpty)
                _emptyHint(context, 'No sales in this period.')
              else
                ...PaymentMethod.values.map((m) {
                  final amount = report.byPaymentMethod[m] ?? 0;
                  if (amount <= 0) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_iconFor(m)),
                    title: Text(m.label),
                    trailing: Text(Formatters.money(amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  );
                }),
              const SizedBox(height: 12),
              _SectionTitle('Top selling medicines'),
              if (report.topItems.isEmpty)
                _emptyHint(context, 'No items sold yet.')
              else
                ...report.topItems.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text('${item.quantity}',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700)),
                      ),
                      title: Text(item.name),
                      subtitle: Text('${item.quantity} units sold'),
                      trailing: Text(Formatters.money(item.revenue),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  IconData _iconFor(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.mobileMoney => Icons.phone_android,
        PaymentMethod.bankTransfer => Icons.account_balance_outlined,
      };
}

class _InventoryReportTab extends ConsumerWidget {
  const _InventoryReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(medicinesProvider).valueOrNull ?? const <Medicine>[];
    final stats = ref.watch(inventoryStatsProvider);
    final lowStock = all.where((m) => m.isLowStock || m.isOutOfStock).toList();
    final expired = all.where((m) => m.isExpired).toList();
    final expiringSoon = all.where((m) => m.isExpiringSoon).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Inventory summary'),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Total value',
                value: Formatters.compactMoney(stats.inventoryValue),
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF00897B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Total units',
                value: '${stats.totalUnits}',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF3949AB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle('Low / out of stock (${lowStock.length})'),
        if (lowStock.isEmpty)
          _ok(context, 'All medicines are sufficiently stocked.')
        else
          ...lowStock.map((m) => _InventoryRow(
                title: m.name,
                subtitle: '${m.quantity} units • reorder at ${m.reorderLevel}',
                trailing: m.stockStatus.label,
                color: m.stockStatus.color,
              )),
        const SizedBox(height: 16),
        _SectionTitle('Expired (${expired.length})'),
        if (expired.isEmpty)
          _ok(context, 'No expired medicines.')
        else
          ...expired.map((m) => _InventoryRow(
                title: m.name,
                subtitle: 'Batch ${m.batchNumber}',
                trailing: Formatters.daysUntil(m.expiryDate),
                color: const Color(0xFFC62828),
              )),
        const SizedBox(height: 16),
        _SectionTitle(
            'Expiring within ${AppConstants.expiryWarningDays} days (${expiringSoon.length})'),
        if (expiringSoon.isEmpty)
          _ok(context, 'Nothing expiring soon.')
        else
          ...expiringSoon.map((m) => _InventoryRow(
                title: m.name,
                subtitle: 'Expires ${Formatters.date(m.expiryDate)}',
                trailing: Formatters.daysUntil(m.expiryDate),
                color: const Color(0xFFF9A825),
              )),
      ],
    );
  }

  Widget _ok(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.medication_outlined, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(trailing,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
