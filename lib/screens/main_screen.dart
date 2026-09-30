import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../services/notification_router.dart';
import '../services/notification_store.dart';
import 'home_tab.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _titles = ['Home', 'Notifications', 'Settings'];

  static const _screens = [
    HomeTab(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        AppSettings.instance.homeTabIndex.value = args;
      }
      // Open a case tapped from an FCM notification once we're signed in.
      NotificationRouter.instance.flushPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.instance.homeTabIndex,
      builder: (context, index, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[index]),
            centerTitle: false,
            backgroundColor: theme.colorScheme.surface,
            scrolledUnderElevation: 0,
          ),
          body: IndexedStack(
            index: index,
            children: _screens,
          ),
          bottomNavigationBar: ValueListenableBuilder<int>(
            valueListenable: NotificationStore.instance.unreadCount,
            builder: (context, unread, child) {
              return NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) {
                  AppSettings.instance.homeTabIndex.value = i;
                },
                backgroundColor: theme.colorScheme.surface,
                indicatorColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                elevation: 3,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: _AlertsIcon(
                      unread: unread,
                      icon: Icons.notifications_none_rounded,
                    ),
                    selectedIcon: _AlertsIcon(
                      unread: unread,
                      icon: Icons.notifications_rounded,
                    ),
                    label: 'Alerts',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AlertsIcon extends StatelessWidget {
  final int unread;
  final IconData icon;

  const _AlertsIcon({required this.unread, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (unread <= 0) return Icon(icon);
    return Badge.count(
      count: unread,
      child: Icon(icon),
    );
  }
}
