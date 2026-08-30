import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Long enough to be truncated in a 120 px card, so a tooltip is attached.
const String kLongLabel = 'Total deliveries completed this month, every region';

Future<void> pumpCard(WidgetTester tester, StatCard card) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 120, child: card)),
      ),
    ),
  );
}

/// How many widgets currently render the full label.
///
/// `find.text` falls back to the plain text of a `Text.rich`, so the card's own
/// (ellipsized) label always counts as one. A second occurrence means the
/// tooltip overlay is up.
int labelOccurrences() => find.text(kLongLabel).evaluate().length;

bool tooltipIsVisible() => labelOccurrences() > 1;

/// Presses and holds the card long enough to trigger a long press.
Future<void> longPress(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byType(Tooltip)),
  );
  await tester.pump(const Duration(milliseconds: 800));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(clearFitCache);

  group('StatCardOverflow.tooltip on a touch device', () {
    testWidgets('the tooltip is attached because the label is truncated', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const StatCard(
          value: '5',
          label: kLongLabel,
          overflow: StatCardOverflow.tooltip,
        ),
      );
      expect(find.byType(Tooltip), findsOneWidget);
      expect(labelOccurrences(), 1, reason: 'nothing is popped up yet');
    });

    testWidgets('a long press reveals the tooltip when there is no onTap', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        const StatCard(
          value: '5',
          label: kLongLabel,
          overflow: StatCardOverflow.tooltip,
        ),
      );

      await longPress(tester);

      expect(tooltipIsVisible(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long press reveals the tooltip and does not fire onTap', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        StatCard(
          value: '5',
          label: kLongLabel,
          overflow: StatCardOverflow.tooltip,
          onTap: () => taps++,
        ),
      );

      await longPress(tester);

      expect(
        tooltipIsVisible(),
        isTrue,
        reason: 'the tooltip must still open inside a tappable card',
      );
      expect(taps, 0, reason: 'a long press is not a tap');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a plain tap fires onTap and opens no tooltip', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        StatCard(
          value: '5',
          label: kLongLabel,
          overflow: StatCardOverflow.tooltip,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tooltipIsVisible(), isFalse);
    });

    testWidgets('shrinkThenTooltip behaves the same way', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        StatCard(
          value: '5',
          label: kLongLabel,
          overflow: StatCardOverflow.shrinkThenTooltip,
          onTap: () => taps++,
        ),
      );

      await longPress(tester);

      expect(tooltipIsVisible(), isTrue);
      expect(taps, 0);
    });
  });
}
