import 'dart:convert';
import 'dart:io';

import '../../../core/network/api_config.dart';
import '../models/skin_item.dart';
import 'skins_repository.dart';

/// Reads the skin catalog from the local development API.
///
/// Override the address for a physical phone with
/// `--dart-define=SKINS_API_BASE_URL=http://<computer-lan-ip>:8000`.
class ApiSkinsRepository extends JsonSkinsRepository {
  ApiSkinsRepository({Uri? baseUri}) : baseUri = baseUri ?? defaultBaseUri;

  static const _configuredBaseUrl = String.fromEnvironment(
    'SKINS_API_BASE_URL',
  );

  static Uri get defaultBaseUri {
    return _configuredBaseUrl.isNotEmpty
        ? Uri.parse(_configuredBaseUrl)
        : ApiConfig.baseUri;
  }

  final Uri baseUri;

  @override
  Future<List<SkinItem>> load({String query = ''}) async {
    final localItems = await super.load();
    final localById = {for (final item in localItems) item.id: item};
    final uri = baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/api/skins',
      queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
    );

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        String message = 'Skin API returned HTTP ${response.statusCode}';
        try {
          final errorBody = jsonDecode(body);
          if (errorBody is Map && errorBody['error'] is String) {
            message = errorBody['error'] as String;
          }
        } catch (_) {
          // Keep the HTTP status message if the error response is not JSON.
        }
        throw HttpException(message, uri: uri);
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
        throw const FormatException('Invalid response from /api/skins');
      }

      return (decoded['items'] as List)
          .map((value) {
            if (value is! Map<String, dynamic>) {
              throw const FormatException('Invalid skin item from /api/skins');
            }
            final id = value['id'];
            final name = value['name'];
            if (id is! String || name is! String) {
              throw const FormatException('Skin item needs string id and name');
            }
            final local = localById[id];
            return SkinItem(
              id: id,
              name: name,
              palette: local?.palette ?? 'steve',
              locked: local?.locked ?? false,
              category: value['category'] as String?,
              previewUrl: _resolveItemUrl(
                value['previewUrl'],
                'api/skins/${Uri.encodeComponent(id)}/preview',
              ),
              downloadUrl: _resolveItemUrl(
                value['downloadUrl'],
                'api/skins/${Uri.encodeComponent(id)}/png',
              ),
              sourceUrl: _resolveItemUrl(value['sourceUrl']),
            );
          })
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  Uri? _resolveItemUrl(Object? value, [String? fallbackPath]) {
    final raw = value is String && value.isNotEmpty ? value : null;
    if (raw == null) {
      return fallbackPath == null ? null : baseUri.resolve(fallbackPath);
    }
    final parsed = Uri.tryParse(raw);
    if (parsed == null) return null;
    if (!parsed.hasScheme) return baseUri.resolve(raw);

    // Local backends often return URLs containing localhost. On a phone that
    // would point back to the phone, so reuse the configured API host instead.
    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      return baseUri.replace(
        scheme: parsed.scheme,
        path: parsed.path,
        query: parsed.hasQuery ? parsed.query : null,
        fragment: parsed.hasFragment ? parsed.fragment : null,
      );
    }
    return parsed;
  }
}
