import '../../../common/widgets/app_text.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../common/widgets/voxel_character.dart';
import '../../../common/widgets/voxel_character_3d.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/skins_bloc.dart';
import '../data/skins_repository.dart';
import '../models/skin_item.dart';
import 'skin_unlock_dialog.dart';

class SkinsPage extends StatefulWidget {
  const SkinsPage({super.key, required this.onGoPro, this.repository});
  final VoidCallback onGoPro;
  final SkinsRepository? repository;
  @override
  State<SkinsPage> createState() => _SkinsPageState();
}

class _SkinsPageState extends State<SkinsPage> {
  late final SkinsBloc _bloc = SkinsBloc(
    widget.repository ?? JsonSkinsRepository(),
  )..load();
  late final _fallbackMonetization = AppMonetization();
  AppMonetization get _access =>
      MonetizationScope.maybeOf(context) ?? _fallbackMonetization;
  bool _dialogOpen = false;
  bool _sharing = false;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  final _skinImage = GlobalKey();
  final _shareOrigin = GlobalKey();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _bloc.dispose();
    _fallbackMonetization.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _bloc.search(value);
    });
  }

  Future<void> _share() async {
    if (_dialogOpen || _sharing) return;
    final selected = _bloc.selected;
    if (_bloc.isLocked(selected, isPro: _access.isPro)) {
      _dialogOpen = true;
      bool? premium;
      try {
        premium = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => SkinUnlockDialog(
            item: selected,
            bloc: _bloc,
            monetization: _access,
          ),
        );
      } finally {
        _dialogOpen = false;
      }
      if (!mounted) return;
      if (premium == true) {
        widget.onGoPro();
        return;
      }
      if (_bloc.isLocked(selected, isPro: _access.isPro)) return;
    }
    setState(() => _sharing = true);
    try {
      // Capture after the selected skin and any closed unlock dialog repaint.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted ||
          !TickerMode.of(context) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final preview =
          _skinImage.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      final origin =
          _shareOrigin.currentContext?.findRenderObject() as RenderBox?;
      if (preview == null || origin == null || preview.size.isEmpty) {
        throw StateError('Skin preview is not ready');
      }
      final sharePosition = origin.localToGlobal(Offset.zero) & origin.size;
      final longestSide = math.max(preview.size.width, preview.size.height);
      final image = await preview.toImage(
        pixelRatio: (1024 / longestSide).clamp(1.0, 4.0),
      );
      late final ByteData? data;
      try {
        data = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (data == null) throw StateError('Unable to encode skin image');
      if (!mounted ||
          !TickerMode.of(context) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final filename =
          'skin-${selected.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: [filename],
          subject: selected.name,
          sharePositionOrigin: sharePosition,
        ),
      );
    } catch (error) {
      debugPrint('Skin image sharing unavailable: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Unable to share this image. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _access,
    builder: (context, _) => LandscapeBackground(
      child: SafeArea(
        bottom: false,
        child: ResourceView<List<SkinItem>>(
          controller: _bloc,
          builder: (context, skins) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  SizedBox(height: 46, child: _searchField()),
                  const SizedBox(height: 6),
                  if (skins.isEmpty)
                    const Expanded(
                      child: Center(
                        child: AppText(
                          'No skins found.',
                          style: AppTextStyles.onPrimaryPixelBody,
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: math.min(
                        285.0,
                        (constraints.maxHeight - 80).clamp(0.0, 10000.0) * .46,
                      ),
                      child: _preview(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: GridView.builder(
                        key: const PageStorageKey('skins-grid'),
                        padding: EdgeInsets.zero,
                        itemCount: skins.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppLayout.gridColumns(
                            constraints.maxWidth,
                          ),
                          mainAxisSpacing: AppSpacing.xl,
                          crossAxisSpacing: AppSpacing.xl,
                          childAspectRatio: .82,
                        ),
                        itemBuilder: (_, index) => _skinCard(skins[index]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _searchField() => TextField(
    controller: _searchController,
    onChanged: _onSearchChanged,
    textInputAction: TextInputAction.search,
    style: AppTextStyles.fieldValue,
    decoration: InputDecoration(
      hintText: context.tr('Search by name or category'),
      hintStyle: AppTextStyles.caption,
      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      border: OutlineInputBorder(
        borderRadius: AppRadii.standard,
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.standard,
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.standard,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );

  Widget _preview() => Container(
    key: const ValueKey('skin-preview'),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.standard,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    16,
                    AppSpacing.md,
                    16,
                  ),
                  child: RepaintBoundary(
                    key: _skinImage,
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: VoxelCharacter3D(
                        key: const ValueKey('skin-3d-viewer'),
                        palette: _bloc.selected.palette,
                        walking: _bloc.walking,
                        skinTextureUrl: _bloc.selected.downloadUrl,
                      ),
                    ),
                  ),
                ),
              ),
              if (_bloc.isLocked(_bloc.selected, isPro: _access.isPro))
                const Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: DecoratedBox(
                    key: ValueKey('selected-skin-locked'),
                    decoration: BoxDecoration(
                      color: AppColors.heroScrim,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Icon(Icons.lock, color: AppColors.lock, size: 22),
                    ),
                  ),
                ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: AppText(
                        _bloc.selected.name,
                        style: AppTextStyles.onPrimaryPixelBody,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: AppColors.primary,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const ValueKey('skin-idle'),
                    onPressed: () => _bloc.setWalking(false),
                    child: AppText(
                      'Idle',
                      style: AppTextStyles.onPrimaryPixelField.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 45,
                  child: VerticalDivider(color: AppColors.onPrimary),
                ),
                Expanded(
                  child: TextButton(
                    key: const ValueKey('skin-walk'),
                    onPressed: () => _bloc.setWalking(true),
                    child: AppText(
                      'Walk',
                      style: AppTextStyles.onPrimaryPixelField.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 45,
                  child: VerticalDivider(color: AppColors.onPrimary),
                ),
                KeyedSubtree(
                  key: _shareOrigin,
                  child: IconButton(
                    key: const ValueKey('skin-share'),
                    tooltip: context.tr('Share skin image'),
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(
                            Icons.reply,
                            color: AppColors.onPrimary,
                            size: 30,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _skinCard(SkinItem skin) => Column(
    children: [
      Expanded(
        child: Semantics(
          selected: _bloc.selected.id == skin.id,
          button: true,
          label: _bloc.isLocked(skin, isPro: _access.isPro)
              ? context.tr('{name}, locked', args: {'name': skin.name})
              : skin.name,
          child: Material(
            color: AppColors.surface,
            borderRadius: AppRadii.standard,
            child: InkWell(
              key: ValueKey('skin-${skin.id}'),
              borderRadius: AppRadii.standard,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),

              onTap: _sharing ? null : () => _bloc.select(skin),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary,
                    width: _bloc.selected.id == skin.id ? 3 : 2,
                  ),
                  borderRadius: AppRadii.standard,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _skinCardArtwork(skin),
                      ),
                    ),
                    if (_bloc.isLocked(skin, isPro: _access.isPro))
                      const Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Icon(
                          Icons.lock,
                          color: AppColors.lock,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppText(
        skin.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.onPrimaryPixelBody,
      ),
    ],
  );

  Widget _skinCardArtwork(SkinItem skin) {
    final previewUrl = skin.previewUrl;
    if (previewUrl == null) return VoxelCharacter(palette: skin.palette);
    return Image.network(
      previewUrl.toString(),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => VoxelCharacter(palette: skin.palette),
    );
  }
}
