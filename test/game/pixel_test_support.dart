import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A rendered test image whose pixels can be read back.
class Pixels {
  Pixels(this.width, this.height, this._data);

  final int width;
  final int height;
  final ByteData _data;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      _data.getUint8(i + 3),
      _data.getUint8(i),
      _data.getUint8(i + 1),
      _data.getUint8(i + 2),
    );
  }

  double luminance(int x, int y) => at(x, y).computeLuminance();

  /// Largest channel spread: ~0 for grey metal, high for saturated colour.
  double saturation(int x, int y) {
    final c = at(x, y);
    final hi = [c.r, c.g, c.b].reduce((a, b) => a > b ? a : b);
    final lo = [c.r, c.g, c.b].reduce((a, b) => a < b ? a : b);
    return hi - lo;
  }

  /// Sum of absolute channel differences between two images of equal size.
  double differenceFrom(Pixels other, {int step = 3}) {
    var total = 0.0;
    for (var y = 0; y < height; y += step) {
      for (var x = 0; x < width; x += step) {
        final a = at(x, y), b = other.at(x, y);
        total += (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
      }
    }
    return total;
  }
}

/// Draws onto a [size] square over [background] and returns the pixels.
Future<Pixels> renderPixels(
  WidgetTester t,
  void Function(Canvas canvas) draw, {
  int size = 100,
  Color background = const Color(0xFF1E2433),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = background,
  );
  draw(canvas);
  final image = await t.runAsync(
    () => recorder.endRecording().toImage(size, size),
  );
  final data = await t.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return Pixels(size, size, data!);
}
