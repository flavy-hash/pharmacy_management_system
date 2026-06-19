import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/stock_status.dart';
import '../../domain/medicine.dart';

/// A list tile showing a medicine with its stock bar and expiry badge.
class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.medicine, this.onTap});

  final Medicine medicine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = medicine.stockStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medication_outlined,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(medicine.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${medicine.category} • ${medicine.manufacturer}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.money(medicine.sellingPrice),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(status.icon, size: 16, color: status.color),
                  const SizedBox(width: 4),
                  Text(
                    '${status.label} • ${medicine.quantity} units',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: status.color, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _ExpiryBadge(medicine: medicine),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: medicine.stockFraction,
                  minHeight: 7,
                  backgroundColor: status.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(status.color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock availability: ${Formatters.percent(medicine.stockFraction)}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  const _ExpiryBadge({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    if (medicine.isExpired) {
      color = const Color(0xFFC62828);
    } else if (medicine.isExpiringSoon) {
      color = const Color(0xFFF9A825);
    } else {
      color = theme.colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        Formatters.daysUntil(medicine.expiryDate),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
