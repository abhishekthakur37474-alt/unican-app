import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/assigned_address.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../verification/verification_address_screen.dart';

class AssignedAddressesScreen extends StatelessWidget {
  const AssignedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Addresses')),
      body: SafeArea(
        child: uid == null
            ? const _EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Sign in required',
                subtitle: 'Log in to see assigned addresses',
              )
            : StreamBuilder<List<AssignedAddress>>(
                stream: db.watchAssignedAddresses(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load addresses',
                      subtitle: 'Check your connection and try again',
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No addresses assigned',
                      subtitle: 'New cases from admin will appear here',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Material(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerificationAddressScreen(
                                  assignedAddress: item,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
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
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.fullAddress,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          if (item.caseId.isNotEmpty)
                                            _Chip(label: item.caseId),
                                          if (item.verificationType.isNotEmpty)
                                            _Chip(label: item.verificationType),
                                          if (item.priority.isNotEmpty)
                                            _Chip(
                                              label: item.priority,
                                              highlight: item.priority
                                                      .toLowerCase() !=
                                                  'normal',
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
                    },
                  );
                },
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
