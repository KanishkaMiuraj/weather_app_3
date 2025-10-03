import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    // Calculate the total duration of daylight in seconds
    final daylightDuration = sunset.difference(sunrise).inSeconds;

    // Calculate the time elapsed since sunrise (or before if pre-sunrise)
    final now = DateTime.now();
    final timeSinceSunrise = now.difference(sunrise).inSeconds;

    // Calculate progress (0.0 = sunrise, 1.0 = sunset)
    double progress = daylightDuration > 0 ? timeSinceSunrise / daylightDuration : 0.0;

    // Clamp progress to be between 0.0 and 1.0 for accurate sun position
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Sun Path',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _SunPathPainter(progress: progress),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.amber),
              Text(
                _formatTime(sunrise, context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _formatTime(sunset, context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.nights_stay_outlined, color: Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, BuildContext context) {
    // Helper to format time based on local device settings (12h/24h)
    return TimeOfDay.fromDateTime(time).format(context);
  }
}

class _SunPathPainter extends CustomPainter {
  final double progress;

  _SunPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintArc = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final paintSun = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Draw arc (sun path)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi, // Half a circle
      false,
      paintArc,
    );

    // Calculate sun position on the arc.
    // Progress 0.0 -> angle math.pi (180 deg, left/sunrise)
    // Progress 1.0 -> angle 0 (0 deg, right/sunset)
    final angle = math.pi * (1 - progress);
    final sunX = center.dx + radius * math.cos(angle);
    final sunY = center.dy + radius * math.sin(angle);

    // Draw sun (radius 12)
    canvas.drawCircle(Offset(sunX, sunY), 12, paintSun);
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}