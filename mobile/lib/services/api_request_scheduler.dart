import 'dart:async';
import 'dart:collection';

class ApiRequestScheduler {
  ApiRequestScheduler._internal();

  static final ApiRequestScheduler _instance = ApiRequestScheduler._internal();

  factory ApiRequestScheduler() => _instance;

  static const int _maxRequestsPerMinute = 50;
  static const int _maxConcurrentRequests = 4;
  static const Duration _minSpacingBetweenRequests =
      Duration(milliseconds: 200);

  final Queue<_QueuedPermit> _highPriorityQueue = Queue<_QueuedPermit>();
  final Queue<_QueuedPermit> _queue = Queue<_QueuedPermit>();
  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();

  int _activeRequests = 0;
  bool _isProcessing = false;
  DateTime? _lastRequestTime;

  Future<RequestPermit> acquire({bool highPriority = false}) {
    final request = _QueuedPermit();
    if (highPriority) {
      _highPriorityQueue.add(request);
    } else {
      _queue.add(request);
    }
    _processQueue();
    return request.completer.future;
  }

  void _processQueue() {
    if (_isProcessing) return;
    _isProcessing = true;
    unawaited(_drainQueue());
  }

  Future<void> _drainQueue() async {
    while ((_highPriorityQueue.isNotEmpty || _queue.isNotEmpty) &&
        _activeRequests < _maxConcurrentRequests) {
      final queued = _highPriorityQueue.isNotEmpty
          ? _highPriorityQueue.removeFirst()
          : _queue.removeFirst();

      await _enforceRateLimits();

      _activeRequests++;
      final permit = RequestPermit(_release);
      queued.completer.complete(permit);
    }

    _isProcessing = false;
  }

  Future<void> _enforceRateLimits() async {
    final now = DateTime.now();
    const oneMinute = Duration(minutes: 1);

    while (_requestTimestamps.isNotEmpty &&
        now.difference(_requestTimestamps.first) >= oneMinute) {
      _requestTimestamps.removeFirst();
    }

    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldest = _requestTimestamps.first;
      final waitDuration =
          oneMinute - now.difference(oldest) + const Duration(milliseconds: 50);
      if (waitDuration > Duration.zero) {
        await Future.delayed(waitDuration);
      }
    }

    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!);
      if (diff < _minSpacingBetweenRequests) {
        await Future.delayed(_minSpacingBetweenRequests - diff);
      }
    }

    final timestamp = DateTime.now();
    _lastRequestTime = timestamp;
    _requestTimestamps.add(timestamp);
  }

  void _release() {
    if (_activeRequests > 0) {
      _activeRequests--;
    }
    _processQueue();
  }
}

class RequestPermit {
  RequestPermit(this._onRelease);

  final void Function() _onRelease;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _onRelease();
  }
}

class _QueuedPermit {
  final Completer<RequestPermit> completer = Completer<RequestPermit>();
}

