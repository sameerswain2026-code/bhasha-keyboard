/// Tavily Search API key pool with automatic failover rotation.
///
/// Mirrors [SarvamKeyPool]'s design exactly: multiple keys are held in a
/// pool, a failing key (auth/quota/rate-limit) is marked bad and rotation
/// advances to the next healthy key. If every key has failed, the pool
/// resets (limits may recover over time) rather than getting permanently
/// stuck.
///
/// Keys are supplied at build time through TAVILY_API_KEYS. No credential is
/// stored in source control. For a public production app, prefer a backend.
library;

class TavilyKeyPool {
  TavilyKeyPool(List<String> keys)
    : _keys = List.unmodifiable(
        keys.where((k) => k.trim().isNotEmpty).isEmpty
            ? ['']
            : keys.where((k) => k.trim().isNotEmpty),
      ),
      assert(keys.isNotEmpty);

  factory TavilyKeyPool.production() {
    const configured = String.fromEnvironment('TAVILY_API_KEYS');
    final keys = configured.split(',').map((key) => key.trim()).toList();
    return TavilyKeyPool(keys.isEmpty ? [''] : keys);
  }

  final List<String> _keys;
  final Set<int> _failed = {};
  int _index = 0;

  int get length => _keys.length;

  /// Number of keys not currently marked as failed.
  int get healthyCount => _keys.length - _failed.length;

  /// The key that should be used for the next request.
  String get current => _keys[_index];

  int get currentIndex => _index;

  /// Mark [key] as failed and rotate to the next healthy key.
  /// Returns true if a healthy key is available afterwards.
  /// When every key has failed, the pool resets all failure marks
  /// (quota/rate-limit states recover over time) and starts over.
  bool markFailed(String key) {
    final idx = _keys.indexOf(key);
    if (idx >= 0) _failed.add(idx);
    if (_failed.length >= _keys.length) {
      _failed.clear();
      _index = 0;
      return false;
    }
    var next = _index;
    for (var step = 1; step <= _keys.length; step++) {
      next = (idx >= 0 ? idx + step : _index + step) % _keys.length;
      if (!_failed.contains(next)) break;
    }
    _index = next;
    return true;
  }

  /// Report the current key worked - clears its failure mark if any.
  void markHealthy(String key) {
    final idx = _keys.indexOf(key);
    if (idx >= 0) _failed.remove(idx);
  }

  /// True if the error text/status indicates the key itself is the
  /// problem (auth, quota, rate limit) and rotation should occur.
  static bool isKeyError({String? message, int? httpStatus}) {
    if (httpStatus == 401 || httpStatus == 403 || httpStatus == 429) {
      return true;
    }
    final m = (message ?? '').toLowerCase();
    return m.contains('unauthorized') ||
        m.contains('forbidden') ||
        m.contains('invalid api key') ||
        m.contains('invalid_api_key') ||
        m.contains('quota') ||
        m.contains('credit') ||
        m.contains('rate limit') ||
        m.contains('too many requests');
  }
}
