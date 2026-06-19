import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../medicines/presentation/medicine_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/receipt_service.dart';
import '../domain/sale.dart';
import 'sales_providers.dart';

/// Collects payment details, records the sale (deducting stock) and offers the
/// receipt.
class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  PaymentMethod _method = PaymentMethod.cash;
  final _customer = TextEditingController();
  final _reference = TextEditingController();
  final _discount = TextEditingController(text: '0');
  bool _processing = false;

  @override
  void dispose() {
    _customer.dispose();
    _reference.dispose();
    _discount.dispose();
    super.dispose();
  }

  bool get _needsReference =>
      _method == PaymentMethod.mobileMoney ||
      _method == PaymentMethod.bankTransfer ||
      _method == PaymentMethod.card;

  String get _referenceLabel => switch (_method) {
        PaymentMethod.mobileMoney => 'Transaction ID (e.g. M-Pesa code)',
        PaymentMethod.bankTransfer => 'Bank reference number',
        PaymentMethod.card => 'Card approval / auth code',
        PaymentMethod.cash => 'Reference (optional)',
      };

  Future<void> _confirm() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    if (_needsReference && _reference.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the $_referenceLabel.')),
      );
      return;
    }

    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final discount = double.tryParse(_discount.text.trim()) ?? 0;
    if (discount > subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount cannot exceed the subtotal.')),
      );
      return;
    }
    final total = subtotal - discount;

    setState(() => _processing = true);
    final user = ref.read(currentUserProvider);
    final now = DateTime.now();
    final saleId = AppDatabase.newId();

    final sale = Sale(
      id: saleId,
      invoiceNumber: AppDatabase.newInvoiceNumber(now),
      customerName: _customer.text.trim(),
      subtotal: subtotal,
      discount: discount,
      tax: 0,
      total: total,
      paymentMethod: _method,
      paymentReference: _reference.text.trim(),
      cashierId: user?.id ?? '',
      cashierName: user?.fullName ?? 'Unknown',
      createdAt: now,
      items: [
        for (final line in cart)
          SaleItem(
            id: AppDatabase.newId(),
            saleId: saleId,
            medicineId: line.medicineId,
            medicineName: line.medicineName,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
          ),
      ],
    );

    try {
      await ref.read(salesRepositoryProvider).recordSale(sale);
      ref.read(cartProvider.notifier).clear();
      // Refresh inventory & sales-derived views.
      await ref.read(medicinesProvider.notifier).reload();
      ref.invalidate(recentSalesProvider);
      ref.invalidate(totalRevenueProvider);

      if (mounted) {
        Navigator.of(context).pop();
        await _showSuccess(sale);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showSuccess(Sale sale) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
        title: const Text('Sale completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sale.invoiceNumber),
            const SizedBox(height: 8),
            Text(Formatters.money(sale.total),
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Paid via ${sale.paymentMethod.label}'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => receiptService.shareReceipt(sale),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: () => receiptService.printReceipt(sale),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;
    final discount = double.tryParse(_discount.text.trim()) ?? 0;
    final total = (subtotal - discount).clamp(0, double.infinity);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Payment',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text('Payment method', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            RadioGroup<PaymentMethod>(
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              child: Column(
                children: PaymentMethod.values
                    .map((m) => RadioListTile<PaymentMethod>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: m,
                          title: Text(m.label),
                          secondary: Icon(_iconFor(m)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customer,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Customer name (optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              decoration: InputDecoration(
                labelText: _referenceLabel,
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Discount',
                prefixIcon: Icon(Icons.percent_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal', Formatters.money(subtotal)),
                  if (discount > 0)
                    _summaryRow('Discount', '- ${Formatters.money(discount)}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount due',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(Formatters.money(total),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _processing ? null : _confirm,
              icon: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.check),
              label: Text('Confirm • ${Formatters.money(total)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );

  IconData _iconFor(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.mobileMoney => Icons.phone_android,
        PaymentMethod.bankTransfer => Icons.account_balance_outlined,
      };
}
