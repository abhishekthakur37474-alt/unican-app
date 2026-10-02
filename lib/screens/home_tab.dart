import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../models/verification_case.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/verification_store.dart';
import '../widgets/assigned_address_card.dart';
import 'assigned_address_detail_screen.dart';
import 'assigned_addresses_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final db = DatabaseService();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: uid == null
            ? _EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Sign in required',
                subtitle: 'Log in to see your assigned verifications',
              )
            : StreamBuilder<List<AssignedAddress>>(
                stream: db.watchAssignedAddresses(uid),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <AssignedAddress>[];
                  final waiting =
                      snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData;
                  final offline = !SyncService.instance.online.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<List<VerificationCase>>(
                        valueListenable: VerificationStore.instance.cases,
                        builder: (context, cases, child) => _StatsRow(
                          assigned: items.length,
                          completed: cases.length,
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: SyncService.instance.pendingCount,
                        builder: (context, pending, child) {
                          if (pending == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _PendingBanner(pending: pending),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assigned Addresses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _open(
                              context,
                              const AssignedAddressesScreen(),
                            ),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError || (offline && items.isEmpty))
                        const _EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load addresses',
                          subtitle: 'Check your connection and try again',
                        )
                      else if (items.isEmpty)
                        const _EmptyState(
                          icon: Icons.location_off_outlined,
                          title: 'No addresses assigned',
                          subtitle: 'New cases from admin will appear here',
                        )
                      else
                        for (final item in items) ...[
                          AssignedAddressCard(
                            item: item,
                            onTap: () => _open(
                              context,
                              AssignedAddressDetailScreen(
                                assignedAddress: item,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int assigned;
  final int completed;

  const _StatsRow({required this.assigned, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_outlined,
            label: 'Received',
            count: assigned,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.task_alt_rounded,
            label: 'Completed',
            count: completed,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int pending;

  const _PendingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pending verification${pending == 1 ? '' : 's'} pending sync. '
              'Will upload automatically when online.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
