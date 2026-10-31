import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment('SKINS_API_BASE_URL'),
  );

  static Uri get baseUri {
    if (_baseUrl.isNotEmpty) return Uri.parse(_baseUrl);
    // Android debug builds establish `adb reverse tcp:8000 tcp:8000` before
    // launch. Use the same localhost backend as the desktop browser; bypass
    // emulator gateway transfers that can close before the full body arrives.
    final host = defaultTargetPlatform == TargetPlatform.android && !kDebugMode
        ? '10.0.2.2'
        : '127.0.0.1';
    return Uri(scheme: 'http', host: host, port: 8000);
  }

  static Uri assetUri(String path, {Uri? baseUri}) {
    final base = baseUri ?? ApiConfig.baseUri;
    final trimmed = path.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
        return base.replace(
          scheme: parsed.scheme,
          path: parsed.path,
          query: parsed.hasQuery ? parsed.query : null,
          fragment: parsed.hasFragment ? parsed.fragment : null,
        );
      }
      return parsed;
    }
    if (trimmed.startsWith('/api/assets/')) return base.resolve(trimmed);

    final relativePath = trimmed
        .replaceFirst(RegExp(r'^/+'), '')
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    return base.resolve('/api/assets/$relativePath');
  }
}
