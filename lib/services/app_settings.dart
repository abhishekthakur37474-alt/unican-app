import 'package:flutter/material.dart';

class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  final ValueNotifier<String> displayName = ValueNotifier<String>('');
  final ValueNotifier<bool> verificationAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<bool> reminderAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<bool> soundAlerts = ValueNotifier<bool>(true);
  final ValueNotifier<int> homeTabIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> alertsRefreshTick = ValueNotifier<int>(0);
}
