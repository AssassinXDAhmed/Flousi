import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mesh gradient background with animated blobs
///
/// Uses 3 large circles with RadialGradient and MaskFilter.blur(sigma: 100)
/// blended with BlendMode.screen. Centers move via sin(time)/cos(time) for
/// fluid, living background.
class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.child,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _AuroraPainter(
                  progress: _controller.value,
                  greenColor: const Color(0xFF22C55E).withAlpha(51),
                  blueColor: const Color(0xFF3B82F6).withAlpha(38),
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  final Color greenColor;
  final Color blueColor;

  _AuroraPainter({
    required this.progress,
    required this.greenColor,
    required this.blueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = progress * 2 * math.pi;

    final blobs = [
      _BlobConfig(
        color: greenColor,
        centerX: size.width * (0.3 + 0.2 * math.sin(time)),
        centerY: size.height * (0.2 + 0.15 * math.cos(time * 1.3)),
        radius: size.width * 0.4,
      ),
      _BlobConfig(
        color: blueColor,
        centerX: size.width * (0.7 + 0.15 * math.cos(time * 0.7)),
        centerY: size.height * (0.6 + 0.2 * math.sin(time * 1.1)),
        radius: size.width * 0.35,
      ),
      _BlobConfig(
        color: greenColor.withAlpha(25),
        centerX: size.width * (0.5 + 0.25 * math.sin(time * 0.5)),
        centerY: size.height * (0.4 + 0.25 * math.cos(time * 0.9)),
        radius: size.width * 0.45,
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100)
        ..shader = RadialGradient(
          colors: [blob.color, Colors.transparent],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(blob.centerX, blob.centerY),
          radius: blob.radius,
        ));

      canvas.drawCircle(
        Offset(blob.centerX, blob.centerY),
        blob.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BlobConfig {
  final Color color;
  final double centerX;
  final double centerY;
  final double radius;

  const _BlobConfig({
    required this.color,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });
}
