import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/localization/app_locale_controller.dart';
import '../core/localization/app_translations.dart';
import '../common/widgets/app_loading_page.dart';
import '../common/widgets/app_page_frame.dart';
import '../core/responsive/app_layout.dart';
import '../core/navigation/app_destination.dart';
import '../core/monetization/app_monetization.dart';
import '../core/monetization/banner_ad_layout.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/data/onboarding_preferences.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/help/presentation/help_page.dart';
import 'navigation/app_shell.dart';
import 'app_repositories.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.skipOnboarding = const bool.fromEnvironment('SKIP_ONBOARDING'),
    this.repositories,
    this.localeController,
    this.monetization,
  });
  final bool skipOnboarding;
  final AppRepositories? repositories;
  final AppLocaleController? localeController;
  final AppMonetization? monetization;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _repositories = widget.repositories ?? AppRepositories();
  late final _monetization = widget.monetization ?? AppMonetization();
  late final AppLocaleController _languages =
      widget.localeController ?? AppLocaleController();

  @override
  void initState() {
    super.initState();
    _languages.load();
  }

  @override
  void dispose() {
    if (widget.localeController == null) _languages.dispose();
    if (widget.monetization == null) _monetization.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MonetizationScope(
    controller: _monetization,
    child: AppLanguageScope(
      controller: _languages,
      child: ListenableBuilder(
        listenable: _languages,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Find Diamonds',
          theme: AppTheme.dark,
          locale: _languages.locale,
          supportedLocales: AppTranslations.supportedLocales,
          localizationsDelegates: const [
            AppTranslations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: _AppEntry(
            skipOnboarding: widget.skipOnboarding,
            repositories: _repositories,
          ),
          routes: {
            '/help': (_) => HelpPage(repository: _repositories.help),
            for (final destination in AppDestination.values)
              destination.route: (_) => AppShell(
                initialDestination: destination,
                repositories: _repositories,
              ),
          },
        ),
      ),
    ),
  );
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({required this.skipOnboarding, required this.repositories});
  final bool skipOnboarding;
  final AppRepositories repositories;
  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final _preferences = OnboardingPreferences();
  late bool? _finished = widget.skipOnboarding ? true : null;
  bool _completing = false;
  bool _splashDone = false;
  bool _launchAdDone = false;
  bool _launchAdStarted = false;
  bool _dataReady = false;
  bool _preparing = false;
  Future<void>? _bannerLayout;
  bool _bannerLayoutReady = false;
  Timer? _splashTimer;
  Timer? _startupRetry;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 3000), () {
      setState(() => _splashDone = true);
    });
    if (!widget.skipOnboarding) _loadOnboarding();
    _prepareData();
  }

  Future<void> _prepareData() async {
    if (_preparing) return;
    _startupRetry?.cancel();
    _preparing = true;
    try {
      await widget.repositories.prepare();
      if (mounted) setState(() => _dataReady = true);
    } catch (error) {
      debugPrint('Startup data unavailable: $error');
      if (mounted) {
        _startupRetry = Timer(const Duration(seconds: 60), _prepareData);
      }
    } finally {
      _preparing = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bannerLayout ??= _prepareBannerLayout();
    if (_launchAdStarted) return;
    _launchAdStarted = true;
    final access = MonetizationScope.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showLaunchAd(access));
    });
  }

  Future<void> _prepareBannerLayout() async {
    final width = MediaQuery.sizeOf(
      context,
    ).width.clamp(0, AppLayout.maxContentWidth).floor();
    await BannerAdLayout.resolve(
      MonetizationScope.maybeOf(context)?.adsRuntime,
      width,
    );
    if (mounted) setState(() => _bannerLayoutReady = true);
  }

  Future<void> _showLaunchAd(AppMonetization? access) async {
    try {
      await access?.showLaunchAd(
        canShow: () =>
            mounted &&
            !_launchAdDone &&
            ModalRoute.of(context)?.isCurrent == true &&
            (WidgetsBinding.instance.lifecycleState == null ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed),
      );
    } catch (error) {
      debugPrint('Launch ad unavailable: $error');
    } finally {
      if (mounted) setState(() => _launchAdDone = true);
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _startupRetry?.cancel();
    super.dispose();
  }

  Future<void> _loadOnboarding() async {
    var completed = false;
    try {
      completed = await _preferences.isSeen();
      // Persist before displaying onboarding, even if the user reloads midway.
      if (!completed) await _preferences.markSeen();
    } catch (error) {
      debugPrint('Unable to read onboarding preferences: $error');
    }
    if (mounted) setState(() => _finished = completed);
  }

  Future<void> _completeOnboarding() async {
    if (_completing) return;
    _completing = true;
    try {
      await _preferences.complete();
    } catch (error) {
      debugPrint('Unable to save onboarding preferences: $error');
    }
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone ||
        !_launchAdDone ||
        _finished == null ||
        !_dataReady ||
        !_bannerLayoutReady) {
      return const Scaffold(body: AppPageFrame(child: AppLoadingPage()));
    }
    return _finished!
        ? AppShell(repositories: widget.repositories)
        : OnboardingFlow(
            splashDuration: Duration.zero,
            onPurchase: MonetizationScope.maybeOf(context)?.onPurchase == null
                ? null
                : MonetizationScope.maybeOf(context)!.purchase,
            onRestore: MonetizationScope.maybeOf(context)?.onRestore == null
                ? null
                : MonetizationScope.maybeOf(context)!.restore,
            onComplete: _completeOnboarding,
          );
  }
}
