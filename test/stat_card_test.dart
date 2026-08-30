import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:adaptive_stat_card/src/widgets/stat_card_skeleton.dart';
import 'package:adaptive_stat_card/src/widgets/stat_trend_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester,
  Widget card, {
  double width = 260,
  TextDirection direction = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: card),
          ),
        ),
      ),
    ),
  );
}

/// The horizontal centre of a widget, used to assert icon placement.
double centerX(WidgetTester tester, Finder finder) =>
    tester.getCenter(finder).dx;

void main() {
  group('content', () {
    testWidgets('renders the value, label, unit and icon', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          unit: 'pkg',
          icon: Icon(Icons.local_shipping_outlined),
        ),
      );

      expect(find.textContaining('1,248', findRichText: true), findsOneWidget);
      expect(find.textContaining('pkg', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Deliveries', findRichText: true),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('renders a trend badge only when a trend is supplied', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard(value: '10', label: 'Orders'));
      expect(find.byType(StatTrendBadge), findsNothing);

      await pump(
        tester,
        const StatCard(
          value: '10',
          label: 'Orders',
          trend: StatTrend.up('+12.4%'),
        ),
      );
      expect(find.byType(StatTrendBadge), findsOneWidget);
      expect(find.textContaining('+12.4%', findRichText: true), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('picks the right glyph for every trend direction', (
      WidgetTester tester,
    ) async {
      const List<(StatTrend, IconData)> cases = <(StatTrend, IconData)>[
        (StatTrend.up('+1%'), Icons.arrow_upward_rounded),
        (StatTrend.down('-1%'), Icons.arrow_downward_rounded),
        (StatTrend.flat('0%'), Icons.trending_flat_rounded),
      ];
      for (final (StatTrend trend, IconData glyph) in cases) {
        await pump(
          tester,
          StatCard(value: '10', label: 'Orders', trend: trend),
        );
        expect(find.byIcon(glyph), findsOneWidget);
      }
    });

    testWidgets('a trend colour override wins over the theme', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '10',
          label: 'Orders',
          trend: StatTrend.up('+1%', color: Color(0xFF00FF00)),
        ),
      );
      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.arrow_upward_rounded),
      );
      expect(icon.color, const Color(0xFF00FF00));
    });
  });

  group('interaction', () {
    testWidgets('onTap fires', (WidgetTester tester) async {
      var taps = 0;
      await pump(
        tester,
        StatCard(value: '1', label: 'One', onTap: () => taps++),
      );
      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('no InkWell is added when onTap is null', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard(value: '1', label: 'One'));
      expect(
        find.descendant(
          of: find.byType(StatCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('an InkWell is added when onTap is set', (
      WidgetTester tester,
    ) async {
      await pump(tester, StatCard(value: '1', label: 'One', onTap: () {}));
      expect(
        find.descendant(
          of: find.byType(StatCard),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });
  });

  group('loading', () {
    testWidgets('isLoading shows the skeleton and hides the text', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(value: '1,248', label: 'Deliveries', isLoading: true),
      );
      expect(find.byType(StatCardSkeleton), findsOneWidget);
      expect(find.textContaining('1,248', findRichText: true), findsNothing);
      expect(
        find.textContaining('Deliveries', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('StatCard.loading needs no value or label', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard.loading());
      expect(find.byType(StatCardSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the skeleton disposes its controller cleanly', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard.loading());
      await tester.pump(const Duration(milliseconds: 400));
      await pump(tester, const StatCard(value: '1', label: 'One'));
      expect(find.byType(StatCardSkeleton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the skeleton holds still when animations are disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SizedBox(width: 200, child: StatCard.loading()),
            ),
          ),
        ),
      );
      final FadeTransition fade = tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(StatCardSkeleton),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('the card exposes one node holding value and label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const StatCard(value: '1,248', label: 'Deliveries', unit: 'pkg'),
      );
      expect(find.bySemanticsLabel('Deliveries: 1,248pkg'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('semanticsLabel overrides the generated label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          semanticsLabel: 'One thousand two hundred forty eight deliveries',
        ),
      );
      expect(
        find.bySemanticsLabel(
          'One thousand two hundred forty eight deliveries',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Deliveries: 1,248'), findsNothing);
      handle.dispose();
    });

    testWidgets('a tappable card is announced as a button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, StatCard(value: '1', label: 'One', onTap: () {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('One: 1')),
        // ignore: deprecated_member_use
        containsSemantics(label: 'One: 1', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group('layouts', () {
    const Widget icon = Icon(Icons.star, key: ValueKey<String>('icon'));

    testWidgets('iconLeading puts the icon before the text', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconLeading,
        ),
      );
      expect(
        centerX(tester, find.byKey(const ValueKey<String>('icon'))),
        lessThan(
          centerX(tester, find.textContaining('1,248', findRichText: true)),
        ),
      );
    });

    testWidgets('iconTrailing puts the icon after the text', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconTrailing,
        ),
      );
      expect(
        centerX(tester, find.byKey(const ValueKey<String>('icon'))),
        greaterThan(
          centerX(tester, find.textContaining('1,248', findRichText: true)),
        ),
      );
    });

    testWidgets('iconLeading and iconTrailing mirror each other', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconLeading,
        ),
      );
      final double leadingX = centerX(
        tester,
        find.byKey(const ValueKey<String>('icon')),
      );

      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconTrailing,
        ),
      );
      final double trailingX = centerX(
        tester,
        find.byKey(const ValueKey<String>('icon')),
      );

      expect(leadingX, lessThan(trailingX));
    });

    testWidgets('iconAbove puts the icon above the value', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconAbove,
        ),
      );
      final double iconY = tester
          .getCenter(find.byKey(const ValueKey<String>('icon')))
          .dy;
      final double valueY = tester
          .getCenter(find.textContaining('1,248', findRichText: true))
          .dy;
      expect(iconY, lessThan(valueY));
    });

    testWidgets('noIcon drops the icon entirely', (WidgetTester tester) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.noIcon,
        ),
      );
      expect(find.byKey(const ValueKey<String>('icon')), findsNothing);
    });

    testWidgets('RTL mirrors the leading icon to the right', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconLeading,
        ),
      );
      final double ltrX = centerX(
        tester,
        find.byKey(const ValueKey<String>('icon')),
      );

      await pump(
        tester,
        const StatCard(
          value: '1,248',
          label: 'Deliveries',
          icon: icon,
          layout: StatCardLayout.iconLeading,
        ),
        direction: TextDirection.rtl,
      );
      final double rtlX = centerX(
        tester,
        find.byKey(const ValueKey<String>('icon')),
      );

      expect(rtlX, greaterThan(ltrX));
    });
  });

  group('presets', () {
    testWidgets('compact uses a single label line and tighter padding', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard.compact(value: '42', label: 'Open tickets'),
      );
      expect(tester.takeException(), isNull);

      final StatCard card = tester.widget<StatCard>(find.byType(StatCard));
      expect(card.labelMaxLines, 1);
      expect(card.overflow, StatCardOverflow.ellipsis);
    });

    testWidgets('compact renders in less vertical space than the default', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatCard(value: '42', label: 'Open tickets'));
      final double defaultHeight = tester.getSize(find.byType(StatCard)).height;

      await pump(
        tester,
        const StatCard.compact(value: '42', label: 'Open tickets'),
      );
      final double compactHeight = tester.getSize(find.byType(StatCard)).height;

      expect(compactHeight, lessThan(defaultHeight));
    });

    testWidgets('an explicit padding overrides the preset', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const StatCard(
          value: '42',
          label: 'Tickets',
          padding: EdgeInsets.all(40),
        ),
      );
      final Padding padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(StatCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(40));
    });
  });
}
