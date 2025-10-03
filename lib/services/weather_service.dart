// weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  Future<Weather> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=precipitation,relativehumidity_2m&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,sunrise,sunset&timezone=auto',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Weather.fromJson(json);
    } else {
      throw Exception('Failed to load weather');
    }
  }
}
