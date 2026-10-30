import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/models/search_record.dart';
import '../../../core/network/api_config.dart';
import '../models/find_catalog.dart';
import 'find_repository.dart';

/// Loads the ore catalog and exact Java ore positions from the backend.
class ApiFindRepository extends JsonFindRepository {
  ApiFindRepository({super.source, Uri? baseUri})
    : baseUri = baseUri ?? ApiConfig.baseUri;

  final Uri baseUri;
  Future<FindCatalog>? _apiCatalog;

  @override
  Future<FindCatalog> load() => _apiCatalog ??= _loadApiCatalog();

  Future<FindCatalog> _loadApiCatalog() async {
    final bundled = await super.load();
    final versions = await _loadVersions(bundled.versions);
    if (versions.isEmpty) {
      throw const FormatException('No game versions are configured.');
    }

    try {
      final (statusCode, body) = await _send('/api/ores');
      if (statusCode < 200 || statusCode >= 300) {
        throw HttpException(
          _errorMessage(body),
          uri: baseUri.resolve('/api/ores'),
        );
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final ores = (decoded['ores'] as List)
          .map((item) => OreOption.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      if (ores.isEmpty) throw const FormatException('Ore catalog is empty.');
      return FindCatalog(
        title: bundled.title,
        help: bundled.help,
        versions: versions,
        ores: ores,
        positions: bundled.positions,
      );
    } catch (error) {
      debugPrint('Ore API unavailable; using bundled ore catalog: $error');
      return FindCatalog(
        title: bundled.title,
        help: bundled.help,
        versions: versions,
        ores: bundled.ores,
        positions: bundled.positions,
      );
    }
  }

  Future<List<GameVersion>> _loadVersions(
    List<GameVersion> fallback,
  ) async {
    try {
      final (statusCode, body) = await _send('/api/versions');
      if (statusCode < 200 || statusCode >= 300) {
        throw HttpException('GET /api/versions returned HTTP $statusCode');
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final versions = <GameVersion>[];
      for (final edition in ['java', 'bedrock']) {
        final rawVersions = decoded[edition];
        if (rawVersions is! List) continue;
        versions.addAll(
          rawVersions
              .whereType<String>()
              .where((version) => RegExp(r'^\d+(?:\.\d+)*$').hasMatch(version))
              .map((version) => GameVersion(
                    id: '${edition}_$version',
                    label: '$version ${edition == 'java' ? 'Java' : 'Bedrock'} Edition',
                    edition: edition,
                    apiVersion: version,
                  )),
        );
      }
      return versions.isEmpty ? fallback : versions;
    } catch (error) {
      debugPrint(
        'Version API unavailable; using bundled versions: $error',
      );
      return fallback;
    }
  }

  @override
  Future<SearchRecord> search(FindQuery query) async {
    final version = query.version.apiVersion.isNotEmpty
        ? query.version.apiVersion
        : RegExp(r'\d+\.\d+').firstMatch(query.version.label)?.group(0) ?? '';
    if (version.isEmpty) {
      throw const FormatException('The selected Java version is invalid.');
    }

    final uri = _uri('/api/plan');
    final (statusCode, body) = await _send(
      '/api/plan',
      payload: {
        'seed': query.seed,
        'edition': query.version.edition,
        'version': version,
        'mode': 'exact',
        'x': query.x,
        'z': query.z,
        'ore': query.ore.id,
      },
    );
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException(_errorMessage(body), uri: uri);
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final points = (decoded['points'] as List? ?? const [])
        .map((point) {
          final value = point as Map<String, dynamic>;
          return OrePosition(
            x: (value['x'] as num).toInt(),
            y: (value['y'] as num).toInt(),
            z: (value['z'] as num).toInt(),
            count: 1,
          );
        })
        .toList(growable: false);
    final now = DateTime.now();
    final responseOreName = decoded['oreName'];
    return SearchRecord(
      id: now.microsecondsSinceEpoch.toString(),
      seed: query.seed,
      playerX: query.x,
      playerZ: query.z,
      version: query.version.label,
      oreId: query.ore.id,
      oreName: responseOreName is String ? responseOreName : query.ore.name,
      positions: points,
      createdAt: now,
      revealedCount: math.min(points.length, 2),
    );
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Use the response body below if it isn't JSON.
    }
    return body.isEmpty ? 'The API request failed.' : body;
  }

  Uri _uri(String path) => baseUri.replace(
    path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$path',
  );

  Future<(int, String)> _send(
    String path, {
    Map<String, Object?>? payload,
  }) async {
    final uri = _uri(path);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = payload == null
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (payload != null) {
        request.headers.contentType = ContentType.json;
        final body = utf8.encode(jsonEncode(payload));
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      return (response.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }
}
