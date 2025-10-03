import 'dart:math';
import 'package:flutter/material.dart';

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
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange[400]!.withOpacity(_glowAnimation.value),
                    Colors.orange[400]!.withOpacity(0.9),
                  ],
                  stops: const [0.4, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(_glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.wb_sunny, size: 100, color: Colors.white),
              ),
            ),
          );
        });
  }
}

class CloudyAnimation extends StatefulWidget {
  const CloudyAnimation({super.key});

  @override
  State<CloudyAnimation> createState() => _CloudyAnimationState();
}

class _CloudyAnimationState extends State<CloudyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
    _offsetAnimation = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCloud(double size, double opacity, {bool addShadow = true}) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(opacity),
        borderRadius: BorderRadius.circular(size * 0.35),
        boxShadow: addShadow
            ? [
          BoxShadow(
              color: Colors.grey.shade500.withOpacity(opacity),
              blurRadius: 6,
              offset: const Offset(3, 3))
        ]
            : [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 60 + _offsetAnimation.value,
                top: 100,
                child: buildCloud(100, 0.6),
              ),
              Positioned(
                left: 120 - _offsetAnimation.value * 1.2,
                top: 60,
                child: buildCloud(70, 0.4, addShadow: false),
              ),
              Positioned(
                left: 180 + _offsetAnimation.value * 0.8,
                top: 110,
                child: buildCloud(90, 0.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RainyAnimation extends StatefulWidget {
  const RainyAnimation({super.key});

  @override
  State<RainyAnimation> createState() => _RainyAnimationState();
}

class _RainyAnimationState extends State<RainyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late List<double> xPositions;
  late List<double> speeds;
  late List<double> lengths;
  late List<double> widths;
  final int dropCount = 30;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();

    xPositions = List.generate(dropCount, (_) => random.nextDouble() * 280);
    speeds = List.generate(dropCount, (_) => 150 + random.nextDouble() * 300);
    lengths = List.generate(dropCount, (_) => 10 + random.nextDouble() * 15);
    widths = List.generate(dropCount, (_) => 2 + random.nextDouble() * 2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildRaindrop(double x, double progress, double speed, double length,
      double width) {
    final y = (progress * speed) % 200;
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: width,
        height: length,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.7),
          borderRadius: BorderRadius.circular(width / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 3,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: List.generate(dropCount, (index) {
                return buildRaindrop(xPositions[index], _controller.value,
                    speeds[index], lengths[index], widths[index]);
              }),
            );
          }),
    );
  }
}



// -------------------- 6. Snow Animation --------------------

class SnowAnimation extends StatefulWidget {
  final double size;
  const SnowAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Snowflake> _snowflakes;
  final int flakeCount = 50;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _snowflakes = List.generate(
      flakeCount,
          (index) => Snowflake(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 3 + 2,
        speed: random.nextDouble() * 0.003 + 0.001,
        angle: random.nextDouble() * 2 * pi,
        angleSpeed: random.nextDouble() * 0.01 + 0.005,
      ),
    );

    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSnowflakes() {
    for (var flake in _snowflakes) {
      flake.y += flake.speed;
      flake.angle += flake.angleSpeed;
      if (flake.y > 1) {
        flake.y = 0;
        flake.x = random.nextDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            _updateSnowflakes();
            return CustomPaint(
              painter: _SnowPainter(snowflakes: _snowflakes),
              size: Size(size, size),
            );
          }),
    );
  }
}

class Snowflake {
  double x;
  double y;
  double radius;
  double speed;
  double angle;
  double angleSpeed;

  Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.angle,
    required this.angleSpeed,
  });
}

class _SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  _SnowPainter({required this.snowflakes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);

    for (var flake in snowflakes) {
      final x = flake.x * size.width + 5 * cos(flake.angle);
      final y = flake.y * size.height;
      canvas.drawCircle(Offset(x, y), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}




class FogAnimation extends StatefulWidget {
  const FogAnimation({super.key});

  @override
  State<FogAnimation> createState() => _FogAnimationState();
}

class _FogAnimationState extends State<FogAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fogShift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    _fogShift = Tween<double>(begin: 0, end: 40).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget fogLayer(double top, double opacity) {
    return Positioned(
      top: top,
      left: -80 + _fogShift.value,
      child: Container(
        width: 400,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.withOpacity(opacity),
              Colors.grey.withOpacity(opacity * 0.7),
              Colors.transparent
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              fogLayer(30, 0.4),
              fogLayer(70, 0.3),
              fogLayer(110, 0.25),
              fogLayer(150, 0.2),
            ],
          );
        },
      ),
    );
  }
}


class HailAnimation extends StatefulWidget {
  const HailAnimation({super.key});

  @override
  State<HailAnimation> createState() => _HailAnimationState();
}

class _HailAnimationState extends State<HailAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int hailCount = 25;
  final Random _random = Random();

  late List<double> xPositions;
  late List<double> speeds;
  late List<double> sizes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    xPositions = List.generate(hailCount, (_) => _random.nextDouble() * 280);
    speeds = List.generate(hailCount, (_) => 100 + _random.nextDouble() * 200);
    sizes = List.generate(hailCount, (_) => 4 + _random.nextDouble() * 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildHailDrop(double x, double progress, double speed, double size) {
    final y = (progress * speed) % 200;
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(hailCount, (index) {
              return buildHailDrop(xPositions[index], _controller.value,
                  speeds[index], sizes[index]);
            }),
          );
        },
      ),
    );
  }
}



// -------------------- 5. Thunderstorm Animation --------------------

class ThunderstormAnimation extends StatefulWidget {
  final double size;
  const ThunderstormAnimation({Key? key, this.size = 300}) : super(key: key); // bigger default size

  @override
  State<ThunderstormAnimation> createState() => _ThunderstormAnimationState();
}

class _ThunderstormAnimationState extends State<ThunderstormAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lightningOpacity;
  late Animation<double> _cloudX;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _lightningOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
    ]).animate(_controller);

    _cloudX = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  bool _shouldShowLightning() {
    return _lightningOpacity.value > 0.5;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size * 0.8,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Stack(
              children: [
                CustomPaint(
                  painter: _ThunderstormPainter(
                    lightningOpacity: _lightningOpacity.value,
                    cloudXOffset: _cloudX.value,
                    showLightning: _shouldShowLightning(),
                  ),
                  size: Size(size, size * 0.8),
                ),
                // Flash overlay for thunder effect
                if (_shouldShowLightning())
                  Opacity(
                    opacity: _lightningOpacity.value * 0.4, // adjust flash brightness
                    child: Container(
                      width: size,
                      height: size * 0.8,
                      color: Colors.yellowAccent,
                    ),
                  ),
              ],
            );
          }),
    );
  }
}

class _ThunderstormPainter extends CustomPainter {
  final double lightningOpacity;
  final double cloudXOffset;
  final bool showLightning;
  _ThunderstormPainter({
    required this.lightningOpacity,
    required this.cloudXOffset,
    required this.showLightning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.grey.shade700.withOpacity(1);

    final baseY = size.height * 0.5;

    final center1 = Offset(size.width / 2 + cloudXOffset, baseY);
    _drawCloud(canvas, center1, size.width / 3, cloudPaint);

    final center2 = Offset(size.width / 3 - cloudXOffset * 0.6, baseY * 0.8);
    final fadedCloudPaint = Paint()..color = cloudPaint.color.withOpacity(0.7);
    _drawCloud(canvas, center2, size.width / 5, fadedCloudPaint);

    if (showLightning) {
      final lightningPaint = Paint()
        ..color = Colors.yellow.withOpacity(lightningOpacity)
        ..strokeWidth = 6  // a bit thicker for more impact
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final startX = size.width / 2;
      final startY = size.height * 0.3;

      path.moveTo(startX, startY);
      path.lineTo(startX - 20, startY + 40);
      path.lineTo(startX + 15, startY + 40);
      path.lineTo(startX - 15, startY + 90);
      path.lineTo(startX + 20, startY + 50);
      path.lineTo(startX, startY + 50);
      path.close();

      canvas.drawPath(path, lightningPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
    final radius = width / 3;
    canvas.drawCircle(center.translate(-radius, 0), radius, paint);
    canvas.drawCircle(center, radius * 1.1, paint);
    canvas.drawCircle(center.translate(radius, 0), radius, paint);
    canvas.drawRect(
      Rect.fromCenter(
          center: center.translate(0, radius / 2), width: width, height: radius * 1.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThunderstormPainter oldDelegate) =>
      oldDelegate.lightningOpacity != lightningOpacity ||
          oldDelegate.cloudXOffset != cloudXOffset ||
          oldDelegate.showLightning != showLightning;
}

// -------------------- 11. Windy Animation --------------------

class WindyAnimation extends StatefulWidget {
  final double size;
  const WindyAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<WindyAnimation> createState() => _WindyAnimationState();
}

class _WindyAnimationState extends State<WindyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveShift;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();

    _waveShift = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size * 0.4,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _WindyPainter(shift: _waveShift.value),
              size: Size(size, size * 0.4),
            );
          }),
    );
  }
}

class _WindyPainter extends CustomPainter {
  final double shift;
  _WindyPainter({required this.shift});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.7)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final waveLength = size.width / 3;
    final amplitude = size.height / 3;

    for (int i = 0; i < 3; i++) {
      final y = size.height / 2 + i * amplitude / 1.5;
      final path = Path();
      for (double x = -waveLength * 2 + shift * waveLength * 4;
      x <= size.width + waveLength;
      x += 1) {
        final dy = sin((x + i * 20) * 2 * pi / waveLength) * amplitude / 2;
        if (x == -waveLength * 2 + shift * waveLength * 4) {
          path.moveTo(x, y + dy);
        } else {
          path.lineTo(x, y + dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindyPainter oldDelegate) => oldDelegate.shift != shift;
}


// -------------------- 12. Rainbow Animation --------------------

class RainbowAnimation extends StatefulWidget {
  final double size;
  const RainbowAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<RainbowAnimation> createState() => _RainbowAnimationState();
}

class _RainbowAnimationState extends State<RainbowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arcShift;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _arcShift = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<Color> rainbowColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF7F00), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFF4B0082), // Indigo
    Color(0xFF8F00FF), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size / 1.5,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _RainbowPainter(arcShift: _arcShift.value),
              size: Size(size, size / 1.5),
            );
          }),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  final double arcShift;
  _RainbowPainter({required this.arcShift});

  static const List<Color> rainbowColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF7F00), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFF4B0082), // Indigo
    Color(0xFF8F00FF), // Violet
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radiusStep = size.width / 14;

    for (int i = 0; i < rainbowColors.length; i++) {
      final paint = Paint()
        ..color = rainbowColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radiusStep * 1.5;

      final radius = radiusStep * (i + 1);
      final startAngle = pi + arcShift;
      final sweepAngle = pi;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
          sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter oldDelegate) =>
      oldDelegate.arcShift != arcShift;
}


// -------------------- 10. Freezing Animation --------------------

class FreezingAnimation extends StatefulWidget {
  final double size;
  const FreezingAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<FreezingAnimation> createState() => _FreezingAnimationState();
}

class _FreezingAnimationState extends State<FreezingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<IceCrystal> _crystals;
  final int crystalCount = 40;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _crystals = List.generate(
      crystalCount,
          (index) => IceCrystal(
        x: random.nextDouble(),
        y: random.nextDouble(),
        length: random.nextDouble() * 15 + 10,
        angle: random.nextDouble() * 2 * pi,
        angleSpeed: random.nextDouble() * 0.02 + 0.01,
      ),
    );
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCrystals() {
    for (var crystal in _crystals) {
      crystal.y += 0.005;
      crystal.angle += crystal.angleSpeed;
      if (crystal.y > 1) {
        crystal.y = 0;
        crystal.x = random.nextDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            _updateCrystals();
            return CustomPaint(
              painter: _FreezingPainter(crystals: _crystals),
              size: Size(size, size),
            );
          }),
    );
  }
}

class IceCrystal {
  double x;
  double y;
  double length;
  double angle;
  double angleSpeed;

  IceCrystal({
    required this.x,
    required this.y,
    required this.length,
    required this.angle,
    required this.angleSpeed,
  });
}

class _FreezingPainter extends CustomPainter {
  final List<IceCrystal> crystals;
  _FreezingPainter({required this.crystals});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var crystal in crystals) {
      final pos = Offset(crystal.x * size.width, crystal.y * size.height);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(crystal.angle);

      canvas.drawLine(Offset.zero, Offset(0, crystal.length), paint);
      canvas.drawLine(Offset(-crystal.length / 2, crystal.length / 2),
          Offset(crystal.length / 2, crystal.length / 2), paint);
      canvas.drawLine(Offset(-crystal.length / 3, crystal.length / 3),
          Offset(crystal.length / 3, crystal.length / 3), paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FreezingPainter oldDelegate) => true;
}


// -------------------- 9. Heat Wave Animation --------------------

class HeatWaveAnimation extends StatefulWidget {
  final double size;
  const HeatWaveAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<HeatWaveAnimation> createState() => _HeatWaveAnimationState();
}

class _HeatWaveAnimationState extends State<HeatWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveShift;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _waveShift = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size / 3,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _HeatWavePainter(shift: _waveShift.value),
              size: Size(size, size / 3),
            );
          }),
    );
  }
}

class _HeatWavePainter extends CustomPainter {
  final double shift;
  _HeatWavePainter({required this.shift});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final waveLength = size.width / 4;
    final amplitude = size.height / 2;

    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + sin((x / waveLength * 2 * pi) + shift) * amplitude / 2;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeatWavePainter oldDelegate) => true;
}


// -------------------- 8. Tornado Animation --------------------

class TornadoAnimation extends StatefulWidget {
  final double size;
  const TornadoAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  State<TornadoAnimation> createState() => _TornadoAnimationState();
}

class _TornadoAnimationState extends State<TornadoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _TornadoPainter(rotation: _rotation.value),
              size: Size(size, size),
            );
          }),
    );
  }
}

class _TornadoPainter extends CustomPainter {
  final double rotation;
  _TornadoPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final paint = Paint()
      ..color = Colors.grey.shade600.withOpacity(0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final maxRadius = size.width / 3;

    for (int i = 0; i < 5; i++) {
      final radius = maxRadius * (1 - i * 0.15);
      final startAngle = rotation + i * pi / 3;
      final sweepAngle = pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TornadoPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}