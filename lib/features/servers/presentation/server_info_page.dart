import '../../../common/widgets/app_text.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/widgets/ad_placements.dart';
import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../models/server_catalog.dart';
import 'server_banner.dart';
import 'server_connection_dialog.dart';

class ServerInfoPage extends StatefulWidget {
  const ServerInfoPage({super.key, required this.server});

  final ServerItem server;

  @override
  State<ServerInfoPage> createState() => _ServerInfoPageState();
}

class _ServerInfoPageState extends State<ServerInfoPage> {
  ServerItem get server => widget.server;
  Timer? _copiedTimer;
  bool _copied = false;
  bool _sharing = false;
  bool _openingWebsite = false;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyAddress() async {
    await Clipboard.setData(ClipboardData(text: server.address));
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _connectionDetails(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) =>
        ServerConnectionDialog(server: server, onCopy: _copyAddress),
  );

  Future<void> _website() async {
    if (_openingWebsite) return;
    setState(() => _openingWebsite = true);
    try {
      final url = Uri.parse(server.website);
      if (!['https', 'http'].contains(url.scheme) ||
          url.host.isEmpty ||
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('Server website could not be opened');
      }
    } catch (error) {
      debugPrint('Server website unavailable: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Unable to open this website. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingWebsite = false);
    }
  }

  Future<void> _share(BuildContext context) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final origin = context.findRenderObject() as RenderBox;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${server.name}\nJava: ${server.javaAddress}:${server.javaPort}\nBedrock: ${server.address}:${server.port}\n${server.website}',
          subject: server.name,
          sharePositionOrigin: origin.localToGlobal(Offset.zero) & origin.size,
        ),
      );
    } catch (error) {
      debugPrint('Server sharing unavailable: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Unable to share this server. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
                    ServerBanner(server: server),
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
                                      onPressed: _copyAddress,
                                      style: _outline(AppColors.onPrimary),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              _copied
                                                  ? 'COPIED!'
                                                  : server.address,
                                              textAlign: _copied
                                                  ? TextAlign.center
                                                  : TextAlign.start,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Icon(
                                            _copied
                                                ? Icons.check_circle
                                                : Icons.content_copy,
                                            color: _copied
                                                ? AppColors.serverAction
                                                : AppColors.onPrimary,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  SizedBox(
                                    width: 50,
                                    child: Builder(
                                      builder: (shareContext) => OutlinedButton(
                                        key: const ValueKey('server-share'),
                                        onPressed: _sharing
                                            ? null
                                            : () => _share(shareContext),
                                        style: _outline(AppColors.onPrimary),
                                        child: const Icon(
                                          Icons.share,
                                          size: 23,
                                          semanticLabel: 'Share server',
                                        ),
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
                        onPressed: _openingWebsite || server.website.isEmpty
                            ? null
                            : _website,
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: SpecialOfferAd(),
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
}
