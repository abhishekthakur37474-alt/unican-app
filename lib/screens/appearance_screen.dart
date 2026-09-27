import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: settings.themeMode,
          builder: (context, mode, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Theme',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _ThemeTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Light',
                  selected: mode == ThemeMode.light,
                  onTap: () => settings.themeMode.value = ThemeMode.light,
                ),
                const SizedBox(height: 10),
                _ThemeTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark',
                  selected: mode == ThemeMode.dark,
                  onTap: () => settings.themeMode.value = ThemeMode.dark,
                ),
                const SizedBox(height: 10),
                _ThemeTile(
                  icon: Icons.brightness_auto_outlined,
                  title: 'System',
                  selected: mode == ThemeMode.system,
                  onTap: () => settings.themeMode.value = ThemeMode.system,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
