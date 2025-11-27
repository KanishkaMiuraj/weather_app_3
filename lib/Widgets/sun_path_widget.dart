import 'dart:math' as math;
import 'package:flutter/material.dart';

class SunPathWidget extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;

  const SunPathWidget({
    required this.sunrise,
    required this.sunset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final daylightDuration = sunset.difference(sunrise).inSeconds;
    final now = DateTime.now();
    final timeSinceSunrise = now.difference(sunrise).inSeconds;

    // Logic: If before sunrise, 0.0. If after sunset, 1.0.
    double progress = 0.0;
    if (daylightDuration > 0) {
      progress = timeSinceSunrise / daylightDuration;
    }
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Glassmorphism style to match main
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sunrise', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_formatTime(sunrise, context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Sunset', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_formatTime(sunset, context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100, // Reduced height for tighter UI
            child: CustomPaint(
              painter: _SunPathPainter(progress: progress),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, BuildContext context) {
    return TimeOfDay.fromDateTime(time).format(context);
  }
}

class _SunPathPainter extends CustomPainter {
  final double progress;

  _SunPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the Arc
    final paintArc = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    // 2. Draw the Sun
    final paintSun = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final center = Offset(size.width / 2, size.height);
    // Radius should fit within width and height
    final radius = math.min(size.width / 2, size.height - 10);

    // Draw full arc background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      paintArc,
    );

    // Draw active arc (time passed)
    final activeArcPaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.amber, Colors.orange])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final currentAngle = math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      currentAngle, // Sweep angle
      false,
      activeArcPaint,
    );

    // Calculate Sun Position
    // pi = left, 0 = right.
    // We start at pi and move to 0 based on progress.
    final angle = math.pi + (math.pi * progress);

    final sunX = center.dx + radius * math.cos(angle);
    final sunY = center.dy + radius * math.sin(angle);

    canvas.drawCircle(Offset(sunX, sunY), 10, paintSun);
    canvas.drawCircle(Offset(sunX, sunY), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) => oldDelegate.progress != progress;
}