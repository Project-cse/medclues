import 'dart:async';

typedef SosTickCallback = void Function(int secondsRemaining);
typedef SosCompleteCallback = void Function();

/// Countdown before auto-SOS activation.
class EmergencySosTimerService {
  Timer? _timer;
  int _remaining = 0;

  bool get isRunning => _timer != null;
  int get remainingSeconds => _remaining;

  void start({
    required int seconds,
    required SosTickCallback onTick,
    required SosCompleteCallback onComplete,
  }) {
    cancel();
    _remaining = seconds;
    onTick(_remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining--;
      if (_remaining <= 0) {
        cancel();
        onComplete();
      } else {
        onTick(_remaining);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
