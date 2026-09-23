import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium mesh gradient background with animated blurred circles.
///
/// Uses 3 large, highly blurred circles moving in a figure-8 pattern
/// to create a slow, breathing liquid gradient effect.
class PremiumMeshBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PremiumMeshBackground({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 25),
  });

  @override
  State<PremiumMeshBackground> createState() => _PremiumMeshBackgroundState();
}

class _PremiumMeshBackgroundState extends State<PremiumMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _MeshPainter(
                  progress: _controller.value,
                  color1:
                      const Color(0xFF0F3D2E).withAlpha(180), // Deep emerald
                  color2: const Color(0xFF1E3A8A)
                      .withAlpha(150), // Deep midnight blue
                  color3: const Color(0xFF166534)
                      .withAlpha(120), // Dark forest green
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final Color color3;

  _MeshPainter({
    required this.progress,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // Figure-8 pattern for circle 1
    final c1X = size.width * (0.3 + 0.15 * math.sin(t));
    final c1Y = size.height * (0.4 + 0.2 * math.sin(2 * t));

    // Inverted figure-8 for circle 2
    final c2X = size.width * (0.7 + 0.15 * math.cos(t));
    final c2Y = size.height * (0.6 + 0.2 * math.cos(2 * t));

    // Slow drift for circle 3
    final c3X = size.width * (0.5 + 0.25 * math.sin(t * 0.7));
    final c3Y = size.height * (0.3 + 0.3 * math.cos(t * 0.5));

    final circles = [
      _CircleConfig(
          center: Offset(c1X, c1Y), radius: size.width * 0.5, color: color1),
      _CircleConfig(
          center: Offset(c2X, c2Y), radius: size.width * 0.45, color: color2),
      _CircleConfig(
          center: Offset(c3X, c3Y), radius: size.width * 0.55, color: color3),
    ];

    // Base dark fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A0A),
    );

    // Draw blurred circles with additive blending
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    for (final circle in circles) {
      final rect =
          Rect.fromCircle(center: circle.center, radius: circle.radius);
      paint.shader = RadialGradient(
        colors: [circle.color, Colors.transparent],
      ).createShader(rect);
      canvas.drawCircle(circle.center, circle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CircleConfig {
  final Offset center;
  final double radius;
  final Color color;

  const _CircleConfig({
    required this.center,
    required this.radius,
    required this.color,
  });
}

/// Premium card with interactive spotlight border that follows touch/hover.
///
/// Tracks pointer coordinates and renders a radial gradient masked to the
/// card's border using BlendMode.srcIn, creating an interactive glowing edge.
class SpotlightBorderCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color spotlightColor;

  const SpotlightBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
    this.spotlightColor = Colors.white,
  });

  @override
  State<SpotlightBorderCard> createState() => _SpotlightBorderCardState();
}

class _SpotlightBorderCardState extends State<SpotlightBorderCard> {
  final ValueNotifier<Offset?> _spotlightPosition = ValueNotifier(null);

  @override
  void dispose() {
    _spotlightPosition.dispose();
    super.dispose();
  }

  void _updatePosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPosition = box.globalToLocal(globalPosition);
      _spotlightPosition.value = localPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _updatePosition(event.position),
      onExit: (_) => _spotlightPosition.value = null,
      child: GestureDetector(
        onPanUpdate: (details) => _updatePosition(details.globalPosition),
        onPanEnd: (_) => _spotlightPosition.value = null,
        onPanCancel: () => _spotlightPosition.value = null,
        onTapDown: (details) => _updatePosition(details.globalPosition),
        onTapUp: (_) => _spotlightPosition.value = null,
        onTapCancel: () => _spotlightPosition.value = null,
        child: ValueListenableBuilder<Offset?>(
          valueListenable: _spotlightPosition,
          builder: (context, spotlightOffset, child) {
            return CustomPaint(
              painter: _SpotlightBorderPainter(
                spotlightOffset: spotlightOffset,
                borderRadius: widget.borderRadius,
                borderColor: widget.borderColor,
                borderWidth: widget.borderWidth,
                spotlightColor: widget.spotlightColor,
              ),
              child: child,
            );
          },
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightBorderPainter extends CustomPainter {
  final Offset? spotlightOffset;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color spotlightColor;

  _SpotlightBorderPainter({
    required this.spotlightOffset,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.spotlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Draw base border (always visible)
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor.withAlpha(38); // ~15% opacity

    canvas.drawRRect(rrect, basePaint);

    // Draw spotlight effect if position is available
    if (spotlightOffset != null) {
      // Use saveLayer to apply blend mode only to the border region
      canvas.saveLayer(rect, Paint());

      // Draw border mask (white stroke)
      final maskPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 2
        ..color = Colors.white;

      canvas.drawRRect(rrect, maskPaint);

      // Draw radial gradient with srcIn blend mode (only intersects with border)
      final glowPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..shader = RadialGradient(
          colors: [
            spotlightColor.withAlpha(200), // ~78% opacity
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
          radius: 0.25,
        ).createShader(rect);

      glowPaint.shader = RadialGradient(
        colors: [
          spotlightColor.withAlpha(200),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
        radius: 0.3,
      ).createShader(Rect.fromCircle(
        center: spotlightOffset!,
        radius: size.shortestSide * 0.4,
      ));

      canvas.drawRect(rect, glowPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightBorderPainter oldDelegate) {
    return oldDelegate.spotlightOffset != spotlightOffset ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.spotlightColor != spotlightColor;
  }
}
