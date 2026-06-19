import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/presentation/medicine_providers.dart';
import 'cart_sheet.dart';
import 'sales_providers.dart';

/// Point-of-sale: pick in-stock medicines into the cart, then check out.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              onPressed: cartNotifier.clear,
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final sellable = all
              .where((m) => m.quantity > 0 && !m.isExpired)
              .where((m) =>
                  _query.isEmpty ||
                  m.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  hintText: 'Search medicine to sell…',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: sellable.isEmpty
                    ? const EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'Nothing to sell',
                        message:
                            'No in-stock, non-expired medicines match your search.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: sellable.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ProductTile(
                          medicine: sellable[i],
                          inCart: cart
                              .where((l) => l.medicineId == sellable[i].id)
                              .fold(0, (s, l) => s + l.quantity),
                          onAdd: () => cartNotifier.add(
                            medicineId: sellable[i].id,
                            medicineName: sellable[i].name,
                            unitPrice: sellable[i].sellingPrice,
                            availableStock: sellable[i].quantity,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _CartBar(
              itemCount: cartNotifier.itemCount,
              total: cartNotifier.subtotal,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const CartSheet(),
              ),
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.medicine,
    required this.inCart,
    required this.onAdd,
  });

  final Medicine medicine;
  final int inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = inCart < medicine.quantity;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.medication_outlined,
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(medicine.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${Formatters.money(medicine.sellingPrice)} • ${medicine.quantity} in stock'),
        trailing: inCart > 0
            ? Chip(
                label: Text('$inCart'),
                avatar: const Icon(Icons.shopping_cart, size: 16),
              )
            : null,
        onTap: canAdd
            ? onAdd
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No more stock available.')),
                ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar(
      {required this.itemCount, required this.total, required this.onTap});

  final int itemCount;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Badge(
                    label: Text('$itemCount'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  const SizedBox(width: 12),
                  const Text('View cart'),
                ],
              ),
              Text(Formatters.money(total),
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
