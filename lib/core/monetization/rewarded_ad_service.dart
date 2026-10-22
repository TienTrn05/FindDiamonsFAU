import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_runtime.dart';

enum RewardedAdResult { earned, dismissed, unavailable, unsupported }

abstract interface class RewardedAdService {
  Future<void> preload({required bool Function() canLoad});
  Future<RewardedAdResult> show({required bool Function() canShow});
  void clearCache();
  void dispose();
}

class GoogleRewardedAdService implements RewardedAdService {
  GoogleRewardedAdService({DateTime Function()? now, AdsRuntime? runtime})
    : _now = now ?? DateTime.now,
      runtime = runtime ?? AdsRuntime(),
      _ownsRuntime = runtime == null;

  final AdsRuntime runtime;
  final bool _ownsRuntime;

  static const _cacheLifetime = Duration(minutes: 55);
  static const _tapWait = Duration(seconds: 5);
  final DateTime Function() _now;
  bool _busy = false;
  bool _disposed = false;
  int _generation = 0;
  RewardedAd? _cachedAd;
  DateTime? _cachedAt;
  Future<void>? _loading;
  Completer<RewardedAd?>? _pendingLoad;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _unitId {
    final android = defaultTargetPlatform == TargetPlatform.android;
    // Debug builds always use Google's sample units, even with production defines.
    if (kDebugMode) {
      return android
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return android
        ? const String.fromEnvironment('ADMOB_REWARDED_ANDROID')
        : const String.fromEnvironment('ADMOB_REWARDED_IOS');
  }

  Future<bool> _prepare(bool Function() canShow) =>
      runtime.prepare(canShowConsent: canShow);

  void _discardExpiredAd() {
    final cachedAt = _cachedAt;
    if (cachedAt != null && _now().difference(cachedAt) >= _cacheLifetime) {
      _cachedAd?.dispose();
      _cachedAd = null;
      _cachedAt = null;
    }
  }

  @override
  Future<void> preload({required bool Function() canLoad}) {
    if (_disposed ||
        !runtime.available ||
        _unitId.isEmpty ||
        _busy ||
        !canLoad()) {
      return Future<void>.value();
    }
    _discardExpiredAd();
    if (_cachedAd != null) return Future<void>.value();
    // All callers share one request, including a tap while preload is running.
    return _loading ??= _load(canLoad, _generation);
  }

  Future<void> _load(bool Function() canLoad, int generation) async {
    var accepting = true;
    try {
      if (!await _prepare(canLoad) || _disposed || generation != _generation) {
        return;
      }
      final load = _pendingLoad = Completer<RewardedAd?>();
      unawaited(
        RewardedAd.load(
          adUnitId: _unitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (!accepting ||
                  _disposed ||
                  generation != _generation ||
                  load.isCompleted) {
                ad.dispose();
              } else {
                load.complete(ad);
              }
            },
            onAdFailedToLoad: (error) {
              debugPrint('Rewarded ad load failed: $error');
              if (!load.isCompleted) load.complete(null);
            },
          ),
        ).catchError((Object error) {
          debugPrint('Rewarded ad load unavailable: $error');
          if (!load.isCompleted) load.complete(null);
        }),
      );
      final ad = await load.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );
      accepting = false;
      if (ad == null) return;
      // Keep a finished preload across navigation. It never displays itself;
      // show() checks the current page again before consuming the cached ad.
      if (_disposed || generation != _generation) {
        ad.dispose();
        return;
      }
      _cachedAd = ad;
      _cachedAt = _now();
    } catch (error) {
      debugPrint('Rewarded ad preload unavailable: $error');
    } finally {
      accepting = false;
      if (generation == _generation) {
        _loading = null;
        _pendingLoad = null;
      }
    }
  }

  @override
  Future<RewardedAdResult> show({required bool Function() canShow}) async {
    if (!supported) return RewardedAdResult.unsupported;
    if (_disposed || _busy || _unitId.isEmpty || !canShow()) {
      return RewardedAdResult.unavailable;
    }
    final ready = preload(canLoad: canShow);
    if (!runtime.beginFullscreen(this)) return RewardedAdResult.unavailable;
    _busy = true;
    var wasShown = false;
    RewardedAd? loaded;
    try {
      // Timing out a tap never schedules a later automatic display. The shared
      // preload may finish in the background and be used by the next tap.
      await ready.timeout(_tapWait);
      _discardExpiredAd();
      if (_disposed || !canShow()) return RewardedAdResult.unavailable;
      loaded = _cachedAd;
      _cachedAd = null;
      _cachedAt = null;
      if (loaded == null) return RewardedAdResult.unavailable;

      final closed = Completer<RewardedAdResult>();
      var earned = false;
      loaded.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          wasShown = true;
          if (!closed.isCompleted) {
            closed.complete(
              earned ? RewardedAdResult.earned : RewardedAdResult.dismissed,
            );
          }
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('Rewarded ad show failed: $error');
          if (!closed.isCompleted) {
            closed.complete(RewardedAdResult.unavailable);
          }
        },
      );
      await loaded.show(onUserEarnedReward: (_, _) => earned = true);
      return await closed.future;
    } catch (error) {
      debugPrint('Rewarded ad unavailable: $error');
      return RewardedAdResult.unavailable;
    } finally {
      loaded?.dispose();
      _busy = false;
      runtime.endFullscreen(this, wasShown: wasShown);
    }
  }

  @override
  void clearCache() {
    _generation++;
    _cachedAd?.dispose();
    _cachedAd = null;
    _cachedAt = null;
    final pending = _pendingLoad;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _pendingLoad = null;
    _loading = null;
  }

  @override
  void dispose() {
    _disposed = true;
    clearCache();
    if (_ownsRuntime) runtime.dispose();
  }

  Future<bool> privacyOptionsRequired() => runtime.privacyOptionsRequired();

  Future<void> showPrivacyOptions() async {
    clearCache();
    await runtime.showPrivacyOptions();
  }
}
