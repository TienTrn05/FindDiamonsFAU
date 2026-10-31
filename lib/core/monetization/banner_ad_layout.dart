import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_runtime.dart';

/// The free and Pro layouts share the same adaptive banner footprint.
/// Measuring the SDK size does not request or display an advertisement.
abstract final class BannerAdLayout {
  static final _sizes = Expando<Map<int, AdSize>>();
  static final _pending = Expando<Map<int, Future<AdSize>>>();

  static AdSize cached(AdsRuntime? runtime, int width) => runtime == null
      ? AdSize.banner
      : _sizes[runtime]?[width] ?? AdSize.banner;

  static Future<AdSize> resolve(AdsRuntime? runtime, int width) {
    if (runtime == null || !runtime.available || width <= 0) {
      return SynchronousFuture(AdSize.banner);
    }
    final sizes = _sizes[runtime] ??= {};
    final size = sizes[width];
    if (size != null) return SynchronousFuture(size);
    final pending = _pending[runtime] ??= {};
    return pending[width] ??= _measure(width)
        .then((size) {
          sizes[width] = size;
          return size;
        })
        .whenComplete(() {
          pending.remove(width);
        });
  }

  static Future<AdSize> _measure(int width) async {
    try {
      return await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width,
          ).timeout(const Duration(seconds: 3)) ??
          AdSize.banner;
    } catch (_) {
      return AdSize.banner;
    }
  }
}
