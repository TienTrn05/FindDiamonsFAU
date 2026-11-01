import '../../../core/network/app_image_cache.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../common/widgets/app_text.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/server_catalog.dart';

/// Render the backend's full banner, centered logo, or icon-and-name variant.
class ServerBanner extends StatelessWidget {
  const ServerBanner({super.key, required this.server});
  final ServerItem server;

  Widget _identity() => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.helpRaised, AppColors.cavePanel, AppColors.cave],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(aspectRatio: 1, child: _icon()),
          const SizedBox(width: 10),
          Flexible(
            child: AppText(
              server.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.onPrimaryPixelBody.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _icon() {
    final icon = server.icon;
    if (icon != null && icon.startsWith('data:image/png;base64,')) {
      try {
        return Image.memory(
          base64Decode(icon.substring(icon.indexOf(',') + 1)),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, error, stackTrace) =>
              const Icon(Icons.dns, color: AppColors.primary),
        );
      } on FormatException {
        /* Use the server identity when the icon is invalid. */
      }
    }
    return const Icon(Icons.dns, color: AppColors.primary);
  }

  Widget _fallback() => server.bannerStyle == 'icon' ? _icon() : _identity();

  Widget _picture(BoxFit fit) {
    if (server.bannerUrl != null) {
      return _ServerNetworkPicture(
        url: server.bannerUrl.toString(),
        key: ValueKey('server-banner-image-${server.id}'),
        fit: fit,
        label: server.name,
        fallback: _fallback,
      );
    }
    if (server.bannerImage != 'assets/images/block_landscape.png') {
      return Image.asset(
        server.bannerImage,
        fit: fit,
        semanticLabel: server.name,
        errorBuilder: (_, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    final variant = switch (server.bannerStyle) {
      'icon' => 'icon',
      'logo' => 'logo',
      _ => 'full',
    };
    return AspectRatio(
      key: ValueKey('server-banner-${server.id}'),
      aspectRatio: AppLayout.serverBannerAspectRatio,
      child: ColoredBox(
        color: AppColors.cave,
        child: switch (variant) {
          'icon' => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                AspectRatio(aspectRatio: 1, child: _picture(BoxFit.contain)),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText(
                    server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.onPrimaryPixelBody.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          'logo' => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Center(child: _picture(BoxFit.contain)),
          ),
          _ => _picture(BoxFit.contain),
        },
      ),
    );
  }
}

/// Startup and revision preparation have already cached the compressed GIF.
class _ServerNetworkPicture extends StatelessWidget {
  const _ServerNetworkPicture({
    super.key,
    required this.url,
    required this.fit,
    required this.label,
    required this.fallback,
  });
  final String url;
  final BoxFit fit;
  final String label;
  final Widget Function() fallback;
  @override
  Widget build(BuildContext context) => Image(
    image: AppNetworkImage(url),
    fit: fit,
    semanticLabel: label,
    gaplessPlayback: true,
    errorBuilder: (_, error, stackTrace) => fallback(),
  );
}
