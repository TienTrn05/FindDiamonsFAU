import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/game_header.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../common/widgets/ad_placements.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/maps_bloc.dart';
import '../data/maps_repository.dart';
import '../models/map_catalog.dart';
import 'map_details_page.dart';
import 'seed_map_card.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key, required this.onGoPro, this.repository});
  final VoidCallback onGoPro;
  final MapsRepository? repository;
  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late final MapsBloc _bloc = MapsBloc(
    widget.repository ?? JsonMapsRepository(),
  )..load();
  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void _open(MapItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MapDetailsPage(
          item: item,
          bloc: _bloc,
          monetization: MonetizationScope.maybeOf(context),
          onGoPro: widget.onGoPro,
        ),
      ),
    );
  }

  Widget _seedFilters() {
    final versions = _bloc.seedVersions;
    final rows = [versions.take(4), versions.skip(4).take(5), versions.skip(9)];
    return Container(
      key: const ValueKey('seed-version-filters'),
      width: double.infinity,
      color: AppColors.banner,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < rows.length; row++)
            if (rows[row].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: row == 0 ? 0 : AppSpacing.xs),
                child: Align(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      key: ValueKey('seed-version-row-$row'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final version in rows[row])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Semantics(
                              button: true,
                              selected: _bloc.seedVersion == version,
                              child: Material(
                                color: _bloc.seedVersion == version
                                    ? AppColors.navigationSelected
                                    : AppColors.chipSurface,
                                shape: const StadiumBorder(),
                                child: InkWell(
                                  key: ValueKey('seed-version-$version'),
                                  customBorder: const StadiumBorder(),
                                  onTap: () => _bloc.selectSeedVersion(
                                    _bloc.seedVersion == version
                                        ? null
                                        : version,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 5,
                                    ),
                                    child: AppText(
                                      version,
                                      style: AppTextStyles.serverInfoTag
                                          .copyWith(fontSize: 11, height: 1.2),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
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

  @override
  Widget build(BuildContext context) => ResourceView<MapCatalog>(
    controller: _bloc,
    builder: (context, catalog) => SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: PageStorageKey('maps-${_bloc.category}'),
        slivers: [
          SliverToBoxAdapter(child: GameHeader(title: catalog.title)),
          PinnedHeaderSliver(
            child: ColoredBox(
              key: const ValueKey('map-category-bar'),
              color: AppColors.oreRow,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: catalog.categories
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: OutlinedButton(
                            key: ValueKey('category-$category'),
                            style: AppTheme.categoryButton(
                              selected: _bloc.category == category,
                            ),
                            onPressed: () => _bloc.selectCategory(category),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (category == 'Favourite') ...[
                                  const Icon(
                                    Icons.star_border,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                AppText(
                                  category,
                                  style: AppTextStyles.pixelBodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          if (_bloc.category == 'Seeds')
            SliverToBoxAdapter(child: _seedFilters()),
          if (_bloc.visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                key: const ValueKey('empty-map-category'),
                child: Padding(
                  padding: AppInsets.screen,
                  child: AppText(
                    'there is no item in "${context.tr(_bloc.category)}"',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pixelBodyLarge,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                10,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount:
                    _bloc.visible.length +
                    (MonetizationScope.maybeOf(context)?.isPro == false &&
                            MonetizationScope.maybeOf(
                                  context,
                                )?.adsRuntime.available ==
                                true
                        ? 1
                        : 0),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) {
                  final hasAd =
                      MonetizationScope.maybeOf(context)?.isPro == false &&
                      MonetizationScope.maybeOf(
                            context,
                          )?.adsRuntime.available ==
                          true;
                  final adIndex = _bloc.visible.length < 2
                      ? _bloc.visible.length
                      : 2;
                  if (hasAd && index == adIndex) {
                    return const SpecialOfferAd();
                  }
                  final item = _bloc
                      .visible[hasAd && index > adIndex ? index - 1 : index];
                  final locked = _bloc.isLocked(
                    item,
                    isPro: MonetizationScope.maybeOf(context)?.isPro ?? false,
                  );
                  if (item.category == 'Seeds') {
                    return SeedMapCard(
                      item: item,
                      favourite: _bloc.favourites.contains(item.id),
                      selectedVersion: _bloc.category == 'Seeds'
                          ? _bloc.seedVersion
                          : null,
                      onFavourite: () => _bloc.toggleFavourite(item.id),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) => Material(
                      color: AppColors.surface,
                      borderRadius: AppRadii.standard,
                      child: InkWell(
                        key: ValueKey('map-${item.id}'),
                        borderRadius: AppRadii.standard,
                        onTap: () => _open(item),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            borderRadius: AppRadii.standard,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: AppLayout.compact(constraints.maxWidth)
                                    ? 90
                                    : 112,
                                height: 118,
                                child: ClipRRect(
                                  borderRadius: AppRadii.standard,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        item.cover,
                                        fit: BoxFit.cover,
                                      ),
                                      if (locked)
                                        const ColoredBox(
                                          color: AppColors.heroScrim,
                                        ),
                                      if (locked)
                                        const Center(
                                          child: Icon(
                                            Icons.lock,
                                            color: AppColors.lock,
                                            size: 28,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            item.name,
                                            style: AppTextStyles.itemTitle,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 28,
                                          height: 32,
                                          child: IconButton(
                                            key: ValueKey(
                                              'favourite-${item.id}',
                                            ),
                                            padding: EdgeInsets.zero,
                                            tooltip: context.tr(
                                              _bloc.favourites.contains(item.id)
                                                  ? 'Remove favourite'
                                                  : 'Add favourite',
                                            ),
                                            onPressed: () =>
                                                _bloc.toggleFavourite(item.id),
                                            iconSize: 21,
                                            icon: Icon(
                                              _bloc.favourites.contains(item.id)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      AppText(
                                        item.subtitle,
                                        style: AppTextStyles.pixelBody,
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    AppText(
                                      item.description,
                                      style: AppTextStyles.pixelBody,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
