import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/receipt_service.dart';
import '../domain/sale.dart';
import 'sales_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No sales yet',
              message: 'Completed transactions will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentSalesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SaleTile extends ConsumerWidget {
  const _SaleTile({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(_iconFor(sale.paymentMethod),
              color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(sale.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${Formatters.dateTime(sale.createdAt)}\n${sale.paymentMethod.label} • ${sale.cashierName}'),
        isThreeLine: true,
        trailing: Text(Formatters.money(sale.total),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        onTap: () => _showDetail(context, ref),
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref) async {
    final full = await ref.read(salesRepositoryProvider).getById(sale.id);
    if (full == null || !context.mounted) return;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(full.invoiceNumber,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(Formatters.dateTime(full.createdAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Divider(height: 24),
            ...full.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              '${item.medicineName}  x${item.quantity}')),
                      Text(Formatters.money(item.subtotal)),
                    ],
                  ),
                )),
            const Divider(height: 24),
            _kv('Subtotal', Formatters.money(full.subtotal)),
            if (full.discount > 0)
              _kv('Discount', '- ${Formatters.money(full.discount)}'),
            _kv('Total', Formatters.money(full.total), bold: true),
            _kv('Payment', full.paymentMethod.label),
            if (full.paymentReference.isNotEmpty)
              _kv('Reference', full.paymentReference),
            if (full.customerName.isNotEmpty)
              _kv('Customer', full.customerName),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => receiptService.shareReceipt(full),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => receiptService.printReceipt(full),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k),
            Text(v,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      );

  IconData _iconFor(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.mobileMoney => Icons.phone_android,
        PaymentMethod.bankTransfer => Icons.account_balance_outlined,
      };
}
