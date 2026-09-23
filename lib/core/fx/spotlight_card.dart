import 'package:flutter/material.dart';

/// Interactive border glow that tracks touch/mouse position
///
/// Uses GestureDetector to update a ValueNotifier<Offset>, then CustomPaint
/// draws a white radial gradient at that offset, masked to the card's border
/// stroke using BlendMode.srcIn.
class SpotlightCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  const SpotlightCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
  });

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
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
    return GestureDetector(
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
            ),
            child: child,
          );
        },
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
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

  _SpotlightBorderPainter({
    required this.spotlightOffset,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Draw base border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor.withAlpha(25);

    canvas.drawRRect(rrect, basePaint);

    // Draw spotlight glow if position is available
    if (spotlightOffset != null) {
      final glowPaint = Paint()
        ..blendMode = BlendMode.srcIn
        ..shader = RadialGradient(
          colors: [
            borderColor.withAlpha(153), // 60% opacity
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
          radius: 0.3,
        ).createShader(rect);

      // Save layer to apply blend mode only to border
      canvas.saveLayer(rect, Paint());

      // Draw border with blend mode
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2
        ..color = Colors.white;

      canvas.drawRRect(rrect, borderPaint);

      // Draw glow overlay
      canvas.drawRect(rect, glowPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightBorderPainter oldDelegate) {
    return oldDelegate.spotlightOffset != spotlightOffset ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
