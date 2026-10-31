import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_config.dart';
import '../models/map_catalog.dart';
import 'maps_repository.dart';

/// Uses `/api/maps` and `/api/seeds` while retaining local fallback data.
class ApiMapsRepository extends JsonMapsRepository {
  ApiMapsRepository({super.source, Uri? baseUri})
    : baseUri = baseUri ?? ApiConfig.baseUri;

  final Uri baseUri;

  @override
  Future<MapCatalog> load() async {
    final localCatalog = await super.load();
    var maps = localCatalog.items.where((item) => item.category != 'Seeds');
    var seeds = localCatalog.items.where((item) => item.category == 'Seeds');
    var versions = <String, List<String>>{};
    try {
      maps = await _loadMaps();
    } catch (error) {
      debugPrint('Map API unavailable; using bundled maps: $error');
    }
    try {
      seeds = await _loadSeeds();
    } catch (error) {
      debugPrint('Seed API unavailable; using bundled seeds: $error');
    }
    try {
      final response = await _getJson('/api/versions');
      for (final edition in ['java', 'bedrock']) {
        final raw = response[edition];
        if (raw is List) {
          versions[edition] = raw
              .whereType<String>()
              .where((version) => RegExp(r'^\d+(?:\.\d+)*$').hasMatch(version))
              .toSet()
              .toList();
        }
      }
    } catch (error) {
      debugPrint('Version API unavailable; using seed versions: $error');
    }

    return MapCatalog(
      title: localCatalog.title,
      categories: localCatalog.categories,
      initialCategory: localCatalog.initialCategory,
      items: [...maps, ...seeds],
      seedVersions: versions,
    );
  }

  Future<List<MapItem>> _loadSeeds() async => (await _getItems('/api/seeds'))
      .map((value) {
        final id = value['id'];
        final title = value['title'];
        final seed = value['seed'];
        final edition = value['edition'];
        final version = value['version'];
        if (id is! String ||
            title is! String ||
            seed is! String ||
            edition is! String ||
            version is! String) {
          throw const FormatException(
            'Seed items need string id, title, seed, edition and version',
          );
        }

        final image = value['image'];
        return MapItem(
          id: id,
          name: title,
          subtitle: '$edition · $version',
          description: value['description'] as String? ?? '',
          category: 'Seeds',
          cover: 'assets/images/block_landscape.png',
          locked: false,
          seed: seed,
          seedEdition: edition,
          seedCategory: value['category'] as String? ?? '',
          coverUrl: image is String && image.isNotEmpty
              ? ApiConfig.assetUri(image, baseUri: baseUri).toString()
              : null,
          sourceUrl: value['sourceUrl'] as String?,
          versions: [version],
        );
      })
      .toList(growable: false);

  Future<List<MapItem>> _loadMaps() async => (await _getItems('/api/maps'))
      .map((value) {
        final id = value['id'];
        final title = value['title'];
        final rawCategory = value['category'];
        final edition = value['edition'];
        if (id is! String ||
            title is! String ||
            rawCategory is! String ||
            edition is! String) {
          throw const FormatException(
            'Map items need string id, title, category and edition',
          );
        }

        final versions = value['versions'] is List
            ? List<String>.from(value['versions'] as List)
            : const <String>[];
        final categories = value['categories'] is List
            ? List<String>.from(value['categories'] as List)
            : [rawCategory];
        final image = value['image'];
        final creator = value['creator'] as String? ?? '';
        final normalizedCategory = _mapCategory(rawCategory);
        final displayCategories = {
          normalizedCategory,
          ...categories.map(_mapCategory),
        }.toList(growable: false);

        return MapItem(
          id: id,
          name: title,
          subtitle: [
            edition.toUpperCase(),
            ...versions,
            if (creator.isNotEmpty) creator,
          ].join(' · '),
          description: value['description'] as String? ?? '',
          category: normalizedCategory,
          cover: 'assets/images/block_landscape.png',
          locked: false,
          coverUrl: image is String && image.isNotEmpty
              ? ApiConfig.assetUri(image, baseUri: baseUri).toString()
              : null,
          sourceUrl: value['sourceUrl'] as String?,
          downloadPageUrl: value['downloadPageUrl'] as String?,
          downloadUrl: _resolveApiUrl(value['downloadUrl'])?.toString(),
          edition: edition,
          creator: creator,
          categories: displayCategories,
          versions: versions,
        );
      })
      .toList(growable: false);

  String _mapCategory(String category) =>
      switch (category.trim().toLowerCase()) {
        'minigame' || 'mini game' || 'minigames' => 'Mini game',
        'skyblock' => 'SkyBlock',
        'horror' => 'Horror',
        'maze' => 'Maze',
        'parkour' => 'Parkour',
        'challenge' || 'challenges' => 'Challenges',
        _ => category,
      };

  Uri? _resolveApiUrl(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final raw = value.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed == null) return null;
    if (!parsed.hasScheme) return baseUri.resolve(raw);
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

  Future<List<Map<String, dynamic>>> _getItems(String path) async {
    final decoded = await _getJson(path);
    if (decoded['items'] is! List) {
      throw FormatException('Invalid response from $path');
    }
    return (decoded['items'] as List)
        .map((value) {
          if (value is! Map<String, dynamic>) {
            throw FormatException('Invalid item from $path');
          }
          return value;
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$path',
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
        throw HttpException(
          '$path returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Invalid response from $path');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}
