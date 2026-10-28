import 'package:flutter/material.dart';

import '../../../common/widgets/app_text.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/server_catalog.dart';

/// Shows the same bundled banner on both routes for non-Pro users only.
class ServerBanner extends StatelessWidget {
  const ServerBanner({super.key, required this.server});

  final ServerItem server;

  @override
  Widget build(BuildContext context) {
    if (MonetizationScope.maybeOf(context)?.isPro ?? false) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      key: ValueKey('server-banner-${server.id}'),
      aspectRatio: AppLayout.serverBannerAspectRatio,
      child: Image.asset(
        server.bannerImage,
        fit: BoxFit.contain,
        semanticLabel: server.name,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: AppColors.banner,
          child: Center(
            child: AppText(
              server.name,
              style: AppTextStyles.onPrimaryPixelBody,
            ),
          ),
        ),
      ),
    );
  }
}
