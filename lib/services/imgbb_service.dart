import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

/// Uploads captured photos to imgbb and returns public URLs.
///
/// The API key is resolved in this order:
///  1. `--dart-define=IMGBB_API_KEY=<key>`
///  2. `AppSecrets.imgbbApiKey` in the git-ignored `config/app_secrets.dart`
///
/// When no key is available, photo upload is skipped and the verification
/// metadata is still synced (photos stay on the device).
class ImgbbService {
  ImgbbService._();

  static final ImgbbService instance = ImgbbService._();

  static const String _apiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: AppSecrets.imgbbApiKey,
  );
  static const String _uploadEndpoint = 'https://api.imgbb.com/1/upload';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns the hosted image URL, or null when the upload failed.
  Future<String?> upload(String filePath) async {
    if (!isConfigured) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final uri = Uri.parse('$_uploadEndpoint?key=$_apiKey');
      final response = await http
          .post(uri, body: <String, String>{'image': base64Encode(bytes)})
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! Map) return null;

      final url = (data['display_url'] ?? data['url'])?.toString();
      if (url == null || url.isEmpty) return null;
      return url;
    } catch (_) {
      return null;
    }
  }
}
