import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/monetization/ad_units.dart';
import '../../core/monetization/ads_runtime.dart';
import '../../core/monetization/app_monetization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text.dart';

class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) => _placement(context, AdPlacement.banner);
}

class SpecialOfferAd extends StatelessWidget {
  const SpecialOfferAd({super.key});

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.of(context)) return const SizedBox.shrink();
    return _placement(context, AdPlacement.native);
  }
}

Widget _placement(BuildContext context, AdPlacement placement) {
  final access = MonetizationScope.maybeOf(context);
  if (access == null ||
      access.isPro ||
      !access.adsRuntime.available ||
      AdUnits.id(placement).isEmpty) {
    return const SizedBox.shrink();
  }
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.floor();
      if (width <= 0 || (placement == AdPlacement.native && width < 320)) {
        return const SizedBox.shrink();
      }
      return _SdkAdView(
        key: ValueKey((
          access.adsRuntime,
          access.adsRuntime.privacyRevision,
          placement,
          width,
        )),
        runtime: access.adsRuntime,
        placement: placement,
        width: width,
      );
    },
  );
}

class _SdkAdView extends StatefulWidget {
  const _SdkAdView({
    super.key,
    required this.runtime,
    required this.placement,
    required this.width,
  });
  final AdsRuntime runtime;
  final AdPlacement placement;
  final int width;

  @override
  State<_SdkAdView> createState() => _SdkAdViewState();
}

class _SdkAdViewState extends State<_SdkAdView> with WidgetsBindingObserver {
  AdWithView? _ad;
  Timer? _retryTimer;
  int _retryCount = 0;
  bool _loading = false;
  bool _ready = false;
  double _height = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  void _loaded(Ad ad) {
    if (!mounted || !identical(ad, _ad)) return;
    _retryTimer?.cancel();
    _retryCount = 0;
    setState(() => _ready = true);
  }

  bool get _canLoad =>
      mounted &&
      widget.runtime.available &&
      TickerMode.of(context) &&
      ModalRoute.of(context)?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  void _scheduleRetry() {
    if (!mounted || !widget.runtime.available) return;
    _retryTimer?.cancel();
    // A temporary network failure must not hide the placement for the session.
    final seconds = 30 * (1 << math.min(_retryCount, 2));
    _retryCount++;
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(_load()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_ready && _ad == null) {
      unawaited(_load());
    }
  }

  void _failed(Ad ad, LoadAdError error) {
    debugPrint('${widget.placement} ad failed: $error');
    ad.dispose();
    if (mounted && identical(ad, _ad)) {
      setState(() {
        _ad = null;
        _ready = false;
      });
      _scheduleRetry();
    }
  }

  Future<void> _load() async {
    if (!mounted || _loading || _ad != null) return;
    if (!_canLoad) {
      _scheduleRetry();
      return;
    }
    _retryTimer?.cancel();
    _loading = true;
    try {
      if (!await widget.runtime.prepare(
            canShowConsent: () =>
                mounted && ModalRoute.of(context)?.isCurrent == true,
          ) ||
          !mounted) {
        _scheduleRetry();
        return;
      }
      if (widget.placement == AdPlacement.banner) {
        final size =
            await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              widget.width.toInt(),
            );
        if (!mounted) return;
        if (size == null) {
          _scheduleRetry();
          return;
        }
        _height = size.height.toDouble();
        _ad = BannerAd(
          adUnitId: AdUnits.id(AdPlacement.banner),
          size: size,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: _loaded,
            onAdFailedToLoad: _failed,
            onAdOpened: (_) => widget.runtime.beginFullscreen(this),
            onAdClosed: (_) =>
                widget.runtime.endFullscreen(this, wasShown: true),
          ),
        );
      } else {
        _height = 180;
        _ad = NativeAd(
          adUnitId: AdUnits.id(AdPlacement.native),
          request: const AdRequest(),
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.small,
            mainBackgroundColor: AppColors.surface,
            cornerRadius: 12,
            callToActionTextStyle: NativeTemplateTextStyle(
              textColor: AppColors.onPrimary,
              backgroundColor: AppColors.primary,
              style: NativeTemplateFontStyle.bold,
              size: 16,
            ),
            primaryTextStyle: NativeTemplateTextStyle(
              textColor: AppColors.text,
              size: 17,
            ),
            secondaryTextStyle: NativeTemplateTextStyle(
              textColor: AppColors.textSecondary,
              size: 14,
            ),
          ),
          listener: NativeAdListener(
            onAdLoaded: _loaded,
            onAdFailedToLoad: _failed,
            onAdOpened: (_) => widget.runtime.beginFullscreen(this),
            onAdClosed: (_) =>
                widget.runtime.endFullscreen(this, wasShown: true),
          ),
        );
      }
      await _ad!.load();
    } catch (error) {
      debugPrint('Ad placement unavailable: $error');
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _ready = false);
      _scheduleRetry();
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _ad?.dispose();
    widget.runtime.endFullscreen(this, wasShown: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ad == null) return const SizedBox.shrink();
    final banner = widget.placement == AdPlacement.banner;
    final adWidth = banner
        ? widget.width.toDouble()
        : math.min(widget.width.toDouble() - 4, 400.0);
    final content = SizedBox(
      width: adWidth,
      height: _height,
      child: AdWidget(ad: _ad!),
    );
    if (banner) {
      return ColoredBox(
        key: const ValueKey('bottom-ad-banner'),
        color: AppColors.adSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(child: content),
        ),
      );
    }
    // The SDK owns all ad assets and click actions, including the real store UI.
    return Container(
      key: const ValueKey('special-offer-ad'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: AppRadii.standard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: AppColors.primary,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                const AppText('Advertisement', style: AppTextStyles.pixelBody),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lock,
                    borderRadius: AppRadii.standard,
                  ),
                  child: const AppText(
                    'Special Offer',
                    style: AppTextStyles.pixelBody,
                  ),
                ),
              ],
            ),
          ),
          Center(child: content),
        ],
      ),
    );
  }
}
