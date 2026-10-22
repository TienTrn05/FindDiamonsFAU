import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/responsive_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_plan.dart';

class Paywall extends StatefulWidget {
  const Paywall({
    super.key,
    required this.onBack,
    required this.onClose,
    required this.onSuccess,
    this.onPurchase,
    this.onRestore,
  });

  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onSuccess;
  final Future<bool> Function(SubscriptionPlan)? onPurchase;
  final Future<bool> Function()? onRestore;

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  bool _allPlans = false;
  bool _busy = false;
  SubscriptionPlan _selected = SubscriptionPlan.weekly;

  Future<void> _purchase() async {
    if (widget.onPurchase == null) {
      _message(
        'Purchase preview — connect App Store or Google Play billing to start a subscription.',
      );
      return;
    }
    await _perform(
      () => widget.onPurchase!(_selected),
      'No purchase was completed. You can try again.',
    );
  }

  Future<void> _restore() async {
    if (widget.onRestore == null) {
      _message(
        'Restore preview — connect your billing service to restore purchases.',
      );
      return;
    }
    await _perform(widget.onRestore!, 'No active subscription was found.');
  }

  Future<void> _perform(Future<bool> Function() action, String fallback) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final success = await action();
      if (!mounted) return;
      if (success) {
        widget.onSuccess();
      } else {
        _message(fallback);
      }
    } catch (_) {
      if (mounted) _message('Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: AppText(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final panelHeight = constraints.maxHeight * .55;
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.heroBackground),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: constraints.maxHeight * .63,
            child: Image.asset(
              'assets/images/adventurer.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.45),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.heroScrim, AppColors.transparent],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Close paywall'),
                      onPressed: _busy ? null : widget.onBack,
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.surface,
                        size: 30,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        heightFactor: 1,
                        child: TextButton(
                          onPressed: _busy ? null : _restore,
                          child: const AppText(
                            'Restore Purchases',
                            textAlign: TextAlign.end,
                            style: AppTextStyles.onPrimaryPixelBody,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: panelHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.sheet,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.contentInset,
                    AppSpacing.contentInset,
                    AppSpacing.contentInset,
                    AppSpacing.sm,
                  ),
                  child: ResponsiveCanvas(
                    alignment: Alignment.topCenter,
                    designSize: Size(352, _allPlans ? 465 : 430),
                    child: LayoutBuilder(
                      builder: (context, panel) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: panel.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: _allPlans ? _plans() : _offer(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _offer() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AppText(
        'Remove All Ads',
        textAlign: TextAlign.center,
        style: AppTextStyles.sectionTitle,
      ),
      const SizedBox(height: AppSpacing.xxxl),
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 60,
            padding: AppInsets.contentHorizontal,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      '₫129.000/week',
                      style: AppTextStyles.onPrimaryPixelPrice,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: AppText(
                      'Try it for free!',
                      style: AppTextStyles.onPrimaryPixelSubtitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: -20, left: 88, right: 88, child: _trialBadge()),
        ],
      ),
      const SizedBox(height: 17),
      ...[
        'Unlock all ore types',
        'Find unlimited ores',
        'Unlimited access to all in-app content',
        'No ads',
      ].map(_benefit),
      const SizedBox(height: 11),
      AppButton(
        label: _busy ? 'Please wait...' : 'Start Free Trial',
        onPressed: _busy ? null : _purchase,
        gradient: true,
        pixel: true,
      ),
      const SizedBox(height: AppSpacing.xs),
      const AppText(
        '3 days free, then ₫129.000/week. Cancel anytime.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
      const Spacer(),
      TextButton(
        onPressed: () => setState(() => _allPlans = true),
        child: const AppText('View All Plans', style: AppTextStyles.link),
      ),
    ],
  );

  Widget _plans() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...[
        'Unlock all ore types',
        'Find unlimited ores',
        'No ads',
      ].map((text) => _benefit(text, compact: true)),
      const SizedBox(height: AppSpacing.xxl),
      _plan(
        SubscriptionPlan.weekly,
        '₫129.000',
        '/week',
        '₫129.000/week',
        trial: true,
      ),
      const SizedBox(height: 11),
      _plan(
        SubscriptionPlan.monthly,
        '₫399.000',
        '/month',
        '₫93.100/week',
        saving: 'Save 28%',
      ),
      const SizedBox(height: 11),
      _plan(
        SubscriptionPlan.yearly,
        '₫999.000',
        '/year',
        '₫19.159/week',
        saving: 'Save 85%',
      ),
      const SizedBox(height: 26),
      AppButton(
        label: _busy
            ? 'Please wait...'
            : _selected == SubscriptionPlan.weekly
            ? 'Start Free Trial'
            : 'Continue',
        onPressed: _busy ? null : _purchase,
        gradient: true,
        pixel: true,
      ),
      const SizedBox(height: 7),
      AppText(
        _selected == SubscriptionPlan.weekly
            ? '3 days free, then ₫129.000/week. Cancel anytime.'
            : _selected == SubscriptionPlan.monthly
            ? '₫399.000/month. Renews monthly. Cancel anytime.'
            : '₫999.000/year. Renews yearly. Cancel anytime.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
      const Spacer(),
      Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () => setState(() => _allPlans = false),
          child: const AppText('Back to offer', style: AppTextStyles.linkSmall),
        ),
      ),
    ],
  );

  Widget _benefit(String text, {bool compact = false}) => Padding(
    padding: EdgeInsets.only(bottom: compact ? AppSpacing.xs : AppSpacing.md),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: AppText(
            text,
            style: (compact
                ? AppTextStyles.pixelBodyLarge
                : AppTextStyles.pixelBody),
          ),
        ),
      ],
    ),
  );

  Widget _trialBadge() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: AppRadii.small,
    ),
    child: const AppText(
      'Start 3-Day trial',
      textAlign: TextAlign.center,
      style: AppTextStyles.onPrimaryPixelBody,
    ),
  );

  Widget _plan(
    SubscriptionPlan plan,
    String price,
    String interval,
    String perWeek, {
    String? saving,
    bool trial = false,
  }) {
    final selected = plan == _selected;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            key: ValueKey('plan-${plan.name}'),
            onTap: _busy ? null : () => setState(() => _selected = plan),
            borderRadius: AppRadii.standard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 59,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                border: Border.all(color: AppColors.primary, width: 1.8),
                borderRadius: AppRadii.standard,
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.surface
                          : AppColors.transparent,
                      border: Border.all(
                        color: selected ? AppColors.surface : AppColors.primary,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  AppText(
                    price,
                    style: AppTextStyles.pixelPrice.copyWith(
                      color: selected ? AppColors.onPrimary : AppColors.text,
                    ),
                  ),
                  AppText(
                    interval,
                    style: AppTextStyles.pixelLabel.copyWith(
                      color: selected ? AppColors.onPrimary : AppColors.text,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AppText(
                          perWeek,
                          style: AppTextStyles.pixelLabel.copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (trial)
          Positioned(top: -19, left: 88, right: 88, child: _trialBadge()),
        if (saving != null)
          Positioned(
            bottom: -6,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AppText(saving, style: AppTextStyles.badge),
            ),
          ),
      ],
    );
  }
}
