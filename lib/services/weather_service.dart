import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // 1. Fetch Weather for a Single Location (Current)
  Future<Weather> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=precipitation,relativehumidity_2m&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,sunrise,sunset&timezone=auto',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Weather.fromJson(json);
    } else {
      throw Exception('Failed to load weather: ${response.statusCode}');
    }
  }

  // 2. Fetch Weather for Multiple Locations (Parallel)
  Future<List<Weather>> fetchRouteWeather(List<Map<String, double>> points) async {
    List<Future<Weather>> requests = points.map((point) {
      return fetchWeather(point['lat']!, point['lng']!);
    }).toList();

    return await Future.wait(requests);
  }

  // 3. NEW: Fetch Daily Forecast (Yesterday, Today, Tomorrow) for Destination
  Future<List<Map<String, dynamic>>> fetchDestinationDaily(double lat, double lon) async {
    // We request 3 days: 1 day past + 2 days forecast (Today + Tomorrow)
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weathercode,temperature_2m_max,temperature_2m_min&past_days=1&forecast_days=2&timezone=auto'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final daily = json['daily'];

        final codes = daily['weathercode'] as List;
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;

        // We expect 3 entries: Yesterday [0], Today [1], Tomorrow [2]
        List<Map<String, dynamic>> result = [];

        // Ensure we don't go out of bounds if API returns fewer days
        final count = [codes.length, maxTemps.length, minTemps.length].reduce((a, b) => a < b ? a : b);

        for (int i = 0; i < count; i++) {
          result.add({
            'code': codes[i],
            'max': maxTemps[i],
            'min': minTemps[i],
          });
        }
        return result;
      } else {
        return []; // Return empty list on failure gracefully
      }
    } catch (e) {
      // Return empty list on network error to prevent crashing UI
      return [];
    }
  }
}