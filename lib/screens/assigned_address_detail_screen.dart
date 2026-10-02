import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../verification/verification_address_screen.dart';
import '../widgets/app_top_bar.dart';

/// Read-only detail view for an assigned address. The staff member reviews the
/// case here and taps Start to enter the existing verification flow.
class AssignedAddressDetailScreen extends StatelessWidget {
  final AssignedAddress assignedAddress;

  const AssignedAddressDetailScreen({
    super.key,
    required this.assignedAddress,
  });

  void _start(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationAddressScreen(
          assignedAddress: assignedAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = assignedAddress;

    return Scaffold(
      appBar: const AppTopBar(title: 'Verification Details', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(item: item),
            const SizedBox(height: 14),
            _Section(
              title: 'Applicant',
              icon: Icons.badge_outlined,
              entries: [
                ('Name', item.applicantName),
                ('Phone', item.phone),
                ('Case ID', item.caseId),
                ('Client', item.clientName),
              ],
            ),
            _Section(
              title: 'Address',
              icon: Icons.location_on_outlined,
              entries: [
                ('Address', item.addressLine),
                ('Landmark', item.landmark),
                ('City', item.city),
                ('State', item.state),
                ('Pincode', item.pincode),
              ],
            ),
            _Section(
              title: 'Assignment',
              icon: Icons.assignment_outlined,
              entries: [
                ('Type', item.verificationType),
                ('Priority', item.priority),
                ('Status', item.status),
                ('Assigned At', _formatDateTime(item.assignedAt)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _start(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Start Verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final AssignedAddress item;

  const _HeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home_work_outlined,
            color: theme.colorScheme.primary,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.applicantName.isEmpty ? item.caseId : item.applicantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.fullAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> entries;

  const _Section({
    required this.title,
    required this.icon,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = entries
        .where((e) => e.$1.isNotEmpty && e.$2.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year}, $h:$m';
}
