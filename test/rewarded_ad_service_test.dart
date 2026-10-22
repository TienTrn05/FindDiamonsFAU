import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Use the SDK codec to exercise real load/reward/dismiss callbacks over its channel.
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:roblox/core/monetization/rewarded_ad_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final channel = instanceManager.channel;
  final calls = <MethodCall>[];

  Future<void> emit(
    int adId,
    String event, [
    Map<String, Object?> extra = const {},
  ]) async {
    final handled = Completer<void>();
    binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': adId, 'eventName': event, ...extra}),
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
      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'preload keeps one ad ready and a tap uses it without another load',
    (tester) async {
      final service = GoogleRewardedAdService();
      final warming = service.preload(canLoad: () => true);
      final shared = service.preload(canLoad: () => true);
      expect(identical(warming, shared), isTrue);
      await tester.pump();
      final load = calls.singleWhere((call) => call.method == 'loadRewardedAd');
      final id = load.arguments['adId'] as int;
      await emit(id, 'onAdLoaded');
      await warming;
      await shared;
      await service.preload(canLoad: () => true);
      expect(
        calls.where((call) => call.method == 'loadRewardedAd'),
        hasLength(1),
      );
      expect(
        calls.where((call) => call.method == 'showAdWithoutView'),
        isEmpty,
      );

      final result = service.show(canShow: () => true);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'loadRewardedAd'),
        hasLength(1),
      );
      expect(
        calls
            .singleWhere((call) => call.method == 'showAdWithoutView')
            .arguments['adId'],
        id,
      );
      await emit(id, 'onAdDismissedFullScreenContent');
      expect(await result, RewardedAdResult.dismissed);

      final next = service.preload(canLoad: () => true);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'loadRewardedAd'),
        hasLength(2),
      );
      final nextId =
          calls
                  .lastWhere((call) => call.method == 'loadRewardedAd')
                  .arguments['adId']
              as int;
      expect(nextId, isNot(id));
      await emit(nextId, 'onAdLoaded');
      await next;
      service.dispose();
      await tester.pump();
      expect(calls.where((call) => call.method == 'disposeAd'), hasLength(2));
    },
  );

  testWidgets(
    'tap during preload shares request and only shows after explicit tap',
    (tester) async {
      final service = GoogleRewardedAdService();
      final warming = service.preload(canLoad: () => true);
      await tester.pump();
      final result = service.show(canShow: () => true);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'loadRewardedAd'),
        hasLength(1),
      );
      final id =
          calls
                  .singleWhere((call) => call.method == 'loadRewardedAd')
                  .arguments['adId']
              as int;
      await emit(id, 'onAdLoaded');
      await warming;
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'showAdWithoutView'),
        hasLength(1),
      );
      await emit(id, 'onAdDismissedFullScreenContent');
      expect(await result, RewardedAdResult.dismissed);
      service.dispose();
    },
  );

  testWidgets(
    'tap stops waiting after five seconds and late load waits for next tap',
    (tester) async {
      final service = GoogleRewardedAdService();
      final result = service.show(canShow: () => true);
      await tester.pump();
      final id =
          calls
                  .singleWhere((call) => call.method == 'loadRewardedAd')
                  .arguments['adId']
              as int;
      await tester.pump(const Duration(seconds: 5));
      expect(await result, RewardedAdResult.unavailable);
      await emit(id, 'onAdLoaded');
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'showAdWithoutView'),
        isEmpty,
      );
      final retry = service.show(canShow: () => true);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'loadRewardedAd'),
        hasLength(1),
      );
      expect(
        calls
            .singleWhere((call) => call.method == 'showAdWithoutView')
            .arguments['adId'],
        id,
      );
      await emit(id, 'onAdDismissedFullScreenContent');
      expect(await retry, RewardedAdResult.dismissed);
      service.dispose();
    },
  );

  testWidgets('expired cached ad is replaced before display', (tester) async {
    var now = DateTime(2026);
    final service = GoogleRewardedAdService(now: () => now);
    var warming = service.preload(canLoad: () => true);
    await tester.pump();
    final oldId =
        calls
                .singleWhere((call) => call.method == 'loadRewardedAd')
                .arguments['adId']
            as int;
    await emit(oldId, 'onAdLoaded');
    await warming;
    now = now.add(const Duration(minutes: 55));
    warming = service.preload(canLoad: () => true);
    await tester.pump();
    expect(
      calls.where((call) => call.method == 'loadRewardedAd'),
      hasLength(2),
    );
    expect(
      calls.singleWhere((call) => call.method == 'disposeAd').arguments['adId'],
      oldId,
    );
    final id =
        calls
                .lastWhere((call) => call.method == 'loadRewardedAd')
                .arguments['adId']
            as int;
    await emit(id, 'onAdLoaded');
    await warming;
    final result = service.show(canShow: () => true);
    await tester.pump();
    expect(
      calls
          .singleWhere((call) => call.method == 'showAdWithoutView')
          .arguments['adId'],
      id,
    );
    await emit(id, 'onAdDismissedFullScreenContent');
    expect(await result, RewardedAdResult.dismissed);
    service.dispose();
  });

  testWidgets('clearing in-flight cache cannot overwrite a later request', (
    tester,
  ) async {
    final service = GoogleRewardedAdService();
    final first = service.preload(canLoad: () => true);
    await tester.pump();
    final oldId =
        calls
                .singleWhere((call) => call.method == 'loadRewardedAd')
                .arguments['adId']
            as int;
    service.clearCache();
    final next = service.preload(canLoad: () => true);
    await tester.pump();
    await first;
    final id =
        calls
                .lastWhere((call) => call.method == 'loadRewardedAd')
                .arguments['adId']
            as int;
    expect(id, isNot(oldId));
    await emit(oldId, 'onAdLoaded');
    await emit(id, 'onAdLoaded');
    await next;
    final result = service.show(canShow: () => true);
    await tester.pump();
    expect(
      calls.where((call) => call.method == 'loadRewardedAd'),
      hasLength(2),
    );
    expect(
      calls
          .singleWhere((call) => call.method == 'showAdWithoutView')
          .arguments['adId'],
      id,
    );
    await emit(id, 'onAdDismissedFullScreenContent');
    expect(await result, RewardedAdResult.dismissed);
    service.dispose();
  });

  testWidgets('disposed service rejects late loads and all further requests', (
    tester,
  ) async {
    final service = GoogleRewardedAdService();
    final warming = service.preload(canLoad: () => true);
    await tester.pump();
    final id =
        calls
                .singleWhere((call) => call.method == 'loadRewardedAd')
                .arguments['adId']
            as int;
    service.dispose();
    await warming;
    await emit(id, 'onAdLoaded');
    await tester.pump();
    await service.preload(canLoad: () => true);
    expect(
      await service.show(canShow: () => true),
      RewardedAdResult.unavailable,
    );
    expect(
      calls.where((call) => call.method == 'loadRewardedAd'),
      hasLength(1),
    );
    expect(calls.where((call) => call.method == 'showAdWithoutView'), isEmpty);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  for (final earned in [false, true]) {
    testWidgets('SDK dismiss ${earned ? 'with' : 'without'} earned callback', (
      tester,
    ) async {
      final service = GoogleRewardedAdService();
      final result = service.show(canShow: () => true);
      await tester.pump();
      final load = calls.singleWhere((call) => call.method == 'loadRewardedAd');
      expect(
        load.arguments['adUnitId'],
        'ca-app-pub-3940256099942544/5224354917',
      );
      final id = load.arguments['adId'] as int;
      await emit(id, 'onAdLoaded');
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'showAdWithoutView'),
        hasLength(1),
      );
      if (earned) {
        await emit(id, 'onRewardedAdUserEarnedReward', {
          'rewardItem': RewardItem(1, 'ore'),
        });
      }
      await emit(id, 'onAdDismissedFullScreenContent');
      await tester.pump();
      expect(
        await result,
        earned ? RewardedAdResult.earned : RewardedAdResult.dismissed,
      );
      expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    });
  }

  testWidgets('ad loaded after leaving route stays cached without showing', (
    tester,
  ) async {
    final service = GoogleRewardedAdService();
    var current = true;
    final result = service.show(canShow: () => current);
    await tester.pump();
    final load = calls.singleWhere((call) => call.method == 'loadRewardedAd');
    current = false;
    await emit(load.arguments['adId'] as int, 'onAdLoaded');
    await tester.pump();
    expect(await result, RewardedAdResult.unavailable);
    expect(calls.where((call) => call.method == 'showAdWithoutView'), isEmpty);
    expect(calls.where((call) => call.method == 'disposeAd'), isEmpty);
    service.dispose();
    await tester.pump();
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  testWidgets('load timeout rejects duplicate request and cleans late ad', (
    tester,
  ) async {
    final service = GoogleRewardedAdService();
    final result = service.show(canShow: () => true);
    await tester.pump();
    expect(
      await service.show(canShow: () => true),
      RewardedAdResult.unavailable,
    );
    expect(
      calls.where((call) => call.method == 'loadRewardedAd'),
      hasLength(1),
    );
    final load = calls.singleWhere((call) => call.method == 'loadRewardedAd');
    await tester.pump(const Duration(seconds: 21));
    expect(await result, RewardedAdResult.unavailable);
    await emit(load.arguments['adId'] as int, 'onAdLoaded');
    await tester.pump();
    expect(calls.where((call) => call.method == 'showAdWithoutView'), isEmpty);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  testWidgets('native load and presentation errors never earn a reward', (
    tester,
  ) async {
    final service = GoogleRewardedAdService();
    var result = service.show(canShow: () => true);
    await tester.pump();
    var load = calls.lastWhere((call) => call.method == 'loadRewardedAd');
    await emit(load.arguments['adId'] as int, 'onAdFailedToLoad', {
      'loadAdError': LoadAdError(3, 'test', 'no fill', null),
    });
    await tester.pump();
    expect(await result, RewardedAdResult.unavailable);

    result = service.show(canShow: () => true);
    await tester.pump();
    load = calls.lastWhere((call) => call.method == 'loadRewardedAd');
    final id = load.arguments['adId'] as int;
    await emit(id, 'onAdLoaded');
    await tester.pump();
    await emit(id, 'onFailedToShowFullScreenContent', {
      'error': AdError(1, 'test', 'show failed'),
    });
    await tester.pump();
    expect(await result, RewardedAdResult.unavailable);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(2));
  });
}
