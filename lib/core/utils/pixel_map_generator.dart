import 'dart:io';
import 'dart:ui' as ui;

const int kPixelMapSize = 8;
const int kPixelMapTotal = kPixelMapSize * kPixelMapSize; // 64

/// Reads an image file, downsamples it to 8×8, and returns the 64 pixel
/// colors as a flat list of ARGB integers (row-major order).
Future<List<int>> generatePixelMap(String imagePath) async {
  final bytes = await File(imagePath).readAsBytes();

  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: kPixelMapSize,
    targetHeight: kPixelMapSize,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();

  if (byteData == null) return [];

  final pixels = <int>[];
  for (int i = 0; i < kPixelMapTotal; i++) {
    final offset = i * 4;
    final r = byteData.getUint8(offset);
    final g = byteData.getUint8(offset + 1);
    final b = byteData.getUint8(offset + 2);
    final a = byteData.getUint8(offset + 3);
    pixels.add((a << 24) | (r << 16) | (g << 8) | b);
  }
  return pixels;
}
