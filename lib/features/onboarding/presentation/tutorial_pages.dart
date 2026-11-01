import 'package:flutter/material.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_components.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/game_palette.dart';
import '../../../core/theme/game_text_styles.dart';

class TutorialPageOne extends StatelessWidget {
  const TutorialPageOne({super.key});
  @override
  Widget build(BuildContext context) => const _TutorialChapter(
    step: 1,
    title: 'Find your bearings',
    message:
        'Welcome to Find Diamonds!\nHow to use the app: in Minecraft Bedrock or Java, find your world’s seed and player current coordinates (x, y, z)',
    illustration: SizedBox(
      width: 374,
      height: 342,
      child: _GameSettingsPreview(),
    ),
  );
}

class TutorialPageTwo extends StatelessWidget {
  const TutorialPageTwo({super.key});
  @override
  Widget build(BuildContext context) => const _TutorialChapter(
    step: 2,
    title: 'Choose your treasure',
    message: 'Enter the details into the app',
    illustration: _WorldDetailsPreview(),
  );
}

class _TutorialChapter extends StatelessWidget {
  const _TutorialChapter({
    required this.step,
    required this.title,
    required this.message,
    required this.illustration,
  });
  final int step;
  final String title;
  final String message;
  final Widget illustration;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: (constraints.maxHeight * .54).clamp(130.0, 310.0),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: const PixelBorder()),
              child: FittedBox(fit: BoxFit.contain, child: illustration),
            ),
          ),
          const SizedBox(height: 24),
          MiningTag('Step $step', icon: Icons.explore_outlined),
          const SizedBox(height: 12),
          AppText(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 26,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AppText(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.caveMuted),
          ),
        ],
      ),
    ),
  );
}

class _WorldDetailsPreview extends StatelessWidget {
  const _WorldDetailsPreview();
  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          label,
          style: AppTextStyles.pixelLabel.copyWith(color: AppColors.caveMuted),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.cave,
          child: AppText(value, style: AppTextStyles.fieldValue),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: MiningPanel(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _line('Player X', '1000')),
              const SizedBox(width: 12),
              Expanded(child: _line('Player Z', '-500')),
            ],
          ),
          _line('World seed (numbers/letters)', '36643745'),
          _line('Version (Scroll to change)', '1.21 Java'),
          const Row(
            children: [
              OreIcon(size: 48),
              SizedBox(width: 12),
              Expanded(
                child: AppText('Diamond', style: AppTextStyles.pixelTitle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary,
            child: const AppText(
              'Start digging',
              textAlign: TextAlign.center,
              style: AppTextStyles.onPrimaryPixelBody,
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const MiningTag('Step 3', icon: Icons.explore_outlined),
      const SizedBox(height: 12),
      AppText(
        'Follow the coordinates',
        style: AppTextStyles.title.copyWith(
          fontSize: 25,
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      AppText(
        'Your ores have been found! Go to the listed coordinates to find them. Keep track by tapping the checkbox next to each ore.',
        style: AppTextStyles.body.copyWith(color: AppColors.caveMuted),
      ),
      const SizedBox(height: 20),
      for (var index = 0; index < _coordinates.length; index++) ...[
        Semantics(
          checked: _checked[index],
          label: context.tr('Ore {index}', args: {'index': '${index + 1}'}),
          child: MiningPanel(
            padding: EdgeInsets.zero,
            child: InkWell(
              key: ValueKey('ore-row-$index'),
              onTap: () => setState(() => _checked[index] = !_checked[index]),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const OreIcon(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 5,
                        children: [
                          AppText(
                            'X: ${_coordinates[index].$1}',
                            style: AppTextStyles.pixelLabel,
                          ),
                          AppText(
                            'Y: ${_coordinates[index].$2}',
                            style: AppTextStyles.pixelLabel,
                          ),
                          AppText(
                            'Z: ${_coordinates[index].$3}',
                            style: AppTextStyles.pixelLabel,
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: _checked[index],
                      activeColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => _checked[index] = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
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
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppText(text, style: GameTextStyles.control),
              ),
            ),
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
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppText(text, style: GameTextStyles.input),
              ),
            ),
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
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(label),
          ),
        ),
      ],
    ),
  );
}
