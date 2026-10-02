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
/// OneSignal External ID, and the subscription id is saved to
/// `staff/{uid}/oneSignalId` so the admin can target either one.
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

  void _log(String msg) {
    // ignore: avoid_print
    print('[PushService] $msg');
  }

  Future<void> init() async {
    _log('init() called, supported=$_supported, alreadyInit=$_initialized');
    if (!_supported || _initialized) return;
    _initialized = true;

    OneSignal.initialize(_oneSignalAppId);
    _log('OneSignal.initialize done, appId=$_oneSignalAppId');
    _attachListeners();
    _observeSubscription();

    // true = send user to app settings if permission was denied earlier.
    final granted = await OneSignal.Notifications.requestPermission(true);
    _log('notification permission granted: $granted');
  }

  /// Called on login and on app start when a session already exists.
  Future<void> registerCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _log('registerCurrentUser() called, supported=$_supported, uid=$uid');
    if (!_supported) return;
    if (uid == null) return;

    try {
      await OneSignal.login(uid);
      _log('OneSignal.login($uid) done');

      // Make sure the device is opted in for push.
      final optedIn = await OneSignal.User.pushSubscription.optedIn;
      if (optedIn != true) {
        await OneSignal.User.pushSubscription.optIn();
        _log('push subscription opted in');
      }
    } catch (e) {
      _log('login failed: $e');
    }

    await _saveSubscriptionIdWithRetry(uid);
  }

  /// Subscription id can be null right after login/install.
  /// Retry a few times; the observer below also covers late arrival.
  Future<void> _saveSubscriptionIdWithRetry(String uid) async {
    for (var i = 0; i < 6; i++) {
      try {
        final id = await OneSignal.User.pushSubscription.id;
        if (id != null && id.isNotEmpty) {
          await _db.setStaffOneSignalId(uid, id);
          _log('subscription id saved: $id');
          return;
        }
      } catch (e) {
        _log('read subscription id failed: $e');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    _log('subscription id still null (permission denied or no network?)');
  }

  Future<void> clearCurrentUser() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.clearStaffOneSignalId(uid);
      } catch (_) {}
    }
    try {
      await OneSignal.logout();
    } catch (_) {}
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
      _log('subscription changed, saving id: $id');
      _db.setStaffOneSignalId(uid, id);
    });
  }
}