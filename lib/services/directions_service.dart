import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DirectionsService {
  // Using OSRM Public Demo Server (Free, no API key required)
  final String baseUrl = 'http://router.project-osrm.org/route/v1/driving';

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng dest) async {
    // OSRM expects coordinates in "Longitude,Latitude" order (Bio-order)
    // Format: {lon},{lat};{lon},{lat}
    final String url = '$baseUrl/${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Check if OSRM returned a valid code
        if (json['code'] != 'Ok') {
          throw Exception('Error fetching route from OSRM: ${json['code']}');
        }

        final routes = json['routes'] as List;
        if (routes.isEmpty) {
          throw Exception('No route found between these locations.');
        }

        final route = routes[0];

        // 1. Extract Geometry (The line to draw)
        final geometry = route['geometry']['coordinates'] as List;

        // Convert GeoJSON [Lon, Lat] to Flutter [Lat, Lon]
        List<LatLng> path = geometry.map((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();

        // 2. Extract Metadata
        final durationSeconds = route['duration'];
        final distanceMeters = route['distance'];

        return {
          'polyline': path,
          'distance': _formatDistance(distanceMeters),
          'duration': _formatDuration(durationSeconds),
        };
      } else {
        throw Exception('Failed to load directions. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching directions: $e');
    }
  }

  // Helper to format distance (e.g., "15.4 km")
  String _formatDistance(dynamic meters) {
    if (meters == null) return "0 km";
    double km = (meters as num) / 1000;
    return "${km.toStringAsFixed(1)} km";
  }

  // Helper to format duration (e.g., "2 hr 15 min")
  String _formatDuration(dynamic seconds) {
    if (seconds == null) return "0 mins";
    int secs = (seconds as num).toInt();
    int hours = secs ~/ 3600;
    int minutes = (secs % 3600) ~/ 60;

    if (hours > 0) {
      return "$hours hr $minutes min";
    } else {
      return "$minutes min";
    }
  }
}