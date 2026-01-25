import 'dart:async';

class CancelToken {
  bool _cancelled = false;
  final Completer<void> _cancelCompleter = Completer<void>();

  bool get isCancelled => _cancelled;

  Future<void> get cancellationFuture => _cancelCompleter.future;

  void cancel() {
    _cancelled = true;
    if (!_cancelCompleter.isCompleted) {
      _cancelCompleter.complete();
    }
  }

  void reset() {
    _cancelled = false;
    // Don't reset the completer, create a new one
  }
}
