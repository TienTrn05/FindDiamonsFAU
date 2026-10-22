import 'package:flutter/material.dart';

import '../../../common/widgets/reward_unlock_dialog.dart';
import '../../../common/widgets/voxel_character.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_spacing.dart';
import '../bloc/skins_bloc.dart';
import '../models/skin_item.dart';

class SkinUnlockDialog extends StatelessWidget {
  const SkinUnlockDialog({
    super.key,
    required this.item,
    required this.bloc,
    required this.monetization,
  });

  final SkinItem item;
  final SkinsBloc bloc;
  final AppMonetization monetization;

  Widget _character(String palette) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: VoxelCharacter(palette: palette),
  );

  @override
  Widget build(BuildContext context) => RewardUnlockDialog(
    keyPrefix: 'skin',
    title: 'Watch Ads to Unlock Skin',
    monetization: monetization,
    isLocked: () => bloc.isLocked(item, isPro: false),
    onUnlock: () => bloc.unlock(item.id),
    watchToUnlockMessage: 'Watch the ad to unlock this skin.',
    saveFailureMessage:
        'Skin unlocked for this session. Unable to save it on this device.',
    illustration: UnlockCardIllustration(
      left: _character('steve'),
      center: _character(item.palette),
      right: _character('explorer'),
    ),
  );
}
