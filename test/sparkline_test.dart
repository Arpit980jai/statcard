import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:adaptive_stat_card/src/widgets/stat_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size kBox = Size(120, 20);
const Color kInk = Color(0xFF3B6EF3);

/// Rasterises [painter] and reports whether it put any ink on the canvas.
Future<bool> paintsAnything(
  SparklinePainter painter, {
  Size size = kBox,
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final ui.Picture picture = recorder.endRecording();
  // Always rasterise into a real box; `size` is only what the painter is told
  // it has, which the degenerate cases deliberately set to zero.
  final ui.Image image = await picture.toImage(
    kBox.width.round(),
    kBox.height.round(),
  );
  final ByteData? data = await image.toByteData();
  picture.dispose();
  image.dispose();
  if (data == null) {
    return false;
  }
  final Uint8List pixels = data.buffer.asUint8List();
  for (var i = 3; i < pixels.length; i += 4) {
    if (pixels[i] != 0) {
      return true;
    }
  }
  return false;
}

SparklinePainter painterFor(List<double> points) =>
    SparklinePainter(points: points, color: kInk, strokeWidth: 1.5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SparklinePainter', () {
    test('draws a series of two or more points', () async {
      expect(await paintsAnything(painterFor(<double>[1, 5, 2, 8])), isTrue);
      expect(await paintsAnything(painterFor(<double>[1, 2])), isTrue);
    });

    test('draws nothing for fewer than two points', () async {
      expect(await paintsAnything(painterFor(<double>[])), isFalse);
      expect(await paintsAnything(painterFor(<double>[7])), isFalse);
    });

    test('draws nothing into a degenerate box', () async {
      expect(
        await paintsAnything(
          painterFor(<double>[1, 5, 2]),
          size: const Size(0, 20),
        ),
        isFalse,
      );
      expect(
        await paintsAnything(
          painterFor(<double>[1, 5, 2]),
          size: const Size(120, 0),
        ),
        isFalse,
      );
    });

    test(
      'draws a flat series down the middle instead of dividing by zero',
      () async {
        expect(await paintsAnything(painterFor(<double>[4, 4, 4, 4])), isTrue);
      },
    );

    test('drops non-finite samples rather than throwing', () async {
      expect(
        await paintsAnything(
          painterFor(<double>[1, double.nan, 5, double.infinity, 2]),
        ),
        isTrue,
      );
      // Only one finite sample survives, so there is no line to draw.
      expect(
        await paintsAnything(painterFor(<double>[double.nan, 3])),
        isFalse,
      );
    });

    test('survives extreme magnitudes', () async {
      expect(
        await paintsAnything(painterFor(<double>[-1e18, 1e18, 0])),
        isTrue,
      );
      expect(await paintsAnything(painterFor(<double>[1e-18, -1e-18])), isTrue);
    });

    test('repaints only when something it draws changed', () {
      final SparklinePainter base = painterFor(<double>[1, 2, 3]);
      expect(base.shouldRepaint(painterFor(<double>[1, 2, 3])), isFalse);
      expect(base.shouldRepaint(painterFor(<double>[1, 2, 4])), isTrue);
      expect(base.shouldRepaint(painterFor(<double>[1, 2])), isTrue);
      expect(
        base.shouldRepaint(
          SparklinePainter(
            points: const <double>[1, 2, 3],
            color: const Color(0xFFFF0000),
            strokeWidth: 1.5,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          SparklinePainter(
            points: const <double>[1, 2, 3],
            color: kInk,
            strokeWidth: 3,
          ),
        ),
        isTrue,
      );
    });
  });

  group('StatSparkline', () {
    testWidgets('takes the height it is given and no more', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: StatSparkline(
                  points: <double>[1, 5, 2, 8],
                  color: kInk,
                  strokeWidth: 1.5,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(StatSparkline)).height, 20);
      expect(tester.takeException(), isNull);
    });
  });
}
