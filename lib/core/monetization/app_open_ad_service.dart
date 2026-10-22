import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_units.dart';
import 'ads_runtime.dart';

abstract interface class AppOpenAdService {
  Future<bool> showAtLaunch({required bool Function() canShow});
  void clearCache();
  void dispose();
}

/// An app-open ad only belongs to the launch screen, never to content opened later.
class GoogleAppOpenAdService implements AppOpenAdService {
  GoogleAppOpenAdService(this.runtime);
  final AdsRuntime runtime;
  bool _disposed = false;
  int _generation = 0;
  Completer<AppOpenAd?>? _pending;

  Future<AppOpenAd?> _load(int generation, bool Function() canShow) async {
    if (!await runtime.prepare(canShowConsent: canShow) ||
        _disposed ||
        generation != _generation ||
        !canShow()) {
      return null;
    }
    final loaded = _pending = Completer<AppOpenAd?>();
    unawaited(
      AppOpenAd.load(
        adUnitId: AdUnits.id(AdPlacement.appOpen),
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed || generation != _generation || loaded.isCompleted) {
              ad.dispose();
            } else {
              loaded.complete(ad);
            }
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open ad load failed: $error');
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      ).catchError((Object error) {
        debugPrint('App open ad unavailable: $error');
        if (!loaded.isCompleted) loaded.complete(null);
      }),
    );
    return loaded.future;
  }

  @override
  Future<bool> showAtLaunch({required bool Function() canShow}) async {
    if (_disposed ||
        !runtime.available ||
        !canShow() ||
        AdUnits.id(AdPlacement.appOpen).isEmpty ||
        !runtime.beginFullscreen(this)) {
      return false;
    }
    AppOpenAd? ad;
    var shown = false;
    final generation = _generation;
    try {
      // Includes initialization/loading, but never limits the ad once displayed.
      ad = await _load(
        generation,
        canShow,
      ).timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (ad == null || _disposed || generation != _generation || !canShow()) {
        return false;
      }
      final closed = Completer<bool>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          shown = true;
          if (!closed.isCompleted) closed.complete(true);
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('App open ad show failed: $error');
          if (!closed.isCompleted) closed.complete(false);
        },
      );
      await ad.show();
      return await closed.future;
    } catch (error) {
      debugPrint('App open ad unavailable: $error');
      return false;
    } finally {
      ad?.dispose();
      clearCache();
      runtime.endFullscreen(this, wasShown: shown);
    }
  }

  @override
  void clearCache() {
    _generation++;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _pending = null;
  }

  @override
  void dispose() {
    _disposed = true;
    clearCache();
  }
}
