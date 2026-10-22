import 'dart:async';

import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class FakeSkinShare extends SharePlatform {
  final requests = <ShareParams>[];
  Completer<ShareParams> started = Completer();
  Completer<ShareResult>? pending;
  bool fail = false;

  void reset() {
    requests.clear();
    started = Completer();
    pending = null;
    fail = false;
  }

  void nextRequest() => started = Completer();

  @override
  Future<ShareResult> share(ShareParams params) async {
    requests.add(params);
    if (!started.isCompleted) started.complete(params);
    if (fail) throw StateError('Share sheet unavailable');
    return pending?.future ??
        const ShareResult('', ShareResultStatus.dismissed);
  }
}
