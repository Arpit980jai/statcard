import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:adaptive_stat_card/src/fit_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(clearFitCache);

  group('LruCache', () {
    test('never grows past its maximum', () {
      final LruCache<int, int> cache = LruCache<int, int>(3);
      for (var i = 0; i < 100; i++) {
        cache[i] = i;
      }
      expect(cache.length, 3);
    });

    test('evicts the least recently used entry, not the oldest insertion', () {
      final LruCache<String, int> cache = LruCache<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;

      // Touching 'a' makes 'b' the least recently used.
      expect(cache['a'], 1);
      cache['d'] = 4;

      expect(cache['b'], isNull);
      expect(cache['a'], 1);
      expect(cache['c'], 3);
      expect(cache['d'], 4);
    });

    test('re-inserting an existing key does not grow the cache', () {
      final LruCache<String, int> cache = LruCache<String, int>(2);
      cache['a'] = 1;
      cache['a'] = 2;
      expect(cache.length, 1);
      expect(cache['a'], 2);
    });

    test('clear empties the cache', () {
      final LruCache<int, int> cache = LruCache<int, int>(4);
      cache[1] = 1;
      cache.clear();
      expect(cache.length, 0);
    });
  });

  group('the shared measurement cache stays bounded', () {
    testWidgets('after 1000 distinct values it holds at most the maximum', (
      WidgetTester tester,
    ) async {
      expect(debugFitCacheLength(), 0);

      // A real dashboard re-renders with a brand new value string on every
      // data refresh, so the cache key is distinct every single time.
      for (var i = 0; i < 1000; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  child: StatCard(
                    value: '$i,${i.toString().padLeft(3, '0')}',
                    label: 'Deliveries',
                    overflow: StatCardOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      expect(debugFitCacheLength(), lessThanOrEqualTo(kFitCacheMaxEntries));
      // The cache is full rather than repeatedly emptied: eviction is by
      // least-recently-used, not by dropping everything on overflow.
      expect(debugFitCacheLength(), kFitCacheMaxEntries);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clearFitCache empties it', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: StatCard(value: '1,248', label: 'Deliveries'),
              ),
            ),
          ),
        ),
      );
      expect(debugFitCacheLength(), greaterThan(0));

      clearFitCache();
      expect(debugFitCacheLength(), 0);
    });
  });
}
