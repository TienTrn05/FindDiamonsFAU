import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_units.dart';
import 'ads_runtime.dart';

abstract interface class InterstitialAdService {
  Future<void> preload({required bool Function() canLoad});
  Future<bool> showIfReady({required bool Function() canShow});
  void clearCache();
  void dispose();
}

class GoogleInterstitialAdService implements InterstitialAdService {
  GoogleInterstitialAdService(this.runtime, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AdsRuntime runtime;
  final DateTime Function() _now;
  InterstitialAd? _cached;
  DateTime? _loadedAt;
  Future<void>? _loading;
  Completer<InterstitialAd?>? _pending;
  bool _disposed = false;
  int _generation = 0;

  void _expire() {
    if (_loadedAt != null &&
        _now().difference(_loadedAt!) >= const Duration(minutes: 55)) {
      _cached?.dispose();
      _cached = null;
      _loadedAt = null;
    }
  }

  @override
  Future<void> preload({required bool Function() canLoad}) {
    if (_disposed ||
        !runtime.available ||
        !canLoad() ||
        AdUnits.id(AdPlacement.interstitial).isEmpty) {
      return Future.value();
    }
    _expire();
    if (_cached != null) return Future.value();
    return _loading ??= _load(canLoad, _generation);
  }

  Future<void> _load(bool Function() canLoad, int generation) async {
    try {
      if (!await runtime.prepare(canShowConsent: canLoad) ||
          _disposed ||
          generation != _generation) {
        return;
      }
      final loaded = _pending = Completer<InterstitialAd?>();
      var accepting = true;
      try {
        unawaited(
          InterstitialAd.load(
            adUnitId: AdUnits.id(AdPlacement.interstitial),
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                if (!accepting ||
                    loaded.isCompleted ||
                    _disposed ||
                    generation != _generation) {
                  ad.dispose();
                } else {
                  loaded.complete(ad);
                }
              },
              onAdFailedToLoad: (error) {
                debugPrint('Interstitial load failed: $error');
                if (!loaded.isCompleted) loaded.complete(null);
              },
            ),
          ).catchError((Object error) {
            debugPrint('Interstitial unavailable: $error');
            if (!loaded.isCompleted) loaded.complete(null);
          }),
        );
        final ad = await loaded.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () => null,
        );
        if (ad == null) return;
        if (_disposed || generation != _generation) {
          ad.dispose();
          return;
        }
        _cached = ad;
        _loadedAt = _now();
      } finally {
        accepting = false;
      }
    } catch (error) {
      debugPrint('Interstitial preload failed: $error');
    } finally {
      if (generation == _generation) {
        _loading = null;
        _pending = null;
      }
    }
  }

  @override
  Future<bool> showIfReady({required bool Function() canShow}) async {
    _expire();
    if (_disposed ||
        _cached == null ||
        !canShow() ||
        !runtime.beginFullscreen(this)) {
      return false;
    }
    final ad = _cached!;
    _cached = null;
    _loadedAt = null;
    var shown = false;
    try {
      final closed = Completer<bool>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          shown = true;
          if (!closed.isCompleted) closed.complete(true);
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('Interstitial show failed: $error');
          if (!closed.isCompleted) closed.complete(false);
        },
      );
      await ad.show();
      return await closed.future;
    } catch (error) {
      debugPrint('Interstitial show unavailable: $error');
      return false;
    } finally {
      ad.dispose();
      runtime.endFullscreen(this, wasShown: shown);
    }
  }

  @override
  void clearCache() {
    _generation++;
    _cached?.dispose();
    _cached = null;
    _loadedAt = null;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _pending = null;
    _loading = null;
  }

  @override
  void dispose() {
    _disposed = true;
    clearCache();
  }
}
