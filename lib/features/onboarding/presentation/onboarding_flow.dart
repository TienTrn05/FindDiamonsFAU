import '../../../common/widgets/app_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_centered_scroll_view.dart';
import '../../../common/widgets/app_loading_page.dart';
import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/tracking_permission_service.dart';
import '../models/subscription_plan.dart';
import 'paywall.dart';
import 'tracking_permission_page.dart';
import 'tutorial_pages.dart';

/// Requests native iOS tracking permission before the tutorial.
/// A purchase callback returns true only after entitlement checks.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    this.trackingPermission = const TrackingPermissionService(),
    this.onPurchase,
    this.onRestore,
    this.onComplete,
    this.reviewTutorial = false,
    this.splashDuration = const Duration(milliseconds: 1100),
  });

  final TrackingPermissionService trackingPermission;
  final Future<bool> Function(SubscriptionPlan plan)? onPurchase;
  final Future<bool> Function()? onRestore;
  final VoidCallback? onComplete;
  final bool reviewTutorial;
  final Duration splashDuration;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Stage { loading, trackingPermission, tutorial, paywall, complete }

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Stage _stage = _Stage.loading;
  var _pages = PageController(keepPage: false);
  Timer? _timer;
  int _page = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.reviewTutorial) {
      _stage = _Stage.tutorial;
    } else {
      _timer = Timer(widget.splashDuration, _prepareTrackingPermission);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _prepareTrackingPermission() async {
    try {
      final status = await widget.trackingPermission.status;
      if (!mounted) return;
      setState(() {
        _stage = status == TrackingStatus.notDetermined
            ? _Stage.trackingPermission
            : _Stage.tutorial;
      });
    } catch (_) {
      // An unavailable permission API must never block onboarding.
      if (mounted) setState(() => _stage = _Stage.tutorial);
    }
  }

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.trackingPermission.request();
      if (mounted) setState(() => _stage = _Stage.tutorial);
    } catch (_) {
      if (mounted) {
        // Tracking is optional; its failure must never block the tutorial.
        setState(() => _stage = _Stage.tutorial);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      setState(() => _stage = _Stage.complete);
    }
  }

  void _returnToTutorial({bool restart = false}) {
    _pages.dispose();
    if (restart) _page = 0;
    _pages = PageController(initialPage: _page, keepPage: false);
    setState(() => _stage = _Stage.tutorial);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _finish();
    },
    child: Scaffold(
      body: AppPageFrame(
        child: switch (_stage) {
          _Stage.loading => const AppLoadingPage(),
          _Stage.trackingPermission => TrackingPermissionPage(
            onContinue: _continue,
            busy: _busy,
          ),
          _Stage.tutorial => _tutorial(),
          _Stage.paywall => Paywall(
            onBack: _finish,
            onClose: _finish,
            onPurchase: widget.onPurchase,
            onRestore: widget.onRestore,
            onSuccess: _finish,
          ),
          _Stage.complete => OreBackground(
            child: SafeArea(
              child: AppCenteredScrollView(
                padding: AppInsets.cardMargin,
                child: Container(
                  padding: AppInsets.cardContent,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadii.standard,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const OreIcon(size: 100),
                      const SizedBox(height: AppSpacing.xl),
                      const AppText(
                        'Ready to explore!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppText(
                        'You’re all set. Your next adventure starts here.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        label: 'View tutorial',
                        onPressed: () => _returnToTutorial(restart: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        },
      ),
    ),
  );

  Widget _tutorial() => MiningBackground(
    child: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: AppLayout.navigationExtent,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                child: _page < 2
                    ? TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.cave,
                          minimumSize: const Size(58, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        onPressed: widget.reviewTutorial
                            ? _finish
                            : () => setState(() => _stage = _Stage.paywall),
                        child: const AppText('SKIP'),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadii.standard,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: AppRadii.standard,
                  border: Border.all(color: AppColors.cardBorder, width: 1.6),
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.standard,
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: const [
                      TutorialPageOne(),
                      TutorialPageTwo(),
                      TutorialPageThree(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: AppLayout.navigationExtent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Semantics(
                  label: context.tr(
                    'Step {step} of {total}',
                    args: {'step': '${index + 1}', 'total': '3'},
                  ),
                  selected: index == _page,
                  child: InkResponse(
                    onTap: () => _pages.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                    child: SizedBox(
                      width: 42,
                      height: 40,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: index == _page
                                ? AppColors.indicatorActive
                                : AppColors.indicatorInactive,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.contentInset,
              0,
              AppSpacing.contentInset,
              14,
            ),
            child: AppButton(
              label: _page == 2 ? 'Done' : 'Next',
              onPressed: () {
                if (_page == 2) {
                  if (widget.reviewTutorial) {
                    _finish();
                  } else {
                    setState(() => _stage = _Stage.paywall);
                  }
                } else {
                  _pages.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
