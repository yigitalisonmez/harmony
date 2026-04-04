import 'package:flutter/material.dart';
import '../../core/utils/pixel_map_generator.dart';

/// Renders a flat list of [kPixelMapTotal] ARGB ints as a 64×64 pixel grid.
class PixelMapWidget extends StatelessWidget {
  const PixelMapWidget({
    super.key,
    required this.pixels,
    required this.size,
    this.pixelGap = 0.0,
  });

  final List<int> pixels;
  final double size;

  /// Gap between individual pixel squares (default 0 for dense pixel art look).
  final double pixelGap;

  @override
  Widget build(BuildContext context) {
    if (pixels.length < kPixelMapTotal) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelMapPainter(pixels: pixels, gap: pixelGap),
      ),
    );
  }
}

class _PixelMapPainter extends CustomPainter {
  _PixelMapPainter({required this.pixels, required this.gap});

  final List<int> pixels;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / kPixelMapSize;
    final cellH = size.height / kPixelMapSize;
    final paint = Paint()..isAntiAlias = false;

    for (int row = 0; row < kPixelMapSize; row++) {
      for (int col = 0; col < kPixelMapSize; col++) {
        paint.color = Color(pixels[row * kPixelMapSize + col]);
        canvas.drawRect(
          Rect.fromLTWH(
            col * cellW + gap / 2,
            row * cellH + gap / 2,
            cellW - gap,
            cellH - gap,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelMapPainter old) =>
      old.pixels != pixels || old.gap != gap;
}
