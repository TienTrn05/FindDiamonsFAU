import '../../../common/widgets/app_text.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_art.dart';
import '../../../common/widgets/digging_pickaxe.dart';
import '../../../common/widgets/game_text_field.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/resource_view.dart';
import '../../digging/presentation/found_ores_page.dart';
import '../../../core/models/search_record.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/mining_style.dart';
import '../../../common/widgets/mining_viewport.dart';
import '../bloc/find_bloc.dart';
import '../data/api_find_repository.dart';
import '../data/find_repository.dart';
import '../models/find_catalog.dart';
import 'ore_picker_page.dart';

class FindPage extends StatefulWidget {
  const FindPage({
    super.key,
    required this.onGoPro,
    required this.onHelp,
    this.onFound,
    this.onReveal,
    this.onFoundChanged,
    this.repository,
    this.onBack,
    this.showBackground = true,
  });
  final VoidCallback onGoPro;
  final VoidCallback onHelp;
  final Future<void> Function(SearchRecord)? onFound;
  final Future<void> Function(String id, int count)? onReveal;
  final Future<void> Function(String id, int index, bool found)? onFoundChanged;
  final FindRepository? repository;
  final VoidCallback? onBack;
  final bool showBackground;
  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  late final FindBloc _bloc = FindBloc(widget.repository ?? ApiFindRepository())
    ..load();
  final _form = GlobalKey<FormState>();
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

  Future<void> _changeOre() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/find/ores'),
        builder: (_) =>
            OrePickerPage(ores: _bloc.availableOres, selectedId: _bloc.ore.id),
      ),
    );
    if (mounted && id != null) _bloc.selectOre(id);
  }

  static InputDecoration _input(bool compact) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Color(0xFFF7F8FA),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: compact ? 7 : 10,
    ),
    hintStyle: TextStyle(
      color: const Color(0xFF989EAA),
      fontSize: compact ? 12 : 13,
    ),
    helperText: compact ? null : ' ',
    helperStyle: const TextStyle(fontSize: 10, height: 1),
    errorStyle: const TextStyle(fontSize: 10, height: 1),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: MiningStyle.edge, width: 2),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: MiningStyle.edge, width: 2),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: MiningStyle.cyan, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final content = ResourceView<FindCatalog>(
      controller: _bloc,
      builder: (context, catalog) => SafeArea(
        bottom: false,
        child: Form(
          key: _form,
          child: MiningViewport(
            minimumHeight: 730,
            compactHeight: 560,
            builder: (context, landscape, compact) => Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                compact ? 8 : 12,
                14,
                compact ? 8 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(compact),
                  SizedBox(height: compact ? 8 : 14),
                  Expanded(
                    child: landscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: _world(catalog, compact),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 5,
                                child: _actions(context, compact),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _world(catalog, compact),
                              SizedBox(height: compact ? 8 : 12),
                              Expanded(child: _actions(context, compact)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.showBackground
        ? MiningBackground(vivid: true, bottomOpacity: .4, child: content)
        : content;
  }

  Widget _header(bool compact) => SizedBox(
    height: compact ? 44 : 56,
    child: Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText('Find Ore', style: MiningStyle.heading),
                const SizedBox(height: 6),
                AppText(
                  'ENTER YOUR WORLD DETAILS',
                  style: MiningStyle.label.copyWith(
                    color: const Color(0xFFBEC8D5),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _world(FindCatalog catalog, bool compact) => MiningPanel(
    key: const ValueKey('world-information'),
    color: MiningStyle.stone,
    borderColor: MiningStyle.edge,
    vivid: true,
    padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 14, compact ? 8 : 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.public, color: Color(0xFF168C39), size: 23),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(
                'WORLD INFORMATION',
                style: MiningStyle.label.copyWith(
                  color: MiningStyle.muted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFCDD0D8), height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                key: 'player-x',
                compact: compact,
                label: 'Player X',
                hint: 'e.g. 1000',
                controller: _x,
                numeric: true,
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                key: 'player-z',
                compact: compact,
                label: 'Player Z',
                hint: 'e.g. -500',
                controller: _z,
                numeric: true,
                icon: Icons.person,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _field(
          key: 'world-seed',
          compact: compact,
          label: 'World seed (numbers/letters)',
          hint: 'e.g. 123456789 or myworld',
          controller: _seed,
          icon: Icons.grass,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.settings, size: 18, color: MiningStyle.muted),
            const SizedBox(width: 6),
            Expanded(
              child: AppText(
                'Version (Scroll to change)',
                style: MiningStyle.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(canvasColor: MiningStyle.stone),
          child: DropdownButtonFormField<String>(
            key: const ValueKey('game-version'),
            initialValue: _bloc.version.id,
            isExpanded: true,
            dropdownColor: MiningStyle.stone,
            iconEnabledColor: MiningStyle.muted,
            decoration: _input(compact).copyWith(helperText: null),
            style: MiningStyle.label,
            items: catalog.versions
                .map(
                  (version) => DropdownMenuItem(
                    key: ValueKey('game-version-${version.id}'),
                    value: version.id,
                    child: AppText(
                      version.label,
                      style: MiningStyle.label,
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
        ),
      ],
    ),
  );

  Widget _field({
    required String key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool numeric = false,
    required bool compact,
  }) => GameTextField(
    key: ValueKey(key),
    label: label,
    hintText: hint,
    controller: controller,
    icon: icon,
    iconColor: numeric ? MiningStyle.ink : MiningStyle.seedGreen,
    numeric: numeric,
    readOnly: _bloc.searching,
    labelStyle: MiningStyle.label.copyWith(fontSize: compact ? 12 : 14),
    labelSpacing: compact ? 3 : 6,
    valueStyle: MiningStyle.label.copyWith(
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w400,
    ),
    decoration: _input(compact),
    validator: numeric
        ? _coordinate
        : (value) => value == null || value.trim().isEmpty
              ? 'Enter your world seed'
              : null,
  );

  Widget _actions(BuildContext context, bool compact) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MiningPanel(
        key: const ValueKey('selected-ore'),
        color: MiningStyle.stone,
        borderColor: MiningStyle.edge,
        vivid: true,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            OreIcon(
              ore: Ore.values.firstWhere(
                (ore) => ore.name == _bloc.ore.id,
                orElse: () => Ore.stone,
              ),
              size: compact ? 40 : 58,
              mineralTint: _bloc.ore.id == 'diamond' ? MiningStyle.cyan : null,
              showCenterGem: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'SELECTED ORE',
                    style: MiningStyle.label.copyWith(
                      color: MiningStyle.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AppText(
                    _bloc.ore.name,
                    style: MiningStyle.cardTitle.copyWith(
                      fontSize: compact ? 18 : 21,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!compact)
                    AppText(
                      'Find valuable ores in your world',
                      style: MiningStyle.body.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: MiningButton(
                key: const ValueKey('change-ore'),
                label: 'Change',
                color: MiningStyle.steel,
                vivid: true,
                height: compact ? 36 : 44,
                fontSize: 12,
                onPressed: _bloc.searching ? null : _changeOre,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: compact ? 8 : 14),
      MiningButton(
        key: const ValueKey('start-digging'),
        label: _bloc.searching ? 'Please wait...' : 'Start digging',
        art: SizedBox.square(
          dimension: compact ? 28 : 42,
          child: _bloc.searching
              ? const DiggingPickaxe()
              : const MiningArt(MiningArtKind.pickaxe, size: 36),
        ),
        trailing: _bloc.searching ? null : Icons.arrow_forward,
        color: MiningStyle.cyan,
        foreground: Colors.white,
        vivid: true,
        height: compact ? 46 : 62,
        fontSize: compact ? 18 : 22,
        onPressed: _bloc.searching ? null : _search,
      ),
      SizedBox(height: compact ? 6 : 12),
      Row(
        children: [
          Expanded(
            child: MiningButton(
              key: const ValueKey('open-help'),
              label: 'Help!',
              icon: Icons.help,
              color: MiningStyle.steel,
              vivid: true,
              height: compact ? 40 : 46,
              fontSize: compact ? 12 : 14,
              onPressed: widget.onHelp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: MonetizationScope.maybeOf(context)?.isPro == true
                ? const SizedBox.shrink()
                : MiningButton(
                    key: const ValueKey('open-premium'),
                    label: 'Go Pro!',
                    art: MiningArt(
                      MiningArtKind.diamond,
                      size: compact ? 23 : 27,
                    ),
                    trailing: Icons.arrow_forward,
                    color: MiningStyle.gold,
                    vivid: true,
                    height: compact ? 40 : 46,
                    fontSize: compact ? 12 : 14,
                    onPressed: widget.onGoPro,
                  ),
          ),
        ],
      ),
      SizedBox(height: compact ? 6 : 12),
      const Expanded(child: SizedBox.shrink()),
    ],
  );
}
