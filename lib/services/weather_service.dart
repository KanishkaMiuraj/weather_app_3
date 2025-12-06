import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // 1. Fetch Weather for a Single Location
  // Used by the Home Screen
  Future<Weather> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=precipitation,relativehumidity_2m&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,sunrise,sunset&timezone=auto',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Weather.fromJson(json);
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // 2. Fetch Weather for Multiple Locations (Parallel)
  // Used by the Journey Planner to check Start, Mid, and End points at the same time
  Future<List<Weather>> fetchRouteWeather(List<Map<String, double>> points) async {
    // Create a list of future requests
    List<Future<Weather>> requests = points.map((point) {
      return fetchWeather(point['lat']!, point['lng']!);
    }).toList();

    // Wait for all requests to finish and return the list of Weather objects
    return await Future.wait(requests);
  }
}