/// Counts time spent in the foreground, excluding full-screen ads and Pro.
class InterstitialSchedule {
  InterstitialSchedule({
    this.interval = const Duration(minutes: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration interval;
  final DateTime Function() _now;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  Duration get elapsed =>
      _elapsed +
      (_startedAt == null ? Duration.zero : _now().difference(_startedAt!));
  bool get due => elapsed >= interval;

  void setActive(bool active) {
    if (active == (_startedAt != null)) return;
    if (active) {
      _startedAt = _now();
    } else {
      _elapsed = elapsed;
      _startedAt = null;
    }
  }

  void reset() {
    _elapsed = Duration.zero;
    if (_startedAt != null) _startedAt = _now();
  }
}
