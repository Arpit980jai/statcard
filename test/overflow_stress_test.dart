import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic worst case English label.
const String kLongLabel = 'Total Deliveries Completed This Month';

/// A German compound noun with no break opportunities at all. This is the
/// hardest possible input: the text engine cannot wrap it anywhere, so it has
/// to shrink or ellipsize.
const String kGermanCompound = 'Rindfleischetikettierungsueberwachungsaufgaben';

/// A large, comma grouped number that overflows narrow phones.
const String kLongValue = '1,248,930,551';

const List<double> kWidths = <double>[80, 120, 160, 240];
const List<double> kTextScales = <double>[1.0, 1.3, 1.75, 2.0];

/// Pumps a card and returns any error the framework logged during layout.
///
/// `tester.takeException()` only surfaces the first error, so overflow errors
/// are also captured directly from [FlutterError.onError].
Future<List<FlutterErrorDetails>> pumpCard(
  WidgetTester tester,
  Widget card, {
  required double width,
  required double textScale,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  final errors = <FlutterErrorDetails>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = errors.add;

  try {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Directionality(
          textDirection: direction,
          child: Builder(
            builder: (BuildContext context) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      // Width is pinned, height is deliberately unconstrained.
                      child: SizedBox(width: width, child: card),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// Describes every logged error, so a failure message is actionable.
String describe(List<FlutterErrorDetails> errors) =>
    errors.map((FlutterErrorDetails e) => e.exceptionAsString()).join('\n');

void main() {
  group('every strategy survives every width and text scale', () {
    for (final StatCardOverflow overflow in StatCardOverflow.values) {
      for (final double width in kWidths) {
        for (final double textScale in kTextScales) {
          testWidgets(
            '${overflow.name} at ${width.toInt()}px, textScaler $textScale',
            (WidgetTester tester) async {
              final List<FlutterErrorDetails> errors = await pumpCard(
                tester,
                StatCard(
                  value: kLongValue,
                  label: kLongLabel,
                  unit: 'pkg',
                  icon: const Icon(Icons.local_shipping_outlined),
                  overflow: overflow,
                  trend: const StatTrend.up('+12.4%'),
                ),
                width: width,
                textScale: textScale,
              );

              expect(tester.takeException(), isNull);
              expect(errors, isEmpty, reason: describe(errors));
              expect(
                describe(errors),
                isNot(contains('A RenderFlex overflowed')),
              );
            },
          );
        }
      }
    }
  });

  group('unbreakable German compound word', () {
    for (final StatCardOverflow overflow in StatCardOverflow.values) {
      testWidgets('${overflow.name} handles a 46 character compound noun', (
        WidgetTester tester,
      ) async {
        final List<FlutterErrorDetails> errors = await pumpCard(
          tester,
          StatCard(
            value: kGermanCompound,
            label: kGermanCompound,
            overflow: overflow,
          ),
          width: 80,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(errors, isEmpty, reason: describe(errors));
      });
    }
  });

  group('every layout survives the worst case', () {
    for (final StatCardLayout layout in StatCardLayout.values) {
      testWidgets('${layout.name} at 100px with textScaler 2.0', (
        WidgetTester tester,
      ) async {
        final List<FlutterErrorDetails> errors = await pumpCard(
          tester,
          StatCard(
            // 12 characters of value, a 40 character label, as specified.
            value: '1,248,930.55',
            label: 'Total deliveries completed this month xx',
            icon: const Icon(Icons.local_shipping_outlined),
            layout: layout,
            unit: 'kg',
            trend: const StatTrend.down('-3.1%'),
          ),
          width: 100,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(errors, isEmpty, reason: describe(errors));
      });
    }
  });

  group('right to left and dark mode', () {
    for (final TextDirection direction in TextDirection.values) {
      for (final Brightness brightness in Brightness.values) {
        testWidgets('${direction.name} / ${brightness.name} at 120px', (
          WidgetTester tester,
        ) async {
          final List<FlutterErrorDetails> errors = await pumpCard(
            tester,
            const StatCard(
              value: kLongValue,
              label: 'إجمالي عمليات التسليم المكتملة هذا الشهر',
              unit: 'kg',
              icon: Icon(Icons.local_shipping_outlined),
              trend: StatTrend.flat('0.0%'),
            ),
            width: 120,
            textScale: 1.75,
            direction: direction,
            brightness: brightness,
          );

          expect(tester.takeException(), isNull);
          expect(errors, isEmpty, reason: describe(errors));
        });
      }
    }
  });

  group('presets and loading', () {
    testWidgets('compact survives the worst case', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = await pumpCard(
        tester,
        const StatCard.compact(
          value: kLongValue,
          label: kLongLabel,
          unit: 'pkg',
          icon: Icon(Icons.star),
          trend: StatTrend.up('+1%'),
        ),
        width: 80,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(errors, isEmpty, reason: describe(errors));
    });

    testWidgets('the loading skeleton survives the worst case', (
      WidgetTester tester,
    ) async {
      for (final StatCardLayout layout in StatCardLayout.values) {
        final List<FlutterErrorDetails> errors = await pumpCard(
          tester,
          StatCard.loading(icon: const Icon(Icons.star), layout: layout),
          width: 80,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty, reason: describe(errors));
      }
    });
  });

  group('a grid of worst case cards', () {
    testWidgets('never overflows from 240px to 2000px at textScaler 2.0', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2400, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (double width = 240; width <= 2000; width += 40) {
        final List<FlutterErrorDetails> errors = await pumpCard(
          tester,
          const StatCardGrid(
            children: <StatCard>[
              StatCard(value: kLongValue, label: kLongLabel, unit: 'pkg'),
              StatCard(value: kGermanCompound, label: kGermanCompound),
              StatCard(
                value: '4.8',
                label: 'Satisfaction',
                trend: StatTrend.up('+0.2'),
              ),
            ],
          ),
          width: width,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: 'at width $width');
        expect(errors, isEmpty, reason: 'at width $width: ${describe(errors)}');
      }
    });
  });
}
