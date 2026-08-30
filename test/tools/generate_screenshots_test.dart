@Tags(<String>['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regenerates the PNGs the README and `pubspec.yaml` point at.
///
/// This is a generator, not an assertion, so it is tagged `screenshots` and
/// excluded from the normal suite. Run it deliberately:
///
/// ```sh
/// flutter test --tags screenshots
/// ```
///
/// The widget tester renders text with a placeholder font that draws every
/// glyph as a filled box, which is fine for goldens and useless for a
/// screenshot. Real fonts are loaded first, taken from the Flutter SDK's own
/// `material_fonts` artifact so that any machine with a Flutter SDK
/// regenerates the same images — Roboto is what a stock Material app paints
/// with anyway. If the artifact cannot be found the generator skips rather
/// than writing boxes over good images.
const String kOut = 'doc/images';

const List<double> kSeries = <double>[3, 5, 4, 9, 7, 12, 11, 15, 13, 18];

/// Locates `bin/cache/artifacts/material_fonts` in the running SDK.
///
/// The test binary is `<sdk>/bin/cache/artifacts/engine/<platform>/
/// flutter_tester`, so the artifact directory is a short walk up from it.
Directory? findMaterialFonts() {
  Directory? dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8 && dir != null; i++) {
    final Directory candidate = Directory(
      '${dir.path}${Platform.pathSeparator}material_fonts',
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    final Directory parent = dir.parent;
    dir = parent.path == dir.path ? null : parent;
  }
  return null;
}

/// Loads [file] from [dir] into the engine under [family].
Future<void> loadFont(Directory dir, String family, String file) async {
  final Uint8List bytes = await File(
    '${dir.path}${Platform.pathSeparator}$file',
  ).readAsBytes();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// A theme that paints with the loaded font instead of the test placeholder.
ThemeData screenshotTheme(Brightness brightness) {
  final ThemeData base = ThemeData(
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF3B6EF3),
    useMaterial3: true,
    fontFamily: 'Screenshot',
  );
  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      StatCardThemeData(
        valueStyle: base.textTheme.headlineSmall?.copyWith(
          fontFamily: 'ScreenshotBold',
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    ],
  );
}

/// Renders [child] at [size] and writes it to `doc/images/<name>.png`.
Future<void> shoot(
  WidgetTester tester,
  String name,
  Widget child, {
  required Size size,
  Brightness brightness = Brightness.light,
  double devicePixelRatio = 2,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    return tester.binding.setSurfaceSize(null);
  });

  final GlobalKey key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: screenshotTheme(brightness),
        home: Scaffold(
          backgroundColor: brightness == Brightness.dark
              ? const Color(0xFF0E1117)
              : const Color(0xFFF7F8FC),
          body: Center(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // Rasterising and PNG-encoding are real engine work, so they have to escape
  // the fake-async zone the widget tester runs the test body in.
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: devicePixelRatio);
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();

    final File file = File('$kOut/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// The card content used in the before/after pair.
const String kBigValue = '1,248,930';
const String kLongLabel = 'Total Deliveries Completed This Month';

void main() {
  setUp(clearFitCache);

  setUpAll(() async {
    final Directory? fonts = findMaterialFonts();
    if (fonts == null) {
      return;
    }
    await loadFont(fonts, 'Screenshot', 'roboto-regular.ttf');
    await loadFont(fonts, 'ScreenshotBold', 'roboto-bold.ttf');
    // Without this every Icon paints as an empty square.
    await loadFont(fonts, 'MaterialIcons', 'materialicons-regular.otf');
  });

  testWidgets('generates the README and pub.dev screenshots', (
    WidgetTester tester,
  ) async {
    if (findMaterialFonts() == null) {
      markTestSkipped(
        'no Flutter material_fonts artifact found; cannot render legible text',
      );
      return;
    }

    // 1. The problem: a plain Column at a width that does not fit.
    await shoot(
      tester,
      'overflow-before',
      const SizedBox(
        width: 200,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  kBigValue,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ScreenshotBold',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  kLongLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      size: const Size(280, 140),
    );

    // 2. The fix: the same content in a StatCard at the same width.
    await shoot(
      tester,
      'overflow-after',
      const SizedBox(
        width: 200,
        child: StatCard(
          value: kBigValue,
          label: kLongLabel,
          icon: Icon(Icons.local_shipping_outlined),
          trend: StatTrend.up('+12.4%'),
        ),
      ),
      size: const Size(280, 140),
    );

    // 3. The gallery: layouts, trend badges, sparklines, states.
    await shoot(
      tester,
      'gallery',
      const Padding(
        padding: EdgeInsets.all(24),
        child: StatCardGrid(
          minCardWidth: 200,
          children: <StatCard>[
            StatCard(
              value: '1,248',
              label: 'Deliveries this month',
              unit: 'pkg',
              icon: Icon(Icons.local_shipping_outlined),
              trend: StatTrend.up('+12.4%'),
            ),
            StatCard(
              value: '4.2',
              label: 'Revenue',
              unit: 'Cr',
              icon: Icon(Icons.currency_rupee),
              trend: StatTrend.up('+3.1%'),
              sparkline: kSeries,
            ),
            StatCard(
              value: '312',
              label: 'Active users right now',
              icon: Icon(Icons.people_outline),
              layout: StatCardLayout.iconAbove,
              trend: StatTrend.down('-1.4%'),
            ),
            StatCard(
              value: '18',
              label: 'Pending pickups',
              icon: Icon(Icons.inventory_2_outlined),
              trend: StatTrend.flat('0.0%'),
              sparkline: kSeries,
            ),
          ],
        ),
      ),
      size: const Size(900, 216),
    );

    // 4. The sync scope, shown as the pair it only makes sense as.
    await shoot(
      tester,
      'sync-scope',
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Without a scope — every card fits its own text'),
            const SizedBox(height: 8),
            _syncRow(),
            const SizedBox(height: 24),
            const Text('StatCardSyncScope — one size across the row'),
            const SizedBox(height: 8),
            StatCardSyncScope(child: _syncRow()),
          ],
        ),
      ),
      size: const Size(560, 300),
    );

    // 5. The numeric ladder: the same number at three widths.
    await shoot(
      tester,
      'number-degradation',
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final double width in <double>[
              220,
              140,
              116,
              100,
            ]) ...<Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${width.toInt()} px'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: width,
                    child: StatCard.number(
                      1250000,
                      label: 'Deliveries this month',
                      icon: const Icon(Icons.local_shipping_outlined),
                      trend: const StatTrend.up('+12.4%'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ),
      size: const Size(760, 280),
    );

    // 6. Dark mode, so the pub.dev gallery shows both.
    await shoot(
      tester,
      'dark-mode',
      const Padding(
        padding: EdgeInsets.all(24),
        child: StatCardGrid(
          minCardWidth: 200,
          children: <StatCard>[
            StatCard(
              value: '1,248',
              label: 'Deliveries this month',
              unit: 'pkg',
              icon: Icon(Icons.local_shipping_outlined),
              trend: StatTrend.up('+12.4%'),
              sparkline: kSeries,
            ),
            StatCard(
              value: '99.97',
              label: 'Uptime',
              unit: '%',
              icon: Icon(Icons.bolt_outlined),
              trend: StatTrend.flat('0.0%'),
            ),
          ],
        ),
      ),
      size: const Size(660, 200),
      brightness: Brightness.dark,
    );
  });
}

/// Three cards whose values need very different sizes.
Widget _syncRow() {
  return const Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: 150,
        child: StatCard(value: '1,248,930,551', label: 'Deliveries'),
      ),
      SizedBox(width: 12),
      SizedBox(
        width: 150,
        child: StatCard(value: '42', label: 'Open tickets'),
      ),
      SizedBox(width: 12),
      SizedBox(
        width: 150,
        child: StatCard(value: '4.8', label: 'Satisfaction'),
      ),
    ],
  );
}
