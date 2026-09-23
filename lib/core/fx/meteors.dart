import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shooting star particle system
///
/// Draws 10-15 lines with trailing gradients falling at an angle.
/// Uses AnimationController to reset them when they go off-screen.
class Meteors extends StatefulWidget {
  final int count;
  final Color color;
  final double angle;

  const Meteors({
    super.key,
    this.count = 12,
    this.color = Colors.white,
    this.angle = -0.5, // Diagonal angle in radians
  });

  @override
  State<Meteors> createState() => _MeteorsState();
}

class _MeteorsState extends State<Meteors> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MeteorConfig> _meteors;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _meteors = List.generate(widget.count, (_) => _generateMeteor());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _MeteorConfig _generateMeteor() {
    return _MeteorConfig(
      startX: _random.nextDouble(),
      startY: _random.nextDouble() * 0.3,
      length: 40 + _random.nextDouble() * 60,
      speed: 0.5 + _random.nextDouble() * 0.5,
      delay: _random.nextDouble() * 0.5,
      opacity: 0.3 + _random.nextDouble() * 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MeteorsPainter(
            progress: _controller.value,
            meteors: _meteors,
            color: widget.color,
            angle: widget.angle,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MeteorsPainter extends CustomPainter {
  final double progress;
  final List<_MeteorConfig> meteors;
  final Color color;
  final double angle;

  _MeteorsPainter({
    required this.progress,
    required this.meteors,
    required this.color,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final meteor in meteors) {
      final meteorProgress = (progress - meteor.delay + 1.0) % 1.0;

      if (meteorProgress < 0 || meteorProgress > meteor.speed) {
        continue;
      }

      final normalizedProgress = meteorProgress / meteor.speed;

      final startX = meteor.startX * size.width;
      final startY = meteor.startY * size.height;

      final dx = math.cos(angle);
      final dy = math.sin(angle);

      final travelDistance = size.width * 1.5 * normalizedProgress;

      final headX = startX + dx * travelDistance;
      final headY = startY + dy * travelDistance;

      final tailX = headX - dx * meteor.length;
      final tailY = headY - dy * meteor.length;

      if (headX < -meteor.length ||
          headX > size.width + meteor.length ||
          headY < -meteor.length ||
          headY > size.height + meteor.length) {
        continue;
      }

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withAlpha((meteor.opacity * 255).round()),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromPoints(
          Offset(tailX, tailY),
          Offset(headX, headY),
        ))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(tailX, tailY),
        Offset(headX, headY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeteorsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MeteorConfig {
  final double startX;
  final double startY;
  final double length;
  final double speed;
  final double delay;
  final double opacity;

  const _MeteorConfig({
    required this.startX,
    required this.startY,
    required this.length,
    required this.speed,
    required this.delay,
    required this.opacity,
  });
}
