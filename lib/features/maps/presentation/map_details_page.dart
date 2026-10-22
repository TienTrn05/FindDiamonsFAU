import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/game_header.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/maps_bloc.dart';
import '../models/map_catalog.dart';
import 'map_unlock_dialog.dart';

class MapDetailsPage extends StatefulWidget {
  const MapDetailsPage({
    super.key,
    required this.item,
    required this.bloc,
    required this.onGoPro,
    this.monetization,
  });

  final MapItem item;
  final MapsBloc bloc;
  final VoidCallback onGoPro;
  final AppMonetization? monetization;

  @override
  State<MapDetailsPage> createState() => _MapDetailsPageState();
}

class _MapDetailsPageState extends State<MapDetailsPage> {
  late final _access = widget.monetization ?? AppMonetization();
  bool _preloadScheduled = false;
  bool _dialogOpen = false;

  bool get _locked => widget.bloc.isLocked(widget.item, isPro: _access.isPro);

  void _preload() {
    if (_preloadScheduled ||
        !_locked ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _preloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadScheduled = false;
      if (!mounted) return;
      unawaited(
        _access.rewardedAds.preload(
          canLoad: () =>
              mounted && _locked && ModalRoute.of(context)?.isCurrent == true,
        ),
      );
    });
  }

  Future<void> _unlock() async {
    if (!_locked || _dialogOpen) return;
    _dialogOpen = true;
    final premium = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MapUnlockDialog(
        item: widget.item,
        bloc: widget.bloc,
        monetization: _access,
      ),
    );
    _dialogOpen = false;
    if (mounted && premium == true) widget.onGoPro();
  }

  @override
  void dispose() {
    if (widget.monetization == null) _access.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.bloc, _access]),
    builder: (context, _) {
      _preload();
      final item = widget.item;
      final favourite = widget.bloc.favourites.contains(item.id);
      return AppPageFrame(
        child: Scaffold(
          body: Column(
            children: [
              GameHeader(
                title: item.name,
                onBack: () => Navigator.pop(context),
                trailing: IconButton(
                  key: const ValueKey('map-detail-favourite'),
                  tooltip: context.tr(
                    favourite ? 'Remove favourite' : 'Add favourite',
                  ),
                  onPressed: () => widget.bloc.toggleFavourite(item.id),
                  icon: Icon(
                    favourite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.onPrimary,
                    size: 30,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  key: const PageStorageKey('map-details'),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    _WorldGallery(item: item),
                    if (item.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppText(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.itemTitle,
                        ),
                      ),
                    for (final detail in item.details)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppText(
                                detail,
                                style: AppTextStyles.pixelBodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(color: AppColors.helpFooter),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const ValueKey('unlock-world'),
                    label: _locked ? 'Unlock World' : 'World Unlocked',
                    pixel: true,
                    leading: Icon(
                      _locked ? Icons.lock : Icons.check_circle,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: _locked ? _unlock : null,
                  ),
                  if (!_locked) ...[
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'Map download is not available yet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dialogBody,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _WorldGallery extends StatefulWidget {
  const _WorldGallery({required this.item});
  final MapItem item;

  @override
  State<_WorldGallery> createState() => _WorldGalleryState();
}

class _WorldGalleryState extends State<_WorldGallery> {
  late final _pages = PageController(
    viewportFraction: widget.item.images.length > 1 ? .78 : 1,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: (constraints.maxWidth * .6).clamp(180.0, 320.0),
      child: PageView.builder(
        key: const ValueKey('map-gallery'),
        controller: _pages,
        padEnds: false,
        itemCount: widget.item.images.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: AppRadii.standard,
            child: Image.asset(
              widget.item.images[index],
              fit: BoxFit.cover,
              semanticLabel: widget.item.name,
            ),
          ),
        ),
      ),
    ),
  );
}
