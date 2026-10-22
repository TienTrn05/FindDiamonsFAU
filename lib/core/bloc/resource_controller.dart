import 'package:flutter/foundation.dart';

/// Shared loading/error lifecycle; each feature owns its repository and actions.
abstract class ResourceController<T> extends ChangeNotifier {
  T? data;
  Object? error;
  bool loading = false;
  bool _disposed = false;
  Future<void>? _pending;

  Future<T> fetch();

  Future<void> load() {
    if (_disposed) return Future.value();
    return _pending ??= _load().whenComplete(() => _pending = null);
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    refresh();
    try {
      final result = await fetch();
      if (!_disposed) data = result;
    } catch (exception) {
      if (!_disposed) error = exception;
    } finally {
      loading = false;
      refresh();
    }
  }

  @protected
  void refresh() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
