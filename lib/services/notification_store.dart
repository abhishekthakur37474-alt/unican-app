import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/staff_notification.dart';
import 'database_service.dart';

/// Realtime cache of the signed-in staff member's in-app notifications.
/// Keeps a live unread count for the Alerts tab badge.
class NotificationStore {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final DatabaseService _db = DatabaseService();

  final ValueNotifier<List<StaffNotification>> notifications =
      ValueNotifier<List<StaffNotification>>(<StaffNotification>[]);

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  StreamSubscription<List<StaffNotification>>? _sub;

  void start() {
    stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _sub = _db.watchStaffNotifications(uid).listen(
      (items) {
        notifications.value = items;
        unreadCount.value = items.where((e) => !e.read).length;
      },
      onError: (_) {},
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    notifications.value = <StaffNotification>[];
    unreadCount.value = 0;
  }
}
