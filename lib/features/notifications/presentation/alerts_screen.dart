import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../medicines/domain/medicine.dart';
import '../../medicines/presentation/medicine_providers.dart';
import '../../medicines/presentation/widgets/medicine_card.dart';
import '../notification_service.dart';

/// Surfaces expired, soon-to-expire and low-stock medicines, mirroring the
/// local push notifications.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(medicinesProvider).valueOrNull ?? const <Medicine>[];
    final expired = all.where((m) => m.isExpired).toList();
    final expiringSoon = all.where((m) => m.isExpiringSoon).toList();
    final lowStock = all.where((m) => m.isLowStock || m.isOutOfStock).toList();
    final hasAlerts =
        expired.isNotEmpty || expiringSoon.isNotEmpty || lowStock.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            tooltip: 'Re-check & notify',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService.instance.scanInventory(all);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventory re-checked.')),
                );
              }
            },
          ),
        ],
      ),
      body: !hasAlerts
          ? const EmptyState(
              icon: Icons.verified_outlined,
              title: 'All clear',
              message:
                  'No expired, expiring or low-stock medicines right now.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (expired.isNotEmpty)
                  _Section(
                    title: 'Expired (${expired.length})',
                    color: const Color(0xFFC62828),
                    icon: Icons.dangerous_outlined,
                    medicines: expired,
                  ),
                if (expiringSoon.isNotEmpty)
                  _Section(
                    title:
                        'Expiring within ${AppConstants.expiryWarningDays} days (${expiringSoon.length})',
                    color: const Color(0xFFF9A825),
                    icon: Icons.access_time,
                    medicines: expiringSoon,
                  ),
                if (lowStock.isNotEmpty)
                  _Section(
                    title: 'Low / out of stock (${lowStock.length})',
                    color: const Color(0xFFF9A825),
                    icon: Icons.inventory_2_outlined,
                    medicines: lowStock,
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.color,
    required this.icon,
    required this.medicines,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<Medicine> medicines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
        ...medicines.map((m) => MedicineCard(medicine: m)),
        const SizedBox(height: 8),
      ],
    );
  }
}
