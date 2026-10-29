import '../../../core/bloc/resource_controller.dart';
import '../data/skins_repository.dart';
import '../models/skin_item.dart';

class SkinsBloc extends ResourceController<List<SkinItem>> {
  SkinsBloc(this.repository);
  final SkinsRepository repository;
  String? selectedId;
  bool walking = false;
  String _query = '';
  int _searchGeneration = 0;
  bool _disposed = false;

  bool isLocked(SkinItem item, {required bool isPro}) =>
      item.locked && !isPro && !repository.unlocked.contains(item.id);

  Future<bool> unlock(String id) async {
    final saved = await repository.unlock(id);
    refresh();
    return saved;
  }

  @override
  Future<List<SkinItem>> fetch() => repository.load(query: _query);

  Future<void> search(String query) async {
    _query = query.trim();
    final generation = ++_searchGeneration;
    loading = true;
    error = null;
    refresh();
    try {
      final results = await repository.load(query: _query);
      if (_disposed || generation != _searchGeneration) return;
      data = results;
      if (!results.any((item) => item.id == selectedId)) selectedId = null;
    } catch (exception) {
      if (!_disposed && generation == _searchGeneration) error = exception;
    } finally {
      if (!_disposed && generation == _searchGeneration) {
        loading = false;
        refresh();
      }
    }
  }

  SkinItem? get selectedOrNull {
    final items = data;
    if (items == null || items.isEmpty) return null;
    return items.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => items.first,
    );
  }

  SkinItem get selected => selectedOrNull!;

  void select(SkinItem item) {
    selectedId = item.id;
    refresh();
  }

  void setWalking(bool value) {
    walking = value;
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
