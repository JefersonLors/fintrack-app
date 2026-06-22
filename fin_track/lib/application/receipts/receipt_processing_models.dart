part of 'receipt_processing_service.dart';

class OcrVariantResult {
  const OcrVariantResult({
    required this.variant,
    required this.result,
    required this.score,
  });

  final OcrImageVariant variant;
  final OcrResult result;
  final double score;
}

class _AsyncSemaphore {
  _AsyncSemaphore(this._max);

  final int _max;
  var _running = 0;
  final _queue = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_running < _max) {
      _running++;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void _release() {
    if (_queue.isEmpty) {
      _running--;
      return;
    }
    _queue.removeAt(0).complete();
  }
}
