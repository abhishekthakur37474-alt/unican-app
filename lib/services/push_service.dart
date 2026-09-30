import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app_settings.dart';
import 'database_service.dart';
import 'notification_router.dart';

/// OneSignal App ID (from OneSignal dashboard > Settings > Keys & IDs).
/// The REST API key is a server-side secret and must NOT live in the app.
const _oneSignalAppId = 'f5e99edf-0039-4e79-890f-d34d6753db0d';

/// Device push via OneSignal. The signed-in staff uid is set as the
/// OneSignal External ID so the admin can target it without storing tokens.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final DatabaseService _db = DatabaseService();

  bool _initialized = false;
  bool _listenersAttached = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;
    _initialized = true;

    OneSignal.initialize(_oneSignalAppId);
    _attachListeners();
    _observeSubscription();

    await OneSignal.Notifications.requestPermission(false);
  }

  /// Called on login and on app start when a session already exists.
  Future<void> registerCurrentUser() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    OneSignal.login(uid);
    try {
      final id = await OneSignal.User.pushSubscription.id;
      if (id != null && id.isNotEmpty) {
        await _db.setStaffOneSignalId(uid, id);
      }
    } catch (_) {}
  }

  Future<void> clearCurrentUser() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.clearStaffOneSignalId(uid);
      } catch (_) {}
    }
    OneSignal.logout();
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Respect the in-app notification toggle for device pushes too.
      if (!AppSettings.instance.verificationAlerts.value) {
        event.preventDefault();
      }
    });

    OneSignal.Notifications.addClickListener((event) {
      NotificationRouter.instance.handleData(
        event.notification.additionalData ?? <String, dynamic>{},
      );
    });
  }

  void _observeSubscription() {
    OneSignal.User.pushSubscription.addObserver((state) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final id = state.current.id;
      if (uid == null || id == null || id.isEmpty) return;
      _db.setStaffOneSignalId(uid, id);
    });
  }
}
