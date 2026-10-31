import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Retains compressed media independently of Flutter's decoded-frame cache.
/// Evicting a decoded GIF/frame must not cause another HTTP request on scroll.
class AppImageCache {
  AppImageCache({this.maximumBytes = 64 * 1024 * 1024});
  static final shared = AppImageCache();
  final int maximumBytes;
  final _bytes = <String, Uint8List>{};
  final _pending = <String, Future<Uint8List>>{};
  int _size = 0;

  Future<Uint8List> load(String url) {
    final cached = _bytes.remove(url);
    if (cached != null) {
      _bytes[url] = cached;
      return SynchronousFuture(cached);
    }
    return _pending.putIfAbsent(
      url,
      () => _download(url).whenComplete(() {
        _pending.remove(url);
      }),
    );
  }

  Future<Uint8List> _download(String url) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final bytes = await _request(url);
        // Do not publish/cache an HTML error, partial PNG, or broken GIF.
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
        if (bytes.length > maximumBytes) {
          throw StateError('Image exceeds media cache capacity');
        }
        while (_size + bytes.length > maximumBytes && _bytes.isNotEmpty) {
          _size -= _bytes.remove(_bytes.keys.first)!.length;
        }
        _bytes[url] = bytes;
        _size += bytes.length;
        return bytes;
      } catch (_) {
        if (attempt >= 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
      }
    }
  }

  Future<Uint8List> _request(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Image HTTP ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
          if (builder.length > maximumBytes) {
            throw StateError('Image too large');
          }
        }
        return builder.takeBytes();
      })().timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }

  Future<void> preload(Iterable<String> urls) async {
    final queue = Queue<String>.of(urls.toSet());
    await Future.wait(
      List.generate(4, (_) async {
        while (queue.isNotEmpty) {
          await load(queue.removeFirst());
        }
      }),
    );
  }
}

/// Both preload and every screen use the same URL-keyed compressed cache.
class AppNetworkImage extends ImageProvider<AppNetworkImage> {
  const AppNetworkImage(this.url);
  final String url;
  @override
  Future<AppNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    AppNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _decode(decode),
    scale: 1,
    debugLabel: url,
  );
  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    try {
      final bytes = await AppImageCache.shared.load(url);
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(this));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppNetworkImage && other.url == url;
  @override
  int get hashCode => url.hashCode;
}

/// Prime the first frame too, so a newly selected server card paints immediately.
Future<void> prepareAppImageFrame(String url) async {
  final stream = AppNetworkImage(url).resolve(ImageConfiguration.empty);
  final ready = Completer<void>();
  final listener = ImageStreamListener(
    (info, _) {
      info.dispose();
      if (!ready.isCompleted) ready.complete();
    },
    onError: (Object error, StackTrace? stack) {
      if (!ready.isCompleted) ready.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  try {
    await ready.future;
  } finally {
    stream.removeListener(listener);
  }
}
