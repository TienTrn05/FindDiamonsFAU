import 'package:flutter/material.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/app_image_cache.dart';

import '../../../common/widgets/skin_head.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../core/theme/app_colors.dart';
import '../../skins/models/skin_item.dart';

class ServerProfileHeader extends StatelessWidget {
  const ServerProfileHeader({
    super.key,
    required this.username,
    required this.onTap,
    this.selectedSkin,
    this.compact = false,
  });

  final String? username;
  final VoidCallback onTap;
  final SkinItem? selectedSkin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = username?.trim() ?? '';
    if (compact) {
      return Tooltip(
        message: name.isEmpty ? context.tr('Tap here...') : name,
        child: Material(
          color: AppColors.helpRaised,
          shape: const PixelBorder(
            side: BorderSide(color: AppColors.helpBorder),
          ),
          child: InkWell(
            key: const ValueKey('server-username-header'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SizedBox.square(
                dimension: 30,
                child: SkinHead(
                  palette: selectedSkin?.palette ?? 'steve',
                  texture: selectedSkin?.downloadUrl == null
                      ? null
                      : AppNetworkImage(selectedSkin!.downloadUrl.toString()),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: AppColors.cavePanel,
      shape: const PixelBorder(side: BorderSide(color: AppColors.helpBorder)),
      child: InkWell(
        key: const ValueKey('server-username-header'),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72),
                child: Text(
                  name.isEmpty ? context.tr('Tap here...') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontFamily: 'Monocraft',
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              Positioned(
                right: 16,
                width: 48,
                height: 48,
                child: SkinHead(
                  palette: selectedSkin?.palette ?? 'steve',
                  texture: selectedSkin?.downloadUrl == null
                      ? null
                      : AppNetworkImage(selectedSkin!.downloadUrl.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
