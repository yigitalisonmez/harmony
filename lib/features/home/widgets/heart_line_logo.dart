import 'dart:math' as math;
import 'package:flutter/material.dart';

class HeartLineLogo extends StatefulWidget {
  const HeartLineLogo({
    super.key,
    this.size = 48,
    this.color = const Color(0xFFFF7070),
    this.strokeWidth = 3.2,
    this.duration = const Duration(milliseconds: 2200),
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;

  @override
  State<HeartLineLogo> createState() => _HeartLineLogoState();
}

class _HeartLineLogoState extends State<HeartLineLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size * 1.5, widget.size),
        painter: _HeartPainter(
          progress: _progress.value,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  /// Build the full heart path using the parametric heart equation
  /// to generate smooth, accurate points, plus bezier additions
  /// for the horizontal lines and teardrop.
  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;

    // ── Coordinate map (from logo image analysis) ──────────────────────
    final ly     = h * 0.82;   // horizontal line y
    final cx     = w * 0.50;   // center x (X-crossing point)

    // Lobe extremes (leftmost / rightmost)
    final lPkX   = w * 0.10;
    final lPkY   = h * 0.55;
    final rPkX   = w * 0.90;

    // Bump tops
    final lBx    = w * 0.34;
    final rBx    = w * 0.66;
    final bTop   = h * 0.10;

    // Notch & teardrop
    final notchY = h * 0.33;
    final dropY  = h * 0.18;

    final path = Path();

    // ── 1. Left horizontal → X-crossing ────────────────────────────────
    path.moveTo(0, ly);
    path.lineTo(cx, ly);

    // ── 2. Left lobe (CCW from X-crossing) ─────────────────────────────

    // X-crossing → left lobe leftmost peak
    // Path dips slightly below line before sweeping left-up (creates X)
    path.cubicTo(
      w * 0.37, h * 0.87,   // cp1 — left & dip below line
      lPkX,     h * 0.68,   // cp2 — approach peak from below
      lPkX,     lPkY,       // left lobe peak
    );

    // Left lobe peak → left bump top
    // Vertical tangent at peak → horizontal tangent at bump top
    path.cubicTo(
      lPkX,     h * 0.28,   // cp1 — go straight up
      w * 0.22, bTop,        // cp2 — arrive from left at bump level
      lBx,      bTop,        // left bump top
    );

    // Left bump top → notch
    path.cubicTo(
      w * 0.44, bTop,        // cp1 — go right at bump level
      w * 0.46, notchY - h * 0.06, // cp2 — descend to notch
      cx,       notchY,      // notch
    );

    // ── 3. Teardrop loop ────────────────────────────────────────────────
    path.cubicTo(
      w * 0.56, notchY - h * 0.06, // cp1 — right & up
      w * 0.56, dropY + h * 0.03,  // cp2 — near top-right
      cx,       dropY,              // teardrop tip
    );
    path.cubicTo(
      w * 0.44, dropY + h * 0.03,  // cp1 — near top-left
      w * 0.44, notchY - h * 0.06, // cp2 — left & down
      cx,       notchY,             // back to notch (crossing)
    );

    // ── 4. Right lobe (CW from notch back to X-crossing) ───────────────

    // Notch → right bump top
    path.cubicTo(
      w * 0.54, notchY - h * 0.06, // cp1 — right & up from notch
      w * 0.56, bTop,               // cp2 — arrive at bump level
      rBx,      bTop,               // right bump top
    );

    // Right bump top → right lobe peak
    path.cubicTo(
      w * 0.78, bTop,        // cp1 — go right at bump level
      rPkX,     h * 0.28,    // cp2 — go down from top
      rPkX,     lPkY,        // right lobe peak
    );

    // Right lobe peak → X-crossing (mirror of left base)
    path.cubicTo(
      rPkX,     h * 0.68,    // cp1 — go down from peak
      w * 0.63, h * 0.87,    // cp2 — right & dip below line (X)
      cx,       ly,           // X-crossing
    );

    // ── 5. Right horizontal ─────────────────────────────────────────────
    path.lineTo(w, ly);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildPath(size);

    for (final m in path.computeMetrics()) {
      canvas.drawPath(
        m.extractPath(0, m.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.progress != progress || old.color != color;
}
