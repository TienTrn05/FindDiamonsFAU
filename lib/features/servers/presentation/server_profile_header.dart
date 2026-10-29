import 'package:flutter/material.dart';

import '../../../common/widgets/skin_head.dart';
import '../../../core/theme/app_colors.dart';
import '../../skins/models/skin_item.dart';

class ServerProfileHeader extends StatelessWidget {
  const ServerProfileHeader({
    super.key,
    required this.username,
    required this.onTap,
    this.selectedSkin,
  });

  final String? username;
  final VoidCallback onTap;
  final SkinItem? selectedSkin;

  @override
  Widget build(BuildContext context) {
    final name = username?.trim() ?? '';
    return Material(
      color: AppColors.banner,
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
                  name.isEmpty ? 'Tap here...' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontFamily: 'Monocraft',
                    fontSize: 24,
                    height: 1.2,
                  ),
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
                      : NetworkImage(selectedSkin!.downloadUrl.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
