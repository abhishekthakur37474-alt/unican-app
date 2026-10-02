import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/app_settings.dart';
import '../services/sync_service.dart';
import '../services/verification_store.dart';
import '../theme/app_theme.dart';
import 'assigned_addresses_screen.dart';
import 'profile_screen.dart';
import 'verification_list_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ValueListenableBuilder<String>(
              valueListenable: AppSettings.instance.displayName,
              builder: (context, name, child) {
                return Text(
                  name.isEmpty ? 'there' : name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<List<VerificationCase>>(
              valueListenable: VerificationStore.instance.cases,
              builder: (context, cases, child) {
                final favorites = cases.where((e) => e.isFavorite).length;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your dashboard',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${cases.length} verifications',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$favorites starred',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.cloud_done_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 40,
                      ),
                    ],
                  ),
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: SyncService.instance.pendingCount,
              builder: (context, pending, child) {
                if (pending == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pending verification${pending == 1 ? '' : 's'} '
                            'pending sync. Will upload automatically when online.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Quick actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
              children: [
                _QuickActionCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Start Verification',
                  onTap: () =>
                      _open(context, const AssignedAddressesScreen()),
                ),
                _QuickActionCard(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () => _open(context, const ProfileScreen()),
                ),
                _QuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Activity',
                  onTap: () => _open(
                    context,
                    const VerificationListScreen(title: 'Activity'),
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.favorite_border_rounded,
                  label: 'Favorites',
                  onTap: () => _open(
                    context,
                    const VerificationListScreen(
                      title: 'Favorites',
                      favoritesOnly: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}