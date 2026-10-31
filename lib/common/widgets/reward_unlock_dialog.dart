import 'dart:async';

import 'package:flutter/material.dart';
import 'mining_surface.dart';

import '../../core/monetization/app_monetization.dart';
import '../../core/monetization/rewarded_ad_service.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';
import 'app_text.dart';

/// Shared rewarded-unlock flow. Content and the grant belong to each feature.
/// Returns true when Premium is chosen, so its owner can open the paywall.
class RewardUnlockDialog extends StatefulWidget {
  const RewardUnlockDialog({
    super.key,
    required this.title,
    required this.illustration,
    required this.monetization,
    required this.isLocked,
    required this.onUnlock,
    required this.watchToUnlockMessage,
    required this.saveFailureMessage,
    required this.keyPrefix,
  });

  final String title;
  final Widget illustration;
  final AppMonetization monetization;
  final bool Function() isLocked;

  /// Grants access in memory and returns whether it was persisted on device.
  final Future<bool> Function() onUnlock;
  final String watchToUnlockMessage;
  final String saveFailureMessage;
  final String keyPrefix;

  @override
  State<RewardUnlockDialog> createState() => _RewardUnlockDialogState();
}

class _RewardUnlockDialogState extends State<RewardUnlockDialog> {
  bool _busy = false;
  String? _message;

  bool _canShow() =>
      mounted &&
      !widget.monetization.isPro &&
      ModalRoute.of(context)?.isCurrent == true &&
      widget.isLocked();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.monetization.rewardedAds.preload(canLoad: _canShow));
    });
  }

  Future<void> _watch() async {
    if (_busy) return;
    if (widget.monetization.isPro || !widget.isLocked()) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    RewardedAdResult result;
    try {
      result = await widget.monetization.rewardedAds.show(canShow: _canShow);
    } catch (_) {
      result = RewardedAdResult.unavailable;
    }
    if (result == RewardedAdResult.earned) {
      // Persist a real reward even if navigation changes while the ad closes.
      final saved = await widget.onUnlock();
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AppText(widget.saveFailureMessage)));
      }
      Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    if (widget.monetization.isPro) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _message = switch (result) {
        RewardedAdResult.dismissed => widget.watchToUnlockMessage,
        RewardedAdResult.unsupported =>
          'Rewarded ads are available on Android and iOS only.',
        _ => 'No ad is available right now. Please try again.',
      };
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      shape: const PixelBorder(
        side: BorderSide(color: AppColors.helpBorder, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: ValueKey('close-${widget.keyPrefix}-unlock'),
                  tooltip: context.tr('Close'),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 28,
                  ),
                ),
              ),
              widget.illustration,
              const SizedBox(height: AppSpacing.xl),
              AppText(widget.title, style: AppTextStyles.unlockTitle),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                key: ValueKey('watch-${widget.keyPrefix}-ad'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(AppLayout.buttonMinHeight),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.standard,
                  ),
                ),
                onPressed: _busy ? null : _watch,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.play_circle_fill),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: AppText(
                        _busy ? 'Loading ad...' : 'Watch Ads',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pixelButton,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: ValueKey('${widget.keyPrefix}-unlock-premium'),
                label: 'Go Ads Free with Premium',
                backgroundColor: AppColors.gold,
                pixel: true,
                textStyle: AppTextStyles.pixelButtonSmall,
                onPressed: _busy ? null : () => Navigator.pop(context, true),
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: AppText(_message!, style: AppTextStyles.dialogBody),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Three interchangeable cards with the same arrangement for every unlock.
class UnlockCardIllustration extends StatelessWidget {
  const UnlockCardIllustration({
    super.key,
    required this.left,
    required this.center,
    required this.right,
  });
  final Widget left;
  final Widget center;
  final Widget right;

  Widget _card(Widget child, double width, double height) => Container(
    width: width,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: AppRadii.standard,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1.65,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.center,
          children: [
            for (final isLeft in [true, false])
              Align(
                alignment: isLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Transform.rotate(
                  angle: isLeft ? -.14 : .14,
                  child: _card(
                    isLeft ? left : right,
                    constraints.maxWidth * .47,
                    constraints.maxHeight * .82,
                  ),
                ),
              ),
            _card(center, constraints.maxWidth * .46, constraints.maxHeight),
          ],
        ),
      ),
    ),
  );
}
