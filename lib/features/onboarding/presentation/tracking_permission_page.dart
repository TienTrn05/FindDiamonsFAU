import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_centered_scroll_view.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Explains the upcoming native iOS prompt; this page does not grant consent.
class TrackingPermissionPage extends StatelessWidget {
  const TrackingPermissionPage({
    super.key,
    required this.onContinue,
    required this.busy,
  });

  final VoidCallback onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) => MiningBackground(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.scrim),
        SafeArea(
          child: AppCenteredScrollView(
            child: MiningPanel(
              padding: AppInsets.dialogContent,
              borderColor: AppColors.primary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  const AppText(
                    'Our app wants to stay free for you',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dialogTitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppText(
                    'Ads help support our app. On the next screen, you can '
                    'choose whether to allow tracking across other companies’ '
                    'apps and websites to show more relevant ads. '
                    'You can use the app with either choice.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dialogBody,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : onContinue,
                      child: busy
                          ? const SizedBox.square(
                              dimension: AppLayout.progressIndicatorSize,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const AppText(
                              'Continue',
                              style: AppTextStyles.body,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
