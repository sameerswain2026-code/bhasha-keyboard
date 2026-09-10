/// Gemini API key pool with automatic failover rotation.
///
/// Legacy local-development fallback. Public builds must leave this empty and
/// route Gemini through the authenticated Appwrite gateway instead.
library;

class GeminiKeyPool {
  GeminiKeyPool(List<String> keys)
    : _keys = List.unmodifiable(
        keys.where((k) => k.trim().isNotEmpty).isEmpty
            ? ['']
            : keys.where((k) => k.trim().isNotEmpty),
      ),
      assert(keys.isNotEmpty);

  factory GeminiKeyPool.production() {
    // Compile-time provider credentials are recoverable from an APK. Public
    // application code is intentionally unable to load one; tests and private
    // tooling may still inject an explicit pool through the constructor.
    return GeminiKeyPool(['']);
  }

  final List<String> _keys;
  final Set<int> _failed = {};
  int _index = 0;

  int get length => _keys.length;
  int get healthyCount => _keys.length - _failed.length;
  String get current => _keys[_index];
  int get currentIndex => _index;

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

  void markHealthy(String key) {
    final idx = _keys.indexOf(key);
    if (idx >= 0) _failed.remove(idx);
  }

  static bool isKeyError({String? message, int? httpStatus}) {
    if (httpStatus == 401 || httpStatus == 403 || httpStatus == 429) {
      return true;
    }
    final m = (message ?? '').toLowerCase();
    return m.contains('unauthorized') ||
        m.contains('forbidden') ||
        m.contains('invalid api key') ||
        m.contains('invalid_api_key') ||
        m.contains('api_key_invalid') ||
        m.contains('quota') ||
        m.contains('credit') ||
        m.contains('rate limit') ||
        m.contains('too many requests') ||
        m.contains('resource_exhausted');
  }
}
