// import 'dart:math';
// import 'package:flutter/material.dart';
//
// // -------------------- 1. Sunny Animation --------------------
//
// class SunnyAnimation extends StatefulWidget {
//   final double size;
//   const SunnyAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<SunnyAnimation> createState() => _SunnyAnimationState();
// }
//
// class _SunnyAnimationState extends State<SunnyAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _rotation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 8))
//       ..repeat();
//     _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size,
//       child: AnimatedBuilder(
//         animation: _rotation,
//         builder: (_, __) {
//           return CustomPaint(
//             painter: _SunnyPainter(rotation: _rotation.value),
//             size: Size(size, size),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _SunnyPainter extends CustomPainter {
//   final double rotation;
//   _SunnyPainter({required this.rotation});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = size.width / 5;
//
//     // Sun core paint
//     final sunPaint = Paint()
//       ..color = Colors.orangeAccent.withOpacity(1)
//       ..style = PaintingStyle.fill;
//
//     // Sun rays paint
//     final rayPaint = Paint()
//       ..color = Colors.deepOrange.withOpacity(0.7)
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;
//
//     canvas.drawCircle(center, radius, sunPaint);
//
//     const rayCount = 12;
//     final rayLength = radius * 1.5;
//
//     for (int i = 0; i < rayCount; i++) {
//       final angle = (2 * pi / rayCount) * i + rotation;
//       final start = Offset(
//         center.dx + cos(angle) * radius,
//         center.dy + sin(angle) * radius,
//       );
//       final end = Offset(
//         center.dx + cos(angle) * (radius + rayLength),
//         center.dy + sin(angle) * (radius + rayLength),
//       );
//       canvas.drawLine(start, end, rayPaint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _SunnyPainter oldDelegate) =>
//       oldDelegate.rotation != rotation;
// }
//
// // -------------------- 2. Partly Cloudy Animation --------------------
//
// class PartlyCloudyAnimation extends StatefulWidget {
//   final double size;
//   const PartlyCloudyAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<PartlyCloudyAnimation> createState() => _PartlyCloudyAnimationState();
// }
//
// class _PartlyCloudyAnimationState extends State<PartlyCloudyAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _cloudX;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 6))
//       ..repeat(reverse: true);
//     _cloudX = Tween<double>(begin: -10, end: 10).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size * 0.7,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _PartlyCloudyPainter(cloudXOffset: _cloudX.value),
//               size: Size(size, size * 0.7),
//             );
//           }),
//     );
//   }
// }
//
// class _PartlyCloudyPainter extends CustomPainter {
//   final double cloudXOffset;
//   _PartlyCloudyPainter({required this.cloudXOffset});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final sunPaint = Paint()
//       ..color = Colors.orangeAccent.withOpacity(0.9)
//       ..style = PaintingStyle.fill;
//
//     final cloudPaint = Paint()
//       ..color = Colors.grey.shade400.withOpacity(0.8)
//       ..style = PaintingStyle.fill;
//
//     final sunCenter = Offset(size.width * 0.3, size.height * 0.4);
//     final sunRadius = size.width / 6;
//     canvas.drawCircle(sunCenter, sunRadius, sunPaint);
//
//     final cloudCenter = Offset(size.width * 0.6 + cloudXOffset, size.height * 0.5);
//     _drawCloud(canvas, cloudCenter, size.width / 3, cloudPaint);
//   }
//
//   void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
//     final radius = width / 3;
//     canvas.drawCircle(center.translate(-radius, 0), radius, paint);
//     canvas.drawCircle(center, radius * 1.1, paint);
//     canvas.drawCircle(center.translate(radius, 0), radius, paint);
//     canvas.drawRect(
//       Rect.fromCenter(
//           center: center.translate(0, radius / 2), width: width, height: radius * 1.2),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant _PartlyCloudyPainter oldDelegate) =>
//       oldDelegate.cloudXOffset != cloudXOffset;
// }
//
// // -------------------- 3. Cloudy Animation --------------------
//
// class CloudyAnimation extends StatefulWidget {
//   final double size;
//   const CloudyAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<CloudyAnimation> createState() => _CloudyAnimationState();
// }
//
// class _CloudyAnimationState extends State<CloudyAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _cloud1X;
//   late Animation<double> _cloud2X;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 8))
//       ..repeat();
//
//     _cloud1X = Tween<double>(begin: -15, end: 15).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//     _cloud2X = Tween<double>(begin: 15, end: -15).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size * 0.7,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _CloudyPainter(
//                   cloud1XOffset: _cloud1X.value, cloud2XOffset: _cloud2X.value),
//               size: Size(size, size * 0.7),
//             );
//           }),
//     );
//   }
// }
//
// class _CloudyPainter extends CustomPainter {
//   final double cloud1XOffset;
//   final double cloud2XOffset;
//   _CloudyPainter({required this.cloud1XOffset, required this.cloud2XOffset});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final cloudPaint1 = Paint()
//       ..color = Colors.grey.shade600.withOpacity(0.85)
//       ..style = PaintingStyle.fill;
//     final cloudPaint2 = Paint()
//       ..color = Colors.grey.shade400.withOpacity(0.75)
//       ..style = PaintingStyle.fill;
//
//     final baseY = size.height * 0.5;
//
//     final center1 = Offset(size.width / 2 + cloud1XOffset, baseY);
//     _drawCloud(canvas, center1, size.width / 3, cloudPaint1);
//
//     final center2 = Offset(size.width / 3 + cloud2XOffset, baseY * 0.8);
//     _drawCloud(canvas, center2, size.width / 4, cloudPaint2);
//   }
//
//   void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
//     final radius = width / 3;
//     canvas.drawCircle(center.translate(-radius, 0), radius, paint);
//     canvas.drawCircle(center, radius * 1.1, paint);
//     canvas.drawCircle(center.translate(radius, 0), radius, paint);
//     canvas.drawRect(
//       Rect.fromCenter(
//           center: center.translate(0, radius / 2), width: width, height: radius * 1.2),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant _CloudyPainter oldDelegate) =>
//       oldDelegate.cloud1XOffset != cloud1XOffset ||
//           oldDelegate.cloud2XOffset != cloud2XOffset;
// }
//
// // -------------------- 4. Rain Animation --------------------
//
// class RainAnimation extends StatefulWidget {
//   final double size;
//   const RainAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<RainAnimation> createState() => _RainAnimationState();
// }
//
// class _RainAnimationState extends State<RainAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late List<RainDrop> _raindrops;
//   final int dropCount = 60;
//   final Random random = Random();
//
//   @override
//   void initState() {
//     super.initState();
//     _raindrops = List.generate(
//       dropCount,
//           (index) => RainDrop(
//         x: random.nextDouble(),
//         y: random.nextDouble(),
//         length: random.nextDouble() * 15 + 10,
//         speed: random.nextDouble() * 0.01 + 0.01,
//       ),
//     );
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 20))
//       ..repeat();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _updateDrops() {
//     for (var drop in _raindrops) {
//       drop.y += drop.speed;
//       if (drop.y > 1) {
//         drop.y = 0;
//         drop.x = random.nextDouble();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             _updateDrops();
//             return CustomPaint(
//               painter: _RainPainter(raindrops: _raindrops),
//               size: Size(size, size),
//             );
//           }),
//     );
//   }
// }
//
// class RainDrop {
//   double x;
//   double y;
//   double length;
//   double speed;
//
//   RainDrop({
//     required this.x,
//     required this.y,
//     required this.length,
//     required this.speed,
//   });
// }
//
// class _RainPainter extends CustomPainter {
//   final List<RainDrop> raindrops;
//   _RainPainter({required this.raindrops});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.blueAccent.withOpacity(0.7)
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round;
//
//     for (var drop in raindrops) {
//       final start = Offset(drop.x * size.width, drop.y * size.height);
//       final end = Offset(drop.x * size.width, drop.y * size.height + drop.length);
//       canvas.drawLine(start, end, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
// }
//
// // -------------------- 5. Thunderstorm Animation --------------------
//
// class ThunderstormAnimation extends StatefulWidget {
//   final double size;
//   const ThunderstormAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<ThunderstormAnimation> createState() => _ThunderstormAnimationState();
// }
//
// class _ThunderstormAnimationState extends State<ThunderstormAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _lightningOpacity;
//   late Animation<double> _cloudX;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 3))
//       ..repeat();
//
//     _lightningOpacity = TweenSequence<double>([
//       TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
//       TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
//     ]).animate(_controller);
//
//     _cloudX = Tween<double>(begin: -10, end: 10).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   bool _shouldShowLightning() {
//     // Show lightning only when opacity > 0.5 to simulate flash
//     return _lightningOpacity.value > 0.5;
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size * 0.8,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _ThunderstormPainter(
//                 lightningOpacity: _lightningOpacity.value,
//                 cloudXOffset: _cloudX.value,
//                 showLightning: _shouldShowLightning(),
//               ),
//               size: Size(size, size * 0.8),
//             );
//           }),
//     );
//   }
// }
//
// class _ThunderstormPainter extends CustomPainter {
//   final double lightningOpacity;
//   final double cloudXOffset;
//   final bool showLightning;
//   _ThunderstormPainter({
//     required this.lightningOpacity,
//     required this.cloudXOffset,
//     required this.showLightning,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final cloudPaint = Paint()
//       ..color = Colors.grey.shade700.withOpacity(1);
//
//     // Clouds
//     final baseY = size.height * 0.5;
//
//     final center1 = Offset(size.width / 2 + cloudXOffset, baseY);
//     _drawCloud(canvas, center1, size.width / 3, cloudPaint);
//
//     final center2 = Offset(size.width / 3 - cloudXOffset * 0.6, baseY * 0.8);
//     _drawCloud(
//         canvas, center2, size.width / 5, cloudPaint..color = cloudPaint.color.withOpacity(0.7));
//
//     // Lightning bolt
//     if (showLightning) {
//       final lightningPaint = Paint()
//         ..color = Colors.yellow.withOpacity(lightningOpacity)
//         ..strokeWidth = 4
//         ..strokeCap = StrokeCap.round;
//
//       final path = Path();
//       final startX = size.width / 2;
//       final startY = size.height * 0.3;
//
//       path.moveTo(startX, startY);
//       path.lineTo(startX - 15, startY + 30);
//       path.lineTo(startX + 10, startY + 30);
//       path.lineTo(startX - 10, startY + 70);
//       path.lineTo(startX + 15, startY + 40);
//       path.lineTo(startX, startY + 40);
//       path.close();
//
//       canvas.drawPath(path, lightningPaint);
//     }
//   }
//
//   void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
//     final radius = width / 3;
//     canvas.drawCircle(center.translate(-radius, 0), radius, paint);
//     canvas.drawCircle(center, radius * 1.1, paint);
//     canvas.drawCircle(center.translate(radius, 0), radius, paint);
//     canvas.drawRect(
//       Rect.fromCenter(
//           center: center.translate(0, radius / 2), width: width, height: radius * 1.2),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant _ThunderstormPainter oldDelegate) =>
//       oldDelegate.lightningOpacity != lightningOpacity ||
//           oldDelegate.cloudXOffset != cloudXOffset ||
//           oldDelegate.showLightning != showLightning;
// }
//
// // -------------------- 6. Snow Animation --------------------
//
// class SnowAnimation extends StatefulWidget {
//   final double size;
//   const SnowAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<SnowAnimation> createState() => _SnowAnimationState();
// }
//
// class _SnowAnimationState extends State<SnowAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late List<Snowflake> _snowflakes;
//   final int flakeCount = 50;
//   final Random random = Random();
//
//   @override
//   void initState() {
//     super.initState();
//     _snowflakes = List.generate(
//       flakeCount,
//           (index) => Snowflake(
//         x: random.nextDouble(),
//         y: random.nextDouble(),
//         radius: random.nextDouble() * 3 + 2,
//         speed: random.nextDouble() * 0.003 + 0.001,
//         angle: random.nextDouble() * 2 * pi,
//         angleSpeed: random.nextDouble() * 0.01 + 0.005,
//       ),
//     );
//
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 20))
//       ..repeat();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _updateSnowflakes() {
//     for (var flake in _snowflakes) {
//       flake.y += flake.speed;
//       flake.angle += flake.angleSpeed;
//       if (flake.y > 1) {
//         flake.y = 0;
//         flake.x = random.nextDouble();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             _updateSnowflakes();
//             return CustomPaint(
//               painter: _SnowPainter(snowflakes: _snowflakes),
//               size: Size(size, size),
//             );
//           }),
//     );
//   }
// }
//
// class Snowflake {
//   double x;
//   double y;
//   double radius;
//   double speed;
//   double angle;
//   double angleSpeed;
//
//   Snowflake({
//     required this.x,
//     required this.y,
//     required this.radius,
//     required this.speed,
//     required this.angle,
//     required this.angleSpeed,
//   });
// }
//
// class _SnowPainter extends CustomPainter {
//   final List<Snowflake> snowflakes;
//   _SnowPainter({required this.snowflakes});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white.withOpacity(0.9);
//
//     for (var flake in snowflakes) {
//       final pos = Offset(flake.x * size.width, flake.y * size.height);
//       canvas.save();
//       canvas.translate(pos.dx, pos.dy);
//       canvas.rotate(flake.angle);
//       canvas.drawCircle(Offset.zero, flake.radius, paint);
//       canvas.restore();
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
// }
//
// // -------------------- 7. Fog Animation --------------------
//
// class FogAnimation extends StatefulWidget {
//   final double size;
//   const FogAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<FogAnimation> createState() => _FogAnimationState();
// }
//
// class _FogAnimationState extends State<FogAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fogShift;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 10))
//       ..repeat();
//
//     _fogShift = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.linear),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size * 0.6,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _FogPainter(shift: _fogShift.value),
//               size: Size(size, size * 0.6),
//             );
//           }),
//     );
//   }
// }
//
// class _FogPainter extends CustomPainter {
//   final double shift;
//   _FogPainter({required this.shift});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final fogPaint = Paint()
//       ..color = Colors.grey.withOpacity(0.25)
//       ..style = PaintingStyle.fill;
//
//     final fogPaint2 = Paint()
//       ..color = Colors.grey.withOpacity(0.15)
//       ..style = PaintingStyle.fill;
//
//     final fogHeight = size.height / 6;
//
//     for (int i = 0; i < 3; i++) {
//       final y = fogHeight * i + (shift * fogHeight * 2);
//       final rect = Rect.fromLTWH(0, y % size.height - fogHeight, size.width, fogHeight);
//       canvas.drawRect(rect, i % 2 == 0 ? fogPaint : fogPaint2);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
// }
//
// // -------------------- 8. Tornado Animation --------------------
//
// class TornadoAnimation extends StatefulWidget {
//   final double size;
//   const TornadoAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<TornadoAnimation> createState() => _TornadoAnimationState();
// }
//
// class _TornadoAnimationState extends State<TornadoAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _rotation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 6))
//       ..repeat();
//
//     _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _TornadoPainter(rotation: _rotation.value),
//               size: Size(size, size),
//             );
//           }),
//     );
//   }
// }
//
// class _TornadoPainter extends CustomPainter {
//   final double rotation;
//   _TornadoPainter({required this.rotation});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//
//     final paint = Paint()
//       ..color = Colors.grey.shade600.withOpacity(0.7)
//       ..strokeWidth = 6
//       ..style = PaintingStyle.stroke;
//
//     final maxRadius = size.width / 3;
//
//     for (int i = 0; i < 5; i++) {
//       final radius = maxRadius * (1 - i * 0.15);
//       final startAngle = rotation + i * pi / 3;
//       final sweepAngle = pi / 2;
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: radius),
//         startAngle,
//         sweepAngle,
//         false,
//         paint,
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _TornadoPainter oldDelegate) =>
//       oldDelegate.rotation != rotation;
// }
//
// // -------------------- 9. Heat Wave Animation --------------------
//
// class HeatWaveAnimation extends StatefulWidget {
//   final double size;
//   const HeatWaveAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<HeatWaveAnimation> createState() => _HeatWaveAnimationState();
// }
//
// class _HeatWaveAnimationState extends State<HeatWaveAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _waveShift;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 4))
//       ..repeat();
//
//     _waveShift = Tween<double>(begin: 0, end: 2 * pi).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.linear),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size / 3,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _HeatWavePainter(shift: _waveShift.value),
//               size: Size(size, size / 3),
//             );
//           }),
//     );
//   }
// }
//
// class _HeatWavePainter extends CustomPainter {
//   final double shift;
//   _HeatWavePainter({required this.shift});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.orange.withOpacity(0.7)
//       ..strokeWidth = 4
//       ..style = PaintingStyle.stroke;
//
//     final waveLength = size.width / 4;
//     final amplitude = size.height / 2;
//
//     final path = Path();
//     for (double x = 0; x <= size.width; x++) {
//       final y = size.height / 2 + sin((x / waveLength * 2 * pi) + shift) * amplitude / 2;
//       if (x == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant _HeatWavePainter oldDelegate) => true;
// }
//
// // -------------------- 10. Freezing Animation --------------------
//
// class FreezingAnimation extends StatefulWidget {
//   final double size;
//   const FreezingAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<FreezingAnimation> createState() => _FreezingAnimationState();
// }
//
// class _FreezingAnimationState extends State<FreezingAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late List<IceCrystal> _crystals;
//   final int crystalCount = 40;
//   final Random random = Random();
//
//   @override
//   void initState() {
//     super.initState();
//     _crystals = List.generate(
//       crystalCount,
//           (index) => IceCrystal(
//         x: random.nextDouble(),
//         y: random.nextDouble(),
//         length: random.nextDouble() * 15 + 10,
//         angle: random.nextDouble() * 2 * pi,
//         angleSpeed: random.nextDouble() * 0.02 + 0.01,
//       ),
//     );
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 20))
//       ..repeat();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _updateCrystals() {
//     for (var crystal in _crystals) {
//       crystal.y += 0.005;
//       crystal.angle += crystal.angleSpeed;
//       if (crystal.y > 1) {
//         crystal.y = 0;
//         crystal.x = random.nextDouble();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             _updateCrystals();
//             return CustomPaint(
//               painter: _FreezingPainter(crystals: _crystals),
//               size: Size(size, size),
//             );
//           }),
//     );
//   }
// }
//
// class IceCrystal {
//   double x;
//   double y;
//   double length;
//   double angle;
//   double angleSpeed;
//
//   IceCrystal({
//     required this.x,
//     required this.y,
//     required this.length,
//     required this.angle,
//     required this.angleSpeed,
//   });
// }
//
// class _FreezingPainter extends CustomPainter {
//   final List<IceCrystal> crystals;
//   _FreezingPainter({required this.crystals});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.cyan.withOpacity(0.7)
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round;
//
//     for (var crystal in crystals) {
//       final pos = Offset(crystal.x * size.width, crystal.y * size.height);
//       canvas.save();
//       canvas.translate(pos.dx, pos.dy);
//       canvas.rotate(crystal.angle);
//
//       canvas.drawLine(Offset.zero, Offset(0, crystal.length), paint);
//       canvas.drawLine(Offset(-crystal.length / 2, crystal.length / 2),
//           Offset(crystal.length / 2, crystal.length / 2), paint);
//       canvas.drawLine(Offset(-crystal.length / 3, crystal.length / 3),
//           Offset(crystal.length / 3, crystal.length / 3), paint);
//
//       canvas.restore();
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _FreezingPainter oldDelegate) => true;
// }
//
// // -------------------- 11. Windy Animation --------------------
//
// class WindyAnimation extends StatefulWidget {
//   final double size;
//   const WindyAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<WindyAnimation> createState() => _WindyAnimationState();
// }
//
// class _WindyAnimationState extends State<WindyAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _waveShift;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 5))
//       ..repeat();
//
//     _waveShift = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.linear),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size * 0.4,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _WindyPainter(shift: _waveShift.value),
//               size: Size(size, size * 0.4),
//             );
//           }),
//     );
//   }
// }
//
// class _WindyPainter extends CustomPainter {
//   final double shift;
//   _WindyPainter({required this.shift});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.lightBlueAccent.withOpacity(0.7)
//       ..strokeWidth = 6
//       ..strokeCap = StrokeCap.round;
//
//     final waveLength = size.width / 3;
//     final amplitude = size.height / 3;
//
//     for (int i = 0; i < 3; i++) {
//       final y = size.height / 2 + i * amplitude / 1.5;
//       final path = Path();
//       for (double x = -waveLength * 2 + shift * waveLength * 4;
//       x <= size.width + waveLength;
//       x += 1) {
//         final dy = sin((x + i * 20) * 2 * pi / waveLength) * amplitude / 2;
//         if (x == -waveLength * 2 + shift * waveLength * 4) {
//           path.moveTo(x, y + dy);
//         } else {
//           path.lineTo(x, y + dy);
//         }
//       }
//       canvas.drawPath(path, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _WindyPainter oldDelegate) => oldDelegate.shift != shift;
// }
//
// // -------------------- 12. Rainbow Animation --------------------
//
// class RainbowAnimation extends StatefulWidget {
//   final double size;
//   const RainbowAnimation({Key? key, this.size = 200}) : super(key: key);
//
//   @override
//   State<RainbowAnimation> createState() => _RainbowAnimationState();
// }
//
// class _RainbowAnimationState extends State<RainbowAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _arcShift;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//     AnimationController(vsync: this, duration: const Duration(seconds: 6))
//       ..repeat();
//
//     _arcShift = Tween<double>(begin: 0, end: 2 * pi).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.linear),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   static const List<Color> rainbowColors = [
//     Color(0xFFFF0000), // Red
//     Color(0xFFFF7F00), // Orange
//     Color(0xFFFFFF00), // Yellow
//     Color(0xFF00FF00), // Green
//     Color(0xFF0000FF), // Blue
//     Color(0xFF4B0082), // Indigo
//     Color(0xFF8F00FF), // Violet
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final size = widget.size;
//     return SizedBox(
//       width: size,
//       height: size / 1.5,
//       child: AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) {
//             return CustomPaint(
//               painter: _RainbowPainter(arcShift: _arcShift.value),
//               size: Size(size, size / 1.5),
//             );
//           }),
//     );
//   }
// }
//
// class _RainbowPainter extends CustomPainter {
//   final double arcShift;
//   _RainbowPainter({required this.arcShift});
//
//   static const List<Color> rainbowColors = [
//     Color(0xFFFF0000), // Red
//     Color(0xFFFF7F00), // Orange
//     Color(0xFFFFFF00), // Yellow
//     Color(0xFF00FF00), // Green
//     Color(0xFF0000FF), // Blue
//     Color(0xFF4B0082), // Indigo
//     Color(0xFF8F00FF), // Violet
//   ];
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height);
//     final radiusStep = size.width / 14;
//
//     for (int i = 0; i < rainbowColors.length; i++) {
//       final paint = Paint()
//         ..color = rainbowColors[i]
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = radiusStep * 1.5;
//
//       final radius = radiusStep * (i + 1);
//       final startAngle = pi + arcShift;
//       final sweepAngle = pi;
//
//       canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
//           sweepAngle, false, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _RainbowPainter oldDelegate) =>
//       oldDelegate.arcShift != arcShift;
// }
