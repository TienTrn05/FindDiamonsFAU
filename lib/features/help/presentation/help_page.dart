import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/game_header.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/monetization/rewarded_ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/presentation/onboarding_flow.dart';
import '../bloc/help_bloc.dart';
import '../data/help_repository.dart';
import '../models/help_content.dart';
import 'help_action_button.dart';
import 'help_faq_illustration.dart';
import 'help_policy_dialog.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key, this.repository, this.onRestore});
  final HelpRepository? repository;
  final Future<bool> Function()? onRestore;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  Future<bool>? _privacyRequired;

  Widget _adPrivacy() {
    final ads = MonetizationScope.maybeOf(context)?.rewardedAds;
    if (ads is! GoogleRewardedAdService) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _privacyRequired ??= ads.privacyOptionsRequired(),
      builder: (context, snapshot) => snapshot.data == true
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: HelpActionButton(
                key: const ValueKey('help-ad-privacy'),
                label: 'Ad privacy choices',
                light: true,
                onPressed: () async {
                  try {
                    await ads.showPrivacyOptions();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: AppText(
                            'Unable to open ad privacy choices. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  late final HelpBloc _bloc = HelpBloc(
    widget.repository ?? const JsonHelpRepository(),
    onRestore:
        widget.onRestore ??
        (MonetizationScope.maybeOf(context)?.onRestore == null
            ? null
            : MonetizationScope.maybeOf(context)!.restore),
  )..load();

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final message = await _bloc.restore();
    if (mounted && message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(message)));
    }
  }

  Future<void> _selectLanguage(String code) async {
    final controller = AppLanguageScope.maybeOf(context);
    if (controller == null) return;
    try {
      await controller.select(code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              context.tr('Unable to change language. Please try again.'),
            ),
          ),
        );
      }
    }
  }

  Widget _language(HelpLanguage language) {
    final selected =
        Localizations.localeOf(context).languageCode == language.code;
    final controller = AppLanguageScope.maybeOf(context);
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        key: ValueKey('help-language-${language.code}'),
        minTileHeight: 44,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/flags/${language.flag}.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
        title: AppText(language.label, style: AppTextStyles.helpBody),
        onTap: controller?.saving == true
            ? null
            : () => _selectLanguage(language.code),
      ),
    );
  }

  void _tutorial() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/help/tutorial'),
      builder: (context) => OnboardingFlow(
        reviewTutorial: true,
        onComplete: () => Navigator.pop(context),
      ),
    ),
  );

  Widget _faq(HelpFaq faq) {
    final expanded = _bloc.expandedFaq == faq.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            value: context.tr(expanded ? 'Expanded' : 'Collapsed'),
            child: HelpActionButton(
              key: ValueKey('help-faq-${faq.id}'),
              label: faq.question,
              light: true,
              alignLeft: true,
              onPressed: () => _bloc.toggleFaq(faq.id),
              trailing: AnimatedRotation(
                turns: expanded ? .5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(faq.before, style: AppTextStyles.helpBody),
                        const SizedBox(height: AppSpacing.md),
                        HelpFaqIllustration(kind: faq.illustration),
                        const SizedBox(height: AppSpacing.md),
                        AppText(faq.after, style: AppTextStyles.helpBody),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPageFrame(
    child: RepaintBoundary(
      key: const ValueKey('help-preview'),
      child: Scaffold(
        backgroundColor: AppColors.adSurface,
        body: Column(
          children: [
            GameHeader(
              title: 'Help!',
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: ResourceView<HelpContent>(
                  controller: _bloc,
                  builder: (context, content) => SingleChildScrollView(
                    key: const PageStorageKey('help-scroll'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppText(
                          'Restore purchases',
                          style: AppTextStyles.helpHeading,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          content.restoreHint,
                          style: AppTextStyles.helpBody.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        HelpActionButton(
                          key: const ValueKey('help-restore'),
                          label: _bloc.restoring
                              ? 'Restoring...'
                              : 'Restore purchases',
                          onPressed: _bloc.restoring ? null : _restore,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const AppText(
                          'Re-visit tutorial',
                          style: AppTextStyles.helpHeading,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        HelpActionButton(
                          key: const ValueKey('help-tutorial'),
                          label: 'View tutorial',
                          onPressed: _tutorial,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          value: context.tr(
                            _bloc.languageExpanded ? 'Expanded' : 'Collapsed',
                          ),
                          child: ListTile(
                            key: const ValueKey('help-language'),
                            contentPadding: EdgeInsets.zero,
                            title: const AppText(
                              'Change language',
                              style: AppTextStyles.helpHeading,
                            ),
                            trailing: AnimatedRotation(
                              turns: _bloc.languageExpanded ? .5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.text,
                                size: 30,
                              ),
                            ),
                            onTap: _bloc.toggleLanguages,
                          ),
                        ),
                        if (_bloc.languageExpanded)
                          for (final language in content.languages)
                            _language(language),
                        const SizedBox(height: AppSpacing.sm),
                        const AppText('FAQ', style: AppTextStyles.helpHeading),
                        const SizedBox(height: AppSpacing.xs),
                        for (final faq in content.faqs) _faq(faq),
                        const SizedBox(height: AppSpacing.xs),
                        const AppText(
                          'Privacy Policy',
                          style: AppTextStyles.helpHeading,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        HelpActionButton(
                          key: const ValueKey('help-privacy'),
                          label: 'See Term and Privacy of App',
                          light: true,
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => HelpPolicyDialog(
                              sections: content.policySections,
                            ),
                          ),
                        ),

                        _adPrivacy(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
