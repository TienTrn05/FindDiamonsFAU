import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:roblox/app/app.dart';
import 'package:roblox/app/app_repositories.dart';
import 'package:roblox/app/navigation/app_shell.dart';
import 'package:roblox/common/widgets/voxel_character_3d.dart';
import 'package:roblox/common/widgets/reward_unlock_dialog.dart';
import 'package:roblox/common/widgets/digging_pickaxe.dart';
import 'package:roblox/common/widgets/app_loading_page.dart';
import 'package:roblox/core/theme/app_colors.dart';
import 'package:roblox/core/monetization/app_monetization.dart';
import 'package:roblox/core/monetization/ads_runtime.dart';
import 'package:roblox/core/monetization/app_open_ad_service.dart';
import 'package:roblox/core/monetization/rewarded_ad_service.dart';
import 'package:roblox/features/onboarding/models/subscription_plan.dart';
import 'package:roblox/core/data/json_asset_source.dart';
import 'package:roblox/core/localization/app_locale_controller.dart';
import 'package:roblox/core/localization/app_translations.dart';
import 'package:roblox/core/navigation/app_destination.dart';
import 'package:roblox/core/theme/app_text_styles.dart';
import 'package:roblox/core/theme/app_theme.dart';
import 'package:roblox/features/find/data/find_repository.dart';
import 'package:roblox/features/find/presentation/find_page.dart';
import 'package:roblox/features/find/models/find_catalog.dart';
import 'package:roblox/features/digging/presentation/found_ores_page.dart';
import 'package:roblox/features/history/data/history_repository.dart';
import 'package:roblox/features/help/data/help_repository.dart';
import 'package:roblox/features/help/presentation/help_page.dart';
import 'package:roblox/features/help/presentation/help_policy_dialog.dart';
import 'package:roblox/features/maps/data/maps_repository.dart';
import 'package:roblox/features/onboarding/data/onboarding_preferences.dart';
import 'package:roblox/features/onboarding/presentation/onboarding_flow.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/skins/data/skins_repository.dart';
import 'support/memory_history_store.dart';
import 'support/fake_skin_share.dart';

const _startupDuration = Duration(seconds: 3);
const _captureKey = ValueKey('route-preview');
final _jsonFiles = <String, String>{};
final _skinShares = FakeSkinShare();

class _LaunchAds implements AppOpenAdService {
  int calls = 0;
  final closed = Completer<bool>();
  bool fail = false;

  @override
  Future<bool> showAtLaunch({required bool Function() canShow}) async {
    if (!canShow()) return false;
    calls++;
    if (fail) throw StateError('offline');
    return closed.future;
  }

  @override
  void clearCache() {}
  @override
  void dispose() {}
}

class _RewardedAds implements RewardedAdService {
  int preloads = 0;
  int clears = 0;
  bool disposed = false;

  @override
  Future<void> preload({required bool Function() canLoad}) async {
    if (canLoad()) preloads++;
  }

  @override
  void clearCache() {
    clears++;
  }

  @override
  void dispose() {
    disposed = true;
  }

  RewardedAdResult result = RewardedAdResult.earned;
  Completer<RewardedAdResult>? pending;
  int requests = 0;

  @override
  Future<RewardedAdResult> show({required bool Function() canShow}) async {
    requests++;
    return pending == null ? result : await pending!.future;
  }
}

class _FixtureBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(_jsonFiles[key]!);

  @override
  Future<ByteData> load(String key) => SynchronousFuture(
    ByteData.sublistView(Uint8List.fromList(utf8.encode(_jsonFiles[key]!))),
  );
}

AppRepositories _repositories({HistoryRepository? history}) {
  final source = JsonAssetSource(bundle: _FixtureBundle());
  return AppRepositories(
    find: JsonFindRepository(source: source),
    history:
        history ??
        JsonHistoryRepository(source: source, store: MemoryHistoryStore()),
    skins: JsonSkinsRepository(source: source),
    servers: JsonServersRepository(source: source),
    maps: JsonMapsRepository(source: source),
    help: JsonHelpRepository(source: source),
  );
}

AppMonetization _testAccess() {
  final access = AppMonetization(
    rewardedAds: _RewardedAds(),
    adsRuntime: AdsRuntime(enabled: false),
  );
  addTearDown(access.dispose);
  return access;
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  AppLocaleController? languages,
  AppMonetization? monetization,
  AppRepositories? repositories,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = languages ?? AppLocaleController();
  addTearDown(controller.dispose);
  final access =
      monetization ??
      AppMonetization(
        rewardedAds: _RewardedAds(),
        adsRuntime: AdsRuntime(enabled: false),
      );
  if (monetization == null) addTearDown(access.dispose);
  await tester.pumpWidget(
    MonetizationScope(
      controller: access,
      child: RepaintBoundary(
        key: _captureKey,
        child: AppLanguageScope(
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: controller.locale ?? const Locale('en'),
              supportedLocales: AppTranslations.supportedLocales,
              localizationsDelegates: const [
                AppTranslations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: AppShell(
                repositories: repositories ?? _repositories(),
                monetization: access,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, AppDestination destination) async {
  await tester.tap(find.byKey(ValueKey('nav-${destination.name}')));
  await tester.pumpAndSettle();
}

Future<void> _finishSkinShare(WidgetTester tester, {bool settle = true}) async {
  // PNG encoding runs on the engine; alternate real async work and test frames.
  for (
    var frame = 0;
    frame < 100 && !_skinShares.started.isCompleted;
    frame++
  ) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(
    _skinShares.started.isCompleted,
    isTrue,
    reason: 'PNG reaches the platform share sheet',
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _shareSkinImage(WidgetTester tester) async {
  _skinShares.nextRequest();
  await tester.tap(find.byKey(const ValueKey('skin-share')));
  await _finishSkinShare(tester);
}

Future<void> _mapCategory(WidgetTester tester, String category) async {
  final page = tester.state<NestedScrollViewState>(
    find.byType(NestedScrollView),
  );
  page.outerController.jumpTo(0);
  await tester.pumpAndSettle();
  final button = find.byKey(ValueKey('category-$category'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openHelp(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('open-help')),
    180,
    scrollable: find.descendant(
      of: find.byKey(const PageStorageKey('find-form')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    ),
  );
  await tester.ensureVisible(find.byKey(const ValueKey('open-help')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-help')));
  await tester.pumpAndSettle();
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  Finder? boundary,
}) async {
  if (Platform.environment['CAPTURE_PREVIEWS'] != 'true') return;
  await tester.runAsync(() async {
    for (final asset in [
      'assets/images/block_landscape.png',
      'assets/images/adventurer.png',
      'assets/images/warehouse.png',
      for (final flag in ['us', 'es', 'pt', 'tr', 'fr', 'de', 'id', 'vn'])
        'assets/images/flags/$flag.png',
    ]) {
      await precacheImage(
        AssetImage(asset),
        tester.element(boundary ?? find.byKey(_captureKey)),
      );
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final renderBoundary = tester.renderObject<RenderRepaintBoundary>(
      boundary ?? find.byKey(_captureKey),
    );
    final image = await renderBoundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('output/previews').create(recursive: true);
    await File(
      'output/previews/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Finder _oreCards() => find.byWidgetPredicate(
  (widget) =>
      widget is InkWell &&
      widget.key is ValueKey<String> &&
      (widget.key as ValueKey<String>).value.startsWith('ore-result-'),
);

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextFormField),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch ad starts on splash and content waits until it closes', (
    tester,
  ) async {
    final ads = _LaunchAds();
    final access = AppMonetization(
      appOpenAds: ads,
      rewardedAds: _RewardedAds(),
      adsRuntime: AdsRuntime(enabled: false),
    );
    addTearDown(access.dispose);
    await tester.pumpWidget(
      MyApp(
        skipOnboarding: true,
        repositories: _repositories(),
        monetization: access,
      ),
    );
    await tester.pump();
    expect(ads.calls, 1);
    expect(find.byType(AppLoadingPage), findsOneWidget);
    await tester.pump(_startupDuration);
    expect(find.byType(AppShell), findsNothing);
    ads.closed.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(AppLoadingPage), findsNothing);
    expect(await access.showLaunchAd(canShow: () => true), isFalse);
    expect(ads.calls, 1);
  });

  testWidgets('Pro skips launch ad and ad errors do not block startup', (
    tester,
  ) async {
    for (final pro in [true, false]) {
      final ads = _LaunchAds()..fail = true;
      final access = AppMonetization(
        isPro: pro,
        appOpenAds: ads,
        rewardedAds: _RewardedAds(),
        adsRuntime: AdsRuntime(enabled: false),
      );
      await tester.pumpWidget(
        MyApp(
          skipOnboarding: true,
          repositories: _repositories(),
          monetization: access,
        ),
      );
      await tester.pump(_startupDuration);
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(ads.calls, pro ? 0 : 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      access.dispose();
    }
  });

  testWidgets('Find dismisses touch focus outside all three inputs', (
    tester,
  ) async {
    await _mount(tester);
    for (final key in ['player-x', 'player-z', 'world-seed']) {
      await tester.ensureVisible(_field(key));
      await tester.tap(_field(key));
      await tester.enterText(_field(key), '123');
      final editable = tester.widget<EditableText>(
        find.descendant(of: _field(key), matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      await tester.tap(
        find.text('Find Diamonds!'),
        kind: ui.PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      expect(editable.focusNode.hasFocus, isFalse);
      expect(editable.controller.text, '123');
    }
  });

  testWidgets(
    'verified purchase expands Help and entitlement expiry restores Go Pro',
    (tester) async {
      final purchase = Completer<bool>();
      final access = AppMonetization(
        onPurchase: (_) => purchase.future,
        rewardedAds: _RewardedAds(),
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      final help = find.byKey(const ValueKey('open-help'));
      final pro = find.byKey(const ValueKey('open-premium'));
      final combinedWidth =
          tester.getRect(pro).right - tester.getRect(help).left;
      final buying = access.purchase(SubscriptionPlan.weekly);
      await tester.pump();
      expect(pro, findsOneWidget);
      purchase.complete(true);
      expect(await buying, isTrue);
      await tester.pumpAndSettle();
      expect(pro, findsNothing);
      expect(tester.getSize(help).width, closeTo(combinedWidth, .01));
      await tester.ensureVisible(help);
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(find.byType(HelpPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      access.updateEntitlement(false);
      await tester.pumpAndSettle();
      expect(pro, findsOneWidget);
    },
  );

  testWidgets(
    'reward required, retry errors, and prevent duplicate ad requests',
    (tester) async {
      final ads = _RewardedAds();
      final access = AppMonetization(
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      final repository = _repositories().find;
      final catalog = await repository.load();
      final record = await repository.search(
        FindQuery(
          x: 0,
          z: 0,
          seed: 'reward',
          version: catalog.versions.first,
          ore: catalog.ores.first,
        ),
      );
      final initialCount = record.revealedCount;
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => FoundOresPage(
            record: record,
            monetization: access,
            onGoPro: () {},
            onHelp: () {},
            showLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final another = find.byKey(const ValueKey('show-another-ore'));
      expect(ads.preloads, greaterThan(0));
      for (final result in [
        RewardedAdResult.dismissed,
        RewardedAdResult.unavailable,
        RewardedAdResult.unsupported,
      ]) {
        ads.result = result;
        await tester.ensureVisible(another);
        await tester.tap(another);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('ore-result-$initialCount')), findsNothing);
        expect(access.revealedCount(record.id), 1);
      }
      ScaffoldMessenger.of(tester.element(another)).clearSnackBars();
      await tester.pumpAndSettle();
      ads.pending = Completer<RewardedAdResult>();
      await tester.tap(another);
      await tester.pump();
      expect(find.text('Loading ad...'), findsOneWidget);
      final requests = ads.requests;
      await tester.tap(another);
      await tester.pump();
      expect(ads.requests, requests);
      expect(find.byKey(ValueKey('ore-result-$initialCount')), findsNothing);
      ads.pending!.complete(RewardedAdResult.earned);
      final preloadsBeforeReward = ads.preloads;
      await tester.pumpAndSettle();
      expect(ads.preloads, greaterThan(preloadsBeforeReward));
      expect(find.byKey(ValueKey('ore-result-$initialCount')), findsOneWidget);
      expect(
        find.byKey(ValueKey('ore-result-${initialCount + 1}')),
        findsNothing,
      );
      expect(access.revealedCount(record.id), initialCount + 1);
      access.updateEntitlement(true);
      await tester.pumpAndSettle();
      expect(ads.clears, 1);
      expect(_oreCards(), findsNWidgets(record.positions.length));
      expect(another, findsNothing);
      expect(find.byKey(const ValueKey('show-all-ores')), findsNothing);
      expect(ads.requests, requests);
      navigator.pop();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'paywall purchase and Help restore update shared Pro entitlement',
    (tester) async {
      var verified = false;
      final access = AppMonetization(
        onPurchase: (_) async => verified,
        onRestore: () async => true,
        adsRuntime: AdsRuntime(enabled: false),
        rewardedAds: _RewardedAds(),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      final pro = find.byKey(const ValueKey('open-premium'));
      await tester.ensureVisible(pro);
      await tester.tap(pro);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Free Trial'));
      await tester.pumpAndSettle();
      expect(access.isPro, isFalse);
      expect(find.text('Remove All Ads'), findsOneWidget);
      await tester.tap(find.byTooltip('Close paywall'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-help')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('help-restore')));
      await tester.pumpAndSettle();
      expect(access.isPro, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(pro, findsNothing);

      access.updateEntitlement(false);
      verified = true;
      await tester.pumpAndSettle();
      await tester.tap(pro);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Free Trial'));
      await tester.pumpAndSettle();
      expect(access.isPro, isTrue);
      expect(find.text('Remove All Ads'), findsNothing);
      expect(pro, findsNothing);
    },
  );

  setUp(() {
    _skinShares.reset();
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() async {
    SharePlatform.instance = _skinShares;
    for (final locale in AppTranslations.supportedLocales) {
      await AppTranslations.load(locale);
    }
    for (final font in [
      (AppFonts.body, 'assets/fonts/Monocraft-Regular.ttf'),
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
    for (final feature in [
      'find',
      'history',
      'skins',
      'servers',
      'maps',
      'help',
    ]) {
      final path = 'assets/data/$feature/$feature.json';
      _jsonFiles[path] = await rootBundle.loadString(path);
    }
  });

  test(
    'feature repositories read JSON and Find records are shared with History',
    () async {
      final findRepository = JsonFindRepository();
      final catalog = await findRepository.load();
      expect(catalog.versions.first.label, '1.21/1.20 Bedrock (v26)');
      final history = JsonHistoryRepository(store: MemoryHistoryStore());
      expect((await history.load()).searches, isEmpty);
      final result = await findRepository.search(
        FindQuery(
          x: -100,
          z: 200,
          seed: 'my-world',
          version: catalog.versions.last,
          ore: catalog.ores.first,
        ),
      );
      await history.add(result);
      final saved = (await history.load()).searches.single;
      expect(saved.seed, 'my-world');
      expect(saved.playerX, -100);
      expect(saved.positions, isNotEmpty);
      await history.remove(saved.id);
      expect((await history.load()).searches, isEmpty);
      expect(
        (await JsonSkinsRepository().load())
            .where((skin) => !skin.locked)
            .length,
        greaterThan(1),
      );
      expect(
        (await const JsonServersRepository().load()).servers.first.online,
        8777,
      );
      expect(
        (await JsonMapsRepository().load()).items.any(
          (item) => item.seed != null,
        ),
        isTrue,
      );
      final maps = await JsonMapsRepository().load();
      expect(maps.categories, contains(maps.initialCategory));
      expect(maps.initialCategory, 'Seeds');
      expect(maps.categories, isNot(contains('All')));
      for (final item in maps.items) {
        expect(maps.categories, contains(item.category), reason: item.id);
      }
    },
  );

  testWidgets('five independent tabs match their reference states', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.text('Find Diamonds!'), findsOneWidget);
    await _capture(tester, '08-find');
    await _tab(tester, AppDestination.history);
    expect(find.text('No searches made yet!'), findsOneWidget);
    await _capture(tester, '09-history');
    await _tab(tester, AppDestination.skins);
    expect(find.byKey(const ValueKey('skin-steve')), findsOneWidget);
    await _capture(tester, '10-skins');
    await _tab(tester, AppDestination.servers);
    expect(find.text('Complex Gaming'), findsOneWidget);
    await _capture(tester, '11-servers');
    await _tab(tester, AppDestination.maps);
    expect(find.text('Emerald Valley'), findsOneWidget);
    await _capture(tester, '12-maps');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Help opens FAQ, language choices, policy and tutorial review', (
    tester,
  ) async {
    await _mount(tester);
    await tester.enterText(_field('world-seed'), 'keep-my-world');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _openHelp(tester);
    expect(find.byType(HelpPage), findsOneWidget);
    await _capture(tester, '14-help');
    final header = find.text('Help!');
    final headerPosition = tester.getTopLeft(header);

    await tester.tap(find.byKey(const ValueKey('help-restore')));
    await tester.pumpAndSettle();
    expect(
      find.text('Restore purchases is not available yet.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-language')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('help-language')));
    await _capture(tester, '18-help-languages');
    await tester.ensureVisible(find.byKey(const ValueKey('help-language-vi')));
    await tester.tap(find.byKey(const ValueKey('help-language-vi')));
    await tester.pumpAndSettle();
    expect(find.text('Đổi ngôn ngữ'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString(
        AppLocaleController.preferenceKey,
      ),
      'vi',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('help-language-en')));
    await tester.tap(find.byKey(const ValueKey('help-language-en')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('help-language')));
    await tester.tap(find.byKey(const ValueKey('help-language')));
    await tester.pumpAndSettle();

    final position = find.byKey(const ValueKey('help-faq-position'));
    await tester.ensureVisible(position);
    await tester.tap(position);
    await tester.pumpAndSettle();
    expect(find.textContaining('Show Coordinates'), findsOneWidget);
    expect(tester.getTopLeft(header), headerPosition);
    await _capture(tester, '15-help-position');
    final seed = find.byKey(const ValueKey('help-faq-seed'));
    await tester.ensureVisible(seed);
    await tester.tap(seed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Show Coordinates'), findsNothing);
    expect(find.textContaining('In Bedrock/PE:'), findsOneWidget);
    await _capture(tester, '16-help-seed');

    final privacy = find.byKey(const ValueKey('help-privacy'));
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(find.byType(HelpPolicyDialog), findsOneWidget);
    await _capture(tester, '17-help-policy');
    final ok = find.byKey(const ValueKey('help-policy-ok'));
    final okPosition = tester.getTopLeft(ok);
    await tester.drag(
      find.byKey(const ValueKey('help-policy-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(ok), okPosition);
    await tester.tap(ok);
    await tester.pumpAndSettle();
    expect(find.byType(HelpPolicyDialog), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('help-tutorial')));
    await tester.tap(find.byKey(const ValueKey('help-tutorial')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Please wait...'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpPage), findsOneWidget);
    expect(find.text('Remove All Ads'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingPreferences.completedKey), isNull);
    await tester.tap(find.byKey(const ValueKey('game-header-back')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(_field('world-seed')).controller!.text,
      'keep-my-world',
    );
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('language changes all tabs and survives restart on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final languages = AppLocaleController();
      await _mount(tester, languages: languages);
      await tester.enterText(_field('world-seed'), 'my-world-123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _openHelp(tester);
      await tester.tap(find.byKey(const ValueKey('help-language')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('help-language-fr')),
      );
      await tester.tap(find.byKey(const ValueKey('help-language-fr')));
      await tester.pumpAndSettle();
      expect(languages.locale, const Locale('fr'));
      expect(find.text('Changer de langue'), findsOneWidget);
      expect(find.text('Aide !'), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/flags/fr.png')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('help-language')));
      await _capture(tester, '19-help-french-${platform.name}');
      await tester.tap(find.byKey(const ValueKey('game-header-back')));
      await tester.pumpAndSettle();
      expect(find.text('Trouvez des diamants !'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_field('world-seed')).controller!.text,
        'my-world-123',
      );
      await _tab(tester, AppDestination.history);
      expect(find.text('Aucune recherche pour le moment !'), findsOneWidget);
      await _tab(tester, AppDestination.skins);
      expect(find.text('Marcher'), findsOneWidget);
      await _tab(tester, AppDestination.maps);
      expect(find.text('Cartes, mods et graines'), findsOneWidget);
      await _tab(tester, AppDestination.servers);
      await tester.tap(find.byKey(const ValueKey('server-complex')));
      await tester.pumpAndSettle();
      expect(find.text('Infos du serveur'), findsOneWidget);
      expect(find.text('demo-complex.example'), findsOneWidget);

      // Start the actual app with a fresh controller and the saved preference.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MyApp(
          skipOnboarding: true,
          repositories: _repositories(),
          monetization: _testAccess(),
        ),
      );
      await tester.pump(_startupDuration);
      await tester.pumpAndSettle();
      expect(find.text('Trouvez des diamants !'), findsOneWidget);
      final context = tester.element(find.byType(AppShell));
      expect(Localizations.localeOf(context).languageCode, 'fr');
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  for (final locale in AppTranslations.supportedLocales) {
    testWidgets(
      'translated offers fit a small screen in ${locale.languageCode}',
      (tester) async {
        final languages = AppLocaleController();
        await _mount(tester, size: const Size(320, 568), languages: languages);
        await languages.select(locale.languageCode);
        await tester.pumpAndSettle();
        final translations = await AppTranslations.load(locale);
        final premium = find.byKey(const ValueKey('open-premium'));
        await tester.scrollUntilVisible(
          premium,
          180,
          scrollable: find.descendant(
            of: find.byKey(const PageStorageKey('find-form')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          ),
        );
        await tester.ensureVisible(premium);
        await Scrollable.ensureVisible(tester.element(premium), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(premium);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        await tester.ensureVisible(
          find.text(translations.trans('View All Plans')),
        );
        await tester.tap(find.text(translations.trans('View All Plans')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        await tester.tap(find.byTooltip(translations.trans('Close paywall')));
        await tester.pumpAndSettle();
        await _openHelp(tester);
        await tester.tap(find.byKey(const ValueKey('help-language')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('help-language-vi')),
        );
        expect(tester.takeException(), isNull, reason: locale.languageCode);
      },
    );
  }

  testWidgets(
    'coordinate inputs accept integers and form labels share readable styling',
    (tester) async {
      await _mount(tester);
      for (final label in [
        'Player X',
        'Player Z',
        'World seed (numbers/letters)',
        'Version (Scroll to change)',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          120,
          scrollable: find.descendant(
            of: find.byKey(const PageStorageKey('find-form')),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          ),
        );
        final text = tester.widget<Text>(find.text(label));
        expect(text.style!.fontSize, 24);
        expect(text.style!.fontWeight, FontWeight.w700);
        expect(text.style!.color, AppColors.text);
      }
      for (final key in ['player-x', 'player-z']) {
        final field = _field(key);
        await tester.ensureVisible(field);
        await tester.enterText(field, '-120');
        for (final invalid in ['-120a', '12.5', '1-2', '++2', ' 23 ']) {
          await tester.enterText(field, invalid);
          expect(tester.widget<TextFormField>(field).controller!.text, '-120');
        }
        await tester.enterText(field, '0');
        expect(tester.widget<TextFormField>(field).controller!.text, '0');
      }
      await tester.enterText(_field('world-seed'), 'letters-and-123');
      expect(
        tester.widget<TextFormField>(_field('world-seed')).controller!.text,
        'letters-and-123',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('validate, search, retain form across tabs and remove history', (
    tester,
  ) async {
    await _mount(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('start-digging')));
    await tester.tap(find.byKey(const ValueKey('start-digging')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number'), findsNWidgets(2));
    expect(find.text('Enter your world seed'), findsOneWidget);
    await tester.enterText(_field('player-x'), '-30');
    await tester.enterText(_field('player-z'), '120');
    await tester.enterText(_field('world-seed'), 'sample-world');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.ensureVisible(find.byKey(const ValueKey('start-digging')));
    await tester.tap(find.byKey(const ValueKey('start-digging')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(DiggingPickaxe), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: _field('player-x'),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    await _capture(tester, '20-digging-form');
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Found Ores!'), findsOneWidget);
    expect(find.byType(DiggingPickaxe), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await _capture(tester, '21-found-loading');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ore-result-0')), findsOneWidget);
    final initialCount = tester.widgetList(_oreCards()).length;
    expect(initialCount, inInclusiveRange(1, 2));
    expect(find.byKey(ValueKey('ore-result-$initialCount')), findsNothing);
    expect(
      find.text('There are ${5 - initialCount} more ore clusters nearby!'),
      findsOneWidget,
    );
    await _capture(tester, '22-found-ores');
    await tester.tap(find.byKey(const ValueKey('ore-result-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ore-status-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mark-ore-found')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ore-status-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-another-ore')));
    await tester.pump();
    expect(find.byType(DiggingPickaxe), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ore-result-1')), findsOneWidget);
    expect(
      find.text('There are ${4 - initialCount} more ore clusters nearby!'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ore-status-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-all-ores')));
    await tester.pumpAndSettle();
    expect(find.text('Remove All Ads'), findsOneWidget);
    await tester.tap(find.byTooltip('Close paywall'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ore-results-help')));
    await tester.pumpAndSettle();
    expect(find.byType(HelpPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('found-ores-back')));
    await tester.pumpAndSettle();
    await _tab(tester, AppDestination.history);
    expect(find.text('sample-world'), findsOneWidget);
    await _capture(tester, '23-history-saved');
    await tester.tap(find.text('sample-world'));
    await tester.pumpAndSettle();
    expect(_oreCards(), findsNWidgets(initialCount + 1));
    expect(find.byKey(const ValueKey('show-all-ores')), findsOneWidget);
    expect(find.byKey(const ValueKey('show-another-ore')), findsOneWidget);
    expect(find.byType(DiggingPickaxe), findsNothing);
    await tester.tap(find.byKey(const ValueKey('found-ores-back')));
    await tester.pumpAndSettle();
    await _tab(tester, AppDestination.find);
    expect(
      tester.widget<TextFormField>(_field('world-seed')).controller!.text,
      'sample-world',
    );
    await tester.tap(find.byTooltip('Next ore'));
    await tester.pumpAndSettle();
    expect(find.text('Copper'), findsOneWidget);
    await _tab(tester, AppDestination.history);
    await tester.tap(find.byTooltip('Delete search'));
    await tester.pumpAndSettle();
    expect(find.text('No searches made yet!'), findsOneWidget);
  });

  testWidgets(
    'ore status requires a choice, stamps Found and survives restart',
    (tester) async {
      final store = MemoryHistoryStore();
      final source = JsonAssetSource(bundle: _FixtureBundle());
      final history = JsonHistoryRepository(source: source, store: store);
      final findRepository = _repositories().find;
      final catalog = await findRepository.load();
      final record = (await findRepository.search(
        FindQuery(
          x: 0,
          z: 0,
          seed: 'status-world',
          version: catalog.versions.first,
          ore: catalog.ores.first,
        ),
      )).withRevealedCount(2);
      await history.add(record);
      await _mount(tester, repositories: _repositories(history: history));
      await _tab(tester, AppDestination.history);
      await tester.tap(find.text(record.seed));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('ore-result-0'));
      final stamp = find.byKey(const ValueKey('ore-status-0'));
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ore-status-dialog')), findsOneWidget);
      expect(stamp, findsNothing);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(stamp, findsNothing);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mark-ore-found')));
      await tester.pumpAndSettle();
      expect(stamp, findsOneWidget);
      expect(find.text('FOUND'), findsOneWidget);
      expect(find.byKey(const ValueKey('ore-status-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('ore-status-1')), findsNothing);
      expect(
        tester.widget<Material>(find.byKey(const ValueKey('ore-card-0'))).color,
        AppColors.oreCollectedSurface,
      );
      expect(
        tester.widget<Material>(find.byKey(const ValueKey('ore-card-1'))).color,
        AppColors.oreRow,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final restarted = JsonHistoryRepository(source: source, store: store);
      await _mount(tester, repositories: _repositories(history: restarted));
      await _tab(tester, AppDestination.history);
      await tester.tap(find.text(record.seed));
      await tester.pumpAndSettle();
      expect(stamp, findsOneWidget);
      expect(_oreCards(), findsNWidgets(2));
      expect(find.byKey(const ValueKey('ore-status-0')), findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mark-ore-not-found')));
      await tester.pumpAndSettle();
      expect(stamp, findsNothing);
      expect(find.byKey(const ValueKey('ore-status-0')), findsNothing);
      expect(
        tester.widget<Material>(find.byKey(const ValueKey('ore-card-0'))).color,
        AppColors.oreRow,
      );
      expect(
        (await JsonHistoryRepository(
          source: source,
          store: store,
        ).load()).searches.single.positions.first.found,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history keeps only earned results across restarts and unlocks one per ad',
    (tester) async {
      final store = MemoryHistoryStore();
      final repositories = _repositories();
      final catalog = await repositories.find.load();
      final record = (await repositories.find.search(
        FindQuery(
          x: 0,
          z: 0,
          seed: 'saved-unlocks',
          version: catalog.versions.first,
          ore: catalog.ores.first,
        ),
      )).withRevealedCount(2);
      final source = JsonAssetSource(bundle: _FixtureBundle());
      final history = JsonHistoryRepository(source: source, store: store);
      await history.add(record);
      final ads = _RewardedAds();
      final access = AppMonetization(
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(
        tester,
        monetization: access,
        repositories: _repositories(history: history),
      );
      await _tab(tester, AppDestination.history);
      await tester.tap(find.text(record.seed));
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('show-all-ores')));
      await tester.pumpAndSettle();
      expect(find.text('Remove All Ads'), findsOneWidget);
      expect(access.isPro, isFalse);
      await tester.tap(find.byTooltip('Close paywall'));
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(2));
      final another = find.byKey(const ValueKey('show-another-ore'));
      ads.result = RewardedAdResult.dismissed;
      await tester.ensureVisible(another);
      await tester.tap(another);
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(2));
      expect((await history.load()).searches.single.revealedCount, 2);
      ScaffoldMessenger.of(tester.element(another)).clearSnackBars();
      await tester.pumpAndSettle();
      ads.result = RewardedAdResult.earned;
      await tester.tap(another);
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox.shrink());

      // A new repository and entitlement controller simulate restarting the app.
      final restartedHistory = JsonHistoryRepository(
        source: source,
        store: store,
      );
      final restartedAccess = _testAccess();
      await _mount(
        tester,
        monetization: restartedAccess,
        repositories: _repositories(history: restartedHistory),
      );
      await _tab(tester, AppDestination.history);
      await tester.tap(find.text(record.seed));
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(3));
      restartedAccess.updateEntitlement(true);
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(record.positions.length));
      restartedAccess.updateEntitlement(false);
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(3));
      for (var count = 4; count <= record.positions.length; count++) {
        await tester.ensureVisible(another);
        await tester.tap(another);
        await tester.pumpAndSettle();
        expect(_oreCards(), findsNWidgets(count));
        expect(
          (await restartedHistory.load()).searches.single.revealedCount,
          count,
        );
      }
      expect(another, findsNothing);
      expect(find.byKey(const ValueKey('show-all-ores')), findsNothing);
      expect(find.text('All ore clusters are shown.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('found-ores-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(record.seed));
      await tester.pumpAndSettle();
      expect(_oreCards(), findsNWidgets(record.positions.length));
      expect(another, findsNothing);
    },
  );

  testWidgets(
    'ore results fit a small screen with large text in every language',
    (tester) async {
      await _mount(tester, size: const Size(320, 568), textScale: 1.5);
      final repository = _repositories().find;
      final catalog = await repository.load();
      final record = await repository.search(
        FindQuery(
          x: -1234567890,
          z: 987654321,
          seed: 'large-coordinates',
          version: catalog.versions.first,
          ore: catalog.ores.first,
        ),
      );
      final languages = AppLanguageScope.maybeOf(
        tester.element(find.byType(AppShell)),
      )!;
      for (final locale in AppTranslations.supportedLocales) {
        await languages.select(locale.languageCode);
        await tester.pumpAndSettle();
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => FoundOresPage(
              record: record,
              onGoPro: () {},
              onHelp: () {},
              showLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ore-result-0')), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-another-ore')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        await tester.ensureVisible(find.byKey(const ValueKey('ore-result-0')));
        await tester.tap(find.byKey(const ValueKey('ore-result-0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ore-status-dialog')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        await tester.tap(find.byKey(const ValueKey('mark-ore-found')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ore-status-0')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: locale.languageCode);
        navigator.pop();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('map filters, favourites, seed details and locked content', (
    tester,
  ) async {
    await _mount(tester);
    await _tab(tester, AppDestination.maps);
    await _mapCategory(tester, 'Challenges');
    await tester.tap(find.byKey(const ValueKey('map-wings')));
    await tester.pumpAndSettle();
    expect(find.text('Unlock World'), findsOneWidget);
    expect(find.text('Remove All Ads'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('unlock-world')));
    await tester.pumpAndSettle();
    expect(find.text('Watch Ads to Unlock World'), findsOneWidget);
    expect(find.byType(RewardUnlockDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-unlock-premium')));
    await tester.pumpAndSettle();
    expect(find.text('Remove All Ads'), findsOneWidget);
    await tester.tap(find.byTooltip('Close paywall'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock World'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('game-header-back')));
    await tester.pumpAndSettle();
    await _mapCategory(tester, 'Seeds');
    await _capture(tester, '24-seeds-cards');
    expect(find.text('Emerald Valley'), findsOneWidget);
    expect(find.text('The Wings'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('favourite-valley')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-Favourite')));
    await tester.pumpAndSettle();
    expect(find.text('Emerald Valley'), findsOneWidget);
    expect(find.text('Cliffside Village'), findsNothing);
    await tester.tap(find.text('Emerald Valley'));
    await tester.pumpAndSettle();
    expect(find.text('Seed: 36643745'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Close'), findsNothing);
    await _tab(tester, AppDestination.find);
    await _tab(tester, AppDestination.maps);
    expect(find.byTooltip('Remove favourite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty map categories show the selected name centered in the app font',
    (tester) async {
      await _mount(tester);
      await _tab(tester, AppDestination.maps);
      for (final category in ['Favourite', 'Maze', 'Parkour', 'Mini game']) {
        await _mapCategory(tester, category);
        final message = find.text('there is no item in "$category"');
        expect(message, findsOneWidget);
        final text = tester.widget<Text>(message);
        expect(text.style!.fontFamily, AppFonts.body);
        expect(text.textAlign, TextAlign.center);
        expect(
          tester.getCenter(message),
          tester.getCenter(find.byKey(const ValueKey('empty-map-category'))),
        );
        expect(find.byKey(const ValueKey('map-wings')), findsNothing);
        if (category == 'Maze') await _capture(tester, '26-empty-map-category');
      }
      await _mapCategory(tester, 'Challenges');
      expect(find.text('The Wings'), findsOneWidget);
      expect(find.byKey(const ValueKey('empty-map-category')), findsNothing);
      await _mapCategory(tester, 'Horror');
      expect(find.text('Warehouse I'), findsOneWidget);
      expect(find.text('The Wings'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Seeds filters versions, copies seed and restores all versions', (
    tester,
  ) async {
    await _mount(tester);
    await _tab(tester, AppDestination.maps);
    await tester.tap(find.byKey(const ValueKey('category-Seeds')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('seed-version-filters')), findsOneWidget);
    final filters = find.byKey(const ValueKey('seed-version-filters'));
    expect(
      find.descendant(of: filters, matching: find.byType(Scrollable)),
      findsNothing,
    );
    final versionButtons = find.descendant(
      of: filters,
      matching: find.byType(InkWell),
    );
    expect(versionButtons, findsNWidgets(11));
    final rowOffsets = versionButtons
        .evaluate()
        .map(
          (element) =>
              tester.getTopLeft(find.byWidget(element.widget)).dy.round(),
        )
        .toSet();
    expect(rowOffsets.length, 3);
    for (final (row, count) in [(0, 4), (1, 5), (2, 2)]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('seed-version-row-$row')),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(count),
      );
    }
    // Bring the entire card into view regardless of the font's line wrapping.
    await tester.drag(
      find.byKey(const PageStorageKey('maps-Seeds')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('map-valley'))),
      alignment: 1,
    );
    await tester.pumpAndSettle();
    final navigationTop = tester
        .getTopLeft(find.byKey(const ValueKey('nav-maps')))
        .dy;
    final card = find.byKey(const ValueKey('map-valley'));
    final clipped = tester.getRect(card).bottom - navigationTop;
    if (clipped > 0) {
      await tester.drag(
        find.byKey(const PageStorageKey('maps-Seeds')),
        Offset(0, -clipped - 16),
      );
      await tester.pumpAndSettle();
    }
    expect(tester.getRect(card).bottom, lessThanOrEqualTo(navigationTop));

    await tester.drag(
      find.byKey(const PageStorageKey('maps-Seeds')),
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('seed-version-1.21 Java')));
    await tester.pumpAndSettle();
    expect(find.text('Emerald Valley'), findsOneWidget);
    expect(find.text('Cliffside Village'), findsNothing);
    expect(find.text('1.21 Java'), findsNWidgets(2));

    String? clipboard;
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.ensureVisible(find.byKey(const ValueKey('copy-seed-valley')));
    await tester.tap(find.byKey(const ValueKey('copy-seed-valley')));
    await tester.pumpAndSettle();
    expect(clipboard, '36643745');
    expect(find.text('Seed copied'), findsOneWidget);

    // Bring the scrolling header back before selecting another version.
    await tester.drag(
      find.byKey(const PageStorageKey('maps-Seeds')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    final olderVersion = find.byKey(const ValueKey('seed-version-1.19 Java'));
    await tester.ensureVisible(olderVersion);
    await tester.tap(olderVersion);
    await tester.pumpAndSettle();
    expect(find.text('Cliffside Village'), findsOneWidget);
    expect(find.text('Emerald Valley'), findsNothing);

    // Tapping the selected version clears the filter without an extra chip.
    await tester.tap(olderVersion);
    await tester.pumpAndSettle();
    expect(find.text('Emerald Valley'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('map-cliffs')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('maps-Seeds')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Cliffside Village'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'seed card shows full description without a sheet and header scrolls away',
    (tester) async {
      const path = 'assets/data/maps/maps.json';
      final original = _jsonFiles[path]!;
      addTearDown(() => _jsonFiles[path] = original);
      final catalog = jsonDecode(original) as Map<String, dynamic>;
      const description =
          'Why have one village when you can have two in close proximity? '
          'This seed comes with one large village and one medium village, with another just off-spawn. '
          'Watch your step when exploring them since this great Minecraft seed is filled with deep caverns '
          'and exciting exploration opportunities. There is also a pillager outpost on top of a mountain.';
      for (final item in catalog['items'] as List) {
        if (item['id'] == 'valley') item['description'] = description;
      }
      _jsonFiles[path] = jsonEncode(catalog);
      await _mount(tester, size: const Size(390, 740));
      await _tab(tester, AppDestination.maps);
      await tester.tap(find.byKey(const ValueKey('category-Seeds')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emerald Valley'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.widget<Text>(find.text(description)).maxLines, isNull);
      await tester.drag(
        find.byKey(const PageStorageKey('maps-Seeds')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byKey(const ValueKey('map-valley')));
      final navigationTop = tester
          .getTopLeft(find.byKey(const ValueKey('nav-maps')))
          .dy;
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.bottom, lessThanOrEqualTo(navigationTop));
      await _capture(tester, '25-seeds-full-card-scrolled');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('History and Seeds fit small screens with large text', (
    tester,
  ) async {
    final languages = AppLocaleController();
    await _mount(
      tester,
      size: const Size(320, 568),
      textScale: 1.5,
      languages: languages,
    );
    final shellContext = tester.element(find.byType(AppShell));
    final record = await _repositories().find.search(
      FindQuery(
        x: -1234567890,
        z: 987654321,
        seed: '-9223372036854775808',
        version: (await _repositories().find.load()).versions.first,
        ore: (await _repositories().find.load()).ores.first,
      ),
    );
    // Seed History through the same callback used by digging.
    await tester.widget<FindPage>(find.byType(FindPage)).onFound!(record);
    await tester.pumpAndSettle();
    await _tab(tester, AppDestination.history);
    expect(find.text(record.seed), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(shellContext.mounted, isTrue);

    await _tab(tester, AppDestination.maps);
    await tester.tap(find.byKey(const ValueKey('category-Seeds')));
    await tester.pumpAndSettle();
    for (final code in ['en', 'vi', 'fr', 'de']) {
      await languages.select(code);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: code);
    }
  });

  testWidgets(
    'earned map reward saves one world, syncs favourite and prevents duplicate ads',
    (tester) async {
      final ads = _RewardedAds()..pending = Completer<RewardedAdResult>();
      final access = AppMonetization(
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      await _tab(tester, AppDestination.maps);
      await _mapCategory(tester, 'Horror');
      await tester.tap(find.byKey(const ValueKey('map-warehouse1')));
      await tester.pumpAndSettle();
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(
        find.text('Story-driven map set in an abandoned warehouse.'),
        findsOneWidget,
      );
      expect(ads.preloads, greaterThan(0));
      await _capture(tester, '17-map-details');
      await tester.tap(find.byKey(const ValueKey('map-detail-favourite')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('unlock-world')));
      await tester.pumpAndSettle();
      await _capture(tester, '18-map-unlock');
      await tester.tap(find.byKey(const ValueKey('watch-map-ad')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('watch-map-ad')));
      await tester.pump();
      expect(ads.requests, 1);
      expect(find.text('World Unlocked'), findsNothing);
      ads.pending!.complete(RewardedAdResult.earned);
      await tester.pumpAndSettle();
      expect(find.text('World Unlocked'), findsOneWidget);
      expect(find.text('Watch Ads to Unlock World'), findsNothing);
      final restored = JsonMapsRepository(
        source: JsonAssetSource(bundle: _FixtureBundle()),
      );
      await restored.load();
      expect(restored.unlocked, {'warehouse1'});
      access.updateEntitlement(true);
      access.updateEntitlement(false);
      await tester.pump();
      expect(find.text('World Unlocked'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('game-header-back')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('map-warehouse1')),
          matching: find.byIcon(Icons.lock),
        ),
        findsNothing,
      );
      expect(find.byTooltip('Remove favourite'), findsOneWidget);
      await _mapCategory(tester, 'Challenges');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('map-wings')),
          matching: find.byIcon(Icons.lock),
        ),
        findsOneWidget,
      );
      await _mapCategory(tester, 'Horror');
      await tester.tap(find.byKey(const ValueKey('map-warehouse1')));
      await tester.pumpAndSettle();
      expect(find.text('World Unlocked'), findsOneWidget);
      expect(ads.requests, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final result in [
    RewardedAdResult.dismissed,
    RewardedAdResult.unavailable,
    RewardedAdResult.unsupported,
  ]) {
    testWidgets('map remains locked after $result and modal can be closed', (
      tester,
    ) async {
      final ads = _RewardedAds()..result = result;
      final access = AppMonetization(
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      await _tab(tester, AppDestination.maps);
      await _mapCategory(tester, 'Challenges');
      await tester.tap(find.byKey(const ValueKey('map-wings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('unlock-world')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('watch-map-ad')));
      await tester.pumpAndSettle();
      final message = switch (result) {
        RewardedAdResult.dismissed => 'Watch the ad to unlock this world.',
        RewardedAdResult.unsupported =>
          'Rewarded ads are available on Android and iOS only.',
        _ => 'No ad is available right now. Please try again.',
      };
      expect(find.text(message), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          JsonMapsRepository.unlockedKey,
        ),
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('close-map-unlock')));
      await tester.pumpAndSettle();
      expect(find.text('Unlock World'), findsOneWidget);
      expect(find.text('World Unlocked'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Pro opens map access without ads and expiry restores unpaid locks',
    (tester) async {
      final ads = _RewardedAds();
      final access = AppMonetization(
        isPro: true,
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      await _tab(tester, AppDestination.maps);
      await _mapCategory(tester, 'Challenges');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('map-wings')),
          matching: find.byIcon(Icons.lock),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('map-wings')));
      await tester.pumpAndSettle();
      expect(find.text('World Unlocked'), findsOneWidget);
      expect(ads.requests, 0);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          JsonMapsRepository.unlockedKey,
        ),
        isNull,
      );
      access.updateEntitlement(false);
      await tester.pumpAndSettle();
      expect(find.text('Unlock World'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final layout in [
    (const Size(320, 568), 1.5),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'map details and unlock dialog fit ${layout.$1} at ${layout.$2}',
      (tester) async {
        await _mount(tester, size: layout.$1, textScale: layout.$2);
        expect(tester.takeException(), isNull, reason: 'mount');
        await _tab(tester, AppDestination.maps);
        expect(tester.takeException(), isNull, reason: 'maps');
        await _mapCategory(tester, 'Challenges');
        await tester.tap(find.byKey(const ValueKey('map-wings')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'detail');
        await tester.tap(find.byKey(const ValueKey('unlock-world')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('map-unlock-premium')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('map-unlock-premium')));
        await tester.pumpAndSettle();
        expect(find.text('Remove All Ads'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unlocked skin shares a PNG of the current view through the platform sheet',
    (tester) async {
      await _mount(tester);
      await _tab(tester, AppDestination.skins);
      await _shareSkinImage(tester);
      final request = _skinShares.requests.single;
      expect(request.fileNameOverrides, ['skin-steve.png']);
      expect(request.files!.single.mimeType, 'image/png');
      expect(request.text, isNull);
      expect(request.subject, 'Steve');
      expect(
        request.sharePositionOrigin,
        tester.getRect(find.byKey(const ValueKey('skin-share'))),
      );
      final png = (await tester.runAsync(request.files!.single.readAsBytes))!;
      expect(png.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        expect(image.width, 1024);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        // The exported preview has a plain white background and real character pixels.
        expect(pixels.take(4).toList(), [255, 255, 255, 255]);
        expect(pixels.every((byte) => byte == 255), isFalse);
        image.dispose();
        codec.dispose();
        if (Platform.environment['CAPTURE_PREVIEWS'] == 'true') {
          await Directory('output/previews').create(recursive: true);
          await File('output/previews/28-shared-skin.png').writeAsBytes(png);
        }
      });
      await tester.drag(
        find.byKey(const ValueKey('skin-3d-viewer')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      await _shareSkinImage(tester);
      final rotated = (await tester.runAsync(
        _skinShares.requests.last.files!.single.readAsBytes,
      ))!;
      expect(listEquals(png, rotated), isFalse);
      expect(find.byType(RewardUnlockDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'image sharing prevents duplicate sheets and recovers from a platform error',
    (tester) async {
      await _mount(tester);
      await _tab(tester, AppDestination.skins);
      _skinShares.pending = Completer<ShareResult>();
      await tester.tap(find.byKey(const ValueKey('skin-share')));
      await _finishSkinShare(tester, settle: false);
      await tester.tap(find.byKey(const ValueKey('skin-share')));
      await tester.pump();
      expect(_skinShares.requests.length, 1);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('skin-share')))
            .onPressed,
        isNull,
      );
      _skinShares.pending!.complete(
        const ShareResult('', ShareResultStatus.dismissed),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to share this image. Please try again.'),
        findsNothing,
      );
      _skinShares.pending = null;
      _skinShares.fail = true;
      await _shareSkinImage(tester);
      expect(
        find.text('Unable to share this image. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('skin-share')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('skins select free characters, animate and open locked offer', (
    tester,
  ) async {
    await _mount(tester);
    await _tab(tester, AppDestination.skins);
    await tester.tap(find.byKey(const ValueKey('skin-batman')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected-skin-locked')), findsOneWidget);
    expect(find.text('Remove All Ads'), findsNothing);
    expect(
      tester.widget<VoxelCharacter3D>(find.byType(VoxelCharacter3D)).palette,
      'knight',
    );
    await tester.tap(find.byKey(const ValueKey('skin-share')));
    await tester.pumpAndSettle();
    expect(find.text('Watch Ads to Unlock Skin'), findsOneWidget);
    expect(find.byType(RewardUnlockDialog), findsOneWidget);
    await _capture(tester, '27-skin-unlock');
    await tester.tap(find.byKey(const ValueKey('skin-unlock-premium')));
    await tester.pumpAndSettle();
    expect(find.text('Remove All Ads'), findsOneWidget);
    await tester.tap(find.byTooltip('Close paywall'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('skin-explorer')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('skins-grid')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('skin-explorer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skin-explorer')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<VoxelCharacter3D>(find.byType(VoxelCharacter3D)).palette,
      'explorer',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('skin-walk')));
    await tester.tap(find.byKey(const ValueKey('skin-walk')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<VoxelCharacter3D>(find.byType(VoxelCharacter3D)).walking,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('No searches made yet!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'skin reward unlocks only the selected skin, persists and blocks duplicate ads',
    (tester) async {
      final ads = _RewardedAds()..pending = Completer<RewardedAdResult>();
      final access = AppMonetization(
        rewardedAds: ads,
        adsRuntime: AdsRuntime(enabled: false),
      );
      addTearDown(access.dispose);
      await _mount(tester, monetization: access);
      await _tab(tester, AppDestination.skins);
      await tester.tap(find.byKey(const ValueKey('skin-batman')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skin-share')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('watch-skin-ad')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('watch-skin-ad')));
      await tester.pump();
      expect(ads.requests, 1);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('close-skin-unlock')))
            .onPressed,
        isNull,
      );
      ads.pending!.complete(RewardedAdResult.earned);
      await _finishSkinShare(tester);
      expect(_skinShares.requests.single.fileNameOverrides, [
        'skin-batman.png',
      ]);
      expect(find.byType(RewardUnlockDialog), findsNothing);
      expect(find.byKey(const ValueKey('selected-skin-locked')), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          JsonSkinsRepository.unlockedKey,
        ),
        ['batman'],
      );
      final restored = JsonSkinsRepository(
        source: JsonAssetSource(bundle: _FixtureBundle()),
      );
      await restored.load();
      expect(restored.unlocked, {'batman'});
      await _shareSkinImage(tester);
      expect(find.byType(RewardUnlockDialog), findsNothing);
      expect(ads.requests, 1);

      await tester.ensureVisible(find.byKey(const ValueKey('skin-superpanda')));
      await tester.tap(find.byKey(const ValueKey('skin-superpanda')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-skin-locked')),
        findsOneWidget,
      );
      access.updateEntitlement(true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selected-skin-locked')), findsNothing);
      await _shareSkinImage(tester);
      expect(_skinShares.requests.last.fileNameOverrides, [
        'skin-superpanda.png',
      ]);
      expect(ads.requests, 1);
      access.updateEntitlement(false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-skin-locked')),
        findsOneWidget,
      );
      expect(restored.unlocked, {'batman'});
      expect(tester.takeException(), isNull);
    },
  );

  for (final result in [
    RewardedAdResult.dismissed,
    RewardedAdResult.unavailable,
    RewardedAdResult.unsupported,
  ]) {
    testWidgets(
      'skin remains locked after $result and unlock dialog can close',
      (tester) async {
        final ads = _RewardedAds()..result = result;
        final access = AppMonetization(
          rewardedAds: ads,
          adsRuntime: AdsRuntime(enabled: false),
        );
        addTearDown(access.dispose);
        await _mount(tester, monetization: access);
        await _tab(tester, AppDestination.skins);
        await tester.tap(find.byKey(const ValueKey('skin-batman')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('skin-share')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('watch-skin-ad')));
        await tester.pumpAndSettle();
        expect(find.byType(RewardUnlockDialog), findsOneWidget);
        final message = switch (result) {
          RewardedAdResult.dismissed => 'Watch the ad to unlock this skin.',
          RewardedAdResult.unsupported =>
            'Rewarded ads are available on Android and iOS only.',
          _ => 'No ad is available right now. Please try again.',
        };
        expect(find.text(message), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getStringList(
            JsonSkinsRepository.unlockedKey,
          ),
          isNull,
        );
        await tester.tap(find.byKey(const ValueKey('close-skin-unlock')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('selected-skin-locked')),
          findsOneWidget,
        );
        expect(_skinShares.requests, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final layout in [
    (const Size(320, 568), 1.5),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('skin unlock dialog fits ${layout.$1} at ${layout.$2}', (
      tester,
    ) async {
      await _mount(tester, size: layout.$1, textScale: layout.$2);
      await _tab(tester, AppDestination.skins);
      await tester.tap(find.byKey(const ValueKey('skin-batman')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skin-share')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('skin-unlock-premium')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skin-unlock-premium')));
      await tester.pumpAndSettle();
      expect(find.text('Remove All Ads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('skins grid scrolls vertically beneath the fixed 3D preview', (
    tester,
  ) async {
    await _mount(tester);
    await _tab(tester, AppDestination.skins);
    final preview = find.byKey(const ValueKey('skin-preview'));
    final viewer = find.byKey(const ValueKey('skin-3d-viewer'));
    final grid = find.byKey(const PageStorageKey('skins-grid'));
    final previewBounds = tester.getRect(preview);
    final angle = tester
        .getSemantics(find.bySemanticsLabel('3D skin preview'))
        .getSemanticsData()
        .value;
    final firstCard = tester.getRect(find.byKey(const ValueKey('skin-steve')));
    final secondCard = tester.getRect(
      find.byKey(const ValueKey('skin-batman')),
    );
    expect(firstCard.top, secondCard.top);
    final thirdCard = tester.getRect(
      find.byKey(const ValueKey('skin-superpanda')),
    );
    expect(thirdCard.top, greaterThan(firstCard.bottom));

    await tester.drag(grid, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(tester.getRect(preview), previewBounds);
    await tester.drag(viewer, const Offset(210, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('3D skin preview'))
          .getSemanticsData()
          .value,
      isNot(angle),
    );
    expect(tester.getRect(preview), previewBounds);
    await _capture(tester, '10-skins-back');

    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(viewer);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('3D skin preview'))
          .getSemanticsData()
          .value,
      angle,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('server info template opens and its local actions work', (
    tester,
  ) async {
    await _mount(tester);
    await _tab(tester, AppDestination.servers);
    await tester.tap(find.byKey(const ValueKey('server-complex')));
    await tester.pumpAndSettle();
    expect(find.text('Server Info'), findsOneWidget);
    expect(find.text('demo-complex.example'), findsOneWidget);
    expect(find.text('ADD TO BEDROCK SERVER LIST'), findsOneWidget);
    expect(find.text('Visit Server Website'), findsOneWidget);
    await _capture(
      tester,
      '13-server-info',
      boundary: find.byKey(const ValueKey('server-info-preview')),
    );

    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.tap(find.byKey(const ValueKey('server-copy-address')));
    await tester.pumpAndSettle();
    expect(copied, 'demo-complex.example');
    expect(find.text('Server address copied'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('server-add')));
    await tester.pumpAndSettle();
    expect(find.text('Port: 19132'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('server-website')));
    await tester.tap(find.byKey(const ValueKey('server-website')));
    await tester.pumpAndSettle();
    expect(find.text('https://example.com/servers/complex'), findsOneWidget);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copied, 'https://example.com/servers/complex');

    await tester.ensureVisible(find.byKey(const ValueKey('server-share')));
    await tester.tap(find.byKey(const ValueKey('server-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy server address'));
    await tester.pumpAndSettle();
    expect(copied, 'demo-complex.example');
    await tester.tap(find.byKey(const ValueKey('server-info-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('server-complex')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'onboarding completion enters Find and named routes open each tab',
    (tester) async {
      await tester.pumpWidget(
        MyApp(repositories: _repositories(), monetization: _testAccess()),
      );
      await tester.pumpAndSettle();
      await tester.pump(_startupDuration);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close paywall'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Find Diamonds!'), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/servers');
      await tester.pumpAndSettle();
      expect(find.text('Complex Gaming'), findsOneWidget);
    },
  );

  for (final exit in [
    'Close paywall',
    'system Back on paywall',
    'system Back on tutorial',
  ]) {
    testWidgets('$exit enters Find and skips onboarding after restart', (
      tester,
    ) async {
      await tester.pumpWidget(
        MyApp(repositories: _repositories(), monetization: _testAccess()),
      );
      await tester.pumpAndSettle();
      await tester.pump(_startupDuration);
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
      if (exit != 'system Back on tutorial') {
        await tester.tap(find.text('SKIP'));
        await tester.pumpAndSettle();
      }
      if (exit.startsWith('system Back')) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byTooltip(exit));
      }
      await tester.pumpAndSettle();
      expect(find.text('Find Diamonds!'), findsOneWidget);
      expect(find.byType(OnboardingFlow), findsNothing);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(OnboardingPreferences.completedKey), isTrue);

      // Recreate the app with the same saved device preferences.
      await tester.pumpWidget(const SizedBox.shrink());
      await preferences.reload();
      await tester.pumpWidget(
        MyApp(repositories: _repositories(), monetization: _testAccess()),
      );
      expect(find.byType(AppLoadingPage), findsOneWidget);
      await tester.pump(_startupDuration);
      await tester.pumpAndSettle();
      expect(find.text('Find Diamonds!'), findsOneWidget);
      expect(find.byType(OnboardingFlow), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('first launch is recorded before onboarding is dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(repositories: _repositories(), monetization: _testAccess()),
    );
    await tester.pump();
    expect(find.byType(AppLoadingPage), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingPreferences.seenKey), isTrue);
    expect(preferences.getBool(OnboardingPreferences.completedKey), isNull);

    // Reload during the initial splash without completing or closing anything.
    await tester.pumpWidget(const SizedBox.shrink());
    await preferences.reload();
    await tester.pumpWidget(
      MyApp(repositories: _repositories(), monetization: _testAccess()),
    );
    await tester.pump(_startupDuration);
    await tester.pumpAndSettle();
    expect(find.text('Find Diamonds!'), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing completed installs continue to skip onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingPreferences.completedKey: true,
    });
    await tester.pumpWidget(
      MyApp(repositories: _repositories(), monetization: _testAccess()),
    );
    await tester.pump(_startupDuration);
    await tester.pumpAndSettle();
    expect(find.text('Find Diamonds!'), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });

  testWidgets('development skip does not complete first-run onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        skipOnboarding: true,
        repositories: _repositories(),
        monetization: _testAccess(),
      ),
    );
    await tester.pump(_startupDuration);
    await tester.pumpAndSettle();
    expect(find.text('Find Diamonds!'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingPreferences.seenKey), isNull);
    expect(preferences.getBool(OnboardingPreferences.completedKey), isNull);
  });

  for (final returningUser in [false, true]) {
    testWidgets('startup shows one splash, returning=$returningUser', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        if (returningUser) OnboardingPreferences.seenKey: true,
      });
      await tester.pumpWidget(
        MyApp(repositories: _repositories(), monetization: _testAccess()),
      );
      expect(find.byType(AppLoadingPage), findsOneWidget);
      await tester.pump(_startupDuration - const Duration(milliseconds: 100));
      expect(find.byType(AppLoadingPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingPage), findsNothing);
      if (returningUser) {
        expect(find.text('Find Diamonds!'), findsOneWidget);
        expect(find.byType(OnboardingFlow), findsNothing);
      } else {
        expect(find.text('Step 1'), findsOneWidget);
      }
    });
  }

  for (final scenario in [
    (const Size(320, 568), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(320, 568), 1.5),
  ]) {
    testWidgets('all tabs fit ${scenario.$1} at text scale ${scenario.$2}', (
      tester,
    ) async {
      await _mount(tester, size: scenario.$1, textScale: scenario.$2);
      for (final destination in AppDestination.values) {
        await _tab(tester, destination);
        expect(tester.takeException(), isNull, reason: destination.name);
      }
      await _tab(tester, AppDestination.servers);
      await tester.tap(find.byKey(const ValueKey('server-complex')));
      await tester.pumpAndSettle();
      expect(find.text('Server Info'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('server-website')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('server-complex')), findsOneWidget);
      await _tab(tester, AppDestination.find);
      await _openHelp(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('help-faq-position')),
      );
      await tester.tap(find.byKey(const ValueKey('help-faq-position')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('help-privacy')));
      await tester.tap(find.byKey(const ValueKey('help-privacy')));
      await tester.pumpAndSettle();
      expect(find.byType(HelpPolicyDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('help-policy-ok')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
