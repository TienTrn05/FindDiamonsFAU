import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/downloaded_map.dart';
import '../models/map_catalog.dart';

Uri? mapFileDownloadUri(MapItem item) {
  for (final value in [
    item.downloadUrl,
    item.downloadPageUrl,
    item.sourceUrl,
  ]) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      continue;
    }
    if (value == item.downloadUrl ||
        RegExp(
          r'\.(mcworld|mcpack|mcaddon|mctemplate|zip)$',
          caseSensitive: false,
        ).hasMatch(uri.path)) {
      return uri;
    }
  }
  return null;
}

class MapDownloadCancellation {
  bool _cancelled = false;
  HttpClient? _client;

  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }

  void check() {
    if (_cancelled) throw const MapDownloadCancelled();
  }

  void attach(HttpClient client) {
    check();
    _client = client;
  }
}

class MapDownloadCancelled implements Exception {
  const MapDownloadCancelled();
}

abstract interface class MapDownloadRepository {
  Future<DownloadedMap?> find(MapItem item);

  Future<DownloadedMap> download(
    MapItem item, {
    required void Function(MapDownloadProgress progress) onProgress,
    required MapDownloadCancellation cancellation,
  });
}

/// Keeps complete archives in Documents. A .part file is never exposed as ready.
class LocalMapDownloadRepository implements MapDownloadRepository {
  LocalMapDownloadRepository({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;

  Future<Directory> _folder(MapItem item) async {
    final documents = await _documentsDirectory();
    final id = base64Url.encode(utf8.encode(item.id)).replaceAll('=', '');
    return Directory('${documents.path}/downloaded_maps/map-$id');
  }

  @override
  Future<DownloadedMap?> find(MapItem item) async {
    final folder = await _folder(item);
    final manifest = File('${folder.path}/download.json');
    if (!await manifest.exists()) return null;
    try {
      final json =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      final filename = json['filename'] as String;
      final bytes = json['bytes'] as int;
      if (filename != _safeFilename(filename) || bytes <= 0) return null;
      final source = mapFileDownloadUri(item);
      if (source != null && json['source'] != source.toString()) return null;
      final file = File('${folder.path}/$filename');
      if (!await file.exists() || await file.length() != bytes) return null;
      return DownloadedMap(path: file.path, filename: filename, bytes: bytes);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<DownloadedMap> download(
    MapItem item, {
    required void Function(MapDownloadProgress progress) onProgress,
    required MapDownloadCancellation cancellation,
  }) async {
    final uri = mapFileDownloadUri(item);
    if (uri == null) {
      throw const FormatException('A direct map file URL is required.');
    }
    cancellation.check();
    final folder = await _folder(item);
    await folder.create(recursive: true);
    final partial = File('${folder.path}/download.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    RandomAccessFile? output;
    File? completedFile;
    var committed = false;
    try {
      cancellation.attach(client);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Map download returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      final mime = response.headers.contentType?.mimeType ?? '';
      if (mime == 'text/html' ||
          mime == 'application/xhtml+xml' ||
          mime.contains('json')) {
        throw const FormatException(
          'The download URL returned a page instead of a map file.',
        );
      }
      final total =
          response.contentLength > 0 &&
              response.compressionState !=
                  HttpClientResponseCompressionState.decompressed
          ? response.contentLength
          : null;
      onProgress(MapDownloadProgress(0, total));
      output = await partial.open(mode: FileMode.write);
      var received = 0;
      final signature = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        cancellation.check();
        if (signature.length < 4) {
          signature.addAll(chunk.take(4 - signature.length));
        }
        await output.writeFrom(chunk);
        received += chunk.length;
        onProgress(MapDownloadProgress(received, total));
      }
      cancellation.check();
      if (received == 0 || (total != null && total != received)) {
        throw const FormatException('The map download was incomplete.');
      }
      if (signature.length < 4 ||
          signature[0] != 0x50 ||
          signature[1] != 0x4B ||
          !((signature[2] == 3 && signature[3] == 4) ||
              (signature[2] == 5 && signature[3] == 6) ||
              (signature[2] == 7 && signature[3] == 8))) {
        throw const FormatException(
          'The downloaded file is not a Minecraft map archive.',
        );
      }
      await output.flush();
      await output.close();
      output = null;
      final filename = _filename(item, uri, response.headers);
      completedFile = await partial.rename('${folder.path}/$filename');
      final manifest = File('${folder.path}/download.json.part');
      await manifest.writeAsString(
        jsonEncode({
          'filename': filename,
          'bytes': received,
          'source': uri.toString(),
        }),
        flush: true,
      );
      await manifest.rename('${folder.path}/download.json');
      committed = true;
      return DownloadedMap(
        path: completedFile.path,
        filename: filename,
        bytes: received,
      );
    } catch (_) {
      cancellation.check();
      rethrow;
    } finally {
      client.close(force: true);
      if (output != null) await output.close();
      if (await partial.exists()) await partial.delete();
      if (!committed && completedFile != null && await completedFile.exists()) {
        await completedFile.delete();
      }
    }
  }

  String _filename(MapItem item, Uri uri, HttpHeaders headers) {
    final disposition = headers.value('content-disposition') ?? '';
    final encoded = RegExp(
      r"filename\*\s*=\s*UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    final plain = RegExp(
      r'''filename\s*=\s*"([^"]+)"|filename\s*=\s*([^;]+)''',
      caseSensitive: false,
    ).firstMatch(disposition);
    String? name;
    if (encoded != null) {
      try {
        name = Uri.decodeComponent(encoded.trim());
      } on FormatException {
        /* Use the ordinary filename. */
      }
    }
    name ??= plain?.group(1) ?? plain?.group(2);
    name ??= uri.pathSegments.isEmpty ? item.name : uri.pathSegments.last;
    var safe = _safeFilename(name);
    if (!RegExp(
      r'\.(mcworld|mcpack|mcaddon|mctemplate|zip)$',
      caseSensitive: false,
    ).hasMatch(safe)) {
      final extension = item.edition.toLowerCase().contains('bedrock')
          ? 'mcworld'
          : 'zip';
      safe = '${_safeFilename(item.name)}.$extension';
    }
    return safe;
  }

  String _safeFilename(String value) {
    final name = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    return name.isEmpty || name == '.' || name == '..' ? 'world' : name;
  }
}
