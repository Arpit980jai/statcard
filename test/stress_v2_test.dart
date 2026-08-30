import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic worst case English label.
const String kLongLabel = 'Total Deliveries Completed This Month';

/// A German compound noun with no break opportunities at all.
const String kGermanCompound = 'Rindfleischetikettierungsueberwachungsaufgaben';

/// A series long enough that the points crowd together.
const List<double> kSeries = <double>[
  3,
  5,
  4,
  9,
  8,
  12,
  11,
  15,
  2,
  18,
  7,
  9,
  14,
  1,
];

const List<double> kWidths = <double>[80, 120, 160, 240];
const List<double> kTextScales = <double>[1.0, 1.3, 1.75, 2.0];

/// Numbers that exercise every rung of the degradation ladder.
const List<num> kNumbers = <num>[
  0,
  -7,
  999,
  1250,
  1250000,
  1248930551,
  -1248930551.75,
  4.85,
];

/// Pumps [card] and returns every error the framework logged during layout.
Future<List<FlutterErrorDetails>> pumpCard(
  WidgetTester tester,
  Widget card, {
  required double width,
  required double textScale,
  TextDirection direction = TextDirection.ltr,
}) async {
  final errors = <FlutterErrorDetails>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = errors.add;

  try {
    await tester.pumpWidget(
      MaterialApp(
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

String describe(List<FlutterErrorDetails> errors) =>
    errors.map((FlutterErrorDetails e) => e.exceptionAsString()).join('\n');

void main() {
  setUp(clearFitCache);

  group('StatCard.number survives every width and text scale', () {
    for (final double width in kWidths) {
      for (final double textScale in kTextScales) {
        testWidgets('${width.toInt()}px, textScaler $textScale', (
          WidgetTester tester,
        ) async {
          for (final StatCardValueFormat format in StatCardValueFormat.values) {
            for (final num value in kNumbers) {
              final List<FlutterErrorDetails> errors = await pumpCard(
                tester,
                StatCard.number(
                  value,
                  label: kLongLabel,
                  format: format,
                  unit: 'pkg',
                  icon: const Icon(Icons.local_shipping_outlined),
                  trend: const StatTrend.up('+12.4%'),
                ),
                width: width,
                textScale: textScale,
              );
              expect(
                tester.takeException(),
                isNull,
                reason: '$value as $format',
              );
              expect(errors, isEmpty, reason: describe(errors));
            }
          }
        });
      }
    }
  });

  group('sparklines survive every width and text scale', () {
    for (final double width in kWidths) {
      for (final double textScale in kTextScales) {
        testWidgets('${width.toInt()}px, textScaler $textScale', (
          WidgetTester tester,
        ) async {
          final List<FlutterErrorDetails> errors = await pumpCard(
            tester,
            const StatCard(
              value: '1,248,930',
              label: kLongLabel,
              sparkline: kSeries,
              unit: 'pkg',
              icon: Icon(Icons.local_shipping_outlined),
              trend: StatTrend.down('-3.1%'),
            ),
            width: width,
            textScale: textScale,
          );
          expect(tester.takeException(), isNull);
          expect(errors, isEmpty, reason: describe(errors));
        });
      }
    }
  });

  group('the new card states survive every width and text scale', () {
    for (final double width in kWidths) {
      for (final double textScale in kTextScales) {
        testWidgets('${width.toInt()}px, textScaler $textScale', (
          WidgetTester tester,
        ) async {
          final List<Widget> cards = <Widget>[
            const StatCard(
              value: '',
              label: kLongLabel,
              error: 'The metrics service did not respond within 30 seconds',
            ),
            const StatCard(value: '', label: kGermanCompound),
            const StatCard(
              value: '1,248,930',
              label: kLongLabel,
              selected: true,
              icon: Icon(Icons.star),
            ),
            StatCard(
              value: '1,248,930',
              label: kLongLabel,
              onLongPress: () {},
              onTap: () {},
            ),
          ];

          for (final Widget card in cards) {
            final List<FlutterErrorDetails> errors = await pumpCard(
              tester,
              card,
              width: width,
              textScale: textScale,
            );
            expect(tester.takeException(), isNull);
            expect(errors, isEmpty, reason: describe(errors));
          }
        });
      }
    }
  });

  group('an animating number survives every width and text scale', () {
    for (final double width in kWidths) {
      for (final double textScale in kTextScales) {
        testWidgets('${width.toInt()}px, textScaler $textScale', (
          WidgetTester tester,
        ) async {
          await pumpCard(
            tester,
            StatCard.number(
              1248930551,
              label: kLongLabel,
              animateValue: true,
              unit: 'pkg',
            ),
            width: width,
            textScale: textScale,
          );

          // Count all the way down to a single digit, checking every frame.
          final List<FlutterErrorDetails> errors = await pumpCard(
            tester,
            StatCard.number(
              5,
              label: kLongLabel,
              animateValue: true,
              unit: 'pkg',
            ),
            width: width,
            textScale: textScale,
          );
          expect(errors, isEmpty, reason: describe(errors));

          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 20));
            expect(tester.takeException(), isNull, reason: 'on frame $i');
          }
          await tester.pumpAndSettle();
        });
      }
    }
  });

  group('a sync scope survives every width and text scale', () {
    for (final double width in kWidths) {
      for (final double textScale in kTextScales) {
        testWidgets('${width.toInt()}px, textScaler $textScale', (
          WidgetTester tester,
        ) async {
          await tester.binding.setSurfaceSize(const Size(1400, 3000));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final List<FlutterErrorDetails> errors = await pumpCard(
            tester,
            StatCardSyncScope(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StatCard.number(1248930551, label: kLongLabel, unit: 'pkg'),
                  const StatCard(value: '4', label: 'Ok'),
                  const StatCard(
                    value: kGermanCompound,
                    label: kGermanCompound,
                  ),
                  const StatCard(
                    value: '1,248',
                    label: kLongLabel,
                    sparkline: kSeries,
                  ),
                  const StatCard(value: '', label: 'Empty', error: 'boom'),
                ],
              ),
            ),
            width: width,
            textScale: textScale,
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(errors, isEmpty, reason: describe(errors));
        });
      }
    }
  });

  group('a synchronised grid survives every width and text scale', () {
    for (final double textScale in kTextScales) {
      testWidgets('240px to 2000px at textScaler $textScale', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(2400, 4000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (double width = 240; width <= 2000; width += 160) {
          final List<FlutterErrorDetails> errors = await pumpCard(
            tester,
            StatCardSyncScope(
              child: StatCardGrid(
                children: <StatCard>[
                  StatCard.number(1248930551, label: kLongLabel, unit: 'pkg'),
                  const StatCard(
                    value: kGermanCompound,
                    label: kGermanCompound,
                  ),
                  const StatCard(
                    value: '4.8',
                    label: 'Satisfaction',
                    sparkline: kSeries,
                    trend: StatTrend.up('+0.2'),
                  ),
                  const StatCard(value: '', label: 'Down', error: 'boom'),
                ],
              ),
            ),
            width: width,
            textScale: textScale,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'at width $width');
          expect(
            errors,
            isEmpty,
            reason: 'at width $width: ${describe(errors)}',
          );
        }
      });
    }
  });

  group('right to left', () {
    for (final double width in kWidths) {
      testWidgets('${width.toInt()}px at textScaler 2.0', (
        WidgetTester tester,
      ) async {
        final List<FlutterErrorDetails> errors = await pumpCard(
          tester,
          StatCardSyncScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StatCard.number(
                  1248930551,
                  label: 'إجمالي عمليات التسليم المكتملة هذا الشهر',
                  unit: 'kg',
                  sparkline: kSeries,
                  icon: const Icon(Icons.local_shipping_outlined),
                ),
                const StatCard(
                  value: '',
                  label: 'إجمالي عمليات التسليم',
                  error: 'خطأ',
                  selected: true,
                ),
              ],
            ),
          ),
          width: width,
          textScale: 2,
          direction: TextDirection.rtl,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty, reason: describe(errors));
      });
    }
  });
}
