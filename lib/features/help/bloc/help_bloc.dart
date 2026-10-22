import '../../../core/bloc/resource_controller.dart';
import '../data/help_repository.dart';
import '../models/help_content.dart';

class HelpBloc extends ResourceController<HelpContent> {
  HelpBloc(this.repository, {this.onRestore});
  final HelpRepository repository;
  final Future<bool> Function()? onRestore;
  String? expandedFaq;
  bool languageExpanded = false;
  bool restoring = false;

  @override
  Future<HelpContent> fetch() => repository.load();

  void toggleFaq(String id) {
    expandedFaq = expandedFaq == id ? null : id;
    refresh();
  }

  void toggleLanguages() {
    languageExpanded = !languageExpanded;
    refresh();
  }

  Future<String?> restore() async {
    if (restoring) return null;
    if (onRestore == null) return 'Restore purchases is not available yet.';
    restoring = true;
    refresh();
    try {
      return await onRestore!()
          ? 'Purchases restored.'
          : 'No active purchases were found.';
    } catch (_) {
      return 'Unable to restore purchases. Please try again.';
    } finally {
      restoring = false;
      refresh();
    }
  }
}
