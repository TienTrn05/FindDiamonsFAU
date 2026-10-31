import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/game_text_styles.dart';

/// Annotated local artwork for the FAQ, replaceable with game screenshots later.
class HelpFaqIllustration extends StatelessWidget {
  const HelpFaqIllustration({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: context.tr(
      kind == 'seed'
          ? 'Example of a world seed in chat'
          : 'Example of X, Y and Z coordinates',
    ),
    child: ClipRRect(
      borderRadius: AppRadii.standard,
      child: AspectRatio(
        aspectRatio: 2.45,
        child: FittedBox(
          child: SizedBox(
            width: 360,
            height: 147,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/block_landscape.png',
                  fit: BoxFit.cover,
                ),
                const ColoredBox(color: AppColors.heroScrim),
                const Center(
                  child: Icon(Icons.add, color: AppColors.onPrimary, size: 16),
                ),
                if (kind == 'coordinates') ...[
                  const Positioned(
                    top: 5,
                    left: 6,
                    child: AppText(
                      'Minecraft Java\nFPS: 60  |  World: Overworld\nChunk: 14 4 -16',
                      style: GameTextStyles.helpDebug,
                    ),
                  ),
                  Positioned(
                    top: 48,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.scrim,
                        border: Border.all(color: AppColors.danger, width: 2),
                      ),
                      child: const AppText(
                        'XYZ: 230.500 / 64.000 / -251.500',
                        style: GameTextStyles.helpDebug,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 34,
                    left: 215,
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.danger,
                      size: 48,
                    ),
                  ),
                ] else ...[
                  const Positioned(
                    bottom: 23,
                    left: 95,
                    child: Icon(
                      Icons.south_west,
                      color: AppColors.danger,
                      size: 46,
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.scrim,
                        border: Border.all(color: AppColors.danger, width: 2),
                      ),
                      child: const AppText(
                        'Seed: [3741945947136570379]',
                        style: GameTextStyles.helpDebug,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
