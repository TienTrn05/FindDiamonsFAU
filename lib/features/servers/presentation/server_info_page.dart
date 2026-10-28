import '../../../common/widgets/app_text.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../models/server_catalog.dart';

class ServerInfoPage extends StatelessWidget {
  const ServerInfoPage({super.key, required this.server});

  final ServerItem server;

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(message)));
    }
  }

  void _connectionDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: AppText(
        server.edition.toLowerCase() == 'java'
            ? 'Add to Java server list'
            : 'Add to Bedrock server list',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(server.name, style: AppTextStyles.serverTitle),
          const SizedBox(height: AppSpacing.md),
          SelectableText(server.address),
          const SizedBox(height: AppSpacing.sm),
          AppText('Port: ${server.port}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const AppText('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _copy(context, server.address, 'Server address copied');
          },
          child: const AppText('Copy address'),
        ),
      ],
    ),
  );

  Future<void> _website(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(server.website.trim());
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      _showWebsiteError(messenger);
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showWebsiteError(messenger);
      }
    } catch (error, stackTrace) {
      debugPrint('Server website could not be opened: $error\n$stackTrace');
      _showWebsiteError(messenger);
    }
  }

  void _showWebsiteError(ScaffoldMessengerState messenger) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: AppText('Unable to open server website.')),
    );
  }

  void _share(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: AppInsets.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(server.name, style: AppTextStyles.dialogTitle),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const AppText('Copy server address'),
              subtitle: AppText(server.address),
              onTap: () {
                Navigator.pop(sheetContext);
                _copy(context, server.address, 'Server address copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const AppText('Copy website link'),
              subtitle: AppText(server.website),
              onTap: () {
                Navigator.pop(sheetContext);
                _copy(context, server.website, 'Website link copied');
              },
            ),
          ],
        ),
      ),
    ),
  );

  ButtonStyle _outline(Color border) => OutlinedButton.styleFrom(
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(0, 50),
    side: BorderSide(color: border, width: 2),
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    textStyle: AppTextStyles.serverInfoAction,
  );

  @override
  Widget build(BuildContext context) => AppPageFrame(
    child: RepaintBoundary(
      key: const ValueKey('server-info-preview'),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          systemOverlayStyle: AppTheme.systemUi,
          centerTitle: true,
          leadingWidth: 92,
          leading: TextButton.icon(
            key: const ValueKey('server-info-back'),
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.serverNavigation,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_back_ios_new, size: 24),
            label: const AppText('Main', style: AppTextStyles.body),
          ),
          title: const AppText('Server Info', style: AppTextStyles.serverTitle),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const LandscapeBackground(
                washed: true,
                child: SizedBox.expand(),
              ),
            ),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                key: const PageStorageKey('server-info-scroll'),
                child: Column(
                  children: [
                    _banner(),
                    ColoredBox(
                      color: AppColors.serverHero,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * .14,
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              AppText(
                                server.name,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.serverInfoTitle,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  for (final tag in server.tags)
                                    DecoratedBox(
                                      decoration: const BoxDecoration(
                                        color: AppColors.chipSurface,
                                        borderRadius: AppRadii.pill,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: AppText(
                                          tag,
                                          style: AppTextStyles.serverInfoTag,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  key: const ValueKey('server-add'),
                                  onPressed: () => _connectionDetails(context),
                                  style: _outline(AppColors.serverActionBorder),
                                  child: AppText(
                                    server.edition.toLowerCase() == 'java'
                                        ? 'ADD TO JAVA SERVER LIST'
                                        : 'ADD TO BEDROCK SERVER LIST',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      key: const ValueKey(
                                        'server-copy-address',
                                      ),
                                      onPressed: () => _copy(
                                        context,
                                        server.address,
                                        'Server address copied',
                                      ),
                                      style: _outline(AppColors.onPrimary),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              server.address,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          const Icon(
                                            Icons.content_copy,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  SizedBox(
                                    width: 50,
                                    child: OutlinedButton(
                                      key: const ValueKey('server-share'),
                                      onPressed: () => _share(context),
                                      style: _outline(AppColors.onPrimary),
                                      child: const Icon(
                                        Icons.share,
                                        size: 23,
                                        semanticLabel: 'Share server',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: FilledButton(
                        key: const ValueKey('server-website'),
                        onPressed: () => _website(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.serverAction,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(0, 46),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.standard,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          textStyle: AppTextStyles.serverInfoAction,
                        ),
                        child: const AppText('Visit Server Website'),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.xs,
                        0,
                        AppSpacing.xs,
                        AppSpacing.xl,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.serverSurface,
                        border: Border.all(
                          color: AppColors.oreRowBorder,
                          width: 3,
                        ),
                        borderRadius: AppRadii.card,
                      ),
                      child: AppText(
                        [
                          server.description,
                          if (server.joinNote.isNotEmpty) server.joinNote,
                          if (server.version != null)
                            'Version: ${server.version}',
                          if (server.motd != null) server.motd!,
                        ].where((line) => line.isNotEmpty).join('\n\n'),
                        style: AppTextStyles.serverInfoBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _banner() {
    final banner = server.bannerUrl;
    final fallback = Image.asset(server.bannerImage, fit: BoxFit.cover);

    return AspectRatio(
      aspectRatio: 8,
      child: banner == null
          ? fallback
          : banner.path.toLowerCase().endsWith('.svg')
          ? SvgPicture.network(
              banner.toString(),
              fit: BoxFit.cover,
              placeholderBuilder: (_) => fallback,
            )
          : Image.network(
              banner.toString(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
