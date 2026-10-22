import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/responsive_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/game_palette.dart';
import '../../../core/theme/game_text_styles.dart';

class TutorialPageOne extends StatelessWidget {
  const TutorialPageOne({super.key});

  @override
  Widget build(BuildContext context) => ResponsiveCanvas(
    fit: BoxFit.fill,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 342, child: _GameSettingsPreview()),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.contentInset,
            26,
            AppSpacing.contentInset,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText('Step 1', style: AppTextStyles.tutorialTitle),
              const SizedBox(height: AppSpacing.md),
              const AppText(
                'Welcome to Find Diamonds!\nHow to use the app: in Minecraft Bedrock or Java, find your world’s seed and player current coordinates (x, y, z)',
                style: AppTextStyles.tutorialBody,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TutorialPageTwo extends StatelessWidget {
  const TutorialPageTwo({super.key});

  @override
  Widget build(BuildContext context) => ResponsiveCanvas(
    fit: BoxFit.fill,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 438, child: _SeedPreview()),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.contentInset,
            25,
            AppSpacing.contentInset,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Step 2', style: AppTextStyles.tutorialTitle),
              SizedBox(height: 10),
              AppText(
                'Enter the details into the app',
                style: AppTextStyles.tutorialBodyRelaxed,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TutorialPageThree extends StatefulWidget {
  const TutorialPageThree({super.key});

  @override
  State<TutorialPageThree> createState() => _TutorialPageThreeState();
}

class _TutorialPageThreeState extends State<TutorialPageThree> {
  final _checked = List.filled(5, true);
  static const _coordinates = [
    (62, 68, 32, 3),
    (39, 41, 28, 9),
    (70, 63, 41, 1),
    (10, 79, 41, 6),
    (6, 48, 40, 1),
  ];

  @override
  Widget build(BuildContext context) => ResponsiveCanvas(
    fit: BoxFit.fill,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.contentInset,
            AppSpacing.cardInset,
            AppSpacing.contentInset,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Step 3', style: AppTextStyles.tutorialTitle),
              SizedBox(height: 10),
              AppText(
                'Your ores have been found! Go to the listed coordinates to find them. Keep track by tapping the checkbox next to each ore.',
                style: AppTextStyles.tutorialBodyCompact,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: _coordinates.length,
            separatorBuilder: (_, index) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final row = _coordinates[index];
              return Semantics(
                label:
                    'Ore ${index + 1}: X ${row.$1}, Y ${row.$2}, Z ${row.$3}',
                checked: _checked[index],
                child: InkWell(
                  key: ValueKey('ore-row-$index'),
                  onTap: () =>
                      setState(() => _checked[index] = !_checked[index]),
                  borderRadius: AppRadii.row,
                  child: Container(
                    height: 83,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.oreRow,
                      border: Border.all(
                        color: AppColors.oreRowBorder,
                        width: 3.5,
                      ),
                      borderRadius: AppRadii.row,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _checked[index]
                                ? AppColors.primary
                                : AppColors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: _checked[index]
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.surface,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: AppText(
                            'X: ${row.$1}   Y: ${row.$2}   Z: ${row.$3}',
                            style: AppTextStyles.pixelBodyLarge,
                          ),
                        ),
                        OreIcon(
                          ore: index == 1 ? Ore.diamond : Ore.copper,
                          size: 35,
                        ),
                        AppText(' x${row.$4}', style: AppTextStyles.pixelCount),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _GameSettingsPreview extends StatelessWidget {
  const _GameSettingsPreview();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: GamePalette.settingsBackground,
    child: DefaultTextStyle(
      style: GameTextStyles.settings,
      child: Column(
        children: [
          Container(
            height: 18,
            color: GamePalette.toolbar,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText('‹ Settings', style: GameTextStyles.toolbar),
                AppText('Game Settings', style: GameTextStyles.toolbar),
                SizedBox(width: AppSpacing.md),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 151,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: GamePalette.divider, width: 5),
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _menu(Icons.key, 'Accessibility'),
                      _menu(Icons.question_mark, 'How to Play'),
                      const AppText('World'),
                      _menu(
                        Icons.sports_esports_outlined,
                        'Game',
                        selected: true,
                      ),
                      _menu(Icons.people_alt_outlined, 'Multiplayer'),
                      const AppText('Controls'),
                      _menu(Icons.keyboard_outlined, 'Keyboard & Mouse'),
                      _menu(Icons.sports_esports_outlined, 'Controller'),
                      _menu(Icons.touch_app_outlined, 'Touch'),
                      const AppText('General'),
                      _menu(Icons.public, 'General'),
                      _menu(Icons.person_outline, 'Account'),
                      _menu(Icons.grid_on, 'Creator'),
                      _menu(Icons.monitor, 'Video'),
                      _menu(Icons.calendar_month_outlined, 'Subscriptions'),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field('Normal                         v'),
                        const SizedBox(height: 6),
                        const AppText('World Preferences'),
                        _toggle('Starting Map'),
                        _toggle('Bonus Chest'),
                        const AppText(
                          'Player permission when joining from invite',
                        ),
                        _field('Member                         >', star: true),
                        const SizedBox(height: AppSpacing.xs),
                        const AppText('World Type'),
                        _field(
                          'Infinite                         v',
                          muted: true,
                        ),
                        const AppText('Seed'),
                        _field(
                          '8138276020532505731             ›',
                          muted: true,
                        ),
                        const AppText('Simulation Distance: 4 chunks'),
                        const SizedBox(height: AppSpacing.xs),
                        Container(height: 7, color: GamePalette.scrollbar),
                        const SizedBox(height: 7),
                        const AppText('World Options'),
                        _toggle('Friendly Fire', on: true),
                        _toggle('Show Coordinates'),
                        _toggle('Fire Spreads', on: true),
                        _toggle('Recipes Unlock', on: true),
                        _toggle('TNT Explodes', on: true),
                        _toggle('Respawn Blocks Explode', on: true),
                        _toggle('Mob Loot', on: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _menu(IconData icon, String text, {bool selected = false}) =>
      Container(
        height: 23,
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? GamePalette.selectedControl : GamePalette.control,
          border: Border.all(color: GamePalette.controlBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: GamePalette.icon, size: 14),
            const SizedBox(width: 9),
            AppText(text, style: GameTextStyles.control),
          ],
        ),
      );

  Widget _field(String text, {bool muted = false, bool star = false}) =>
      Container(
        height: 22,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: muted ? GamePalette.mutedControl : GamePalette.input,
          border: Border.all(color: GamePalette.inputBorder),
        ),
        child: Row(
          children: [
            if (star) ...[
              const Icon(Icons.star, color: GamePalette.star, size: 15),
              const SizedBox(width: AppSpacing.xs),
            ],
            AppText(text, style: GameTextStyles.input),
          ],
        ),
      );

  Widget _toggle(String label, {bool on = false}) => SizedBox(
    height: 14,
    child: Row(
      children: [
        Container(
          width: 19,
          height: 10,
          padding: EdgeInsets.only(
            left: on ? AppSpacing.md : 0,
            right: on ? 0 : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: GamePalette.toggleTrack,
            border: Border.all(color: GamePalette.toggleBorder),
          ),
          child: const ColoredBox(color: GamePalette.toggleThumb),
        ),
        const SizedBox(width: 5),
        AppText(label),
      ],
    ),
  );
}

class _SeedPreview extends StatelessWidget {
  const _SeedPreview();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: GamePalette.seedBackground,
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _line('World seed (numbers/letters)', height: 50),
            _line('36643745', height: 52),
            _line('Version (Scroll to change)', height: 48),
            _line('1.18 Bedrock', height: 52, dropdown: true),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.arrow_left, size: 55, color: GamePalette.arrow),
                Column(
                  children: [
                    OreIcon(ore: Ore.lapis, size: 57),
                    AppText('Lapis', style: AppTextStyles.pixelTitle),
                  ],
                ),
                Icon(Icons.arrow_right, size: 55, color: GamePalette.arrow),
              ],
            ),
            const SizedBox(height: 9),
            Container(height: 54, color: GamePalette.adBanner),
            const SizedBox(height: 10),
            Container(
              height: 36,
              color: GamePalette.action,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    'Start digging',
                    style: AppTextStyles.onPrimaryPixelField,
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 23, color: AppColors.surface),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: GamePalette.callout,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const AppText(
              'and the version\nof your game',
              textAlign: TextAlign.center,
              style: GameTextStyles.callout,
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 12,
          right: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppText(
                '(Works on EVERY\nminecraft version!)',
                textAlign: TextAlign.center,
                style: GameTextStyles.outlinedCallout,
              ),
              const AppText(
                '(Works on EVERY\nminecraft version!)',
                textAlign: TextAlign.center,
                style: GameTextStyles.highlightCallout,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _line(String label, {required double height, bool dropdown = false}) =>
      Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: GamePalette.fieldBorder, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: AppText(label, style: AppTextStyles.pixelField)),
            if (dropdown)
              const Icon(Icons.expand_more, size: 23, color: AppColors.border),
          ],
        ),
      );
}
