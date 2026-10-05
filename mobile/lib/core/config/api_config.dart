import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    final url = configured.isNotEmpty ? configured :
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
    validate(url, release: kReleaseMode);
    return url.replaceFirst(RegExp(r'/+$'), '');
  }

  static void validate(String url, {bool release = false}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme) || uri.userInfo.isNotEmpty ||
        uri.hasQuery || uri.hasFragment || (release && uri.scheme != 'https')) {
      throw const FormatException('Set API_BASE_URL to a valid API URL. Release builds require HTTPS.');
    }
  }
}
