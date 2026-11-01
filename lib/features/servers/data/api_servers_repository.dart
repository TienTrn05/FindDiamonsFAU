import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_config.dart';
import '../models/server_catalog.dart';
import 'servers_repository.dart';

class ApiServersRepository implements RefreshableServersRepository {
  ApiServersRepository({Uri? baseUri, DateTime Function()? now})
    : baseUri = baseUri ?? ApiConfig.baseUri,
      _now = now ?? DateTime.now;

  final Uri baseUri;
  final DateTime Function() _now;
  Map<String, dynamic>? _lastLive;
  Map<String, dynamic>? _catalog;
  ServerCatalog? _cached;
  DateTime? _expiresAt;
  Future<ServerCatalog>? _pending;

  @override
  Future<ServerCatalog> load() {
    if (_pending != null) return _pending!;
    if (_cached != null && _now().isBefore(_expiresAt!)) {
      return Future.value(_cached);
    }
    return refresh();
  }

  @override
  Future<ServerCatalog> refresh() =>
      _pending ??= _fetchAndCache().whenComplete(() => _pending = null);

  Future<ServerCatalog> _fetchAndCache() async {
    final result = await _loadFromNetwork();
    _cached = result;
    _expiresAt = _now().add(const Duration(seconds: 60));
    return result;
  }

  Future<ServerCatalog> _loadFromNetwork() async {
    Map<String, dynamic> catalog;
    try {
      catalog = await _get('/api/minecraft-servers/catalog');
      if (catalog['servers'] is! List) {
        throw const FormatException('Invalid server catalog response');
      }
      _catalog = catalog;
    } catch (error) {
      if (_catalog == null) rethrow;
      catalog = _catalog!;
      debugPrint('Using cached Minecraft server catalog: $error');
    }
    Map<String, dynamic>? live;
    try {
      live = await _get('/api/minecraft-servers');
      if (live['servers'] is! List) {
        throw const FormatException('Invalid server status response');
      }
      final revision = live['fetchedAt'];
      if (revision is int &&
          _cached?.liveStatusAvailable == true &&
          _cached!.fetchedAt != null &&
          revision <= _cached!.fetchedAt!.millisecondsSinceEpoch) {
        return _cached!;
      }
      // An individual status lookup can fail inside a successful batch. Keep
      // that server's last known status instead of replacing it with Unknown.
      final previous = <String, Map<String, dynamic>>{
        for (final item in (_lastLive?['servers'] as List? ?? []))
          if (item is Map<String, dynamic> && item['id'] is String)
            item['id'] as String: item,
      };
      live = {
        ...live,
        'servers': [
          for (final item in live['servers'] as List)
            if (item is Map<String, dynamic> &&
                item['online'] == null &&
                previous[item['id']]?['online'] is bool)
              {
                ...item,
                for (final key in [
                  'online',
                  'playersOnline',
                  'playersMax',
                  'version',
                  'motd',
                  'icon',
                ])
                  key: previous[item['id']]![key],
              }
            else
              item,
        ],
      };
      _lastLive = live;
    } catch (error) {
      live = null;
      // The catalog remains useful when mcstatus.io is unavailable.
      debugPrint('Minecraft server status unavailable: $error');
      if (_cached != null) return _cached!;
    }

    final catalogServers = catalog['servers'];
    if (catalogServers is! List) {
      throw const FormatException('Invalid server catalog response');
    }
    final liveById = <String, Map<String, dynamic>>{};
    final liveServers = (live ?? _lastLive)?['servers'];
    if (liveServers is List) {
      for (final value in liveServers) {
        if (value is Map<String, dynamic> && value['id'] is String) {
          liveById[value['id'] as String] = value;
        }
      }
    }

    final servers = <ServerItem>[];
    for (var index = 0; index < catalogServers.length; index++) {
      final value = catalogServers[index];
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid server in catalog response');
      }
      final id = value['id'];
      if (id is! String || value['name'] is! String) {
        throw const FormatException('Server catalog item needs id and name');
      }
      // `banner` is the backend-hosted, cached image. `bannerSource` is the
      // original external URL and must only be a fallback for older catalogs.
      final bannerSource = [value['banner'], value['bannerSource']]
          .whereType<String>()
          .where((source) => source.trim().isNotEmpty)
          .firstOrNull;
      servers.add(
        ServerItem.fromApiJson(
          value,
          rank: index + 1,
          live: liveById[id],
          bannerUrl: bannerSource is String && bannerSource.isNotEmpty
              ? ApiConfig.assetUri(bannerSource, baseUri: baseUri)
              : null,
        ),
      );
    }

    return ServerCatalog(
      banner: displayServerBannerText(catalog['banner'], 'Minecraft servers'),
      servers: servers,
      liveStatusAvailable: live != null && live['servers'] is List,
      fetchedAt: (live ?? _lastLive)?['fetchedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              (live ?? _lastLive)!['fetchedAt'] as int,
            )
          : null,
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _getOnce(path);
      } on IOException {
        if (attempt >= 1) rethrow;
      } on TimeoutException {
        if (attempt >= 1) rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<Map<String, dynamic>> _getOnce(String path) async {
    final uri = baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$path',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Server API returned HTTP ${response.statusCode}',
            uri: uri,
          );
        }
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Invalid JSON response from $path');
        }
        return decoded;
      })().timeout(const Duration(seconds: 25));
    } finally {
      client.close(force: true);
    }
  }
}
