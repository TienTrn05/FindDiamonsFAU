import 'package:flutter/material.dart';
import 'dart:async';
import '../app_repositories.dart';
import '../../common/widgets/app_page_frame.dart';
import '../../common/widgets/game_bottom_navigation.dart';
import '../../common/widgets/ad_placements.dart';
import '../../common/widgets/app_text.dart';

import '../../core/navigation/app_destination.dart';
import '../../core/monetization/app_monetization.dart';
import '../../core/models/search_record.dart';
import '../../features/find/presentation/find_page.dart';
import '../../features/help/presentation/help_page.dart';
import '../../features/history/bloc/history_bloc.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/maps/presentation/maps_page.dart';
import '../../features/onboarding/presentation/paywall.dart';
import '../../features/servers/presentation/servers_page.dart';
import '../../features/skins/presentation/skins_page.dart';
import '../../features/skins/bloc/skins_bloc.dart';

/// Only composes feature routes and owns shared session dependencies.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialDestination = AppDestination.find,
    this.repositories,
    this.monetization,
  });
  final AppDestination initialDestination;
  final AppRepositories? repositories;
  final AppMonetization? monetization;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AppMonetization? _sessionAccess;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final access = _monetization;
    if (!identical(_sessionAccess, access)) {
      _sessionAccess?.removeListener(_prepareInterstitial);
      _sessionAccess = access;
      access.addListener(_prepareInterstitial);
    }
    access.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _prepareInterstitial();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sessionAccess?.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) _prepareInterstitial();
  }

  void _prepareInterstitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final access = _sessionAccess;
      if (!mounted || access == null || access.isPro) return;
      unawaited(
        access.interstitialAds.preload(
          canLoad: () =>
              mounted &&
              !access.isPro &&
              ModalRoute.of(context)?.isCurrent == true,
        ),
      );
    });
  }

  Future<void> _transitionAd() async {
    final access = _monetization;
    await access.maybeShowInterstitial(
      canShow: () =>
          mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          MediaQuery.viewInsetsOf(context).bottom == 0,
    );
    if (mounted) _prepareInterstitial();
  }

  Future<void> _selectDestination(AppDestination destination) async {
    if (_switching || _selected == destination) return;
    _switching = true;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await _transitionAd();
      if (mounted) setState(() => _selected = destination);
    } finally {
      _switching = false;
    }
  }

  Future<void> _recordSearch(SearchRecord record) async {
    try {
      await _history.record(record);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'Results are ready, but history could not be saved. Please try again.',
            ),
          ),
        );
      }
    }
    if (mounted) await _transitionAd();
  }

  late final _fallbackMonetization = AppMonetization();
  AppMonetization get _monetization =>
      widget.monetization ??
      MonetizationScope.maybeOf(context) ??
      _fallbackMonetization;
  late AppDestination _selected = widget.initialDestination;
  late final AppRepositories _repositories =
      widget.repositories ?? AppRepositories();
  late final HistoryBloc _history = HistoryBloc(_repositories.history)..load();
  late final SkinsBloc _skins = SkinsBloc(_repositories.skins)..load();
  late final List<Widget> _pages = [
    FindPage(
      onGoPro: _goPro,
      onHelp: _help,
      onFound: _recordSearch,
      onReveal: _history.reveal,
      onFoundChanged: _history.setFound,
      repository: _repositories.find,
    ),
    HistoryPage(controller: _history, onGoPro: _goPro, onHelp: _help),
    SkinsPage(onGoPro: _goPro, controller: _skins),
    ListenableBuilder(
      listenable: _skins,
      builder: (_, _) => ServersPage(
        repository: _repositories.servers,
        selectedSkin: _skins.selectedOrNull,
      ),
    ),
    MapsPage(onGoPro: _goPro, repository: _repositories.maps),
  ];

  void _help() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/help'),
      builder: (_) => MonetizationScope(
        controller: _monetization,
        child: HelpPage(
          repository: _repositories.help,
          onRestore: _monetization.onRestore == null
              ? null
              : _monetization.restore,
        ),
      ),
    ),
  );

  void _goPro() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/premium'),
      builder: (context) => Scaffold(
        body: AppPageFrame(
          child: Paywall(
            onPurchase: _monetization.onPurchase == null
                ? null
                : _monetization.purchase,
            onRestore: _monetization.onRestore == null
                ? null
                : _monetization.restore,
            onBack: () => Navigator.pop(context),
            onClose: () => Navigator.pop(context),
            onSuccess: () => Navigator.pop(context),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionAccess?.removeListener(_prepareInterstitial);
    _sessionAccess?.setForeground(false);
    _history.dispose();
    _skins.dispose();
    _fallbackMonetization.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return MonetizationScope(
      controller: _monetization,
      child: PopScope(
        canPop: _selected == AppDestination.find,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _selectDestination(AppDestination.find);
        },
        child: Scaffold(
          body: AppPageFrame(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _selected.index,
                    children: [
                      for (final destination in AppDestination.values)
                        TickerMode(
                          enabled: _selected == destination,
                          child: _pages[destination.index],
                        ),
                    ],
                  ),
                ),
                if (!keyboardVisible) ...[
                  const BannerAdSlot(),
                  GameBottomNavigation(
                    selected: _selected,
                    onSelected: _selectDestination,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
