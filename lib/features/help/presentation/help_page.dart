import '../../../common/widgets/game_back_button.dart';
import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/app_page_frame.dart';
import '../../../common/widgets/mining_surface.dart';
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
import 'help_emblem.dart';
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
  final _faqAnchor = GlobalKey();
  final _search = TextEditingController();
  bool _faqsExpanded = false;

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
    _search.dispose();
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

  Widget _flag(HelpLanguage language, {double size = 28}) => ClipOval(
    child: Image.asset(
      'assets/images/flags/${language.flag}.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    ),
  );

  Widget _language(HelpLanguage language) {
    final selected =
        Localizations.localeOf(context).languageCode == language.code;
    final controller = AppLanguageScope.maybeOf(context);
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        key: ValueKey('help-language-${language.code}'),
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.stone,
              size: 23,
            ),
            const SizedBox(width: 18),
            _flag(language),
          ],
        ),
        title: AppText(language.label, style: AppTextStyles.helpOnDarkBody),
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

  void _toggleFaqs() {
    setState(() => _faqsExpanded = !_faqsExpanded);
    if (!_faqsExpanded) return;
    _scrollToFaq();
  }

  void _scrollToFaq() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = _faqAnchor.currentContext;
      if (mounted && anchor != null) {
        Scrollable.ensureVisible(
          anchor,
          alignment: 0,
          duration: const Duration(milliseconds: 220),
        );
      }
    });
  }

  Widget _cardHeader({
    required String title,
    required String hint,
    required String kind,
    VoidCallback? onTap,
    Key? key,
    bool expanded = false,
    bool chevron = true,
  }) => InkWell(
    key: key,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          HelpEmblem(kind: kind, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, style: AppTextStyles.helpOnDarkHeading),
                const SizedBox(height: 5),
                AppText(hint, style: AppTextStyles.helpOnDarkBody),
              ],
            ),
          ),
          if (chevron) ...[
            const SizedBox(width: 8),
            Icon(
              expanded ? Icons.expand_less : Icons.chevron_right,
              color: AppColors.stone,
              size: 24,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _panel({required Widget child, bool highlighted = false}) =>
      MiningPanel(
        color: AppColors.helpSurface,
        borderColor: highlighted ? AppColors.primary : AppColors.helpBorder,
        padding: EdgeInsets.zero,
        child: child,
      );

  Widget _faq(HelpFaq faq) {
    final expanded = _bloc.expandedFaq == faq.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _panel(
        highlighted: expanded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              value: context.tr(expanded ? 'Expanded' : 'Collapsed'),
              child: InkWell(
                key: ValueKey('help-faq-${faq.id}'),
                onTap: () {
                  _bloc.toggleFaq(faq.id);
                  _scrollToFaq();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      HelpEmblem(
                        kind: faq.illustration.isEmpty
                            ? faq.id
                            : faq.illustration,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          faq.question,
                          style: AppTextStyles.helpOnDarkHeading.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.expand_more,
                          color: AppColors.stone,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              onEnd: _scrollToFaq,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(color: AppColors.helpBorder, height: 1),
                          const SizedBox(height: 12),
                          AppText(
                            faq.before,
                            style: AppTextStyles.helpOnDarkBody,
                          ),
                          if (faq.illustration.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            HelpFaqIllustration(kind: faq.illustration),
                          ],
                          if (faq.after.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            AppText(
                              faq.after,
                              style: AppTextStyles.helpOnDarkBody,
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageCard(HelpContent content) {
    final code = Localizations.localeOf(context).languageCode;
    final selected = content.languages.firstWhere(
      (language) => language.code == code,
      orElse: () => content.languages.first,
    );
    return _panel(
      highlighted: _bloc.languageExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            value: context.tr(
              _bloc.languageExpanded ? 'Expanded' : 'Collapsed',
            ),
            child: _cardHeader(
              key: const ValueKey('help-language'),
              title: 'Change language',
              hint: 'Select your preferred language.',
              kind: 'language',
              onTap: _bloc.toggleLanguages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 12, 12),
            child: MiningPanel(
              color: AppColors.helpRaised,
              borderColor: AppColors.helpBorder,
              padding: EdgeInsets.zero,
              onTap: _bloc.toggleLanguages,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _flag(selected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        selected.label,
                        style: AppTextStyles.helpOnDarkBody,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _bloc.languageExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.stone,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_bloc.languageExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: MiningPanel(
                color: AppColors.helpSurface,
                borderColor: AppColors.helpBorder,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < content.languages.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: AppColors.helpBorder,
                          indent: 16,
                          endIndent: 16,
                        ),
                      _language(content.languages[i]),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _faqSection(HelpContent content) {
    final query = _search.text.trim().toLowerCase();
    final faqs = content.faqs
        .where(
          (faq) => [
            faq.question,
            faq.before,
            faq.after,
          ].any((text) => context.tr(text).toLowerCase().contains(query)),
        )
        .toList();
    return Column(
      key: _faqAnchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(
          highlighted: _faqsExpanded,
          child: _cardHeader(
            key: const ValueKey('help-faq'),
            title: 'FAQ',
            hint: 'Common questions and answers.',
            kind: 'faq',
            onTap: _toggleFaqs,
            expanded: _faqsExpanded,
          ),
        ),
        if (_faqsExpanded) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('help-faq-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.helpOnDarkBody,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: context.tr('Search questions...'),
              hintStyle: AppTextStyles.helpOnDarkBody.copyWith(
                color: AppColors.caveMuted,
              ),
              filled: true,
              fillColor: AppColors.helpSurface,
              prefixIcon: const Icon(Icons.search, color: AppColors.stone),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr('Clear search'),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: AppColors.stone),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadii.small,
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadii.small,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (faqs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppText(
                'No matching questions. Try another search.',
                style: AppTextStyles.helpOnDarkBody,
                textAlign: TextAlign.center,
              ),
            ),
          for (final faq in faqs) _faq(faq),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AppPageFrame(
    child: RepaintBoundary(
      key: const ValueKey('help-preview'),
      child: Scaffold(
        backgroundColor: AppColors.cave,
        body: MiningBackground(
          asset: 'assets/images/help_cave.png',
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                _HelpHeader(
                  compact: constraints.maxHeight < 550,
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: ResourceView<HelpContent>(
                      controller: _bloc,
                      builder: (context, content) => SingleChildScrollView(
                        key: const PageStorageKey('help-scroll'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _panel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _cardHeader(
                                    title: 'Restore purchases',
                                    hint: content.restoreHint,
                                    kind: 'restore',
                                    chevron: false,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      14,
                                    ),
                                    child: HelpActionButton(
                                      key: const ValueKey('help-restore'),
                                      label: _bloc.restoring
                                          ? 'Restoring...'
                                          : 'Restore purchases',
                                      onPressed: _bloc.restoring
                                          ? null
                                          : _restore,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _panel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _cardHeader(
                                    title: 'Re-visit tutorial',
                                    hint: 'View the tutorial again.',
                                    kind: 'tutorial',
                                    onTap: _tutorial,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      14,
                                    ),
                                    child: HelpActionButton(
                                      key: const ValueKey('help-tutorial'),
                                      label: 'View tutorial',
                                      light: true,
                                      onPressed: _tutorial,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _languageCard(content),
                            const SizedBox(height: 12),
                            _faqSection(content),
                            const SizedBox(height: 12),
                            _panel(
                              child: _cardHeader(
                                key: const ValueKey('help-privacy'),
                                title: 'Privacy Policy',
                                hint: 'See Term and Privacy of App',
                                kind: 'privacy',
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => HelpPolicyDialog(
                                    sections: content.policySections,
                                  ),
                                ),
                              ),
                            ),
                            _adPrivacy(),
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
      ),
    ),
  );
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.compact, required this.onBack});
  final bool compact;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: compact ? 108 : 186),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/help_cave.png'),
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    ),
    child: ColoredBox(
      color: AppColors.cave.withValues(alpha: .22),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 48,
                  child: GameBackButton(
                    key: const ValueKey('game-header-back'),
                    size: 48,
                    onPressed: onBack,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AppText(
                      'Help!',
                      style: AppTextStyles.title.copyWith(
                        fontSize: compact ? 28 : 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        shadows: const [
                          Shadow(color: AppColors.cave, offset: Offset(3, 3)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HelpEmblem(kind: 'pickaxe', size: compact ? 32 : 44),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                'Get support and learn how to use Ore Scout',
                textAlign: TextAlign.center,
                style: AppTextStyles.helpOnDarkBody.copyWith(
                  fontSize: 12,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
