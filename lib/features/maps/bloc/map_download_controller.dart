import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/map_download_repository.dart';
import '../models/downloaded_map.dart';
import '../models/map_catalog.dart';

class MapDownloadController extends ChangeNotifier {
  MapDownloadController(this.item, this.repository);

  final MapItem item;
  final MapDownloadRepository repository;
  DownloadedMap? saved;
  MapDownloadProgress progress = const MapDownloadProgress(0, null);
  Object? error;
  bool restoring = true;
  bool downloading = false;
  bool _disposed = false;
  Future<void>? _restoring;
  Future<void>? _pending;
  MapDownloadCancellation? _cancellation;

  bool get canDownload => mapFileDownloadUri(item) != null;

  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    try {
      final result = await repository.find(item);
      if (!_disposed) saved = result;
    } catch (exception) {
      debugPrint('Saved map could not be restored: $exception');
    } finally {
      restoring = false;
      _notify();
    }
  }

  Future<void> download() {
    if (_disposed) return Future.value();
    return _pending ??= _download().whenComplete(() => _pending = null);
  }

  Future<void> _download() async {
    await restore();
    if (_disposed || saved != null) return;
    downloading = true;
    error = null;
    progress = const MapDownloadProgress(0, null);
    _notify();
    final cancellation = _cancellation = MapDownloadCancellation();
    final clock = Stopwatch()..start();
    var lastPercent = -1;
    try {
      final result = await repository.download(
        item,
        cancellation: cancellation,
        onProgress: (value) {
          if (_disposed) return;
          progress = value;
          final percent = value.fraction == null
              ? -1
              : (value.fraction! * 100).floor();
          if (percent != lastPercent ||
              clock.elapsedMilliseconds >= 100 ||
              value.received == value.total) {
            lastPercent = percent;
            clock.reset();
            _notify();
          }
        },
      );
      if (!_disposed) saved = result;
    } on MapDownloadCancelled {
      // The owner was disposed; the partial file is removed by the repository.
    } catch (exception) {
      if (!_disposed) error = exception;
    } finally {
      downloading = false;
      _cancellation = null;
      _notify();
    }
  }

  void invalidateSavedFile() {
    saved = null;
    error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancellation?.cancel();
    super.dispose();
  }
}
