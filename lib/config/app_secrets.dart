/// App configuration secrets.
///
/// The imgbb key can be overridden at build time with:
///   --dart-define=IMGBB_API_KEY=<key>
class AppSecrets {
  AppSecrets._();

  static const String imgbbApiKey = '55331c54c78b85dea1d9b242223ba62c';
}
