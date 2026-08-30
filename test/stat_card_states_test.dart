import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:adaptive_stat_card/src/widgets/stat_card_skeleton.dart';
import 'package:adaptive_stat_card/src/widgets/stat_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<double> kSeries = <double>[3, 5, 4, 9, 8, 12, 11, 15];

Future<void> pump(WidgetTester tester, Widget card, {double width = 200}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: card),
        ),
      ),
    ),
  );
}

/// The border the card's Material is painting.
BorderSide cardBorder(WidgetTester tester) {
  final Material material = tester.widget<Material>(
    find
        .descendant(of: find.byType(StatCard), matching: find.byType(Material))
        .first,
  );
  return (material.shape! as RoundedRectangleBorder).side;
}

void main() {
  setUp(clearFitCache);

  group('emptyPlaceholder', () {
    testWidgets('an empty value renders the em dash by default', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard(value: '', label: 'Deliveries'));
      expect(find.textContaining('—', findRichText: true), findsOneWidget);
    });

    testWidgets('the placeholder is overridable', (WidgetTester tester) async {
      await pump(
        tester,
        const StatCard(value: '', label: 'Deliveries', emptyPlaceholder: 'n/a'),
      );
      expect(find.textContaining('n/a', findRichText: true), findsOneWidget);
    });

    testWidgets('a real value is never replaced', (WidgetTester tester) async {
      await pump(tester, const StatCard(value: '0', label: 'Deliveries'));
      expect(find.textContaining('0', findRichText: true), findsOneWidget);
      expect(find.textContaining('—', findRichText: true), findsNothing);
    });

    testWidgets('the placeholder is what a screen reader hears', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, const StatCard(value: '', label: 'Deliveries'));
      expect(find.bySemanticsLabel('Deliveries: —'), findsOneWidget);
      handle.dispose();
    });
  });

  group('error', () {
    testWidgets('replaces the value with an error glyph and keeps the label', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          error: 'network unreachable',
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.textContaining('1,248', findRichText: true), findsNothing);
      expect(
        find.textContaining('Deliveries', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('exposes the message as a tooltip', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '',
          label: 'Deliveries',
          error: 'network unreachable',
        ),
      );
      final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'network unreachable');
    });

    testWidgets('reads as an error to a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const StatCard(
          value: '',
          label: 'Deliveries',
          error: 'network unreachable',
        ),
      );
      expect(
        find.bySemanticsLabel('Deliveries: network unreachable'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('takes precedence over isLoading', (WidgetTester tester) async {
      await pump(
        tester,
        const StatCard(
          value: '',
          label: 'Deliveries',
          isLoading: true,
          error: 'boom',
        ),
      );
      expect(find.byType(StatCardSkeleton), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('accepts any object, not just a string', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        StatCard(value: '', label: 'Deliveries', error: Exception('timed out')),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('onLongPress', () {
    testWidgets('fires on a long press', (WidgetTester tester) async {
      var presses = 0;
      await pump(
        tester,
        StatCard(
          value: '1,248',
          label: 'Deliveries',
          onLongPress: () => presses++,
        ),
      );

      await tester.longPress(find.byType(StatCard));
      await tester.pumpAndSettle();
      expect(presses, 1);
    });

    testWidgets('adds an InkWell even without an onTap', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        StatCard(value: '1,248', label: 'Deliveries', onLongPress: () {}),
      );
      expect(
        find.descendant(
          of: find.byType(StatCard),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a long press does not fire onTap', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      var presses = 0;
      await pump(
        tester,
        StatCard(
          value: '1,248',
          label: 'Deliveries',
          onTap: () => taps++,
          onLongPress: () => presses++,
        ),
      );

      await tester.longPress(find.byType(StatCard));
      await tester.pumpAndSettle();
      expect(presses, 1);
      expect(taps, 0);

      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(presses, 1);
    });

    testWidgets('is exposed to a screen reader', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        StatCard(value: '1', label: 'One', onLongPress: () {}),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('One: 1')),
        containsSemantics(hasLongPressAction: true),
      );
      handle.dispose();
    });
  });

  group('selected', () {
    testWidgets('thickens and recolours the border', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard(value: '1', label: 'One'));
      final BorderSide unselected = cardBorder(tester);

      await pump(
        tester,
        const StatCard(value: '1', label: 'One', selected: true),
      );
      final BorderSide selected = cardBorder(tester);

      expect(selected.width, greaterThan(unselected.width));
      expect(selected.color, isNot(unselected.color));
    });

    testWidgets('is announced to a screen reader', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const StatCard(value: '1', label: 'One', selected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('One: 1')),
        containsSemantics(isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('an unselected card is not announced as selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, const StatCard(value: '1', label: 'One'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('One: 1')),
        containsSemantics(isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('a zero-width border still becomes visible when selected', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1',
          label: 'One',
          selected: true,
          theme: StatCardThemeData(borderWidth: 0),
        ),
      );
      expect(cardBorder(tester).width, greaterThan(0));
    });
  });

  group('sparkline', () {
    testWidgets('is drawn in a card that has room', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(value: '1,248', label: 'Deliveries', sparkline: kSeries),
        width: 240,
      );
      expect(find.byType(StatSparkline), findsOneWidget);
    });

    testWidgets('is omitted below the documented width threshold', (
      WidgetTester tester,
    ) async {
      // The content box is the card minus 32 px of padding, so a 100 px card
      // leaves 68 px — under StatCard.sparklineMinWidth.
      await pump(
        tester,
        const StatCard(value: '1,248', label: 'Deliveries', sparkline: kSeries),
        width: 100,
      );
      expect(find.byType(StatSparkline), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is omitted for fewer than two points', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          sparkline: <double>[4],
        ),
        width: 240,
      );
      expect(find.byType(StatSparkline), findsNothing);

      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          sparkline: <double>[],
        ),
        width: 240,
      );
      expect(find.byType(StatSparkline), findsNothing);
    });

    testWidgets('takes its colour and width from the resolved theme', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          sparkline: kSeries,
          theme: StatCardThemeData(
            sparklineColor: Color(0xFF00FF00),
            sparklineStrokeWidth: 4,
          ),
        ),
        width: 240,
      );

      final StatSparkline line = tester.widget<StatSparkline>(
        find.byType(StatSparkline),
      );
      expect(line.color, const Color(0xFF00FF00));
      expect(line.strokeWidth, 4);
    });

    testWidgets('sits between the label and the trend badge', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          sparkline: kSeries,
          trend: StatTrend.up('+12.4%'),
        ),
        width: 240,
      );

      final double labelY = tester
          .getCenter(find.textContaining('Deliveries', findRichText: true))
          .dy;
      final double lineY = tester.getCenter(find.byType(StatSparkline)).dy;
      final double trendY = tester
          .getCenter(find.textContaining('+12.4%', findRichText: true))
          .dy;

      expect(lineY, greaterThan(labelY));
      expect(trendY, greaterThan(lineY));
    });

    testWidgets('a loading card draws no sparkline', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          sparkline: kSeries,
          isLoading: true,
        ),
        width: 240,
      );
      expect(find.byType(StatSparkline), findsNothing);
      expect(find.byType(StatCardSkeleton), findsOneWidget);
    });
  });
}
