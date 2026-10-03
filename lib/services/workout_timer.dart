// Wall-clock timing survives screen disposal and app suspension.
class PersistentWorkoutTimer {
  final DateTime Function() now;
  DateTime? _startedAt;
  int _elapsedMilliseconds = 0;
  PersistentWorkoutTimer({DateTime Function()? clock})
      : now = clock ?? DateTime.now;
  bool get isRunning => _startedAt != null;
  Duration get elapsed => Duration(
      milliseconds: _elapsedMilliseconds +
          (_startedAt == null
              ? 0
              : now()
                  .difference(_startedAt!)
                  .inMilliseconds
                  .clamp(0, 604800000)));
  void start() {
    _startedAt ??= now();
  }

  void stop() {
    _elapsedMilliseconds = elapsed.inMilliseconds;
    _startedAt = null;
  }

  void reset() {
    _elapsedMilliseconds = 0;
    _startedAt = isRunning ? now() : null;
  }

  Map<String, dynamic> toJson() => {
        'startedAt': _startedAt?.toUtc().toIso8601String(),
        'elapsedMilliseconds': _elapsedMilliseconds
      };
  void restore(Map<String, dynamic> value) {
    _startedAt = DateTime.tryParse('${value['startedAt']}');
    _elapsedMilliseconds =
        (value['elapsedMilliseconds'] as num? ?? 0).toInt().clamp(0, 604800000);
  }
}
