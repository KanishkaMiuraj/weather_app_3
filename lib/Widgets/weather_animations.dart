// Widgets/weather_animations.dart

import 'dart:async' show Timer;
import 'dart:math';
import 'package:flutter/material.dart';

// --- BASE WIDGET AND UTILITIES ---

class WeatherAnimationBase extends StatelessWidget {
  final Widget child;
  final double size;
  const WeatherAnimationBase({super.key, required this.child, this.size = 250});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
  }
}

// Custom particle class for managing particle properties
class Particle {
  final double xOffset = Random().nextDouble();
  final double yStart = Random().nextDouble();
  final double size = 3 + Random().nextDouble() * 2;
  final double speed = 0.5 + Random().nextDouble() * 0.5;
  final bool isHail = Random().nextDouble() > 0.8;
}

// Base painter for drawing a simple cloud shape
void drawCloud(Canvas canvas, Offset center, double radius, Color color,
    double opacity, double drift) {
  final cloudPaint = Paint()
    ..color = color.withOpacity(opacity)
    ..style = PaintingStyle.fill;

  final c = center + Offset(drift, 0);

  // Main cloud shape (overlapping circles)
  canvas.drawCircle(c + Offset(-radius * 0.4, -radius * 0.1), radius * 0.6, cloudPaint);
  canvas.drawCircle(c + Offset(radius * 0.3, -radius * 0.2), radius * 0.7, cloudPaint);
  canvas.drawOval(
    Rect.fromCenter(center: c, width: radius * 1.8, height: radius * 1.0),
    cloudPaint,
  );
}

// --- 1. SUNNY/CLEAR DAY ANIMATION ---

class SunnyAnimation extends StatefulWidget {
  const SunnyAnimation({super.key});

  @override
  State<SunnyAnimation> createState() => _SunnyAnimationState();
}

class _SunnyAnimationState extends State<SunnyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeatherAnimationBase(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _SunPainter(
              rotation: _rotationAnimation.value,
              glow: _glowAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  final double rotation;
  final double glow;

  _SunPainter({required this.rotation, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = 50.0;

    // Draw rays
    final rayPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8 * glow)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const numRays = 12;
    for (int i = 0; i < numRays; i++) {
      final angle = (i * (2 * pi / numRays)) + rotation;
      final start = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final end = Offset(
        center.dx + (radius + 20) * cos(angle),
        center.dy + (radius + 20) * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Draw sun body
    final sunPaint = Paint()
      ..color = Colors.yellow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glow)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sunPaint);
    canvas.drawCircle(center, radius - 5, Paint()..color = Colors.yellowAccent);
  }

  @override
  bool shouldRepaint(_SunPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.glow != glow;
}

// --- NIGHT CLEAR ANIMATION (THE FIX) ---

// Line 188 in your old code
class NightClearAnimation extends StatefulWidget {
  final double size; // Added size property
  const NightClearAnimation({super.key, this.size = 250});

  @override
  State<NightClearAnimation> createState() => _NightClearAnimationState();
}

class _NightClearAnimationState extends State<NightClearAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _stars = List.generate(50, (_) => Particle());
  late Animation<double> _moonPhase;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat();

    // Simulates a subtle moon orbit/phase shift for animation
    _moonPhase = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    // **FIX 1: Structural Fix - Enforcing a non-zero size with SizedBox**
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            // painter class was crashing on line 225
            painter: _NightClearPainter(
              stars: _stars,
              animationValue: _controller.value,
              moonPhase: _moonPhase.value,
            ),
            // It is good practice to explicitly set the size on CustomPaint
            // even if the parent widget is constrained.
            size: Size(size, size),
          );
        },
      ),
    );
  }
}

class _NightClearPainter extends CustomPainter {
  final List<Particle> stars;
  final double animationValue;
  final double moonPhase;

  _NightClearPainter({required this.stars, required this.animationValue, required this.moonPhase});

  @override
  void paint(Canvas canvas, Size size) {
    // **FIX 2: Defensive Fix - Preventing NaN by checking for zero size**
    if (size.isEmpty || size.width.isNaN || size.height.isNaN) {
      return;
    }

    final center = size.center(Offset.zero);
    final moonRadius = size.width / 4;

    // 1. Draw Stars
    final starPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (final star in stars) {
      // The old error-causing line was likely a calculation for position or size
      // that used 'size.width' or 'size.height' without the check above.

      final x = size.width * star.xOffset;
      // Stars twinkle slightly based on animation
      final y = size.height * star.yStart + sin(animationValue * 2 * pi * 5) * 2;

      final starSize = 1 + sin(animationValue * 2 * pi * star.xOffset) * 0.5;

      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // 2. Draw Moon (A simple crescent moon effect)
    final moonCenter = center - Offset(size.width / 8, size.height / 8);

    // Moon body
    final moonPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(moonCenter, moonRadius, moonPaint);

    // Moon shadow (to create the crescent shape)
    final shadowPaint = Paint()
      ..color = Colors.indigo.shade900 // Use a dark background color for the shadow
      ..blendMode = BlendMode.dstOut; // This blend mode cuts out the shape

    // Calculate the shadow offset to create a crescent based on moonPhase
    final shadowOffset = moonRadius * 0.4;
    final shadowCenter = moonCenter + Offset(shadowOffset, shadowOffset * sin(moonPhase * 2 * pi));

    canvas.drawCircle(shadowCenter, moonRadius, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _NightClearPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// --- 3. CLOUDY ANIMATION ---

class CloudyAnimation extends StatefulWidget {
  const CloudyAnimation({super.key});

  @override
  State<CloudyAnimation> createState() => _CloudyAnimationState();
}

class _CloudyAnimationState extends State<CloudyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _driftAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);
    _driftAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeatherAnimationBase(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _CloudyPainter(drift: _driftAnimation.value),
          );
        },
      ),
    );
  }
}

class _CloudyPainter extends CustomPainter {
  final double drift;
  _CloudyPainter({required this.drift});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = 60.0;
    final color = Colors.grey.shade300;

    // Draw main cloud (slightly higher opacity, less drift)
    drawCloud(canvas, center, radius, color, 1.0, drift * 0.5);

    // Draw secondary cloud (lower opacity, more drift)
    drawCloud(canvas, center + const Offset(50, 30), radius * 0.7, Colors.grey.shade400, 0.7, drift);
  }

  @override
  bool shouldRepaint(_CloudyPainter oldDelegate) => oldDelegate.drift != drift;
}

// --- 4. RAINY ANIMATION ---

class RainyAnimation extends StatefulWidget {
  const RainyAnimation({super.key});

  @override
  State<RainyAnimation> createState() => _RainyAnimationState();
}

class _RainyAnimationState extends State<RainyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    particles = List.generate(30, (_) => Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeatherAnimationBase(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _RainyPainter(
              rainProgress: _controller.value,
              particles: particles,
            ),
          );
        },
      ),
    );
  }
}

class _RainyPainter extends CustomPainter {
  final double rainProgress;
  final List<Particle> particles;

  _RainyPainter({required this.rainProgress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const cloudRadius = 60.0;
    final cloudCenter = center - const Offset(0, 50);

    // 1. Draw Cloud
    drawCloud(canvas, cloudCenter, cloudRadius, Colors.grey.shade600, 1.0, 0);

    // 2. Draw Rain Particles
    final rainPaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rainStart = cloudCenter.dy + cloudRadius * 0.5;
    final rainEnd = size.height;

    for (final particle in particles) {
      final yPos = (particle.yStart + particle.speed * rainProgress) % 1.0;
      final xPos = particle.xOffset;

      final startY = rainStart + (rainEnd - rainStart) * yPos;
      final startX = center.dx - 50 + 100 * xPos;

      if (startY < rainEnd) {
        canvas.drawLine(
          Offset(startX, startY),
          Offset(startX + 5, startY + 15),
          rainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RainyPainter oldDelegate) =>
      oldDelegate.rainProgress != rainProgress;
}

// --- 5. SNOW ANIMATION ---

class SnowAnimation extends StatefulWidget {
  const SnowAnimation({super.key});

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    particles = List.generate(40, (_) => Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeatherAnimationBase(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _SnowPainter(
              snowProgress: _controller.value,
              particles: particles,
            ),
          );
        },
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  final double snowProgress;
  final List<Particle> particles;

  _SnowPainter({required this.snowProgress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const cloudRadius = 60.0;
    final cloudCenter = center - const Offset(0, 50);

    // 1. Draw Cloud (darker for snowy conditions)
    drawCloud(canvas, cloudCenter, cloudRadius, Colors.grey.shade700, 1.0, 0);

    // 2. Draw Snow Particles
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final snowStart = cloudCenter.dy + cloudRadius * 0.5;
    final snowEnd = size.height;

    for (final particle in particles) {
      final yPos = (particle.yStart + particle.speed * snowProgress) % 1.0;
      final xPos = particle.xOffset;

      final currentY = snowStart + (snowEnd - snowStart) * yPos;
      final currentX = center.dx - 50 + 100 * xPos;

      if (currentY < snowEnd) {
        canvas.drawCircle(Offset(currentX, currentY), particle.size * 0.5, snowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) =>
      oldDelegate.snowProgress != snowProgress;
}

// --- 6. HAIL/THUNDERSTORM ANIMATION ---

class HailAnimation extends StatefulWidget {
  const HailAnimation({super.key});

  @override
  State<HailAnimation> createState() => _HailAnimationState();
}

class _HailAnimationState extends State<HailAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  late bool _flash;
  late Timer _flashTimer;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    particles = List.generate(20, (_) => Particle());
    _flash = false;

    // Create a random lightning flash effect
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (Random().nextDouble() < 0.15) { // 15% chance to flash every 0.5s
        setState(() => _flash = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() => _flash = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flashTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeatherAnimationBase(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _HailPainter(
              hailProgress: _controller.value,
              particles: particles,
              flash: _flash,
            ),
          );
        },
      ),
    );
  }
}

class _HailPainter extends CustomPainter {
  final double hailProgress;
  final List<Particle> particles;
  final bool flash;

  _HailPainter({required this.hailProgress, required this.particles, required this.flash});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const cloudRadius = 70.0;
    final cloudCenter = center - const Offset(0, 50);

    // 1. Draw Cloud (very dark for storms)
    drawCloud(canvas, cloudCenter, cloudRadius, Colors.grey.shade900, 1.0, 0);

    // 2. Draw Lightning (Hailstorms are usually thunderstorms)
    if (flash) {
      final lightningPaint = Paint()
        ..color = Colors.yellow.shade100.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final path = Path()
        ..moveTo(cloudCenter.dx + 20, cloudCenter.dy + 30)
        ..lineTo(cloudCenter.dx - 10, cloudCenter.dy + 70)
        ..lineTo(cloudCenter.dx + 15, cloudCenter.dy + 70)
        ..lineTo(cloudCenter.dx, cloudCenter.dy + 120);

      canvas.drawPath(path, lightningPaint..style = PaintingStyle.stroke..strokeWidth = 3);
      canvas.drawPath(path, lightningPaint..color = Colors.yellow.shade400.withOpacity(0.8));
    }

    // 3. Draw Hail Particles
    final hailPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final hailStart = cloudCenter.dy + cloudRadius * 0.5;
    final hailEnd = size.height;

    for (final particle in particles) {
      final yPos = (particle.yStart + particle.speed * hailProgress) % 1.0;
      final xPos = particle.xOffset;

      final startY = hailStart + (hailEnd - hailStart) * yPos;
      final startX = center.dx - 50 + 100 * xPos;

      if (startY < hailEnd) {
        // Draw hail (small, hard-looking circles or ovals)
        canvas.drawOval(
          Rect.fromCircle(center: Offset(startX, startY), radius: 3),
          hailPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HailPainter oldDelegate) =>
      oldDelegate.hailProgress != hailProgress || oldDelegate.flash != flash;
}