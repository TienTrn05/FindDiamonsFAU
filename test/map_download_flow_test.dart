import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:roblox/common/widgets/ad_placements.dart';
import 'package:roblox/core/monetization/ads_runtime.dart';
import 'package:roblox/core/monetization/app_monetization.dart';
import 'package:roblox/core/monetization/interstitial_ad_service.dart';
import 'package:roblox/core/monetization/interstitial_schedule.dart';
import 'package:roblox/core/monetization/rewarded_ad_service.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/maps/bloc/maps_bloc.dart';
import 'package:roblox/features/maps/data/map_download_repository.dart';
import 'package:roblox/features/maps/data/maps_repository.dart';
import 'package:roblox/features/maps/models/downloaded_map.dart';
import 'package:roblox/features/maps/models/map_catalog.dart';
import 'package:roblox/features/maps/presentation/map_details_page.dart';

import 'support/fake_skin_share.dart';

const _captureKey = ValueKey('map-download-preview');

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_PREVIEWS'] != 'true') return;
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/warehouse.png'),
      tester.element(find.byKey(_captureKey)),
    );
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await Directory('output/previews').create(recursive: true);
      await File('output/previews/$name.png').writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

const _map = MapItem(
  id: 'warehouse',
  name: 'Warehouse I',
  subtitle: 'Chapter 1',
  description: 'Explore the warehouse.',
  category: 'Horror',
  cover: 'assets/images/warehouse.png',
  locked: false,
  edition: 'bedrock',
  downloadUrl: 'https://example.com/warehouse.mcworld',
);

class _Catalog implements MapsRepository {
  @override
  Set<String> get favourites => {};
  @override
  Set<String> get unlocked => {};
  @override
  void toggleFavourite(String id) {}
  @override
  Future<bool> unlock(String id) async => true;
  @override
  Future<MapCatalog> load() async => const MapCatalog(
    title: 'Maps',
    categories: ['Horror'],
    initialCategory: 'Horror',
    items: [_map],
  );
}

class _Downloads implements MapDownloadRepository {
  DownloadedMap? stored;
  int calls = 0;
  Completer<DownloadedMap>? _pending;
  Completer<DownloadedMap> get pending => _pending ??= Completer();
  set pending(Completer<DownloadedMap> value) => _pending = value;
  void Function(MapDownloadProgress)? progress;
  @override
  Future<DownloadedMap?> find(MapItem item) async => stored;
  @override
  Future<DownloadedMap> download(
    MapItem item, {
    required void Function(MapDownloadProgress) onProgress,
    required MapDownloadCancellation cancellation,
  }) async {
    calls++;
    progress = onProgress;
    return stored = await pending.future;
  }
}

class _Ads implements InterstitialAdService {
  int preloads = 0;
  int shows = 0;
  Completer<bool>? pending;
  @override
  Future<void> preload({required bool Function() canLoad}) async {
    preloads++;
  }

  @override
  Future<bool> showIfReady({required bool Function() canShow}) async {
    if (!canShow()) return false;
    shows++;
    return pending?.future ?? false;
  }

  @override
  void clearCache() {}
  @override
  void dispose() {}
}

class _Rewards implements RewardedAdService {
  int preloads = 0;
  int shows = 0;
  @override
  Future<void> preload({required bool Function() canLoad}) async {
    preloads++;
  }

  @override
  Future<RewardedAdResult> show({required bool Function() canShow}) async {
    shows++;
    return RewardedAdResult.unavailable;
  }

  @override
  void clearCache() {}
  @override
  void dispose() {}
}

void main() {
  late Directory directory;
  late DownloadedMap saved;
  late _Downloads downloads;
  late MapsBloc bloc;
  late _Ads ads;
  late _Rewards rewards;
  late AppMonetization access;
  late FakeSkinShare share;

  setUpAll(() async {
    for (final font in [
      ('Monocraft', 'assets/fonts/Monocraft-Regular.ttf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('map-flow-test-');
    final file = File('${directory.path}/Warehouse.mcworld');
    await file.writeAsBytes([80, 75, 5, 6, ...List.filled(18, 0)]);
    saved = DownloadedMap(
      path: file.path,
      filename: 'Warehouse.mcworld',
      bytes: 22,
    );
    downloads = _Downloads();
    bloc = MapsBloc(_Catalog(), downloads: downloads);
    ads = _Ads();
    rewards = _Rewards();
    access = AppMonetization(
      isPro: true,
      adsRuntime: AdsRuntime(enabled: false),
      interstitialAds: ads,
      rewardedAds: rewards,
      interstitialSchedule: InterstitialSchedule(interval: Duration.zero),
    );
    access.setForeground(true);
    share = FakeSkinShare();
    final previous = SharePlatform.instance;
    SharePlatform.instance = share;
    addTearDown(() => SharePlatform.instance = previous);
  });
  tearDown(() async {
    bloc.dispose();
    access.dispose();
    await directory.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    MapItem item = _map,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: MonetizationScope(
            controller: access,
            child: MapDetailsPage(item: item, bloc: bloc, onGoPro: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openLaunch(WidgetTester tester, {bool doubleTap = false}) async {
    await tester.tap(find.byKey(const ValueKey('launch-map')));
    if (doubleTap) await tester.tap(find.byKey(const ValueKey('launch-map')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    'downloads with percentage, then counts down and shares the local file; Pro never calls ads',
    (tester) async {
      await mount(tester);
      expect(find.text('Download Map'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('download-map')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('download-map')));
      expect(downloads.calls, 1);
      downloads.progress!(const MapDownloadProgress(45, 100));
      await tester.pump();
      expect(find.text('Downloading...'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      await _capture(tester, 'map-downloading');
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('map-download-progress')),
            )
            .value,
        .45,
      );
      downloads.pending.complete(saved);
      await tester.pumpAndSettle();
      expect(find.text('Launch Map'), findsOneWidget);
      expect(find.text('Downloading...'), findsNothing);
      await openLaunch(tester);
      expect(find.text('Please wait 15s'), findsOneWidget);
      expect(share.requests, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Please wait 14s'), findsOneWidget);
      await _capture(tester, 'map-launch-countdown');
      await tester.pump(const Duration(seconds: 14));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('launch-world')), findsOneWidget);
      expect(find.byType(SpecialOfferAd), findsNothing);
      await _capture(tester, 'map-launch-world-pro');
      await tester.tap(find.byKey(const ValueKey('launch-world')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(share.requests, hasLength(1));
      expect(share.requests.single.files!.single.path, saved.path);
      expect(
        share.requests.single.files!.single.mimeType,
        'application/octet-stream',
      );
      expect(share.requests.single.sharePositionOrigin!.isEmpty, isFalse);
      expect(ads.preloads, 0);
      expect(ads.shows, 0);
      expect(rewards.preloads, 0);
      expect(rewards.shows, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restores downloaded state without downloading again; closing cancels the countdown',
    (tester) async {
      downloads.stored = saved;
      await mount(tester);
      expect(find.byKey(const ValueKey('launch-map')), findsOneWidget);
      expect(downloads.calls, 0);
      await openLaunch(tester, doubleTap: true);
      expect(find.byKey(const ValueKey('map-launch-overlay')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-map-launch')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byKey(const ValueKey('map-launch-overlay')), findsNothing);
      expect(share.requests, isEmpty);
      expect(ads.shows, 0);
    },
  );

  testWidgets(
    'Free waits until the eligible launch ad closes; Pro upgrade hides the native placement',
    (tester) async {
      access.updateEntitlement(false);
      downloads.stored = saved;
      ads.pending = Completer<bool>();
      await mount(tester, width: 320);
      await openLaunch(tester);
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(ads.preloads, 1);
      expect(ads.shows, 1);
      expect(find.byKey(const ValueKey('launch-world')), findsNothing);
      ads.pending!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(SpecialOfferAd), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-world')), findsOneWidget);
      access.updateEntitlement(true);
      await tester.pumpAndSettle();
      expect(find.byType(SpecialOfferAd), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed downloads can retry and do not expose Launch Map', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('download-map')));
    await tester.pump();
    downloads.pending.completeError(const SocketException('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Retry Download'), findsOneWidget);
    expect(find.byKey(const ValueKey('launch-map')), findsNothing);
    downloads.pending = Completer();
    await tester.tap(find.byKey(const ValueKey('download-map')));
    await tester.pump();
    downloads.pending.complete(saved);
    await tester.pumpAndSettle();
    expect(downloads.calls, 2);
    expect(find.byKey(const ValueKey('launch-map')), findsOneWidget);
  });

  testWidgets('a download survives leaving the details page', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('download-map')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    downloads.pending.complete(saved);
    await tester.pump();
    await mount(tester);
    expect(find.byKey(const ValueKey('launch-map')), findsOneWidget);
    expect(downloads.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing local file returns to Download Map', (tester) async {
    downloads.stored = saved;
    await mount(tester);
    await tester.runAsync(() => File(saved.path).delete());
    await tester.tap(find.byKey(const ValueKey('launch-map')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-launch-overlay')), findsNothing);
    expect(find.text('Download Map'), findsOneWidget);
  });

  testWidgets('Pro bypasses locked-map unlock ads as well as launch ads', (
    tester,
  ) async {
    downloads.stored = saved;
    const item = MapItem(
      id: 'locked-world',
      name: 'Locked World',
      subtitle: '',
      description: '',
      category: 'Horror',
      cover: 'assets/images/warehouse.png',
      locked: true,
      downloadUrl: 'https://example.com/world.mcworld',
    );
    await mount(tester, item: item);
    expect(find.byKey(const ValueKey('unlock-world')), findsNothing);
    await openLaunch(tester);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('launch-world')), findsOneWidget);
    expect(find.byType(SpecialOfferAd), findsNothing);
    expect(ads.preloads + ads.shows + rewards.preloads + rewards.shows, 0);
    expect(tester.takeException(), isNull);
  });
}
