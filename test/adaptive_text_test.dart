import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:adaptive_stat_card/src/widgets/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String kLongText =
    'Total deliveries completed this month across every region';
const double kBaseFontSize = 20;
const TextStyle kStyle = TextStyle(fontSize: kBaseFontSize);

Future<void> pumpAdaptiveText(
  WidgetTester tester, {
  required String text,
  required StatCardOverflow overflow,
  double width = 100,
  int maxLines = 1,
  double minFontScale = 0.7,
  double textScale = 1.0,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: AdaptiveText(
                    text: text,
                    style: kStyle,
                    overflow: overflow,
                    maxLines: maxLines,
                    minFontScale: minFontScale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Reads the font size the engine actually decided to paint.
///
/// `Text.rich` nests the supplied span inside an outer span carrying the
/// ambient [DefaultTextStyle], so the inner span is the one to inspect.
double resolvedFontSize(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(AdaptiveText),
      matching: find.byType(RichText),
    ),
  );
  final outer = richText.text as TextSpan;
  final inner = outer.children?.first;
  if (inner is TextSpan && inner.style?.fontSize != null) {
    return inner.style!.fontSize!;
  }
  return outer.style!.fontSize!;
}

/// Reads the `maxLines` the engine settled on.
int resolvedMaxLines(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(AdaptiveText),
      matching: find.byType(RichText),
    ),
  );
  return richText.maxLines!;
}

void main() {
  setUp(AdaptiveText.debugClearCache);

  group('shrink strategy', () {
    testWidgets('shrinks below the base size when the text is too long', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrink,
      );
      expect(resolvedFontSize(tester), lessThan(kBaseFontSize));
    });

    testWidgets('never shrinks below style.fontSize * minFontScale', (
      WidgetTester tester,
    ) async {
      const double minFontScale = 0.7;
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrink,
        width: 40,
        minFontScale: minFontScale,
      );
      expect(
        resolvedFontSize(tester),
        greaterThanOrEqualTo(kBaseFontSize * minFontScale),
      );
    });

    testWidgets('honours a custom, lower minFontScale floor', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrink,
        width: 40,
        minFontScale: 0.4,
      );
      expect(
        resolvedFontSize(tester),
        greaterThanOrEqualTo(kBaseFontSize * 0.4),
      );
      expect(resolvedFontSize(tester), lessThan(kBaseFontSize * 0.7));
    });

    testWidgets('text that already fits keeps the exact base font size', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: '42',
        overflow: StatCardOverflow.shrink,
        width: 300,
      );
      expect(resolvedFontSize(tester), kBaseFontSize);
    });

    testWidgets('accessibility text scaling forces a smaller font', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: 'Deliveries',
        overflow: StatCardOverflow.shrink,
        width: 220,
      );
      final double atNormalScale = resolvedFontSize(tester);

      await pumpAdaptiveText(
        tester,
        text: 'Deliveries',
        overflow: StatCardOverflow.shrink,
        width: 220,
        textScale: 2,
      );
      expect(resolvedFontSize(tester), lessThan(atNormalScale));
    });
  });

  group('tooltip strategy', () {
    testWidgets('attaches a Tooltip when the text is truncated', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.tooltip,
      );
      expect(find.byType(Tooltip), findsOneWidget);
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, kLongText);
    });

    testWidgets('adds no Tooltip when the text fits', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: '42',
        overflow: StatCardOverflow.tooltip,
        width: 300,
      );
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets(
      'shrinkThenTooltip shrinks first and only then adds a tooltip',
      (WidgetTester tester) async {
        await pumpAdaptiveText(
          tester,
          text: kLongText,
          overflow: StatCardOverflow.shrinkThenTooltip,
        );
        expect(resolvedFontSize(tester), lessThan(kBaseFontSize));
        expect(find.byType(Tooltip), findsOneWidget);
      },
    );
  });

  group('other strategies', () {
    testWidgets('wrap keeps the base font size and uses the line budget', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.wrap,
        maxLines: 3,
        width: 200,
      );
      expect(resolvedFontSize(tester), kBaseFontSize);
      expect(resolvedMaxLines(tester), 3);
    });

    testWidgets('shrinkThenWrap wraps once shrinking cannot save one line', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrinkThenWrap,
        maxLines: 2,
        width: 160,
      );
      expect(resolvedMaxLines(tester), 2);
      expect(resolvedFontSize(tester), lessThanOrEqualTo(kBaseFontSize));
    });

    testWidgets('scroll renders inside a horizontal scroll view', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.scroll,
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(scrollView.physics, isA<ClampingScrollPhysics>());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders nothing for an empty string', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: '',
        overflow: StatCardOverflow.shrinkThenWrap,
      );
      expect(find.byType(RichText), findsNothing);
    });

    testWidgets('skips measurement under unbounded width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AdaptiveText(
              text: kLongText,
              style: kStyle,
              overflow: StatCardOverflow.shrink,
              maxLines: 1,
              minFontScale: 0.7,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(resolvedFontSize(tester), kBaseFontSize);
    });
  });

  group('measurement cache', () {
    testWidgets('a repeated build resolves to the same font size', (
      WidgetTester tester,
    ) async {
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrink,
        width: 140,
      );
      final double first = resolvedFontSize(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAdaptiveText(
        tester,
        text: kLongText,
        overflow: StatCardOverflow.shrink,
        width: 140,
      );
      expect(resolvedFontSize(tester), first);
    });
  });
}
