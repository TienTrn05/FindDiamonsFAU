import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/digging_pickaxe.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../core/models/search_record.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/monetization/rewarded_ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/digging_bloc.dart';
import 'ore_status_dialog.dart';
import 'ore_found_stamp.dart';

class FoundOresPage extends StatefulWidget {
  const FoundOresPage({
    super.key,
    required this.record,
    required this.onGoPro,
    required this.onHelp,
    this.showLoading = true,
    this.onReveal,
    this.onFoundChanged,
    this.monetization,
    this.revealDuration = const Duration(milliseconds: 1100),
  });
  final SearchRecord record;
  final VoidCallback onGoPro;
  final VoidCallback onHelp;
  final bool showLoading;
  final Future<void> Function(int count)? onReveal;
  final Future<void> Function(int index, bool found)? onFoundChanged;
  final AppMonetization? monetization;
  final Duration revealDuration;

  @override
  State<FoundOresPage> createState() => _FoundOresPageState();
}

class _FoundOresPageState extends State<FoundOresPage>
    with SingleTickerProviderStateMixin {
  late final _bloc = DiggingBloc(widget.record);
  late final _progress = AnimationController(
    vsync: this,
    duration: widget.revealDuration,
  );
  late bool _loading = widget.showLoading;
  bool _nextPending = false;
  bool _adPending = false;
  bool _preloadScheduled = false;
  bool _statusDialogOpen = false;
  late final _fallbackMonetization = AppMonetization();
  AppMonetization get _access =>
      widget.monetization ??
      MonetizationScope.maybeOf(context) ??
      _fallbackMonetization;
  int get _visibleCount => math.min(
    widget.record.positions.length,
    _access.isPro
        ? widget.record.positions.length
        : math.max(_bloc.visibleCount, _access.revealedCount(widget.record.id)),
  );
  int get _remaining => widget.record.positions.length - _visibleCount;

  void _scheduleAdPreload() {
    final access = _access;
    // Reading isCurrent also rebuilds this page when returning from Help/paywall.
    if (_preloadScheduled ||
        access.isPro ||
        _remaining == 0 ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _preloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadScheduled = false;
      if (!mounted) return;
      unawaited(
        access.rewardedAds.preload(
          canLoad: () =>
              mounted &&
              !access.isPro &&
              _remaining > 0 &&
              ModalRoute.of(context)?.isCurrent == true,
        ),
      );
    });
  }

  Ore get _ore => Ore.values.firstWhere(
    (ore) => ore.name == widget.record.oreId,
    orElse: () => Ore.diamond,
  );

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (_nextPending) _bloc.revealNext();
      setState(() {
        _loading = false;
        _nextPending = false;
      });
    });
    if (_loading) _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _bloc.dispose();
    _fallbackMonetization.dispose();
    super.dispose();
  }

  Future<void> _another() async {
    if (_loading || _adPending || _remaining == 0) return;
    final access = _access;
    final count = _visibleCount;
    setState(() => _adPending = true);
    RewardedAdResult result;
    try {
      result = await access.rewardedAds.show(
        canShow: () =>
            mounted &&
            !access.isPro &&
            ModalRoute.of(context)?.isCurrent == true,
      );
    } catch (_) {
      result = RewardedAdResult.unavailable;
    }
    if (result == RewardedAdResult.earned) {
      access.rememberRevealed(widget.record.id, count + 1);
      try {
        await widget.onReveal?.call(count + 1);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AppText('History could not be saved.')),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() => _adPending = false);
    if (result != RewardedAdResult.earned) {
      final message = switch (result) {
        RewardedAdResult.dismissed =>
          'Watch the ad to earn one more ore cluster.',
        RewardedAdResult.unsupported =>
          'Rewarded ads are available on Android and iOS only.',
        _ => 'No ad is available right now. Please try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(message)));
      return;
    }
    setState(() {
      _loading = true;
      _nextPending = true;
    });
    _progress.forward(from: 0);
  }

  Future<void> _chooseStatus(int index) async {
    if (_statusDialogOpen || _adPending || _loading) return;
    _statusDialogOpen = true;
    final position = widget.record.positions[index];
    bool? choice;
    try {
      choice = await showDialog<bool>(
        context: context,
        builder: (_) => OreStatusDialog(position: position, ore: _ore),
      );
    } finally {
      _statusDialogOpen = false;
    }
    if (!mounted || choice == null) return;
    _bloc.setFound(index, choice);
    try {
      await widget.onFoundChanged?.call(index, choice);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('History could not be saved.')),
        );
      }
    }
  }

  Widget _oreCard(int index) {
    final position = widget.record.positions[index];
    final found = _bloc.isFound(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        label: context.tr(found ? 'Found' : 'Not found'),
        button: true,
        child: Material(
          key: ValueKey('ore-card-$index'),
          color: found ? AppColors.oreCollectedSurface : AppColors.oreRow,
          borderRadius: AppRadii.card,
          child: InkWell(
            key: ValueKey('ore-result-$index'),
            borderRadius: AppRadii.card,
            onTap: () => _chooseStatus(index),
            child: Container(
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.oreRowBorder, width: 3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppText(
                          'X: ${position.x}',
                          style: AppTextStyles.resultCoordinates,
                        ),
                        AppText(
                          'Y: ${position.y}',
                          style: AppTextStyles.resultCoordinates,
                        ),
                        AppText(
                          'Z: ${position.z}',
                          style: AppTextStyles.resultCoordinates,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 104,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: found ? .18 : 1,
                              child: OreIcon(ore: _ore, size: 34),
                            ),
                            if (found)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: OreFoundStamp(
                                  key: ValueKey('ore-status-$index'),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        'x${position.count}',
                        style: AppTextStyles.oreStatus,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results() => ListenableBuilder(
    listenable: _bloc,
    builder: (context, _) => SingleChildScrollView(
      key: const PageStorageKey('found-ores-scroll'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _visibleCount; index++) _oreCard(index),
          if (widget.record.positions.isEmpty)
            const AppText(
              'No ore clusters found.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            )
          else if (_remaining > 0) ...[
            AppText(
              'There are $_remaining more ore clusters nearby!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('show-all-ores'),
              label: 'Show all...',
              backgroundColor: AppColors.danger,
              pixel: true,
              onPressed: widget.onGoPro,
              leading: const Icon(
                Icons.diamond,
                color: AppColors.indicatorActive,
                size: 28,
              ),
              trailing: const Icon(
                Icons.diamond,
                color: AppColors.indicatorActive,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('show-another-ore'),
              label: _adPending ? 'Loading ad...' : 'Show another...',
              backgroundColor: AppColors.action,
              pixel: true,
              leading: const Icon(
                Icons.video_library_outlined,
                color: AppColors.onPrimary,
                size: 28,
              ),
              onPressed: _adPending ? null : _another,
            ),
            const SizedBox(height: AppSpacing.xs),
            const AppText(
              'Watch an ad to reveal one more ore cluster.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ] else if (widget.record.positions.isNotEmpty)
            const AppText(
              'All ore clusters are shown.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const ValueKey('ore-results-help'),
            onPressed: widget.onHelp,
            child: const AppText(
              'Having trouble finding ores?',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _access,
    builder: (context, _) {
      _scheduleAdPreload();
      return AppPageFrame(
        child: RepaintBoundary(
          key: const ValueKey('found-ores-preview'),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              systemOverlayStyle: AppTheme.systemUi,
              centerTitle: true,
              leadingWidth: 92,
              leading: TextButton.icon(
                key: const ValueKey('found-ores-back'),
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.serverNavigation,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText(
                    'Main',
                    style: AppTextStyles.body,
                    maxLines: 1,
                  ),
                ),
              ),
              title: const AppText(
                'Found Ores!',
                style: AppTextStyles.serverTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: const LandscapeBackground(
                    washed: true,
                    child: SizedBox.expand(),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 240,
                            height: 210,
                            child: DiggingPickaxe(),
                          ),
                        )
                      : _results(),
                ),
                if (_loading)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.paddingOf(context).bottom,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => Column(
                        children: [
                          SizedBox(
                            height: 32,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progress.value,
                                    child: const ColoredBox(
                                      color: AppColors.loadingOverlay,
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: OreIcon(ore: _ore, size: 30),
                                ),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: _progress.value,
                            minHeight: 2,
                            color: AppColors.action,
                            backgroundColor: AppColors.surface,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
