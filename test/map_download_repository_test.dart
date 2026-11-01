import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/maps/data/map_download_repository.dart';
import 'package:roblox/features/maps/models/downloaded_map.dart';
import 'package:roblox/features/maps/models/map_catalog.dart';

final _archive = [0x50, 0x4B, 5, 6, ...List.filled(18, 0)];

MapItem _item(String url, {String id = 'world'}) => MapItem(
  id: id,
  name: 'Warehouse I',
  subtitle: '',
  description: '',
  category: 'Horror',
  cover: 'assets/images/warehouse.png',
  locked: false,
  edition: 'bedrock',
  downloadUrl: url,
);

void main() {
  late Directory documents;
  late LocalMapDownloadRepository repository;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('map-download-test-');
    repository = LocalMapDownloadRepository(
      documentsDirectory: () async => documents,
    );
  });
  tearDown(() async => documents.delete(recursive: true));

  Future<String> serve(Future<void> Function(HttpRequest) handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        await handler(request);
      } catch (_) {
        /* The cancellation tests close the socket. */
      }
    });
    addTearDown(() => server.close(force: true));
    return 'http://127.0.0.1:${server.port}/world/download';
  }

  test(
    'streams progress, saves complete bytes and restores after reopening',
    () async {
      final firstChunkReceived = Completer<void>();
      final url = await serve((request) async {
        request.response.headers.set(
          'content-disposition',
          "attachment; filename*=UTF-8''Warehouse%20I.mcworld",
        );
        request.response.headers.contentType = ContentType(
          'application',
          'octet-stream',
        );
        request.response.contentLength = _archive.length;
        request.response.bufferOutput = false;
        request.response.add(_archive.sublist(0, 8));
        await request.response.flush();
        await firstChunkReceived.future.timeout(const Duration(seconds: 3));
        request.response.add(_archive.sublist(8));
        await request.response.close();
      });
      final progress = <MapDownloadProgress>[];
      final file = await repository.download(
        _item(url),
        onProgress: (value) {
          progress.add(value);
          if (value.received > 0 && !firstChunkReceived.isCompleted) {
            firstChunkReceived.complete();
          }
        },
        cancellation: MapDownloadCancellation(),
      );
      expect(file.filename, 'Warehouse I.mcworld');
      expect(await File(file.path).readAsBytes(), _archive);
      expect(progress.first.received, 0);
      expect(progress.last.fraction, 1);
      expect(progress.any((p) => p.fraction! > 0 && p.fraction! < 1), isTrue);
      final reopened = LocalMapDownloadRepository(
        documentsDirectory: () async => documents,
      );
      expect((await reopened.find(_item(url)))?.path, file.path);
      expect(
        await documents
            .list(recursive: true)
            .where((f) => f.path.endsWith('.part'))
            .length,
        0,
      );

      await File(file.path).writeAsBytes([1, 2]);
      expect(
        await reopened.find(_item(url)),
        isNull,
        reason: 'truncated files are never launchable',
      );
    },
  );

  test(
    'unknown content length stays indeterminate until the file is complete',
    () async {
      final url = await serve((request) async {
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.headers.chunkedTransferEncoding = true;
        request.response.add(_archive);
        await request.response.close();
      });
      final progress = <MapDownloadProgress>[];
      final file = await repository.download(
        _item(url),
        onProgress: progress.add,
        cancellation: MapDownloadCancellation(),
      );
      expect(file.bytes, _archive.length);
      expect(
        progress.every((p) => p.total == null && p.fraction == null),
        isTrue,
      );
    },
  );

  for (final html in [true, false]) {
    test(
      'rejects ${html ? 'an HTML download page' : 'a non-archive response'} and removes partial data',
      () async {
        final url = await serve((request) async {
          request.response.headers.contentType = html
              ? ContentType.html
              : ContentType('application', 'octet-stream');
          request.response.write('<html>Download here</html>');
          await request.response.close();
        });
        await expectLater(
          repository.download(
            _item(url),
            onProgress: (_) {},
            cancellation: MapDownloadCancellation(),
          ),
          throwsFormatException,
        );
        expect(await repository.find(_item(url)), isNull);
        expect(
          await documents.list(recursive: true).where((f) => f is File).length,
          0,
        );
      },
    );
  }

  test(
    'cancellation aborts the transfer and leaves no launchable file',
    () async {
      final url = await serve((request) async {
        request.response.contentLength = _archive.length;
        request.response.add(_archive.sublist(0, 8));
        await request.response.flush();
        await Future<void>.delayed(const Duration(seconds: 1));
        request.response.add(_archive.sublist(8));
        await request.response.close();
      });
      final cancellation = MapDownloadCancellation();
      await expectLater(
        repository.download(
          _item(url),
          onProgress: (p) {
            if (p.received > 0) cancellation.cancel();
          },
          cancellation: cancellation,
        ),
        throwsA(isA<MapDownloadCancelled>()),
      );
      expect(await repository.find(_item(url)), isNull);
      expect(
        await documents.list(recursive: true).where((f) => f is File).length,
        0,
      );
    },
  );

  test('sanitizes filenames and map ids from remote data', () async {
    final url = await serve((request) async {
      request.response.headers.set(
        'content-disposition',
        'attachment; filename="../../world.mcworld"',
      );
      request.response.add(_archive);
      await request.response.close();
    });
    final item = _item(url, id: '../../outside');
    final file = await repository.download(
      item,
      onProgress: (_) {},
      cancellation: MapDownloadCancellation(),
    );
    expect(file.path.startsWith('${documents.path}/downloaded_maps/'), isTrue);
    expect(file.filename.contains('/'), isFalse);
    expect((await repository.find(item))?.path, file.path);
  });

  test('does not use a source webpage as a direct file URL', () {
    final item = MapItem(
      id: 'page',
      name: 'Page',
      subtitle: '',
      description: '',
      category: '',
      cover: '',
      locked: false,
      sourceUrl: 'https://example.com/world.html',
    );
    expect(mapFileDownloadUri(item), isNull);
  });

  test(
    'a connection closed before Content-Length never leaves a saved map',
    () async {
      final url = await serve((request) async {
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.contentLength = _archive.length;
        final socket = await request.response.detachSocket(writeHeaders: true);
        socket.add(_archive.sublist(0, 8));
        await socket.flush();
        socket.destroy();
      });
      await expectLater(
        repository.download(
          _item(url),
          onProgress: (_) {},
          cancellation: MapDownloadCancellation(),
        ),
        throwsA(isA<HttpException>()),
      );
      expect(await repository.find(_item(url)), isNull);
      expect(
        await documents.list(recursive: true).where((f) => f is File).length,
        0,
      );
    },
  );
}
