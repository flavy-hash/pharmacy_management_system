import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import 'checkout_sheet.dart';
import 'sales_providers.dart';

/// Reviewable cart: edit quantities, remove lines, then proceed to payment.
class CartSheet extends ConsumerWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cart',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final line = cart[i];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.medicineName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${Formatters.money(line.unitPrice)} each',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        _StepperButton(
                          icon: Icons.remove,
                          onTap: line.quantity > 1
                              ? () => notifier.setQuantity(
                                  line.medicineId, line.quantity - 1)
                              : () => notifier.remove(line.medicineId),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('${line.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                        _StepperButton(
                          icon: Icons.add,
                          onTap: line.quantity < line.availableStock
                              ? () => notifier.setQuantity(
                                  line.medicineId, line.quantity + 1)
                              : null,
                        ),
                        SizedBox(
                          width: 86,
                          child: Text(Formatters.money(line.subtotal),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  Text(Formatters.money(notifier.subtotal),
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => const CheckoutSheet(),
                        );
                      },
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to payment'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
    );
  }
}
