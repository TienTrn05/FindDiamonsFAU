import '../../../core/bloc/resource_controller.dart';
import '../../../core/models/search_record.dart';
import '../data/history_repository.dart';
import '../models/history_data.dart';

class HistoryBloc extends ResourceController<HistoryData> {
  HistoryBloc(this.repository);
  final HistoryRepository repository;

  @override
  Future<HistoryData> fetch() => repository.load();

  Future<void> record(SearchRecord record) async {
    try {
      await repository.add(record);
    } finally {
      await load();
    }
  }

  Future<void> remove(String id) async {
    try {
      await repository.remove(id);
    } finally {
      await load();
    }
  }
}
