import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'app_settings.dart';
import 'database_service.dart';
import 'notification_router.dart';

const _androidChannelId = 'unican_assignments';
const _androidChannelName = 'Verification assignments';
const _openAlertsPayload = 'open_alerts';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _db = DatabaseService();

  bool _initialized = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<void> init() async {
    if (!_supported || _initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => NotificationRouter.instance.handleData(message.data),
    );

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      NotificationRouter.instance.handleData(initial.data);
    }

    _messaging.onTokenRefresh.listen(_saveToken);
    await registerCurrentUser();
  }

  Future<void> registerCurrentUser() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _requestPermission();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(token);
    } catch (_) {}
  }

  Future<void> clearCurrentUser() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.clearStaffFcmToken(uid);
    } catch (_) {}
  }

  static void openAlertsTab() {
    AppSettings.instance.homeTabIndex.value = 1;
    AppSettings.instance.alertsRefreshTick.value++;
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Alerts when a verification address is assigned',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    // iOS + Android 13+ (no-op prompt on older Android).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    if (payload == _openAlertsPayload) {
      openAlertsTab();
      return;
    }

    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        NotificationRouter.instance.handleData(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      openAlertsTab();
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.setStaffFcmToken(uid, token);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (!AppSettings.instance.verificationAlerts.value) return;

    final notification = message.notification;
    final title = notification?.title ??
        message.data['title'] ??
        'New verification assigned';
    final body = notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        'Open Alerts to view the assigned address';

    final rawId =
        (message.data['notificationId'] ?? message.messageId ?? '').toString();
    final id = rawId.isNotEmpty
        ? rawId.hashCode & 0x7fffffff
        : message.hashCode & 0x7fffffff;

    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'Alerts when a verification address is assigned',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(<String, dynamic>{
        'type': message.data['type'],
        'caseId': message.data['caseId'],
        'addressId': message.data['addressId'],
        'notificationId': message.data['notificationId'],
      }),
    );
  }
}
