import 'dart:collection';

import 'package:flutter/foundation.dart';

/// The maximum number of measurement results kept in the text-fit cache.
///
/// Once the cache holds this many entries, inserting a new one evicts the
/// least recently used entry. A dashboard that refreshes its numbers every few
/// seconds produces a new cache key on every refresh, so an unbounded cache
/// would grow for as long as the app runs.
///
/// ```dart
/// expect(debugFitCacheLength(), lessThanOrEqualTo(kFitCacheMaxEntries));
/// ```
const int kFitCacheMaxEntries = 200;

/// A least-recently-used map with a hard upper bound on its size.
///
/// [LinkedHashMap] iterates in insertion order, which is all an LRU needs:
/// reading an entry re-inserts it at the end, and an insertion past [maximum]
/// drops the entry at the front.
///
/// This class is internal to the package and is not exported.
class LruCache<K, V> {
  /// Creates a cache that holds at most [maximum] entries.
  LruCache(this.maximum) : assert(maximum > 0, 'maximum must be positive');

  /// The largest number of entries the cache will hold.
  final int maximum;

  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  /// The number of entries currently held.
  int get length => _entries.length;

  /// Returns the value for [key], marking it as the most recently used.
  V? operator [](K key) {
    final V? value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  /// Stores [value] under [key], evicting the least recently used entry when
  /// the cache is full.
  void operator []=(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > maximum) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Drops every entry.
  void clear() => _entries.clear();
}

/// Process-wide measurement cache shared by every adaptive text in the app.
///
/// A single layout pass repeats the same query many times, and
/// `TextPainter.layout` is the most expensive thing this package does.
///
/// This object is internal to the package and is not exported.
final LruCache<Object, Object> fitCache = LruCache<Object, Object>(
  kFitCacheMaxEntries,
);

/// Empties the text-fit measurement cache.
///
/// Every stat card in the process shares one bounded cache of text
/// measurements. Clearing it is only useful in tests that assert on
/// measurement behaviour and need a cold start; production code never has to
/// call this, because the cache evicts its own least recently used entries at
/// [kFitCacheMaxEntries].
///
/// ```dart
/// setUp(clearFitCache);
/// ```
@visibleForTesting
void clearFitCache() => fitCache.clear();

/// The number of entries currently held by the text-fit measurement cache.
///
/// Exposed so that tests can assert the cache stays bounded while a dashboard
/// churns through values.
///
/// ```dart
/// expect(debugFitCacheLength(), lessThanOrEqualTo(kFitCacheMaxEntries));
/// ```
@visibleForTesting
int debugFitCacheLength() => fitCache.length;
