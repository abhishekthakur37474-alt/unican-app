import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/verification_store.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: ValueListenableBuilder<String>(
                        valueListenable: AppSettings.instance.displayName,
                        builder: (context, name, child) {
                          final initial = name.isNotEmpty
                              ? name[0]
                              : (user?.displayName?.isNotEmpty == true
                                  ? user!.displayName![0]
                                  : 'U');
                          return Text(
                            initial.toUpperCase(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<String>(
                            valueListenable: AppSettings.instance.displayName,
                            builder: (context, name, child) {
                              return Text(
                                name.isEmpty
                                    ? (user?.displayName ?? 'User')
                                    : name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
          ),
          const SizedBox(height: 28),

          _SectionLabel(text: 'Account', theme: theme),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          _SectionLabel(text: 'Preferences', theme: theme),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          _SectionLabel(text: 'About', theme: theme),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About this app',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              onPressed: () async {
                await authService.logout();
                VerificationStore.instance.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge,
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