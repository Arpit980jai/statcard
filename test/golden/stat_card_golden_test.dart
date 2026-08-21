@Tags(<String>['golden'])
library;

import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [card] in a deterministic, screenshot sized harness.
Widget harness(
  Widget card, {
  required Brightness brightness,
  required TextDirection direction,
  required double textScale,
  double width = 260,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: brightness, useMaterial3: true),
    home: Directionality(
      textDirection: direction,
      child: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: width, child: card),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> expectGolden(
  WidgetTester tester,
  Widget card,
  String name, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1.0,
  Size surface = const Size(320, 240),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    harness(
      card,
      brightness: brightness,
      direction: direction,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

const StatCard kDefaultCard = StatCard(
  value: '1,248',
  label: 'Deliveries this month',
  unit: 'pkg',
  icon: Icon(Icons.local_shipping_outlined),
  trend: StatTrend.up('+12.4%'),
);

void main() {
  testWidgets('default light', (WidgetTester tester) async {
    await expectGolden(tester, kDefaultCard, 'default_light');
  });

  testWidgets('default dark', (WidgetTester tester) async {
    await expectGolden(
      tester,
      kDefaultCard,
      'default_dark',
      brightness: Brightness.dark,
    );
  });

  testWidgets('default rtl', (WidgetTester tester) async {
    await expectGolden(
      tester,
      kDefaultCard,
      'default_rtl',
      direction: TextDirection.rtl,
    );
  });

  testWidgets('default at textScaler 2.0', (WidgetTester tester) async {
    await expectGolden(
      tester,
      kDefaultCard,
      'default_text_scale_2',
      textScale: 2,
      surface: const Size(320, 360),
    );
  });

  testWidgets('compact', (WidgetTester tester) async {
    await expectGolden(
      tester,
      const StatCard.compact(
        value: '42',
        label: 'Open tickets awaiting triage',
        icon: Icon(Icons.confirmation_number_outlined),
      ),
      'compact',
    );
  });

  testWidgets('loading skeleton', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      harness(
        const StatCard.loading(icon: Icon(Icons.local_shipping_outlined)),
        brightness: Brightness.light,
        direction: TextDirection.ltr,
        textScale: 1,
      ),
    );
    // Land on a fixed point of the pulse instead of settling, which would
    // never terminate for a repeating animation.
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/loading.png'),
    );
  });

  for (final StatCardLayout layout in StatCardLayout.values) {
    testWidgets('layout ${layout.name}', (WidgetTester tester) async {
      await expectGolden(
        tester,
        StatCard(
          value: '1,248',
          label: 'Deliveries this month',
          unit: 'pkg',
          icon: const Icon(Icons.local_shipping_outlined),
          layout: layout,
        ),
        'layout_${layout.name}',
      );
    });
  }

  testWidgets('narrow card with a very long label', (
    WidgetTester tester,
  ) async {
    await expectGolden(
      tester,
      const StatCard(
        value: '1,248,930',
        label: 'Total Deliveries Completed This Month',
        icon: Icon(Icons.local_shipping_outlined),
      ),
      'narrow_long_label',
      surface: const Size(160, 200),
    );
  });

  testWidgets('grid', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: StatCardGrid(
              children: <StatCard>[
                StatCard(value: '1,248', label: 'Deliveries'),
                StatCard(value: '4.2L', label: 'Revenue', unit: 'INR'),
                StatCard(value: '312', label: 'Active users'),
                StatCard(value: '18', label: 'Pending pickups'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/grid.png'),
    );
  });
}
