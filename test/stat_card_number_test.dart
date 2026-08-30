import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The string the card is actually painting for its value.
String paintedValue(WidgetTester tester) {
  final RichText richText = tester.widget<RichText>(
    find
        .descendant(of: find.byType(StatCard), matching: find.byType(RichText))
        .first,
  );
  final TextSpan span = richText.text as TextSpan;
  final InlineSpan? inner = span.children?.first;
  if (inner is TextSpan && inner.text != null) {
    return inner.text!;
  }
  return span.toPlainText();
}

double paintedValueSize(WidgetTester tester) {
  final RichText richText = tester.widget<RichText>(
    find
        .descendant(of: find.byType(StatCard), matching: find.byType(RichText))
        .first,
  );
  final TextSpan span = richText.text as TextSpan;
  final InlineSpan? inner = span.children?.first;
  if (inner is TextSpan && inner.style?.fontSize != null) {
    return inner.style!.fontSize!;
  }
  return span.style!.fontSize!;
}

Future<void> pumpNumber(
  WidgetTester tester,
  Widget card, {
  double width = 200,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: Scaffold(
              body: Center(
                child: SizedBox(width: width, child: card),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  setUp(clearFitCache);

  group('StatCard.number degradation ladder', () {
    testWidgets('a wide card shows the full grouped number', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(1250000, label: 'Deliveries'),
        width: 400,
      );
      expect(paintedValue(tester), '1,250,000');
    });

    testWidgets('a narrower card falls back to two compact digits', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(1250000, label: 'Deliveries'),
        width: 190,
      );
      expect(paintedValue(tester), '1.25M');
    });

    testWidgets('a narrower card still falls back to one compact digit', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(1250000, label: 'Deliveries'),
        width: 120,
      );
      expect(paintedValue(tester), '1.2M');
    });

    testWidgets('shortening happens before shrinking', (
      WidgetTester tester,
    ) async {
      // The point of the ladder: at a width where a plain string value would
      // already have been shrunk, the number is still at full size because a
      // shorter rendering of it fits.
      await pumpNumber(
        tester,
        const StatCard(value: '1,250,000', label: 'Deliveries'),
        width: 150,
      );
      final double stringSize = paintedValueSize(tester);

      clearFitCache();
      await pumpNumber(
        tester,
        StatCard.number(1250000, label: 'Deliveries'),
        width: 150,
      );

      expect(paintedValueSize(tester), greaterThan(stringSize));
    });

    testWidgets('the font only shrinks once the shortest rendering fails', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          overflow: StatCardOverflow.shrink,
        ),
        width: 60,
      );
      expect(paintedValue(tester), '1.2M');
      expect(paintedValueSize(tester), lessThan(24));
    });

    testWidgets('format: grouped never abbreviates', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          format: StatCardValueFormat.grouped,
        ),
        width: 120,
      );
      expect(paintedValue(tester), '1,250,000');
    });

    testWidgets('format: compact never spells the number out', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          format: StatCardValueFormat.compact,
        ),
        width: 400,
      );
      expect(paintedValue(tester), '1.25M');
    });
  });

  group('valueFormatter escape hatch', () {
    testWidgets('replaces the built-in formatter entirely', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          valueFormatter: (num value, double availableWidth) => 'ZZ$value',
        ),
        width: 400,
      );
      expect(paintedValue(tester), 'ZZ1250000');
    });

    testWidgets('is handed the width actually available', (
      WidgetTester tester,
    ) async {
      final List<double> widths = <double>[];
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          valueFormatter: (num value, double availableWidth) {
            widths.add(availableWidth);
            return availableWidth < 100 ? 'narrow' : 'wide';
          },
        ),
        width: 400,
      );
      expect(widths, isNotEmpty);
      expect(widths.every((double w) => w.isFinite && w > 0), isTrue);
      expect(paintedValue(tester), 'wide');

      clearFitCache();
      await pumpNumber(
        tester,
        StatCard.number(
          1250000,
          label: 'Deliveries',
          valueFormatter: (num value, double availableWidth) =>
              availableWidth < 100 ? 'narrow' : 'wide',
        ),
        width: 90,
      );
      expect(paintedValue(tester), 'narrow');
    });
  });

  group('semantics', () {
    testWidgets('reads the full number even when a compact one is painted', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpNumber(
        tester,
        StatCard.number(1250000, label: 'Deliveries'),
        width: 120,
      );

      expect(paintedValue(tester), '1.2M');
      expect(find.bySemanticsLabel('Deliveries: 1,250,000'), findsOneWidget);
      handle.dispose();
    });
  });

  group('animateValue', () {
    testWidgets('counts from the old value to the new one', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(0, label: 'Deliveries', animateValue: true),
        width: 400,
      );
      expect(paintedValue(tester), '0');

      await pumpNumber(
        tester,
        StatCard.number(1000, label: 'Deliveries', animateValue: true),
        width: 400,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final String midway = paintedValue(tester);
      expect(midway, isNot('0'));
      expect(midway, isNot('1,000'));

      await tester.pumpAndSettle();
      expect(paintedValue(tester), '1,000');
    });

    testWidgets('does not animate on the first build', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(1000, label: 'Deliveries', animateValue: true),
        width: 400,
      );
      expect(paintedValue(tester), '1,000');
    });

    testWidgets('is suppressed when animations are disabled', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(0, label: 'Deliveries', animateValue: true),
        width: 400,
        disableAnimations: true,
      );
      await pumpNumber(
        tester,
        StatCard.number(1000, label: 'Deliveries', animateValue: true),
        width: 400,
        disableAnimations: true,
      );
      await tester.pump();

      expect(paintedValue(tester), '1,000');
    });

    testWidgets('an animation in flight does not churn the fit cache', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(0, label: 'Deliveries', animateValue: true),
        width: 400,
      );
      clearFitCache();

      await pumpNumber(
        tester,
        StatCard.number(1000000, label: 'Deliveries', animateValue: true),
        width: 400,
      );
      await tester.pump();
      final int afterFirstFrame = debugFitCacheLength();

      // Thirty frames of a running count, each painting a different string.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 12));
      }

      expect(
        debugFitCacheLength(),
        afterFirstFrame,
        reason: 'the animation added measurement keys frame by frame',
      );
      await tester.pumpAndSettle();
      expect(paintedValue(tester), '1,000,000');
    });

    testWidgets('a counting card never overflows mid-animation', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(1248930551, label: 'Deliveries', animateValue: true),
        width: 100,
      );
      await pumpNumber(
        tester,
        StatCard.number(5, label: 'Deliveries', animateValue: true),
        width: 100,
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 12));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(paintedValue(tester), '5');
    });
  });

  group('non-finite and edge values', () {
    testWidgets('NaN falls back to the empty placeholder', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(double.nan, label: 'Deliveries'),
        width: 200,
      );
      expect(paintedValue(tester), '—');
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero and negatives render normally', (
      WidgetTester tester,
    ) async {
      await pumpNumber(
        tester,
        StatCard.number(0, label: 'Deliveries'),
        width: 200,
      );
      expect(paintedValue(tester), '0');

      clearFitCache();
      await pumpNumber(
        tester,
        StatCard.number(-1250, label: 'Deliveries'),
        width: 200,
      );
      expect(paintedValue(tester), '-1,250');
    });
  });
}
