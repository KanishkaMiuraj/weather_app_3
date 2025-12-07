import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Free Map Widget
import 'package:latlong2/latlong.dart'; // Coordinate System
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

  String? _journeySummary;
  String? _durationText;
  String? _distanceText;
  bool _isLoading = false;

  // Default Location: Colombo, Sri Lanka
  static const LatLng _kDefaultLocation = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _directionsService = DirectionsService(); // Uses free OSRM
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
    });
    FocusScope.of(context).unfocus(); // Close keyboard

    try {
      // 1. Geocode Start & End Locations
      List<Location> startLocs = await locationFromAddress(_startController.text);
      List<Location> endLocs = await locationFromAddress(_endController.text);

      if (startLocs.isEmpty || endLocs.isEmpty) {
        throw Exception("Could not find one of those places. Please check spelling.");
      }

      LatLng start = LatLng(startLocs.first.latitude, startLocs.first.longitude);
      LatLng end = LatLng(endLocs.first.latitude, endLocs.first.longitude);

      // 2. Get Directions (Route Line) from OSRM
      final directionData = await _directionsService.getDirections(start, end);
      final List<LatLng> polylinePoints = directionData['polyline'];

      // 3. Sample Points Logic (Start, Middle, End)
      List<Map<String, double>> samplePoints = [];

      // Start Point
      samplePoints.add({'lat': start.latitude, 'lng': start.longitude});

      // Middle Point (only if route is long enough)
      if (polylinePoints.length > 20) {
        final mid = polylinePoints[polylinePoints.length ~/ 2];
        samplePoints.add({'lat': mid.latitude, 'lng': mid.longitude});
      }

      // End Point
      samplePoints.add({'lat': end.latitude, 'lng': end.longitude});

      // 4. Fetch Weather for all sampled points
      final weatherList = await _weatherService.fetchRouteWeather(samplePoints);

      // 5. Get AI Insight (Generic Travel Assistant)
      final summary = await _assistantService.getJourneySummary(
          _startController.text,
          _endController.text,
          weatherList,
          directionData['duration']
      );

      // 6. Update UI State
      setState(() {
        _routeWeather = weatherList;
        _journeySummary = summary;
        _durationText = directionData['duration'];
        _distanceText = directionData['distance'];
        _routePoints = polylinePoints;

        _markers = [];

        // Helper function to build custom marker widgets
        Marker buildMarker(LatLng pos, Color color, int weatherCode, String label) {
          return Marker(
            point: pos,
            width: 80,
            height: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weather Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        "${getWeatherCondition(weatherCode).split(" ").first} ${weatherList[0].temperature.round()}°",
                        style: const TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                // Pin Icon
                Icon(Icons.location_on, color: color, size: 40),
              ],
            ),
          );
        }

        // Add Start Marker
        _markers.add(buildMarker(start, Colors.green.shade700, weatherList[0].weatherCode, "START"));

        // Add Mid Marker (if exists)
        if (weatherList.length > 2 && polylinePoints.length > 20) {
          final mid = polylinePoints[polylinePoints.length ~/ 2];
          _markers.add(buildMarker(mid, Colors.amber.shade800, weatherList[1].weatherCode, "MID"));
        }

        // Add End Marker
        _markers.add(buildMarker(end, Colors.red.shade700, weatherList.last.weatherCode, "END"));
      });

      // 7. Auto-zoom to show the full route
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

  // Helper to zoom the map to fit the route
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
      body: Stack(
        children: [
          // 1. THE MAP LAYER (Background)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _kDefaultLocation,
              initialZoom: 12,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Disable rotation for simplicity
              ),
            ),
            children: [
              // Free OpenStreetMap Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
              // The Blue Route Line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              // The Markers (Start, Mid, End)
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. BACK BUTTON (Top Left)
          Positioned(
            top: 50, left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. INPUT CARD (Top Center)
          Positioned(
            top: 100, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                        hintText: "From (e.g. Colombo)",
                        icon: Icon(Icons.my_location, color: Colors.blue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 5)
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                        hintText: "To (e.g. Kandy)",
                        icon: Icon(Icons.location_on, color: Colors.red),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 5)
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _calculateJourney,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Plan Trip", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 4. SUMMARY CARD (Bottom) - Only shows after calculation
          if (_journeySummary != null)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: _buildSummaryCard(),
            ),
        ],
      ),
    );
  }

  // --- WIDGET: Bottom Summary Card ---
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2A).withOpacity(0.95), // Dark theme to match main app
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Duration and Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Distance: $_distanceText",
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("Est. Time: $_durationText",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Colors.white),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 24),

          // Generic Advice Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Travel Tips:", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _journeySummary!,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Horizontal List of Weather Stops
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _routeWeather.length,
              itemBuilder: (context, index) {
                String label;
                if (index == 0) label = "Start";
                else if (index == _routeWeather.length - 1) label = "End";
                else label = "Mid-way";

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 6),
                      // Weather Icon (Simplified mapping)
                      Icon(
                          _routeWeather[index].rain > 0 ? Icons.cloudy_snowing : Icons.wb_sunny,
                          color: Colors.white,
                          size: 24
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "${_routeWeather[index].temperature.round()}°C",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}