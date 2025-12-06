import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Services & Models
import 'services/weather_repository.dart';
import 'models/weather_model.dart';
import 'helpers/weather_condition_helper.dart';

// Widgets
import 'Widgets/weather_animations.dart';
import 'Widgets/sun_path_widget.dart';

// Screens
import 'screens/journey_screen.dart'; // Import the new Journey Screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String resolvedApiKey = '';

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    resolvedApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  } catch (e) {
    debugPrint("DOTENV ERROR: $e");
  }

  runApp(WeatherApp(geminiApiKey: resolvedApiKey));
}

class WeatherApp extends StatelessWidget {
  final String geminiApiKey;
  const WeatherApp({required this.geminiApiKey, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: WeatherHomePage(geminiApiKey: geminiApiKey),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final String geminiApiKey;
  const WeatherHomePage({required this.geminiApiKey, super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  late final WeatherRepository _repository;

  Weather? _weather;
  String? _city;
  String? _aiSummary;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = WeatherRepository(widget.geminiApiKey);
    _initWeatherData();
  }

  Future<void> _initWeatherData() async {
    await _fetchData(() => _repository.getWeatherForCurrentLocation());
  }

  Future<void> _searchCity(String city) async {
    await _fetchData(() => _repository.getWeatherForCity(city));
  }

  Future<void> _fetchData(Future<Map<String, dynamic>> Function() fetcher) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await fetcher();
      if (mounted) {
        setState(() {
          _weather = data['weather'];
          _city = data['city'];
          _aiSummary = data['summary'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  bool _isDayTime() {
    if (_weather == null) return true;
    final now = DateTime.now();
    return now.isAfter(_weather!.sunrise) && now.isBefore(_weather!.sunset);
  }

  void _showSearchDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Search City', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter city name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (value) {
            Navigator.pop(context);
            if(value.isNotEmpty) _searchCity(value.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if(controller.text.isNotEmpty) _searchCity(controller.text.trim());
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  LinearGradient getBackgroundGradient(int weatherCode) {
    final bool isDay = _isDayTime();
    if (weatherCode == 0) {
      return isDay
          ? const LinearGradient(colors: [Color(0xFF87CEEB), Color(0xFF004E92)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          : const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    }
    return const LinearGradient(colors: [Color(0xFF1C1C2A), Color(0xFF323353)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = _weather != null
        ? getBackgroundGradient(_weather!.weatherCode)
        : const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]);

    return Scaffold(
      // --- NEW FEATURE BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Journey Screen (No Google Maps API Key needed anymore!)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JourneyScreen(
                geminiApiKey: widget.geminiApiKey,
              ),
            ),
          );
        },
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.map, color: Colors.black),
        label: const Text("Plan Journey", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      // ---------------------------

      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _loading
                    ? _buildShimmerLoading()
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _buildWeatherContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: _showSearchDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                _city ?? 'Search City...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text("Oops!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Something went wrong.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Center(child: _buildShimmerBox(width: 150, height: 150, borderRadius: 75)),
        const SizedBox(height: 20),
        Center(child: _buildShimmerBox(width: 200, height: 30, borderRadius: 8)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShimmerBox(width: 160, height: 120, borderRadius: 16),
            _buildShimmerBox(width: 160, height: 120, borderRadius: 16),
          ],
        ),
        const SizedBox(height: 20),
        _buildShimmerBox(width: double.infinity, height: 200, borderRadius: 16),
      ],
    );
  }

  Widget _buildShimmerBox({double? width, double? height, double borderRadius = 0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildWeatherContent() {
    return RefreshIndicator(
      onRefresh: _initWeatherData,
      color: Colors.white,
      backgroundColor: Colors.indigo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(child: getWeatherAnimation(_weather!.weatherCode)),
            const SizedBox(height: 20),
            Center(
              child: Text(
                getWeatherCondition(_weather!.weatherCode),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
            ),
            Center(
              child: Text(
                '${_weather!.temperature.toStringAsFixed(1)}°',
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                buildMetricCard(
                  title: 'Humidity',
                  value: '${_weather!.humidity.toStringAsFixed(0)}%',
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                ),
                buildMetricCard(
                  title: 'Wind',
                  value: '${_weather!.windSpeed.toStringAsFixed(1)} km/h',
                  icon: Icons.air,
                  color: Colors.tealAccent,
                ),
                buildMetricCard(
                  title: 'Rain',
                  value: '${_weather!.rain.toStringAsFixed(1)} mm',
                  icon: Icons.cloudy_snowing,
                  color: Colors.indigoAccent,
                ),
                buildMetricCard(
                  title: 'Direction',
                  value: _weather!.getWindDirection(),
                  icon: Icons.explore,
                  color: Colors.purpleAccent,
                ),
              ],
            ),

            const SizedBox(height: 24),
            SunPathWidget(sunrise: _weather!.sunrise, sunset: _weather!.sunset),
            const SizedBox(height: 24),
            _buildAiSummaryCard(),
            const SizedBox(height: 24),
            const Text('7-Day Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weather!.forecast.length,
                itemBuilder: (context, index) {
                  return buildForecastCard(_weather!.forecast[index]);
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAiSummaryCard() {
    if (_aiSummary == null) return const SizedBox.shrink();

    final lines = _aiSummary!.trim().split('\n').where((s) => s.isNotEmpty).toList();
    final List<IconData> icons = [Icons.wb_sunny, Icons.shield_outlined, Icons.eco_outlined, Icons.spa_outlined, Icons.commute_outlined];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amberAccent),
              SizedBox(width: 10),
              Text('Avani\'s Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(lines.length.clamp(0, 5), (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icons[index % icons.length], color: Colors.lightBlueAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lines[index], style: const TextStyle(fontSize: 15, height: 1.4))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildForecastCard(Forecast forecast) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(DateFormat('EEE, d').format(DateTime.parse(forecast.date)), style: const TextStyle(fontWeight: FontWeight.bold)),
          Icon(Icons.cloud, color: Colors.white.withOpacity(0.8), size: 32),
          Text(getWeatherCondition(forecast.weatherCode).split(" ").first, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${forecast.maxTemp.round()}°', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('${forecast.minTemp.round()}°', style: const TextStyle(color: Colors.white60)),
            ],
          )
        ],
      ),
    );
  }

  Widget getWeatherAnimation(int code) {
    final bool isDay = _isDayTime();
    switch (code) {
      case 0: return isDay ? const SunnyAnimation() : const NightClearAnimation(size: 200);
      case 1: case 2: case 3: return const CloudyAnimation();
      case 51: case 53: case 61: case 63: return const RainyAnimation();
      case 71: case 73: return const SnowAnimation();
      case 95: case 96: return const HailAnimation();
      default: return isDay ? const SunnyAnimation() : const NightClearAnimation(size: 200);
    }
  }
}