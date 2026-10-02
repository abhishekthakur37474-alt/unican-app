import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../theme/app_theme.dart';

/// Tappable card summarising an assigned verification address. Shared by the
/// home tab and the full assigned-addresses screen.
class AssignedAddressCard extends StatelessWidget {
  final AssignedAddress item;
  final VoidCallback onTap;

  const AssignedAddressCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.applicantName.isEmpty
                          ? item.caseId
                          : item.applicantName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.fullAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (item.caseId.isNotEmpty) _Chip(label: item.caseId),
                        if (item.verificationType.isNotEmpty)
                          _Chip(label: item.verificationType),
                        if (item.priority.isNotEmpty)
                          _Chip(
                            label: item.priority,
                            highlight:
                                item.priority.toLowerCase() != 'normal',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _Chip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.error.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlight ? theme.colorScheme.error : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
