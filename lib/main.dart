import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

// === NEW IMPORTS FOR AI AND DOTENV ===
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/weather_assistant_service.dart';

// Assuming these files exist in your project structure
import 'Widgets/weather_animations.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'helpers/weather_condition_helper.dart';

// === UPDATED main() TO LOAD API KEY ===
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String resolvedApiKey = '';

  try {
    await dotenv.load(fileName: ".env");
    resolvedApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  } catch (e) {
    print("FATAL DOTENV LOAD ERROR: $e");
  }

  if (resolvedApiKey.isEmpty) {
    throw Exception(
        "GEMINI_API_KEY not found. Ensure it is set in your .env file and loaded correctly.\nCheck pubspec.yaml assets section.");
  }

  runApp(WeatherApp(geminiApiKey: resolvedApiKey));
}

// === UPDATED WeatherApp TO ACCEPT API KEY ===
class WeatherApp extends StatelessWidget {
  final String geminiApiKey;
  const WeatherApp({required this.geminiApiKey, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: WeatherHomePage(geminiApiKey: geminiApiKey),
    );
  }
}

// === UPDATED WeatherHomePage TO ACCEPT API KEY ===
class WeatherHomePage extends StatefulWidget {
  final String geminiApiKey;
  const WeatherHomePage({required this.geminiApiKey, super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

// === UPDATED _WeatherHomePageState FOR AI INTEGRATION ===
class _WeatherHomePageState extends State<WeatherHomePage> {
  final WeatherService _weatherService = WeatherService();

  // NEW: AI Service and Summary state
  late final WeatherAssistantService _assistantService;
  String? _aiSummary;

  Weather? _weather;
  String? _city;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Initialize AI Service
    _assistantService = WeatherAssistantService(widget.geminiApiKey);
    _loadWeatherForCurrentLocation();
  }

  // Helper function to determine if it is currently day time
  bool _isDayTime() {
    if (_weather == null) return true;
    final now = DateTime.now();
    return now.isAfter(_weather!.sunrise) && now.isBefore(_weather!.sunset);
  }

  // === LOCATION AND WEATHER LOADING FUNCTIONS (UPDATED TO CALL AI) ===

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _loadWeatherForCurrentLocation() async {
    setState(() {
      _loading = true;
      _aiSummary = null; // Clear previous summary
    });
    try {
      final position = await _determinePosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final weather = await _weatherService.fetchWeather(position.latitude, position.longitude);
      setState(() {
        _city = placemarks.first.locality ?? "Unknown";
        _weather = weather;
        _loading = false;
      });
      // Call AI summary after successful weather load
      if (_city != null) {
        await _getAiSummary(weather, _city!);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _loadWeatherForCity(String cityName) async {
    setState(() {
      _loading = true;
      _aiSummary = null; // Clear previous summary
    });
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isEmpty) throw Exception('City not found');
      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      final weather = await _weatherService.fetchWeather(location.latitude, location.longitude);
      setState(() {
        _city = placemarks.first.locality ?? cityName;
        _weather = weather;
        _loading = false;
      });
      // Call AI summary after successful weather load
      await _getAiSummary(weather, _city!);
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog(e.toString());
    }
  }

  // NEW: Fetch the AI summary
  Future<void> _getAiSummary(Weather weather, String city) async {
    if (widget.geminiApiKey.isEmpty) {
      setState(() {
        _aiSummary = "AI service not configured (API Key missing).";
      });
      return;
    }
    try {
      final summary = await _assistantService.getInsightfulSummary(weather, city);
      setState(() {
        _aiSummary = summary;
      });
    } catch (e) {
      print("AI Summary Error: $e");
      setState(() {
        _aiSummary = "Could not load AI insights.";
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search City', style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter city name'),
          style: const TextStyle(color: Colors.black),
          onSubmitted: (value) {
            Navigator.pop(context);
            _loadWeatherForCity(value.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadWeatherForCity(controller.text.trim());
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  String formatDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('EEE, MMM d').format(parsed);
  }

  // --- UI HELPERS (GRADIENT, CARDS, ANIMATION) ---

  LinearGradient getBackgroundGradient(int weatherCode) {
    final bool isDay = _isDayTime();

    if (weatherCode == 0) {
      return isDay
          ? const LinearGradient(colors: [Color(0xFF87CEEB), Color(0xFF004E92)])
          : const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)]);
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      return const LinearGradient(colors: [Color(0xFF90A4AE), Color(0xFF455A64)]);
    } else if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
      return const LinearGradient(colors: [Color(0xFF3A6073), Color(0xFF16222A)]);
    } else if ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86)) {
      return const LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]);
    } else if (weatherCode >= 95) {
      return const LinearGradient(colors: [Color(0xFF373B44), Color(0xFF4286f4)]);
    } else {
      return isDay
          ? const LinearGradient(colors: [Color(0xFF1C1C2A), Color(0xFF323353)])
          : const LinearGradient(colors: [Color(0xFF000000), Color(0xFF0F0F0F)]);
    }
  }

  Color getForecastTileColor(int weatherCode) {
    if (weatherCode == 0) return const Color(0xFF4FC3F7);
    if (weatherCode >= 1 && weatherCode <= 3) return const Color(0xFF90A4AE);
    if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
      return const Color(0xFF4A6FA5);
    }
    if ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86)) {
      return const Color(0xFFE0F7FA);
    }
    if (weatherCode >= 95) return const Color(0xFF5C6BC0);
    return const Color(0xFFB0BEC5);
  }

  Widget buildForecastCard(Forecast forecast) {
    final bgColor = getForecastTileColor(forecast.weatherCode).withOpacity(0.25);
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDate(forecast.date),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text(getWeatherCondition(forecast.weatherCode),
                    style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 8),
                Text('🌧 Rain: ${forecast.rain.toStringAsFixed(1)} mm', style: const TextStyle(color: Colors.white70)),
                Text('🌡 Max: ${forecast.maxTemp.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white70)),
                Text('🌡 Min: ${forecast.minTemp.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMetricCard({
    required String title,
    required String value,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: Icon(icon, color: Colors.white.withOpacity(0.3), size: 60),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(value,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getWeatherAnimation(int code) {
    final bool isDay = _isDayTime();

    switch (code) {
      case 0: return isDay ? const SunnyAnimation() : const NightClearAnimation();
      case 1:
      case 2:
      case 3: return const CloudyAnimation();
      case 45:
      case 48: return const CloudyAnimation();
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65: return const RainyAnimation();
      case 56:
      case 57:
      case 66:
      case 67: return const HailAnimation();
      case 71:
      case 73:
      case 75:
      case 77: return const SnowAnimation();
      case 80:
      case 81:
      case 82: return const RainyAnimation();
      case 85:
      case 86: return const SnowAnimation();
      case 95:
      case 96:
      case 99: return const HailAnimation();
      default: return isDay ? const SunnyAnimation() : const NightClearAnimation();
    }
  }

  // UPDATED HELPER FUNCTION TO BUILD THE FIVE THEMATIC INSIGHT LINES
  List<Widget> _buildInsightLines() {
    if (_aiSummary == null) return [const SizedBox.shrink()];

    // Split the summary into lines. Now expecting exactly five lines.
    final lines = _aiSummary!.trim().split('\n').where((s) => s.isNotEmpty).toList();

    // Define icons for the five fixed themes
    final List<IconData> icons = [
      Icons.wb_sunny_rounded,      // ☀️ Theme 1: Day's Nature
      Icons.shield_outlined,       // 🛡️ Theme 2: Tactical Suggestion
      Icons.eco_outlined,          // 🌿 Theme 3: General Eco Tip
      Icons.spa_outlined,          // 🌱 Theme 4: SL Cultivation Tip
      Icons.commute_outlined,      // 🚗 Theme 5: Driver's Road Tip (New Icon)
    ];

    // Custom 'glowing' text style (preserved)
    const glowingTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.white,
      shadows: [
        Shadow(
          blurRadius: 5.0,
          color: Colors.lightBlueAccent, // Subtle glow color
        ),
      ],
    );

    // Ensure we only process up to 5 lines
    return List.generate(lines.length.clamp(0, 5), (index) {
      if (index >= icons.length) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icons[index],
              color: Colors.lightBlueAccent, // Color the icon for visibility/glow effect
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lines[index],
                style: glowingTextStyle,
              ),
            ),
          ],
        ),
      );
    });
  }

  // UPDATED WIDGET: AI Summary Card
  Widget buildAiSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🟢 AI Weather Insight',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          _aiSummary == null
              ? const LinearProgressIndicator(
            color: Colors.lightBlueAccent,
            backgroundColor: Colors.transparent,
          )
          // Use the new structured display method
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildInsightLines(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = _weather != null
        ? getBackgroundGradient(_weather!.weatherCode)
        : const LinearGradient(colors: [Colors.blueGrey, Colors.black]);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _weather == null
              ? const Center(child: Text('Weather data not available'))
              : RefreshIndicator(
            onRefresh: () => _city != null
                ? _loadWeatherForCity(_city!)
                : _loadWeatherForCurrentLocation(),
            color: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title & search
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onTap: () {
                            _showSearchDialog();
                          },
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter to search weather',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white24,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Location: $_city',
                      style: const TextStyle(fontSize: 24, color: Colors.white)),
                  const SizedBox(height: 20),
                  Center(child: getWeatherAnimation(_weather!.weatherCode)),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(getWeatherCondition(_weather!.weatherCode),
                        style: const TextStyle(fontSize: 22, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),

                  // Metric Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildMetricCard(
                        title: 'Temperature',
                        value: '${_weather!.temperature.toStringAsFixed(1)} °C',
                        gradientColors: const [Colors.orangeAccent, Colors.deepOrange],
                        icon: Icons.thermostat,
                      ),
                      buildMetricCard(
                        title: 'Humidity',
                        value: '${_weather!.humidity.toStringAsFixed(1)} %',
                        gradientColors: const [Colors.lightBlueAccent, Colors.blue],
                        icon: Icons.water_drop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildMetricCard(
                        title: 'Rain',
                        value: '${_weather!.rain.toStringAsFixed(1)} mm',
                        gradientColors: const [Colors.indigo, Colors.blueGrey],
                        icon: Icons.grain,
                      ),
                      buildMetricCard(
                        title: 'Wind Speed',
                        value: '${_weather!.windSpeed.toStringAsFixed(1)} km/h',
                        gradientColors: const [Colors.greenAccent, Colors.teal],
                        icon: Icons.air,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wind Direction Metric Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildMetricCard(
                        title: 'Wind Direction',
                        value: _weather!.getWindDirection(),
                        gradientColors: const [Colors.purpleAccent, Colors.deepPurple],
                        icon: Icons.explore,
                      ),
                      const Spacer(),
                    ],
                  ),

                  // === Sunrise & Sunset Tile (SunPathAnimation) ===
                  const SizedBox(height: 24),
                  const Text('Sunrise & Sunset',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  const SizedBox(height: 10),
                  // Removed margin here to allow SunPathAnimation to use full width if needed
                  Container(
                    height: 190,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SunPathAnimation(
                        sunrise: _weather!.sunrise,
                        sunset: _weather!.sunset,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // === AI INSIGHT CARD (CORRECTED POSITION) ===
                  buildAiSummaryCard(),

                  const SizedBox(height: 10),

                  // === 7-Day Forecast ===
                  const Text('📆 7-Day Forecast',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                      _weather!.forecast.map((f) => buildForecastCard(f)).toList(),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Sun Path Animation and Painter logic (Preserved)

class SunPathAnimation extends StatefulWidget {
  final DateTime sunrise;
  final DateTime sunset;

  const SunPathAnimation({
    Key? key,
    required this.sunrise,
    required this.sunset,
  }) : super(key: key);

  @override
  _SunPathAnimationState createState() => _SunPathAnimationState();
}

class _SunPathAnimationState extends State<SunPathAnimation> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get _progress {
    if (widget.sunrise.isAtSameMomentAs(widget.sunset)) return 0.5;
    if (_now.isBefore(widget.sunrise)) return 0.0;
    if (_now.isAfter(widget.sunset)) return 1.0;
    final total = widget.sunset.difference(widget.sunrise).inSeconds;
    final passed = _now.difference(widget.sunrise).inSeconds;
    return (passed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SunPathPainter(progress: _progress),
      child: SizedBox(
        height: 140,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // Sunrise time
              Positioned(
                left: 0,
                bottom: 10,
                child: Text(
                  _formatTime(widget.sunrise),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
              // Sunset time
              Positioned(
                right: 0,
                bottom: 10,
                child: Text(
                  _formatTime(widget.sunset),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
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

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      paintArc,
    );

    // Calculate sun position (0.0=left/pi, 1.0=right/0)
    final angle = math.pi * (1 - progress);
    final sunX = center.dx + radius * math.cos(angle);
    final sunY = center.dy + radius * math.sin(angle);

    // Draw glowing sun
    canvas.drawCircle(Offset(sunX, sunY), 14, paintSun);

    final innerGlow = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 6, innerGlow);
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) => true;
}