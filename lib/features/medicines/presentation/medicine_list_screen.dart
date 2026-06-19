import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/stock_status.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/medicine.dart';
import 'medicine_form_screen.dart';
import 'medicine_providers.dart';
import 'widgets/medicine_card.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final filtered = ref.watch(filteredMedicinesProvider);
    final query = ref.watch(medicineSearchProvider);
    final category = ref.watch(medicineCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load inventory: $e')),
        data: (_) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchBar(
                hintText: 'Search name, batch, maker…',
                leading: const Icon(Icons.search),
                trailing: query.isEmpty
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref
                              .read(medicineSearchProvider.notifier)
                              .state = '',
                        )
                      ],
                onChanged: (v) =>
                    ref.read(medicineSearchProvider.notifier).state = v,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: category.isEmpty,
                    onTap: () => ref
                        .read(medicineCategoryFilterProvider.notifier)
                        .state = '',
                  ),
                  ...AppConstants.medicineCategories.map(
                    (c) => _CategoryChip(
                      label: c,
                      selected: category == c,
                      onTap: () => ref
                          .read(medicineCategoryFilterProvider.notifier)
                          .state = category == c ? '' : c,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No medicines found',
                      message: query.isEmpty
                          ? 'Register your first medicine to get started.'
                          : 'Try a different search or filter.',
                      action: FilledButton.icon(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Register medicine'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(medicinesProvider.notifier).reload(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => MedicineCard(
                          medicine: filtered[i],
                          onTap: () =>
                              _showDetail(context, ref, filtered[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, [Medicine? existing]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MedicineFormScreen(existing: existing),
    ));
  }

  void _showDetail(BuildContext context, WidgetRef ref, Medicine m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MedicineDetailSheet(medicine: m),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MedicineDetailSheet extends ConsumerWidget {
  const _MedicineDetailSheet({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final status = medicine.stockStatus;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(medicine.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${medicine.category} • ${medicine.manufacturer}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(status.label, status.color, status.icon),
              if (medicine.isExpired)
                _pill('Expired', const Color(0xFFC62828), Icons.dangerous_outlined)
              else if (medicine.isExpiringSoon)
                _pill('Expiring soon', const Color(0xFFF9A825),
                    Icons.access_time),
            ],
          ),
          const SizedBox(height: 16),
          _row('Batch number', medicine.batchNumber),
          _row('Quantity in stock', '${medicine.quantity} units'),
          _row('Stock availability',
              Formatters.percent(medicine.stockFraction)),
          _row('Reorder level', '${medicine.reorderLevel} units'),
          _row('Purchase price', Formatters.money(medicine.purchasePrice)),
          _row('Selling price', Formatters.money(medicine.sellingPrice)),
          _row('Manufactured', Formatters.date(medicine.manufacturingDate)),
          _row('Expires', Formatters.date(medicine.expiryDate)),
          _row('Inventory value', Formatters.money(medicine.inventoryValue)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          MedicineFormScreen(existing: medicine),
                    ));
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: isAdmin
                      ? () => _confirmDelete(context, ref)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(isAdmin ? 'Delete' : 'Admin only'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text(
            'This permanently removes "${medicine.name}" from inventory.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(medicinesProvider.notifier).remove(medicine.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _pill(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
