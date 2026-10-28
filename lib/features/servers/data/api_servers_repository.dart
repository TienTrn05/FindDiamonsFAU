import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_config.dart';
import '../models/server_catalog.dart';
import 'servers_repository.dart';

class ApiServersRepository implements ServersRepository {
  ApiServersRepository({Uri? baseUri}) : baseUri = baseUri ?? ApiConfig.baseUri;

  final Uri baseUri;

  @override
  Future<ServerCatalog> load() async {
    final catalog = await _get('/api/minecraft-servers/catalog');
    Map<String, dynamic>? live;
    try {
      live = await _get('/api/minecraft-servers');
    } catch (error) {
      // The catalog remains useful when mcstatus.io is unavailable.
      debugPrint('Minecraft server status unavailable: $error');
    }

    final catalogServers = catalog['servers'];
    if (catalogServers is! List) {
      throw const FormatException('Invalid server catalog response');
    }
    final liveById = <String, Map<String, dynamic>>{};
    final liveServers = live?['servers'];
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
      final bannerSource = value['bannerSource'];
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
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
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
          'Server API returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Invalid JSON response from $path');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}
