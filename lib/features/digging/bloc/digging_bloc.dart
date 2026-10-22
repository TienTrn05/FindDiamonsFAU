import 'package:flutter/foundation.dart';

import '../../../core/models/search_record.dart';

class DiggingBloc extends ChangeNotifier {
  DiggingBloc(this.record, {bool showAllInitially = false})
    : visibleCount = showAllInitially
          ? record.positions.length
          : (record.positions.isEmpty ? 0 : 1);
  final SearchRecord record;
  int visibleCount;
  final Set<int> _found = {};

  int get remaining => record.positions.length - visibleCount;
  bool isFound(int index) => _found.contains(index);

  void toggleFound(int index) {
    if (index < 0 || index >= record.positions.length) return;
    if (!_found.add(index)) _found.remove(index);
    notifyListeners();
  }

  void revealNext() {
    if (remaining <= 0) return;
    visibleCount++;
    notifyListeners();
  }
}
