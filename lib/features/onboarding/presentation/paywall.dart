import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_components.dart';
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
  Widget build(BuildContext context) => MiningBackground(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.tr('Close paywall'),
                  onPressed: _busy ? null : widget.onBack,
                  icon: const Icon(Icons.close, color: AppColors.onPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: AppText(
                    'Restore Purchases',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.caveMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiningPanel(
                    color: AppColors.goldPanel,
                    borderColor: AppColors.gold,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: AppColors.gold,
                          size: 54,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'MINER PRO',
                                style: AppTextStyles.pixelLabel.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                'Unlock Pro Tools',
                                style: AppTextStyles.itemTitle.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  MiningPanel(
                    borderColor: AppColors.helpBorder,
                    child: _allPlans ? _plans() : _offer(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _offer() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        'Remove All Ads',
        textAlign: TextAlign.center,
        style: AppTextStyles.sectionTitle.copyWith(
          color: AppColors.gold,
          fontSize: 26,
        ),
      ),
      const SizedBox(height: 20),
      _trialBadge(),
      const SizedBox(height: 10),
      MiningPanel(
        color: AppColors.cavePanel,
        borderColor: AppColors.accent,
        child: Column(
          children: [
            const AppText(
              '\u20ab129.000/week',
              style: AppTextStyles.onPrimaryPixelPrice,
            ),
            const SizedBox(height: 7),
            AppText(
              'Try it for free!',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ...[
        'Unlock all ore types',
        'Find unlimited ores',
        'Unlimited access to all in-app content',
        'No ads',
      ].map(_benefit),
      const SizedBox(height: 12),
      AppButton(
        label: _busy ? 'Please wait...' : 'Start Free Trial',
        backgroundColor: AppColors.gold,
        pixel: true,
        onPressed: _busy ? null : _purchase,
      ),
      const SizedBox(height: 10),
      const AppText(
        '3 days free, then \u20ab129.000/week. Cancel anytime.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
      const SizedBox(height: 10),
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
        backgroundColor: AppColors.gold,
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
      const SizedBox(height: 12),
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
      color: AppColors.cavePanel,
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
    return Semantics(
      selected: selected,
      button: true,
      child: MiningPanel(
        color: selected ? AppColors.cavePanel : AppColors.cave,
        borderColor: selected ? AppColors.gold : AppColors.helpBorder,
        padding: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('plan-${plan.name}'),
          onTap: _busy ? null : () => setState(() => _selected = plan),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (trial) ...[
                  Align(alignment: Alignment.centerLeft, child: _trialBadge()),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.gold : AppColors.caveMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppText(
                            price,
                            style: AppTextStyles.pixelPrice.copyWith(
                              fontSize: 18,
                              color: AppColors.text,
                            ),
                          ),
                          AppText(
                            interval,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.caveMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: AppText(
                        perWeek,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          color: AppColors.caveMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (saving != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: MiningTag(saving, color: AppColors.gold),
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
