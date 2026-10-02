import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings.dart';
import 'services/auth_service.dart';
import 'services/notification_router.dart';
import 'services/notification_store.dart';
import 'services/push_service.dart';
import 'services/sync_service.dart';
import 'services/verification_store.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep a local RTDB cache so assigned addresses and notifications stay
  // readable while offline. Must run before the first database reference.
  unawaited(
    FirebaseDatabase.instance
        .setPersistenceEnabled(true)
        .catchError((Object _) {}),
  );

  // Local storage + connectivity listener: no network needed, must finish
  // before the first frame so offline drafts are available.
  await SyncService.instance.init();

  // Push setup talks to OneSignal; never block the UI on it.
  unawaited(PushService.instance.init().catchError((Object _) {}));

  AppSettings.instance.displayName.value =
      FirebaseAuth.instance.currentUser?.displayName ?? '';
  unawaited(AuthService().loadCurrentStaffName());
  if (FirebaseAuth.instance.currentUser != null) {
    VerificationStore.instance.start();
    NotificationStore.instance.start();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.instance.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Unican',
          navigatorKey: NotificationRouter.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
