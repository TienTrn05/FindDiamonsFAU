import 'package:flutter/material.dart';

import '../../../common/widgets/app_text.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/server_catalog.dart';

/// The same bundled image, including its GIF animation, is used on both routes.
class ServerBanner extends StatelessWidget {
  const ServerBanner({super.key, required this.server});

  final ServerItem server;

  @override
  Widget build(BuildContext context) => AspectRatio(
    key: ValueKey('server-banner-${server.id}'),
    aspectRatio: AppLayout.serverBannerAspectRatio,
    child: Image.asset(
      server.bannerImage,
      fit: BoxFit.contain,
      semanticLabel: server.name,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.banner,
        child: Center(
          child: AppText(server.name, style: AppTextStyles.onPrimaryPixelBody),
        ),
      ),
    ),
  );
}
