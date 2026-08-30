import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<StatCard> kCards = <StatCard>[
  StatCard(value: '1,248', label: 'Deliveries this month'),
  StatCard(value: '4.2L', label: 'Revenue'),
  StatCard(value: '312', label: 'Active users'),
  StatCard(value: '18', label: 'Pending pickups'),
  StatCard(value: '27', label: 'Average delivery time'),
  StatCard(value: '4.8', label: 'Satisfaction score'),
];

Future<void> pumpGrid(
  WidgetTester tester, {
  required double width,
  double minCardWidth = 160,
  double? childAspectRatio,
  List<StatCard> children = kCards,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: StatCardGrid(
                minCardWidth: minCardWidth,
                childAspectRatio: childAspectRatio,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The number of cards sharing the topmost row.
int columnsInFirstRow(WidgetTester tester) {
  final List<Rect> rects = tester
      .widgetList<StatCard>(find.byType(StatCard))
      .map((StatCard card) => tester.getRect(find.byWidget(card)))
      .toList();
  final double firstTop = rects
      .map((Rect r) => r.top)
      .reduce((double a, double b) => a < b ? a : b);
  return rects.where((Rect r) => (r.top - firstTop).abs() < 1).length;
}

void main() {
  testWidgets('column count follows the available width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpGrid(tester, width: 300);
    expect(columnsInFirstRow(tester), 1);

    await pumpGrid(tester, width: 360);
    expect(columnsInFirstRow(tester), 2);

    await pumpGrid(tester, width: 700);
    expect(columnsInFirstRow(tester), 4);

    await pumpGrid(tester, width: 2000);
    // Capped by the number of children, never more columns than cards.
    expect(columnsInFirstRow(tester), kCards.length);
  });

  testWidgets('minCardWidth changes the breakpoints', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // (600 + 12) / (100 + 12) = 5.46 -> 5 columns of 105.6 px.
    await pumpGrid(tester, width: 600, minCardWidth: 100);
    expect(columnsInFirstRow(tester), 5);

    // (600 + 12) / (300 + 12) = 1.96 -> 1 column; two would be 294 px each.
    await pumpGrid(tester, width: 600, minCardWidth: 300);
    expect(columnsInFirstRow(tester), 1);
  });

  testWidgets('spacing is counted, so no card is narrower than minCardWidth', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Widths that the old `(maxWidth / minCardWidth).floor()` formula split
    // into cards below minCardWidth: at 600/100 it claimed six 90 px columns,
    // at 600/300 two 294 px columns, at 340/160 two 164 px columns.
    const List<(double, double)> cases = <(double, double)>[
      (600, 100),
      (600, 300),
      (340, 160),
      (320, 160),
      (500, 160),
      (720, 240),
    ];

    for (final (double width, double minCardWidth) in cases) {
      await pumpGrid(tester, width: width, minCardWidth: minCardWidth);
      final Size size = tester.getSize(find.byWidget(kCards.first));
      expect(
        size.width,
        greaterThanOrEqualTo(minCardWidth - 0.5),
        reason:
            'a $width px grid of $minCardWidth px cards produced '
            '${size.width} px cards',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a single column is used when even two would be too narrow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Two 160 px cards plus a 12 px gap need 332 px.
    await pumpGrid(tester, width: 331);
    expect(columnsInFirstRow(tester), 1);

    await pumpGrid(tester, width: 332);
    expect(columnsInFirstRow(tester), 2);
  });

  testWidgets('a larger spacing costs a column at the same width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: StatCardGrid(spacing: 100, children: kCards),
              ),
            ),
          ),
        ),
      ),
    );
    // (500 + 100) / (160 + 100) = 2.3 -> 2 columns, not the three that
    // ignoring spacing would have claimed.
    expect(columnsInFirstRow(tester), 2);
    expect(
      tester.getSize(find.byWidget(kCards.first)).width,
      greaterThanOrEqualTo(160),
    );
  });

  testWidgets('never overflows at any width from 240 to 2000', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (double width = 240; width <= 2000; width += 20) {
      await pumpGrid(tester, width: width);
      expect(
        tester.takeException(),
        isNull,
        reason: 'grid overflowed at width $width',
      );
      // No card may stick out of the viewport it was given.
      for (final StatCard card in kCards) {
        final Rect rect = tester.getRect(find.byWidget(card));
        expect(
          rect.right,
          lessThanOrEqualTo(width + 0.5),
          reason: 'card exceeded the grid width at $width',
        );
      }
    }
  });

  testWidgets('honours childAspectRatio when one is given', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpGrid(tester, width: 660, childAspectRatio: 2);
    expect(find.byType(GridView), findsOneWidget);
    final Size size = tester.getSize(find.byWidget(kCards.first));
    expect(size.width / size.height, closeTo(2, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing for an empty child list', (
    WidgetTester tester,
  ) async {
    await pumpGrid(tester, width: 400, children: const <StatCard>[]);
    expect(find.byType(StatCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to a plain wrap under unbounded width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StatCardGrid(children: kCards),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(StatCard), findsNWidgets(kCards.length));
  });
}
