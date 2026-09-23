import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cyberpunk data decode text effect
///
/// Randomizes characters then locks them from left to right until the string
/// matches the target. Perfect for "Total Balance" numbers.
class ScrambleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final int scrambleSpeed;

  const ScrambleText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.scrambleSpeed = 30,
  });

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText> {
  String _displayText = '';
  int _lockedIndex = 0;
  Timer? _scrambleTimer;
  Timer? _lockTimer;
  final math.Random _random = math.Random();

  static const String _charset =
      r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
    _startScramble();
  }

  @override
  void didUpdateWidget(ScrambleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _stopScramble();
      _startScramble();
    }
  }

  @override
  void dispose() {
    _stopScramble();
    super.dispose();
  }

  void _startScramble() {
    _lockedIndex = 0;
    _displayText = _generateRandomString(widget.text.length);

    // Scramble timer - randomizes unlocked characters
    _scrambleTimer = Timer.periodic(
      Duration(milliseconds: widget.scrambleSpeed),
      (timer) {
        if (_lockedIndex >= widget.text.length) {
          timer.cancel();
          return;
        }

        final buffer = StringBuffer();
        for (int i = 0; i < widget.text.length; i++) {
          if (i < _lockedIndex) {
            buffer.write(widget.text[i]);
          } else {
            buffer.write(_charset[_random.nextInt(_charset.length)]);
          }
        }

        if (mounted) {
          setState(() {
            _displayText = buffer.toString();
          });
        }
      },
    );

    // Lock timer - progressively locks characters from left to right
    final lockInterval = widget.duration.inMilliseconds ~/ widget.text.length;
    _lockTimer = Timer.periodic(
      Duration(milliseconds: lockInterval),
      (timer) {
        if (_lockedIndex >= widget.text.length) {
          timer.cancel();
          _scrambleTimer?.cancel();
          if (mounted) {
            setState(() {
              _displayText = widget.text;
            });
          }
          return;
        }

        _lockedIndex++;
      },
    );
  }

  void _stopScramble() {
    _scrambleTimer?.cancel();
    _lockTimer?.cancel();
  }

  String _generateRandomString(int length) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}
