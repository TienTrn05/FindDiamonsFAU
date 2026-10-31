import '../../../core/network/app_image_cache.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_components.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/game_header.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/maps_bloc.dart';
import '../bloc/map_download_controller.dart';
import '../models/map_catalog.dart';
import 'map_unlock_dialog.dart';
import 'map_launch_dialog.dart';

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
  AppMonetization? _ownedAccess;
  AppMonetization get _access =>
      widget.monetization ??
      MonetizationScope.maybeOf(context) ??
      (_ownedAccess ??= AppMonetization());
  late final MapDownloadController _download = widget.bloc.downloadFor(
    widget.item,
  );
  bool _preloadScheduled = false;
  bool _dialogOpen = false;

  bool get _locked => widget.bloc.isLocked(widget.item, isPro: _access.isPro);

  Future<void> _downloadMap() async {
    if (_locked || _dialogOpen || _download.downloading) return;
    await _download.download();
  }

  void _missingFile() {
    _download.invalidateSavedFile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'The saved map is missing. Please download it again.',
          ),
        ),
      );
    }
  }

  Future<void> _launchMap() async {
    final file = _download.saved;
    if (file == null || _locked || _dialogOpen) return;
    _dialogOpen = true;
    try {
      final exists = await File(file.path).exists();
      if (!mounted) return;
      if (!exists) {
        _missingFile();
        return;
      }
      await showGeneralDialog<void>(
        context: context,
        barrierColor: const Color(0xE6000000),
        pageBuilder: (_, _, _) => MapLaunchDialog(
          item: widget.item,
          file: file,
          monetization: _access,
          onMissingFile: _missingFile,
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

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
    _ownedAccess?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.bloc, _access, _download]),
    builder: (context, _) {
      _preload();
      final item = widget.item;
      final favourite = widget.bloc.favourites.contains(item.id);
      return AppPageFrame(
        child: Scaffold(
          body: MiningBackground(
            child: Column(
              children: [
                GameHeader(
                  title: item.name,
                  contentHeight: AppLayout.gameHeaderHeight * .5,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      _WorldGallery(item: item),
                      if (item.edition.isNotEmpty ||
                          item.versions.isNotEmpty ||
                          item.seed != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: MiningPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (item.edition.isNotEmpty)
                                      MiningTag(
                                        item.edition,
                                        icon: Icons.sports_esports_outlined,
                                      ),
                                    for (final version in item.versions)
                                      MiningTag(version),
                                  ],
                                ),
                                if (item.seed != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppText(
                                          'Seed: ${item.seed}',
                                          style: AppTextStyles.fieldValue,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: context.tr('Copy seed'),
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: item.seed!),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: AppText('Seed copied'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.copy,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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
                  if (_locked)
                    AppButton(
                      key: const ValueKey('unlock-world'),
                      label: 'Unlock World',
                      pixel: true,
                      leading: const Icon(
                        Icons.lock,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: _unlock,
                    )
                  else if (_download.saved != null)
                    AppButton(
                      key: const ValueKey('launch-map'),
                      label: 'Launch Map',
                      pixel: true,
                      leading: const Icon(
                        Icons.rocket_launch,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: _launchMap,
                    )
                  else if (_download.restoring || _download.canDownload) ...[
                    AppButton(
                      key: const ValueKey('download-map'),
                      label: _download.restoring
                          ? 'Checking download...'
                          : _download.downloading
                          ? 'Downloading...'
                          : _download.error == null
                          ? 'Download Map'
                          : 'Retry Download',
                      pixel: true,
                      leading: const Icon(
                        Icons.download,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: _download.restoring || _download.downloading
                          ? null
                          : _downloadMap,
                    ),
                    if (_download.downloading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        key: const ValueKey('map-download-progress'),
                        value: _download.progress.fraction,
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        _download.progress.fraction == null
                            ? '${(_download.progress.received / 1024).toStringAsFixed(0)} KB downloaded'
                            : '${(_download.progress.fraction! * 100).floor().clamp(0, 99)}%',
                        key: const ValueKey('map-download-percent'),
                        style: AppTextStyles.pixelBody,
                      ),
                    ],
                    if (_download.error != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: AppText(
                          'Unable to download this map. Check the download link and try again.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.dialogBody,
                        ),
                      ),
                  ] else ...[
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
            child: widget.item.coverUrl != null && widget.item.gallery.isEmpty
                ? Image(
                    image: AppNetworkImage(widget.item.coverUrl!),
                    fit: BoxFit.cover,
                    semanticLabel: widget.item.name,
                    errorBuilder: (_, _, _) => Image.asset(
                      widget.item.cover,
                      fit: BoxFit.cover,
                      semanticLabel: widget.item.name,
                    ),
                  )
                : Image.asset(
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
