import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'ore_art.dart';
import 'wave_loading_text.dart';

class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OreBackground(
      child: Center(
        child: ColoredBox(
          color: AppColors.loadingOverlay,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: WaveLoadingText(
                    text: 'Please wait...',
                    style: AppTextStyles.loading,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
