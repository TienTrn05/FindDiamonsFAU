import '../../../common/widgets/app_text.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/digging_pickaxe.dart';
import '../../../common/widgets/game_header.dart';
import '../../../common/widgets/game_text_field.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../core/responsive/app_layout.dart';
import '../../digging/presentation/found_ores_page.dart';
import '../../../core/models/search_record.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/find_bloc.dart';
import '../data/api_find_repository.dart';
import '../data/find_repository.dart';
import '../models/find_catalog.dart';

class FindPage extends StatefulWidget {
  const FindPage({
    super.key,
    required this.onGoPro,
    required this.onHelp,
    this.onFound,
    this.onReveal,
    this.onFoundChanged,
    this.repository,
  });
  final VoidCallback onGoPro;
  final VoidCallback onHelp;
  final Future<void> Function(SearchRecord)? onFound;
  final Future<void> Function(String id, int count)? onReveal;
  final Future<void> Function(String id, int index, bool found)? onFoundChanged;
  final FindRepository? repository;
  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  late final FindBloc _bloc = FindBloc(widget.repository ?? ApiFindRepository())
    ..load();
  final _form = GlobalKey<FormState>();
  final _digging = GlobalKey();
  final _x = TextEditingController();
  final _z = TextEditingController();
  final _seed = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final access = MonetizationScope.maybeOf(context);
    if (access == null || access.isPro || !TickerMode.of(context)) return;
    // Use the time spent filling in the form to prepare the first rewarded ad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        access.rewardedAds.preload(
          canLoad: () =>
              mounted &&
              !access.isPro &&
              TickerMode.of(context) &&
              ModalRoute.of(context)?.isCurrent == true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _bloc.dispose();
    _x.dispose();
    _z.dispose();
    _seed.dispose();
    super.dispose();
  }

  String? _coordinate(String? value) =>
      int.tryParse(value?.trim() ?? '') == null ? 'Enter a whole number' : null;

  Future<void> _search() async {
    if (_bloc.searching || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loaderContext = _digging.currentContext;
      if (mounted && loaderContext != null) {
        Scrollable.ensureVisible(
          loaderContext,
          duration: const Duration(milliseconds: 180),
          alignment: .5,
        );
      }
    });
    try {
      final record = await _bloc.search(
        x: int.parse(_x.text.trim()),
        z: int.parse(_z.text.trim()),
        seed: _seed.text.trim(),
      );
      if (record == null || !mounted) return;
      await widget.onFound?.call(record);
      if (mounted &&
          TickerMode.of(context) &&
          ModalRoute.of(context)?.isCurrent == true) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => FoundOresPage(
              monetization: MonetizationScope.maybeOf(context),
              record: record,
              onGoPro: widget.onGoPro,
              onHelp: widget.onHelp,
              onReveal: widget.onReveal == null
                  ? null
                  : (count) => widget.onReveal!(record.id, count),
              onFoundChanged: widget.onFoundChanged == null
                  ? null
                  : (index, found) =>
                        widget.onFoundChanged!(record.id, index, found),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              error is HttpException ? error.message : error.toString(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ResourceView<FindCatalog>(
    controller: _bloc,
    builder: (context, catalog) => Column(
      children: [
        GameHeader(
          title: catalog.title,
          contentHeight: AppLayout.gameHeaderHeight * .6,
        ),
        Expanded(
          child: Form(
            key: _form,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: const PageStorageKey('find-form'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GameTextField(
                        key: const ValueKey('player-x'),
                        label: 'Player X',
                        controller: _x,
                        numeric: true,
                        readOnly: _bloc.searching,
                        validator: _coordinate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GameTextField(
                        key: const ValueKey('player-z'),
                        label: 'Player Z',
                        controller: _z,
                        numeric: true,
                        readOnly: _bloc.searching,
                        validator: _coordinate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                GameTextField(
                  key: const ValueKey('world-seed'),
                  label: 'World seed (numbers/letters)',
                  controller: _seed,
                  readOnly: _bloc.searching,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your world seed'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppText(
                  'Version (Scroll to change)',
                  style: AppTextStyles.fieldLabel,
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  key: const ValueKey('game-version'),
                  initialValue: _bloc.version.id,
                  isExpanded: true,
                  decoration: AppTheme.gameInputDecoration,
                  style: AppTextStyles.fieldValue,
                  items: catalog.versions
                      .map(
                        (version) => DropdownMenuItem(
                          key: ValueKey('game-version-${version.id}'),
                          value: version.id,
                          child: AppText(
                            '${version.apiVersion} Java',
                            style: AppTextStyles.fieldValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _bloc.searching
                      ? null
                      : (value) {
                          if (value != null) _bloc.selectVersion(value);
                        },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Previous ore'),
                      onPressed: _bloc.searching
                          ? null
                          : () => _bloc.changeOre(-1),
                      icon: const Icon(
                        Icons.arrow_left,
                        size: 52,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          OreIcon(
                            ore: Ore.values.firstWhere(
                              (ore) => ore.name == _bloc.ore.id,
                            ),
                            size: 54,
                          ),
                          AppText(
                            _bloc.ore.name,
                            style: AppTextStyles.pixelTitle,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Next ore'),
                      onPressed: _bloc.searching
                          ? null
                          : () => _bloc.changeOre(1),
                      icon: const Icon(
                        Icons.arrow_right,
                        size: 52,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_bloc.searching)
                  SizedBox(
                    key: _digging,
                    height: 180,
                    child: const DiggingPickaxe(),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          key: const ValueKey('open-help'),
                          label: 'Help!',
                          pixel: true,
                          shadow: false,
                          backgroundColor: AppColors.danger,
                          onPressed: widget.onHelp,
                        ),
                      ),
                      if (MonetizationScope.maybeOf(context)?.isPro !=
                          true) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            key: const ValueKey('open-premium'),
                            label: 'Go Pro!',
                            leading: const Icon(
                              Icons.diamond,
                              color: AppColors.indicatorActive,
                              size: 26,
                            ),
                            trailing: const Icon(
                              Icons.diamond,
                              color: AppColors.indicatorActive,
                              size: 26,
                            ),
                            pixel: true,
                            shadow: false,
                            backgroundColor: AppColors.danger,
                            onPressed: widget.onGoPro,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  key: const ValueKey('start-digging'),
                  label: _bloc.searching ? 'Please wait...' : 'Start digging',
                  trailing: _bloc.searching
                      ? null
                      : const Icon(
                          Icons.arrow_forward,
                          color: AppColors.onPrimary,
                          size: 26,
                        ),
                  pixel: true,
                  shadow: false,
                  backgroundColor: AppColors.action,
                  onPressed: _bloc.searching ? null : _search,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
