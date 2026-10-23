import 'package:flutter/foundation.dart';

import '../../../core/models/search_record.dart';

class DiggingBloc extends ChangeNotifier {
  DiggingBloc(this.record)
    : visibleCount = record.revealedCount.clamp(0, record.positions.length),
      _found = {
        for (var i = 0; i < record.positions.length; i++)
          if (record.positions[i].found) i,
      };
  final SearchRecord record;
  int visibleCount;
  final Set<int> _found;

  int get remaining => record.positions.length - visibleCount;
  bool isFound(int index) => _found.contains(index);

  void setFound(int index, bool found) {
    if (index < 0 || index >= record.positions.length) return;
    final changed = found ? _found.add(index) : _found.remove(index);
    if (changed) notifyListeners();
  }

  void revealNext() {
    if (remaining <= 0) return;
    visibleCount++;
    notifyListeners();
  }
}
