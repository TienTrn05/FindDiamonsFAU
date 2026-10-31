import 'package:flutter/material.dart';

import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/ore_display.dart';
import '../../../common/widgets/mining_neon_panel.dart';
import '../../../common/widgets/mining_viewport.dart';
import '../../../common/widgets/game_back_button.dart';
import '../../../core/theme/mining_style.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/find_catalog.dart';

class OrePickerPage extends StatefulWidget {
  const OrePickerPage({
    super.key,
    required this.ores,
    required this.selectedId,
  });
  final List<OreOption> ores;
  final String selectedId;
  @override
  State<OrePickerPage> createState() => _OrePickerPageState();
}

class _OrePickerPageState extends State<OrePickerPage> {
  late int _index = widget.ores
      .indexWhere((ore) => ore.id == widget.selectedId)
      .clamp(0, widget.ores.length - 1);
  late final _controller = PageController(
    initialPage: _index,
    viewportFraction: .72,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) => _controller.animateToPage(
    (_index + delta) % widget.ores.length,
    duration: const Duration(milliseconds: 360),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPageFrame(
      child: MiningBackground(
        vivid: true,
        child: SafeArea(
          child: MiningViewport(
            minimumHeight: 730,
            compactHeight: 620,
            builder: (context, landscape, compact) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GameBackButton(
                        key: const ValueKey('ore-picker-back'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      if (landscape) ...[
                        const SizedBox(width: 14),
                        Expanded(child: _title()),
                      ],
                    ],
                  ),
                  if (!landscape) ...[const SizedBox(height: 14), _title()],
                  const SizedBox(height: 8),
                  AppText(
                    'Swipe to select the ore you want to find',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pixelBody.copyWith(
                      color: AppColors.caveMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: landscape
                        ? Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    Expanded(child: _carousel()),
                                    _dots(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _facts(vertical: true),
                                    const Spacer(),
                                    _continue(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, bounds) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: (bounds.maxHeight - 44).clamp(
                                          80.0,
                                          bounds.maxWidth,
                                        ),
                                        child: _carousel(),
                                      ),
                                      _dots(),
                                    ],
                                  ),
                                ),
                              ),
                              _facts(),
                              const SizedBox(height: 16),
                              _continue(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _title() => FittedBox(
    fit: BoxFit.scaleDown,
    child: AppText(
      'Choose your ore',
      style: MiningStyle.heading.copyWith(fontSize: 28),
      textAlign: TextAlign.center,
    ),
  );

  Widget _carousel() => Stack(
    children: [
      PageView.builder(
        key: const ValueKey('ore-carousel'),
        controller: _controller,
        itemCount: widget.ores.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) {
          final item = widget.ores[index];
          final selected = index == _index;
          final accent = MiningStyle.oreAccent(item.id);
          return AnimatedPadding(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 7,
              vertical: selected ? 8 : 35,
            ),
            child: MiningNeonPanel(
              accent: accent,
              emphasized: selected,
              glow: selected,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Expanded(
                    child: FittedBox(
                      child: OreDisplay(id: item.id, size: 260, pin: selected),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppText(
                      context.tr(item.name).toUpperCase(),
                      style: MiningStyle.heading.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 7,
                    ),
                    decoration: ShapeDecoration(
                      color: accent,
                      shape: const PixelBorder(),
                    ),
                    child: AppText(
                      {'diamond', 'emerald'}.contains(item.id)
                          ? 'Rare'
                          : 'Common',
                      style: MiningStyle.label.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      Align(alignment: Alignment.centerLeft, child: _arrow(-1)),
      Align(alignment: Alignment.centerRight, child: _arrow(1)),
    ],
  );

  Widget _arrow(int delta) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Material(
      color: AppColors.cave,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.helpBorder, width: 2),
      ),
      child: IconButton(
        tooltip: context.tr(delta < 0 ? 'Previous ore' : 'Next ore'),
        onPressed: () => _move(delta),
        icon: Icon(
          delta < 0 ? Icons.chevron_left : Icons.chevron_right,
          color: AppColors.onPrimary,
          size: 32,
        ),
      ),
    ),
  );

  Widget _dots() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      children: [
        for (var i = 0; i < widget.ores.length; i++)
          Semantics(
            button: true,
            selected: i == _index,
            label: context.tr(widget.ores[i].name),
            child: InkWell(
              onTap: () => _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
              ),
              child: SizedBox.square(
                dimension: 26,
                child: Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.helpBorder,
                      boxShadow: i == _index
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .7),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _facts({bool vertical = false}) {
    final ore = widget.ores[_index];
    final best = switch (ore.id) {
      'diamond' => 'Strong equipment',
      'emerald' => 'Trading',
      'coal' => 'Fuel & torches',
      'redstone' => 'Mechanisms',
      'lapis' => 'Enchanting',
      'gold' => 'Golden equipment',
      _ => 'Building',
    };
    final children = [
      _fact(Icons.diamond, 'Best for', best),
      _fact(
        Icons.signal_cellular_alt,
        'Rarity',
        {'diamond', 'emerald'}.contains(ore.id) ? 'Rare' : 'Common',
      ),
    ];
    return vertical
        ? Column(
            children: [children[0], const SizedBox(height: 12), children[1]],
          )
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 10),
                Expanded(child: children[1]),
              ],
            ),
          );
  }

  Widget _fact(IconData icon, String label, String value) => MiningNeonPanel(
    accent: AppColors.helpBorder,
    glow: false,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 29),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                style: AppTextStyles.pixelBody.copyWith(
                  fontSize: 11,
                  color: AppColors.caveMuted,
                ),
              ),
              const SizedBox(height: 5),
              AppText(
                value,
                style: AppTextStyles.pixelBody.copyWith(
                  fontSize: 12,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _continue() => MiningButton(
    key: const ValueKey('confirm-ore'),
    label: 'Continue',
    vivid: true,
    color: AppColors.primary,
    foreground: AppColors.cave,
    height: 60,
    fontSize: 22,
    trailing: Icons.arrow_forward,
    onPressed: () => Navigator.pop(context, widget.ores[_index].id),
  );
}
