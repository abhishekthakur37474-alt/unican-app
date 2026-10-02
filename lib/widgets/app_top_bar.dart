import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../screens/notifications_screen.dart';
import '../services/notification_store.dart';

/// Shared top bar used across the app so every screen has the same header
/// treatment. Optionally renders a smaller [subtitle] under the [title] and
/// accepts trailing [actions] (e.g. the notifications bell).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(_hasSubtitle ? 72 : kToolbarHeight);

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = _hasSubtitle;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
            )
          : null,
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surface,
      toolbarHeight: hasSubtitle ? 72 : kToolbarHeight,
      titleSpacing: showBack ? null : 20,
      title: hasSubtitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: actions.isEmpty ? null : actions,
    );
  }
}

/// Notification (alert) button for [AppTopBar]. Shows an unread badge and
/// opens the notifications screen.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: NotificationStore.instance.unreadCount,
      builder: (context, unread, child) {
        final bell = HugeIcon(
          icon: HugeIcons.strokeRoundedNotification01,
          color: theme.colorScheme.onSurface,
          size: 26,
        );
        return IconButton(
          tooltip: 'Alerts',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: unread > 0 ? Badge.count(count: unread, child: bell) : bell,
        );
      },
    );
  }
}
