import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:roblox/common/widgets/ad_placements.dart';
import 'package:roblox/core/monetization/ads_runtime.dart';
import 'package:roblox/core/monetization/app_open_ad_service.dart';
import 'package:roblox/core/monetization/app_monetization.dart';
import 'package:roblox/core/monetization/interstitial_ad_service.dart';
import 'package:roblox/core/monetization/interstitial_schedule.dart';
import 'package:roblox/core/monetization/rewarded_ad_service.dart';

class _Interstitial implements InterstitialAdService {
  _Interstitial(this.runtime);
  final AdsRuntime runtime;
  int shows = 0;
  int preloads = 0;
  int clears = 0;
  bool ready = true;
  @override
  Future<void> preload({required bool Function() canLoad}) async {
    if (canLoad()) preloads++;
  }

  @override
  Future<bool> showIfReady({required bool Function() canShow}) async {
    if (!ready || !canShow() || !runtime.beginFullscreen(this)) return false;
    shows++;
    runtime.endFullscreen(this, wasShown: true);
    return true;
  }

  @override
  void clearCache() {
    clears++;
  }

  @override
  void dispose() {}
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final channel = instanceManager.channel;
  final calls = <MethodCall>[];

  Future<void> emit(
    int id,
    String event, [
    Map<String, Object?> extra = const {},
  ]) async {
    final handled = Completer<void>();
    binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': event, ...extra}),
      ),
      (_) => handled.complete(),
    );
    await handled.future;
  }

  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus({});
      }
      if (call.method == 'AdSize#getLargeAnchoredAdaptiveBannerAdSize') {
        return 50;
      }
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method == 'create') return 0;
        if (call.method == 'resize') {
          return {
            'width': call.arguments['width'],
            'height': call.arguments['height'],
          };
        }
        return null;
      },
    );
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    );
  });

  testWidgets(
    'app open ad shows on launch and releases shared lock after close',
    (tester) async {
      final runtime = AdsRuntime();
      final ads = GoogleAppOpenAdService(runtime);
      final result = ads.showAtLaunch(canShow: () => true);
      await tester.pump();
      final load = calls.singleWhere((c) => c.method == 'loadAppOpenAd');
      expect(
        load.arguments['adUnitId'],
        'ca-app-pub-3940256099942544/9257395921',
      );
      final id = load.arguments['adId'] as int;
      await emit(id, 'onAdLoaded');
      await tester.pump();
      expect(runtime.fullscreenBusy, isTrue);
      expect(calls.where((c) => c.method == 'showAdWithoutView'), hasLength(1));
      await emit(id, 'onAdDismissedFullScreenContent');
      expect(await result, isTrue);
      expect(runtime.fullscreenBusy, isFalse);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      ads.dispose();
      runtime.dispose();
    },
  );

  testWidgets(
    'launch ad waits at most five seconds and never opens from a late load',
    (tester) async {
      final runtime = AdsRuntime();
      final ads = GoogleAppOpenAdService(runtime);
      final result = ads.showAtLaunch(canShow: () => true);
      await tester.pump();
      final id =
          calls
                  .singleWhere((c) => c.method == 'loadAppOpenAd')
                  .arguments['adId']
              as int;
      await tester.pump(const Duration(seconds: 5));
      expect(await result, isFalse);
      await emit(id, 'onAdLoaded');
      await tester.pump();
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      expect(runtime.fullscreenBusy, isFalse);
      ads.dispose();
      runtime.dispose();
    },
  );

  testWidgets('launch ad skips a covered or backgrounded launch screen', (
    tester,
  ) async {
    final runtime = AdsRuntime();
    final ads = GoogleAppOpenAdService(runtime);
    var current = true;
    final result = ads.showAtLaunch(canShow: () => current);
    await tester.pump();
    final id =
        calls.singleWhere((c) => c.method == 'loadAppOpenAd').arguments['adId']
            as int;
    current = false;
    await emit(id, 'onAdLoaded');
    expect(await result, isFalse);
    expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
    expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
    ads.dispose();
    runtime.dispose();
  });

  test(
    'three-minute schedule excludes background, full-screen ads and Pro',
    () async {
      var now = DateTime(2026);
      final runtime = AdsRuntime(now: () => now);
      final ads = _Interstitial(runtime);
      final schedule = InterstitialSchedule(now: () => now);
      final access = AppMonetization(
        adsRuntime: runtime,
        interstitialAds: ads,
        interstitialSchedule: schedule,
      );
      access.setForeground(true);
      now = now.add(const Duration(minutes: 2));
      expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
      access.setForeground(false);
      now = now.add(const Duration(hours: 1));
      access.setForeground(true);
      now = now.add(const Duration(seconds: 59));
      expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(await access.maybeShowInterstitial(canShow: () => false), isFalse);
      expect(await access.maybeShowInterstitial(canShow: () => true), isTrue);
      expect(ads.shows, 1);
      now = now.add(const Duration(seconds: 15));
      expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
      now = now.add(const Duration(minutes: 3));
      final rewarded = Object();
      expect(runtime.beginFullscreen(rewarded), isTrue);
      now = now.add(const Duration(seconds: 60));
      expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
      runtime.endFullscreen(rewarded, wasShown: true);
      expect(schedule.elapsed, Duration.zero);
      now = now.add(const Duration(minutes: 3));
      access.updateEntitlement(true);
      expect(ads.clears, 1);
      expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
      access.updateEntitlement(false);
      expect(schedule.due, isFalse);
      access.dispose();
    },
  );

  test('missing interstitial never blocks navigation', () async {
    var now = DateTime(2026);
    final runtime = AdsRuntime(now: () => now);
    final ads = _Interstitial(runtime)..ready = false;
    final access = AppMonetization(
      adsRuntime: runtime,
      interstitialAds: ads,
      interstitialSchedule: InterstitialSchedule(now: () => now),
    );
    access.setForeground(true);
    now = now.add(const Duration(minutes: 3));
    expect(await access.maybeShowInterstitial(canShow: () => true), isFalse);
    expect(ads.preloads, 1);
    expect(ads.shows, 0);
    access.dispose();
  });

  testWidgets(
    'preloaded interstitial is used once and does not appear after a missed transition',
    (tester) async {
      final runtime = AdsRuntime();
      final ads = GoogleInterstitialAdService(runtime);
      final preload = ads.preload(canLoad: () => true);
      await tester.pump();
      expect(await ads.showIfReady(canShow: () => true), isFalse);
      final id =
          calls
                  .singleWhere((c) => c.method == 'loadInterstitialAd')
                  .arguments['adId']
              as int;
      await emit(id, 'onAdLoaded');
      await preload;
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      expect(await ads.showIfReady(canShow: () => false), isFalse);
      final shown = ads.showIfReady(canShow: () => true);
      await tester.pump();
      expect(runtime.fullscreenBusy, isTrue);
      await emit(id, 'onAdDismissedFullScreenContent');
      expect(await shown, isTrue);
      expect(runtime.fullscreenBusy, isFalse);
      expect(runtime.lastFullscreenClosedAt, isNotNull);
      expect(await ads.showIfReady(canShow: () => true), isFalse);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      ads.dispose();
      runtime.dispose();
    },
  );

  testWidgets('rewarded ad and interstitial share the full-screen lock', (
    tester,
  ) async {
    final runtime = AdsRuntime();
    final interstitial = GoogleInterstitialAdService(runtime);
    final rewarded = GoogleRewardedAdService(runtime: runtime);
    final preload = interstitial.preload(canLoad: () => true);
    await tester.pump();
    final interstitialId =
        calls
                .singleWhere((c) => c.method == 'loadInterstitialAd')
                .arguments['adId']
            as int;
    await emit(interstitialId, 'onAdLoaded');
    await preload;
    final reward = rewarded.show(canShow: () => true);
    await tester.pump();
    expect(await interstitial.showIfReady(canShow: () => true), isFalse);
    final rewardId =
        calls.singleWhere((c) => c.method == 'loadRewardedAd').arguments['adId']
            as int;
    await emit(rewardId, 'onAdLoaded');
    await tester.pump();
    await emit(rewardId, 'onAdDismissedFullScreenContent');
    expect(await reward, RewardedAdResult.dismissed);
    final shown = interstitial.showIfReady(canShow: () => true);
    await tester.pump();
    await emit(interstitialId, 'onAdDismissedFullScreenContent');
    expect(await shown, isTrue);
    expect(
      calls.where((c) => c.method == 'MobileAds#initialize'),
      hasLength(1),
    );
    rewarded.dispose();
    interstitial.dispose();
    runtime.dispose();
  });

  testWidgets('cleared interstitial discards late SDK callback', (
    tester,
  ) async {
    final runtime = AdsRuntime();
    final ads = GoogleInterstitialAdService(runtime);
    final preload = ads.preload(canLoad: () => true);
    await tester.pump();
    final id =
        calls
                .singleWhere((c) => c.method == 'loadInterstitialAd')
                .arguments['adId']
            as int;
    ads.clearCache();
    await preload;
    await emit(id, 'onAdLoaded');
    await tester.pump();
    expect(await ads.showIfReady(canShow: () => true), isFalse);
    expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
    ads.dispose();
    runtime.dispose();
  });

  testWidgets(
    'banner and Special Offer render SDK views and disappear with Pro',
    (tester) async {
      final access = AppMonetization();
      await tester.pumpWidget(
        MonetizationScope(
          controller: access,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpecialOfferAd(),
                      const BannerAdSlot(),
                      Container(key: const ValueKey('nav'), height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final bannerId =
          calls.singleWhere((c) => c.method == 'loadBannerAd').arguments['adId']
              as int;
      final nativeLoad = calls.singleWhere((c) => c.method == 'loadNativeAd');
      final nativeId = nativeLoad.arguments['adId'] as int;
      expect(nativeLoad.arguments['nativeTemplateStyle'], isNotNull);
      await emit(bannerId, 'onAdLoaded');
      await emit(nativeId, 'onAdLoaded');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('bottom-ad-banner')), findsOneWidget);
      expect(find.byKey(const ValueKey('special-offer-ad')), findsOneWidget);
      expect(find.text('Special Offer'), findsOneWidget);
      expect(find.byType(AdWidget), findsNWidgets(2));
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('bottom-ad-banner'))).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(const ValueKey('nav'))).dy,
        ),
      );
      await emit(nativeId, 'onAdOpened');
      expect(access.adsRuntime.fullscreenBusy, isTrue);
      await emit(nativeId, 'onAdClosed');
      expect(access.adsRuntime.fullscreenBusy, isFalse);
      access.updateEntitlement(true);
      await tester.pump();
      expect(find.byType(AdWidget), findsNothing);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      access.dispose();
    },
  );
}
