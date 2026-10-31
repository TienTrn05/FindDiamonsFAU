import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text.dart';
import 'ore_art.dart';
import 'mining_surface.dart';
import 'wave_loading_text.dart';

class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});
  @override
  Widget build(BuildContext context) => MiningBackground(
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OreIcon(size: 112),
              const SizedBox(height: 28),
              AppText(
                'ORE SCOUT',
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              AppText(
                'FIND ORES. EXPLORE MORE.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.caveMuted,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 36),
              const WaveLoadingText(
                text: 'Please wait...',
                style: AppTextStyles.onPrimaryPixelBody,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
