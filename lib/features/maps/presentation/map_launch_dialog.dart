import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:share_plus/share_plus.dart';

import '../../../common/widgets/ad_placements.dart';
import '../../../common/widgets/app_text.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/downloaded_map.dart';
import '../models/map_catalog.dart';

class MapLaunchDialog extends StatefulWidget {
  const MapLaunchDialog({
    super.key,
    required this.item,
    required this.file,
    required this.monetization,
    required this.onMissingFile,
  });

  final MapItem item;
  final DownloadedMap file;
  final AppMonetization monetization;
  final VoidCallback onMissingFile;

  @override
  State<MapLaunchDialog> createState() => _MapLaunchDialogState();
}

class _MapLaunchDialogState extends State<MapLaunchDialog> {
  Timer? _timer;
  int _remaining = 15;
  bool _ready = false;
  bool _sharing = false;
  String? _error;

  bool get _canShowAd =>
      mounted &&
      !widget.monetization.isPro &&
      ModalRoute.of(context)?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        timer.cancel();
        setState(() => _remaining = 0);
        unawaited(_finishPreparation());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canShowAd) {
        unawaited(
          widget.monetization.interstitialAds.preload(
            canLoad: () => _canShowAd,
          ),
        );
      }
    });
  }

  Future<void> _finishPreparation() async {
    try {
      if (_canShowAd) {
        // Uses the existing session cooldown. Pro never enters this call.
        await widget.monetization.maybeShowInterstitial(
          canShow: () => _canShowAd,
        );
      }
    } catch (error) {
      debugPrint('Map launch ad unavailable: $error');
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _share(BuildContext buttonContext) async {
    if (!_ready || _sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      if (!await File(widget.file.path).exists()) {
        if (!mounted) return;
        widget.onMissingFile();
        Navigator.pop(context);
        return;
      }
      if (!mounted || !buttonContext.mounted) return;
      final origin = buttonContext.findRenderObject() as RenderBox;
      final extension = widget.file.filename.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'zip' => 'application/zip',
        _ => 'application/octet-stream',
      };
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.file.path, mimeType: mime)],
          subject: widget.item.name,
          sharePositionOrigin: origin.localToGlobal(Offset.zero) & origin.size,
        ),
      );
    } catch (error) {
      debugPrint('Downloaded map sharing unavailable: $error');
      if (mounted) {
        setState(() => _error = 'Unable to share this map. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _heading() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        'Launch World',
        style: AppTextStyles.gameHeader.copyWith(fontSize: 28),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      AppText(
        widget.item.name,
        style: AppTextStyles.onPrimaryPixelBody.copyWith(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => MonetizationScope(
    controller: widget.monetization,
    child: ListenableBuilder(
      listenable: widget.monetization,
      builder: (context, _) => Material(
        key: const ValueKey('map-launch-overlay'),
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              if (!_ready) ...[
                Align(
                  alignment: const Alignment(0, -.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _heading(),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(
                        radius: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      AppText(
                        _remaining > 0
                            ? 'Please wait ${_remaining}s'
                            : 'Preparing world...',
                        style: AppTextStyles.onPrimaryPixelBody.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Positioned.fill(
                  top: 48,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          children: [
                            _heading(),
                            const SizedBox(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: AppColors.primary,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.file.filename,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      color: AppColors.text,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const AppText(
                                    'Share with Minecraft',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.pixelBodyLarge,
                                  ),
                                  const SizedBox(height: 10),
                                  const AppText(
                                    'Choose Minecraft or Save to Files from the share sheet.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.dialogBody,
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.monetization.isPro) ...[
                              const SizedBox(height: 24),
                              const SpecialOfferAd(),
                            ],
                            const SizedBox(height: 28),
                            Builder(
                              builder: (buttonContext) => TextButton.icon(
                                key: const ValueKey('launch-world'),
                                onPressed: _sharing
                                    ? null
                                    : () => _share(buttonContext),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.onPrimary,
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                icon: _sharing
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.rocket_launch, size: 22),
                                label: AppText(
                                  _sharing ? 'Opening...' : 'Launch World',
                                  style: AppTextStyles.onPrimaryPixelBody
                                      .copyWith(fontSize: 20),
                                ),
                              ),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: AppText(
                                  _error!,
                                  style: AppTextStyles.onPrimaryPixelBody,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: const ValueKey('close-map-launch'),
                  tooltip: context.tr('Close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.onPrimary,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
