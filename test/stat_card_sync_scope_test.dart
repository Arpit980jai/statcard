import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Five labels of wildly different lengths, so every card fits differently.
const List<String> kLabels = <String>[
  'Ok',
  'Deliveries',
  'Total deliveries completed this month',
  'Average time to first response across every support queue this quarter',
  'Net promoter score',
];

const List<String> kValues = <String>[
  '4',
  '1,248',
  '1,248,930,551',
  '99.97',
  '-12,004',
];

/// Builds a row of [count] cards, optionally wrapped in a sync scope.
Widget buildRow({
  required bool synced,
  required double textScale,
  int count = 5,
  double cardWidth = 140,
  StatCardOverflow overflow = StatCardOverflow.shrink,
}) {
  final Widget row = Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (var i = 0; i < count; i++)
        SizedBox(
          width: cardWidth,
          child: StatCard(
            key: ValueKey<int>(i),
            value: kValues[i],
            label: kLabels[i],
            overflow: overflow,
            labelMaxLines: 1,
          ),
        ),
    ],
  );

  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: synced ? StatCardSyncScope(child: row) : row,
            ),
          ),
        );
      },
    ),
  );
}

/// The font size the card with [index] actually painted for [slot].
///
/// Slot 0 is the value, slot 1 the label.
double paintedFontSize(WidgetTester tester, int index, int slot) {
  final Finder texts = find.descendant(
    of: find.byKey(ValueKey<int>(index)),
    matching: find.byType(RichText),
  );
  final RichText richText = tester.widget<RichText>(texts.at(slot));
  final TextSpan outer = richText.text as TextSpan;
  final InlineSpan? inner = outer.children?.first;
  if (inner is TextSpan && inner.style?.fontSize != null) {
    return inner.style!.fontSize!;
  }
  return outer.style!.fontSize!;
}

List<double> paintedSizes(WidgetTester tester, int slot, {int count = 5}) {
  return <double>[
    for (var i = 0; i < count; i++) paintedFontSize(tester, i, slot),
  ];
}

void main() {
  setUp(clearFitCache);

  for (final double textScale in <double>[1.0, 2.0]) {
    group('at text scale $textScale', () {
      testWidgets('five cards converge on one value size', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildRow(synced: false, textScale: textScale));
        await tester.pumpAndSettle();
        final List<double> unsynced = paintedSizes(tester, 0);

        clearFitCache();
        await tester.pumpWidget(buildRow(synced: true, textScale: textScale));
        await tester.pumpAndSettle();
        final List<double> synced = paintedSizes(tester, 0);

        expect(
          synced.toSet(),
          hasLength(1),
          reason: 'every card should paint the same value size, got $synced',
        );
        expect(
          synced.first,
          closeTo(unsynced.reduce((double a, double b) => a < b ? a : b), 0.05),
          reason: 'the agreed size is the smallest anyone needed',
        );
      });

      testWidgets('five cards converge on one label size', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildRow(synced: true, textScale: textScale));
        await tester.pumpAndSettle();

        expect(paintedSizes(tester, 1).toSet(), hasLength(1));
      });

      testWidgets('without a scope the cards stay independent', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildRow(synced: false, textScale: textScale));
        await tester.pumpAndSettle();

        expect(
          paintedSizes(tester, 0).toSet().length,
          greaterThan(1),
          reason: 'these values do not all need the same size',
        );
      });
    });
  }

  testWidgets('the scope settles instead of rebuilding forever', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: true, textScale: 1));

    // A frame budget far beyond the two passes the scope is allowed to need.
    // pumpAndSettle throws if the tree never stops scheduling frames.
    final int frames = await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
    );
    expect(frames, lessThan(10), reason: 'took $frames frames to settle');
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the card that forced the minimum lets the rest grow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: true, textScale: 1));
    await tester.pumpAndSettle();
    final double withLongest = paintedFontSize(tester, 0, 0);

    // Card 2 holds the longest value, so it is the one setting the minimum.
    await tester.pumpWidget(buildRow(synced: true, textScale: 1, count: 2));
    await tester.pumpAndSettle();
    final double withoutLongest = paintedFontSize(tester, 0, 0);

    expect(withoutLongest, greaterThan(withLongest));
    expect(paintedSizes(tester, 0, count: 2).toSet(), hasLength(1));
  });

  testWidgets('adding a card that needs less space pulls the group down', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: true, textScale: 1, count: 2));
    await tester.pumpAndSettle();
    final double before = paintedFontSize(tester, 0, 0);

    await tester.pumpWidget(buildRow(synced: true, textScale: 1, count: 5));
    await tester.pumpAndSettle();
    final double after = paintedFontSize(tester, 0, 0);

    expect(after, lessThan(before));
    expect(paintedSizes(tester, 0).toSet(), hasLength(1));
  });

  testWidgets('a disabled scope behaves exactly like no scope at all', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: false, textScale: 1));
    await tester.pumpAndSettle();
    final List<double> unscoped = paintedSizes(tester, 0);

    clearFitCache();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: StatCardSyncScope(
              enabled: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < 5; i++)
                    SizedBox(
                      width: 140,
                      child: StatCard(
                        key: ValueKey<int>(i),
                        value: kValues[i],
                        label: kLabels[i],
                        overflow: StatCardOverflow.shrink,
                        labelMaxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(paintedSizes(tester, 0), unscoped);
  });

  testWidgets('a lone card in a scope keeps its own natural size', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: false, textScale: 1, count: 1));
    await tester.pumpAndSettle();
    final double alone = paintedFontSize(tester, 0, 0);

    clearFitCache();
    await tester.pumpWidget(buildRow(synced: true, textScale: 1, count: 1));
    await tester.pumpAndSettle();

    expect(paintedFontSize(tester, 0, 0), alone);
  });

  testWidgets('a scope survives a text scale change', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRow(synced: true, textScale: 1));
    await tester.pumpAndSettle();
    expect(paintedSizes(tester, 0).toSet(), hasLength(1));

    await tester.pumpWidget(buildRow(synced: true, textScale: 2));
    await tester.pumpAndSettle();
    expect(paintedSizes(tester, 0).toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scope full of cards never overflows', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final double scale in <double>[1.0, 1.3, 1.75, 2.0]) {
      await tester.pumpWidget(
        buildRow(synced: true, textScale: scale, cardWidth: 90),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'at text scale $scale');
    }
  });
}
