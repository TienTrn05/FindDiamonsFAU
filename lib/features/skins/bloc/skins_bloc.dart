import '../../../core/bloc/resource_controller.dart';
import '../data/skins_repository.dart';
import '../models/skin_item.dart';

class SkinsBloc extends ResourceController<List<SkinItem>> {
  SkinsBloc(this.repository);
  final SkinsRepository repository;
  String? selectedId;
  bool walking = false;

  bool isLocked(SkinItem item, {required bool isPro}) =>
      item.locked && !isPro && !repository.unlocked.contains(item.id);

  Future<bool> unlock(String id) async {
    final saved = await repository.unlock(id);
    refresh();
    return saved;
  }

  @override
  Future<List<SkinItem>> fetch() => repository.load();

  SkinItem get selected => data!.firstWhere(
    (item) => item.id == selectedId,
    orElse: () => data!.first,
  );

  void select(SkinItem item) {
    selectedId = item.id;
    refresh();
  }

  void setWalking(bool value) {
    walking = value;
    refresh();
  }
}
