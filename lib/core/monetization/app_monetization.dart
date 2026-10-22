import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/onboarding/models/subscription_plan.dart';
import 'rewarded_ad_service.dart';
import 'ads_runtime.dart';
import 'app_open_ad_service.dart';
import 'interstitial_ad_service.dart';
import 'interstitial_schedule.dart';

/// Billing callbacks must return an entitlement verified by the billing service.
class AppMonetization extends ChangeNotifier {
  AppMonetization({
    bool isPro = kDebugMode && const bool.fromEnvironment('DEBUG_PRO'),
    this.onPurchase,
    this.onRestore,
    RewardedAdService? rewardedAds,
    AdsRuntime? adsRuntime,
    InterstitialAdService? interstitialAds,
    AppOpenAdService? appOpenAds,
    InterstitialSchedule? interstitialSchedule,
  }) : _isPro = isPro,
       adsRuntime = adsRuntime ?? AdsRuntime(),
       interstitialSchedule =
           interstitialSchedule ??
           InterstitialSchedule(
             interval: Duration(
               seconds: kDebugMode
                   ? const int.fromEnvironment(
                       'DEBUG_INTERSTITIAL_SECONDS',
                       defaultValue: 180,
                     )
                   : 180,
             ),
           ) {
    this.rewardedAds =
        rewardedAds ?? GoogleRewardedAdService(runtime: this.adsRuntime);
    this.interstitialAds =
        interstitialAds ?? GoogleInterstitialAdService(this.adsRuntime);
    this.appOpenAds = appOpenAds ?? GoogleAppOpenAdService(this.adsRuntime);
    this.adsRuntime.addListener(_adStateChanged);
  }

  final Future<bool> Function(SubscriptionPlan)? onPurchase;
  final Future<bool> Function()? onRestore;
  late final RewardedAdService rewardedAds;
  final AdsRuntime adsRuntime;
  late final InterstitialAdService interstitialAds;
  late final AppOpenAdService appOpenAds;
  bool _launchAdAttempted = false;
  final InterstitialSchedule interstitialSchedule;
  bool _foreground = false;
  DateTime? _lastClosed;
  int _privacyRevision = 0;
  final Map<String, int> _revealed = {};
  bool _isPro;

  bool get isPro => _isPro;

  /// Call again on expiry, refund, account change, or a verified store update.
  void updateEntitlement(bool active) {
    if (_isPro == active) return;
    _isPro = active;
    if (active) {
      rewardedAds.clearCache();
      interstitialAds.clearCache();
      appOpenAds.clearCache();
    }
    interstitialSchedule.reset();
    _updateClock();
    notifyListeners();
  }

  Future<bool> purchase(SubscriptionPlan plan) async {
    final active = await onPurchase?.call(plan) ?? false;
    if (active) updateEntitlement(true);
    return active;
  }

  Future<bool> restore() async {
    if (onRestore == null) return false;
    final active = await onRestore!();
    updateEntitlement(active);
    return active;
  }

  int revealedCount(String recordId) => _revealed[recordId] ?? 1;

  void rememberRevealed(String recordId, int count) {
    _revealed[recordId] = math.max(revealedCount(recordId), count);
  }

  void setForeground(bool active) {
    _foreground = active;
    _updateClock();
  }

  void _updateClock() => interstitialSchedule.setActive(
    _foreground && !_isPro && !adsRuntime.fullscreenBusy,
  );

  void _adStateChanged() {
    if (_lastClosed != adsRuntime.lastFullscreenClosedAt) {
      _lastClosed = adsRuntime.lastFullscreenClosedAt;
      interstitialSchedule.reset();
    }
    _updateClock();
    if (_privacyRevision != adsRuntime.privacyRevision) {
      _privacyRevision = adsRuntime.privacyRevision;
      rewardedAds.clearCache();
      interstitialAds.clearCache();
      appOpenAds.clearCache();
      notifyListeners();
    }
  }

  Future<bool> maybeShowInterstitial({required bool Function() canShow}) async {
    if (_isPro ||
        !_foreground ||
        !interstitialSchedule.due ||
        adsRuntime.fullscreenBusy ||
        !canShow()) {
      return false;
    }
    final shown = await interstitialAds.showIfReady(
      canShow: () =>
          !_isPro && _foreground && interstitialSchedule.due && canShow(),
    );
    if (!shown && !_isPro) {
      // Missing/late ads never delay navigation or appear after the transition.
      unawaited(interstitialAds.preload(canLoad: () => !_isPro && canShow()));
    }
    return shown;
  }

  Future<bool> showLaunchAd({required bool Function() canShow}) async {
    if (_launchAdAttempted) return false;
    _launchAdAttempted = true;
    if (_isPro) return false;
    return appOpenAds.showAtLaunch(canShow: () => !_isPro && canShow());
  }

  @override
  void dispose() {
    rewardedAds.dispose();
    interstitialAds.dispose();
    appOpenAds.dispose();
    adsRuntime.removeListener(_adStateChanged);
    adsRuntime.dispose();
    super.dispose();
  }
}

class MonetizationScope extends InheritedNotifier<AppMonetization> {
  const MonetizationScope({
    super.key,
    required AppMonetization controller,
    required super.child,
  }) : super(notifier: controller);

  static AppMonetization? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MonetizationScope>()?.notifier;
}
