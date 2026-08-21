import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns the [Material] that paints the card surface.
Material cardMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find
        .descendant(of: find.byType(StatCard), matching: find.byType(Material))
        .first,
  );
}

double cardRadius(WidgetTester tester) {
  final shape = cardMaterial(tester).shape! as RoundedRectangleBorder;
  return (shape.borderRadius.resolve(TextDirection.ltr)).topLeft.x;
}

Future<void> pumpCard(
  WidgetTester tester, {
  ThemeData? themeData,
  StatCardThemeData? ancestorTheme,
  StatCardThemeData? widgetTheme,
}) {
  Widget card = SizedBox(
    width: 200,
    child: StatCard(value: '1,248', label: 'Deliveries', theme: widgetTheme),
  );
  if (ancestorTheme != null) {
    card = StatCardTheme(data: ancestorTheme, child: card);
  }
  return tester.pumpWidget(
    MaterialApp(
      theme: themeData,
      home: Scaffold(body: Center(child: card)),
    ),
  );
}

void main() {
  group('resolution order', () {
    testWidgets('a ThemeData extension is applied', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        themeData: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            StatCardThemeData(
              backgroundColor: Color(0xFF112233),
              borderRadius: 30,
            ),
          ],
        ),
      );
      expect(cardMaterial(tester).color, const Color(0xFF112233));
      expect(cardRadius(tester), 30);
    });

    testWidgets('a StatCardTheme ancestor beats the ThemeData extension', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        themeData: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            StatCardThemeData(backgroundColor: Color(0xFF112233)),
          ],
        ),
        ancestorTheme: const StatCardThemeData(
          backgroundColor: Color(0xFF445566),
        ),
      );
      expect(cardMaterial(tester).color, const Color(0xFF445566));
    });

    testWidgets('the per-widget theme beats both other layers', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        themeData: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            StatCardThemeData(backgroundColor: Color(0xFF112233)),
          ],
        ),
        ancestorTheme: const StatCardThemeData(
          backgroundColor: Color(0xFF445566),
        ),
        widgetTheme: const StatCardThemeData(
          backgroundColor: Color(0xFF778899),
        ),
      );
      expect(cardMaterial(tester).color, const Color(0xFF778899));
    });

    testWidgets('a partial theme still inherits the fallback colours', (
      WidgetTester tester,
    ) async {
      final ThemeData themeData = ThemeData(useMaterial3: true);
      await pumpCard(
        tester,
        themeData: themeData,
        widgetTheme: const StatCardThemeData(borderRadius: 4),
      );
      expect(cardRadius(tester), 4);
      // The background was never set on the override, so it must still come
      // from the derived fallback rather than being null.
      expect(
        cardMaterial(tester).color,
        themeData.colorScheme.surfaceContainerHighest,
      );
    });

    testWidgets('layers merge field by field rather than wholesale', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        themeData: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            StatCardThemeData(backgroundColor: Color(0xFF112233)),
          ],
        ),
        widgetTheme: const StatCardThemeData(borderRadius: 2),
      );
      // borderRadius from the widget, backgroundColor from the extension.
      expect(cardRadius(tester), 2);
      expect(cardMaterial(tester).color, const Color(0xFF112233));
    });
  });

  group('fallback', () {
    testWidgets('populates every field in light and dark mode', (
      WidgetTester tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        late StatCardThemeData resolved;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Builder(
              builder: (BuildContext context) {
                resolved = StatCardThemeData.fallback(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(resolved.backgroundColor, isNotNull);
        expect(resolved.borderColor, isNotNull);
        expect(resolved.iconColor, isNotNull);
        expect(resolved.upColor, isNotNull);
        expect(resolved.downColor, isNotNull);
        expect(resolved.flatColor, isNotNull);
        expect(resolved.skeletonBaseColor, isNotNull);
        expect(resolved.valueStyle, isNotNull);
        expect(resolved.labelStyle, isNotNull);
        expect(resolved.unitStyle, isNotNull);
        expect(resolved.trendStyle, isNotNull);
        expect(resolved.borderRadius, isNotNull);
        expect(resolved.borderWidth, isNotNull);
        expect(resolved.elevation, isNotNull);
        expect(resolved.iconSize, isNotNull);
        expect(resolved.spacing, isNotNull);
        expect(resolved.padding, isNotNull);
      }
    });

    testWidgets('works with Material 2 as well as Material 3', (
      WidgetTester tester,
    ) async {
      for (final bool useMaterial3 in <bool>[false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: useMaterial3),
            home: const Scaffold(
              body: SizedBox(
                width: 200,
                child: StatCard(value: '1', label: 'One'),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(cardMaterial(tester).color, isNotNull);
      }
    });
  });

  group('value semantics', () {
    const StatCardThemeData a = StatCardThemeData(
      backgroundColor: Color(0xFF000000),
      borderRadius: 10,
      spacing: 4,
    );

    test('equality and hashCode follow the fields', () {
      expect(
        a,
        equals(
          const StatCardThemeData(
            backgroundColor: Color(0xFF000000),
            borderRadius: 10,
            spacing: 4,
          ),
        ),
      );
      expect(
        a.hashCode,
        const StatCardThemeData(
          backgroundColor: Color(0xFF000000),
          borderRadius: 10,
          spacing: 4,
        ).hashCode,
      );
      expect(a, isNot(equals(const StatCardThemeData(borderRadius: 11))));
      expect(a, equals(a));
    });

    test('copyWith replaces only what it is given', () {
      final StatCardThemeData copy = a.copyWith(borderRadius: 20);
      expect(copy.borderRadius, 20);
      expect(copy.backgroundColor, a.backgroundColor);
      expect(copy.spacing, a.spacing);
      expect(a.copyWith(), equals(a));
    });

    test('merge lets the other side win field by field', () {
      final StatCardThemeData merged = a.merge(
        const StatCardThemeData(borderRadius: 99),
      );
      expect(merged.borderRadius, 99);
      expect(merged.backgroundColor, a.backgroundColor);
      expect(a.merge(null), same(a));
    });

    test('lerp interpolates colours and numbers', () {
      const StatCardThemeData b = StatCardThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        borderRadius: 20,
        spacing: 8,
      );
      final StatCardThemeData mid = a.lerp(b, 0.5);
      expect(mid.borderRadius, 15);
      expect(mid.spacing, 6);
      expect(
        mid.backgroundColor,
        Color.lerp(a.backgroundColor, b.backgroundColor, 0.5),
      );
      expect(a.lerp(b, 0), equals(a));
      expect(a.lerp(b, 1), equals(b));
    });

    test('lerp returns itself for a foreign extension', () {
      expect(a.lerp(null, 0.5), same(a));
    });
  });

  testWidgets('StatCardTheme.maybeOf finds and misses correctly', (
    WidgetTester tester,
  ) async {
    StatCardThemeData? withoutAncestor;
    StatCardThemeData? withAncestor;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            Builder(
              builder: (BuildContext context) {
                withoutAncestor = StatCardTheme.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
            StatCardTheme(
              data: const StatCardThemeData(spacing: 3),
              child: Builder(
                builder: (BuildContext context) {
                  withAncestor = StatCardTheme.maybeOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
    expect(withoutAncestor, isNull);
    expect(withAncestor?.spacing, 3);
  });

  testWidgets('StatCardTheme notifies dependents only when data changes', (
    WidgetTester tester,
  ) async {
    const StatCardTheme theme = StatCardTheme(
      data: StatCardThemeData(spacing: 3),
      child: SizedBox.shrink(),
    );
    expect(
      theme.updateShouldNotify(
        const StatCardTheme(
          data: StatCardThemeData(spacing: 3),
          child: SizedBox.shrink(),
        ),
      ),
      isFalse,
    );
    expect(
      theme.updateShouldNotify(
        const StatCardTheme(
          data: StatCardThemeData(spacing: 9),
          child: SizedBox.shrink(),
        ),
      ),
      isTrue,
    );
  });
}
