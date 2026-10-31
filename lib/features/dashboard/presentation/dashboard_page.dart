import 'package:flutter/material.dart';

import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/mining_art.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_viewport.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/skin_head.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/navigation/app_destination.dart';
import '../../../core/theme/mining_style.dart';
import 'dashboard_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onNavigate,
    required this.onGoPro,
    required this.onHelp,
  });
  final ValueChanged<AppDestination> onNavigate;
  final VoidCallback onGoPro;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => MiningBackground(
    vivid: true,
    headerAsset: 'assets/images/dashboard_cave_v2.png',
    child: SafeArea(
      bottom: false,
      child: MiningViewport(
        minimumHeight: 680,
        compactHeight: 460,
        builder: (context, landscape, compact) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: landscape
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(flex: 5, child: _brand()),
                          const SizedBox(height: 12),
                          Expanded(flex: 4, child: _findCard(compact)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _links(context, compact)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 27, child: _brand()),
                    const SizedBox(height: 12),
                    Expanded(flex: 25, child: _findCard(compact)),
                    const SizedBox(height: 14),
                    Expanded(flex: 58, child: _links(context, compact)),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _brand() =>
      RepaintBoundary(child: DashboardHeader(onSettings: onHelp));

  Widget _findCard(bool compact) => MiningPanel(
    key: const ValueKey('dashboard-find'),
    vivid: true,
    scenery: true,
    color: MiningStyle.teal,
    borderColor: MiningStyle.cyan,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    onTap: () => onNavigate(AppDestination.find),
    child: Center(
      child: Row(
        children: [
          OreIcon(
            size: compact ? 58 : 82,
            mineralTint: MiningStyle.cyan,
            showCenterGem: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 185,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      'ORE TOOL',
                      style: MiningStyle.label.copyWith(
                        color: MiningStyle.cyan,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const AppText('Find Ore', style: MiningStyle.heading),
                    const SizedBox(height: 7),
                    AppText(
                      'Enter your world details and find valuable ores!',
                      style: MiningStyle.body.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: MiningButton(
              label: '',
              semanticLabel: 'Find Ore',
              icon: Icons.arrow_forward,
              color: MiningStyle.cyan,
              foreground: MiningStyle.ink,
              vivid: true,
              height: 48,
              onPressed: () => onNavigate(AppDestination.find),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _links(BuildContext context, bool compact) => Column(
    children: [
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: _tile(
                AppDestination.history,
                'View your past searches',
                const MiningArt(MiningArtKind.book),
                compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tile(
                AppDestination.skins,
                'Browse and download skins',
                const SizedBox.square(dimension: 46, child: SkinHead()),
                compact,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: _tile(
                AppDestination.servers,
                'Discover popular servers',
                const MiningArt(MiningArtKind.grass),
                compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tile(
                AppDestination.maps,
                'Explore useful world maps',
                const MiningArt(MiningArtKind.map),
                compact,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: MonetizationScope.maybeOf(context)?.isPro == true
            ? const SizedBox.shrink()
            : MiningPanel(
                key: const ValueKey('dashboard-pro'),
                vivid: true,
                scenery: true,
                color: MiningStyle.amber,
                borderColor: MiningStyle.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                onTap: onGoPro,
                child: Center(
                  child: Row(
                    children: [
                      const MiningArt(MiningArtKind.crown, size: 58),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 225,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'MINER PRO',
                                  style: MiningStyle.label.copyWith(
                                    color: MiningStyle.gold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                AppText(
                                  'Unlock Pro Tools',
                                  style: MiningStyle.heading.copyWith(
                                    fontSize: 19,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (!compact)
                                  AppText(
                                    'More ores, advanced features, no ads and more!',
                                    style: MiningStyle.body.copyWith(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 40,
                        child: MiningButton(
                          label: '',
                          semanticLabel: 'Unlock Pro Tools',
                          icon: Icons.arrow_forward,
                          vivid: true,
                          height: 44,
                          color: MiningStyle.gold,
                          foreground: MiningStyle.ink,
                          onPressed: onGoPro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ],
  );

  Widget _tile(
    AppDestination destination,
    String subtitle,
    Widget art,
    bool compact,
  ) => MiningPanel(
    key: ValueKey('dashboard-${destination.name}'),
    color: MiningStyle.stone,
    borderColor: MiningStyle.edge,
    vivid: true,
    padding: const EdgeInsets.all(10),
    onTap: () => onNavigate(destination),
    child: Center(
      child: Row(
        children: [
          SizedBox.square(
            dimension: compact ? 34 : 52,
            child: FittedBox(child: art),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    destination.label,
                    style: MiningStyle.cardTitle.copyWith(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 6),
                if (!compact)
                  AppText(
                    subtitle,
                    style: MiningStyle.body.copyWith(fontSize: 12),
                    maxLines: 3,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: MiningStyle.muted, size: 16),
        ],
      ),
    ),
  );
}
