import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/app_settings.dart';
import '../services/notification_router.dart';
import '../widgets/app_top_bar.dart';
import 'home_tab.dart';
import 'settings_screen.dart';
import 'verification_list_screen.dart';
import 'verified_addresses_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _titles = ['Welcome Back', 'Activity', 'Reports', 'Settings'];

  static const _screens = [
    HomeTab(),
    VerificationListScreen(title: 'Activity', embedded: true),
    VerifiedAddressesScreen(embedded: true),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < _screens.length) {
        AppSettings.instance.homeTabIndex.value = args;
      }
      // Open a case tapped from an FCM notification once we're signed in.
      NotificationRouter.instance.flushPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.instance.displayName,
      builder: (context, name, child) {
        return ValueListenableBuilder<int>(
          valueListenable: AppSettings.instance.homeTabIndex,
          builder: (context, index, child) {
            final selectedColor = theme.colorScheme.primary;
            final unselectedColor = theme.colorScheme.onSurfaceVariant;

            Widget navIcon(IconData icon, {required bool selected}) => HugeIcon(
                  icon: icon,
                  color: selected ? selectedColor : unselectedColor,
                  size: 26,
                );

            return Scaffold(
              appBar: AppTopBar(
                title: _titles[index],
                subtitle: index == 0 && name.trim().isNotEmpty ? name : null,
                actions: const [NotificationBell()],
              ),
              body: IndexedStack(
                index: index,
                children: _screens,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) {
                  AppSettings.instance.homeTabIndex.value = i;
                },
                backgroundColor: theme.colorScheme.surface,
                indicatorColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                elevation: 3,
                destinations: [
                  NavigationDestination(
                    icon: navIcon(HugeIcons.strokeRoundedHome03,
                        selected: false),
                    selectedIcon:
                        navIcon(HugeIcons.strokeRoundedHome03, selected: true),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: navIcon(HugeIcons.strokeRoundedActivity01,
                        selected: false),
                    selectedIcon: navIcon(HugeIcons.strokeRoundedActivity01,
                        selected: true),
                    label: 'Activity',
                  ),
                  NavigationDestination(
                    icon: navIcon(HugeIcons.strokeRoundedAnalytics01,
                        selected: false),
                    selectedIcon: navIcon(HugeIcons.strokeRoundedAnalytics01,
                        selected: true),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: navIcon(HugeIcons.strokeRoundedSettings02,
                        selected: false),
                    selectedIcon: navIcon(HugeIcons.strokeRoundedSettings02,
                        selected: true),
                    label: 'Settings',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
