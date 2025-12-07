import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

// Services
import '../services/directions_service.dart';
import '../services/weather_service.dart';
import '../services/weather_assistant_service.dart';

// Models & Helpers
import '../models/weather_model.dart';
import '../helpers/weather_condition_helper.dart';

class JourneyScreen extends StatefulWidget {
  final String geminiApiKey;

  const JourneyScreen({
    required this.geminiApiKey,
    super.key,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  // Controllers
  final MapController _mapController = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  // Services
  late final DirectionsService _directionsService;
  late final WeatherService _weatherService;
  late final WeatherAssistantService _assistantService;

  // State Variables
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];
  List<Weather> _routeWeather = [];

  // Map Key: 'start', 'mid', 'end'
  Map<String, List<Map<String, dynamic>>> _hourlyForecasts = {};

  String? _journeySummary;
  String? _durationText;
  String? _distanceText;
  bool _isLoading = false;

  // Default Location: Colombo, Sri Lanka
  static const LatLng _kDefaultLocation = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _directionsService = DirectionsService();
    _weatherService = WeatherService();
    _assistantService = WeatherAssistantService(widget.geminiApiKey);
  }

  // --- CORE LOGIC ---

  Future<void> _calculateJourney() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter both start and end locations."))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _journeySummary = null;
      _hourlyForecasts = {};
    });
    FocusScope.of(context).unfocus();

    try {
      List<Location> startLocs = await locationFromAddress(_startController.text);
      List<Location> endLocs = await locationFromAddress(_endController.text);

      if (startLocs.isEmpty || endLocs.isEmpty) {
        throw Exception("Could not find one of those places. Please check spelling.");
      }

      LatLng start = LatLng(startLocs.first.latitude, startLocs.first.longitude);
      LatLng end = LatLng(endLocs.first.latitude, endLocs.first.longitude);

      final directionData = await _directionsService.getDirections(start, end);
      final List<LatLng> polylinePoints = directionData['polyline'];

      List<Map<String, double>> samplePoints = [];
      LatLng? midPoint;

      samplePoints.add({'lat': start.latitude, 'lng': start.longitude});

      if (polylinePoints.length > 20) {
        final midIndex = polylinePoints.length ~/ 2;
        midPoint = polylinePoints[midIndex];
        samplePoints.add({'lat': midPoint.latitude, 'lng': midPoint.longitude});
      }

      samplePoints.add({'lat': end.latitude, 'lng': end.longitude});

      final weatherList = await _weatherService.fetchRouteWeather(samplePoints);
      await _fetchHourlyForecasts(start, midPoint, end);

      final summary = await _assistantService.getJourneySummary(
          _startController.text,
          _endController.text,
          weatherList,
          directionData['duration']
      );

      setState(() {
        _routeWeather = weatherList;
        _journeySummary = summary;
        _durationText = directionData['duration'];
        _distanceText = directionData['distance'];
        _routePoints = polylinePoints;

        _markers = [];

        Marker buildMarker(LatLng pos, Color color, int weatherCode, String label) {
          return Marker(
            point: pos,
            width: 80,
            height: 100, // Increased height for marker
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black38)],
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getWeatherIcon(weatherCode), size: 12, color: Colors.black87),
                          const SizedBox(width: 4),
                          Text(
                            "${weatherList[0].temperature.round()}°",
                            style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.location_on, color: color, size: 45),
              ],
            ),
          );
        }

        _markers.add(buildMarker(start, Colors.green.shade700, weatherList[0].weatherCode, "START"));

        if (weatherList.length > 2 && polylinePoints.length > 20) {
          final mid = polylinePoints[polylinePoints.length ~/ 2];
          _markers.add(buildMarker(mid, Colors.amber.shade800, weatherList[1].weatherCode, "MID"));
        }

        _markers.add(buildMarker(end, Colors.red.shade700, weatherList.last.weatherCode, "END"));
      });

      _fitBounds(polylinePoints);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString().replaceAll('Exception:', '')}"),
            backgroundColor: Colors.redAccent,
          )
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHourlyForecasts(LatLng start, LatLng? mid, LatLng end) async {
    Future<List<Map<String, dynamic>>> fetchForLocation(double lat, double lon) async {
      try {
        final url = Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,weathercode&forecast_days=2'
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final hourly = data['hourly'];
          final times = hourly['time'] as List;
          final temps = hourly['temperature_2m'] as List;
          final codes = hourly['weathercode'] as List;

          final now = DateTime.now();
          int startIndex = -1;

          for(int i=0; i<times.length; i++) {
            if (DateTime.parse(times[i]).hour == now.hour && DateTime.parse(times[i]).day == now.day) {
              startIndex = i;
              break;
            }
          }

          if (startIndex == -1) return [];

          List<Map<String, dynamic>> forecast = [];
          for(int i=1; i<=3; i++) {
            if (startIndex + i < times.length) {
              forecast.add({
                'time': DateTime.parse(times[startIndex + i]),
                'temp': temps[startIndex + i],
                'code': codes[startIndex + i],
              });
            }
          }
          return forecast;
        }
      } catch (e) {
        debugPrint("Error fetching hourly forecast: $e");
      }
      return [];
    }

    final startForecast = await fetchForLocation(start.latitude, start.longitude);
    final endForecast = await fetchForLocation(end.latitude, end.longitude);
    List<Map<String, dynamic>> midForecast = [];

    if (mid != null) {
      midForecast = await fetchForLocation(mid.latitude, mid.longitude);
    }

    setState(() {
      _hourlyForecasts['start'] = startForecast;
      if (mid != null) _hourlyForecasts['mid'] = midForecast;
      _hourlyForecasts['end'] = endForecast;
    });
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.grain_rounded;
    if (code >= 85 && code <= 86) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;

    return Icons.wb_cloudy_rounded;
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _kDefaultLocation,
              initialZoom: 12,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6,
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderColor: Colors.blue.shade900,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. GRADIENT HEADER
          Positioned(
            top: 0, left: 0, right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. BACK BUTTON
          Positioned(
            top: 50, left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // 4. FLOATING INPUT CARD
          Positioned(
            top: 100, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  _buildInputField(_startController, "Start Location", Icons.my_location, Colors.blueAccent),
                  const Divider(height: 1, indent: 50, endIndent: 20),
                  _buildInputField(_endController, "Destination", Icons.location_on, Colors.redAccent),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Plan Trip", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. RECENTER BUTTON (Visible when summary is hidden)
          if (_journeySummary == null)
            Positioned(
              bottom: 40, right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  _mapController.move(_kDefaultLocation, 12);
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.indigo),
              ),
            ),

          // 6. SCROLLABLE BOTTOM SHEET
          if (_journeySummary != null)
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              builder: (BuildContext context, ScrollController scrollController) {
                return _buildScrollableSummary(scrollController);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, Color iconColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: iconColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildScrollableSummary(ScrollController scrollController) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2A).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white10),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Duration & Distance Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Distance: $_distanceText",
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text("Est. Time: $_durationText",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // AI Tips Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text("Travel Assistant", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _journeySummary!,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Journey Conditions (Start, Mid, End)
              const Text("Journey Conditions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 170, // Increased height to prevent overflow
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _routeWeather.length,
                  itemBuilder: (context, index) {
                    String label = index == 0 ? "Start Point" : (index == _routeWeather.length - 1 ? "Destination" : "Mid-Journey");
                    return _buildWeatherCard(label, _routeWeather[index], true);
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Hourly Forecasts
              if (_hourlyForecasts.isNotEmpty) ...[
                const Text("Next 3 Hours Forecast", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (_hourlyForecasts.containsKey('start'))
                  _buildLocationForecastSection("At Start Point", _hourlyForecasts['start']!),

                if (_hourlyForecasts.containsKey('mid') && _hourlyForecasts['mid']!.isNotEmpty)
                  _buildLocationForecastSection("At Mid Point", _hourlyForecasts['mid']!),

                if (_hourlyForecasts.containsKey('end'))
                  _buildLocationForecastSection("At Destination", _hourlyForecasts['end']!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationForecastSection(String title, List<Map<String, dynamic>> forecastData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: forecastData.length,
            itemBuilder: (context, index) {
              final data = forecastData[index];
              return _buildHourlyCard(data);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeatherCard(String label, Weather w, bool isCurrent) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const Spacer(),
          Icon(_getWeatherIcon(w.weatherCode), color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text("${w.temperature.round()}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          // Fixed: Text handling
          SizedBox(
            height: 36, // Fixed height for text
            child: Center(
              child: Text(
                getWeatherCondition(w.weatherCode),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.1),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHourlyCard(Map<String, dynamic> data) {
    final time = data['time'] as DateTime;
    final temp = data['temp'];
    final code = data['code'];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${time.hour}:00", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Icon(_getWeatherIcon(code), color: Colors.lightBlueAccent, size: 28),
          const SizedBox(height: 8),
          Text("$temp°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          // Added SizedBox to prevent overflow
          SizedBox(
            height: 36, // Fixed height for forecast text
            child: Center(
              child: Text(
                getWeatherCondition(code),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}