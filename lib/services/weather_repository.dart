import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import 'location_service.dart';
import 'weather_service.dart';
import 'weather_assistant_service.dart';

class WeatherRepository {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final WeatherAssistantService _assistantService;

  WeatherRepository(String apiKey) : _assistantService = WeatherAssistantService(apiKey);

  Future<Map<String, dynamic>> getWeatherForCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final city = placemarks.first.locality ?? "Unknown Location";

      final weather = await _weatherService.fetchWeather(position.latitude, position.longitude);
      final summary = await _assistantService.getInsightfulSummary(weather, city);

      return {
        'weather': weather,
        'city': city,
        'summary': summary,
      };
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> getWeatherForCity(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isEmpty) throw Exception('City not found');

      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      final city = placemarks.first.locality ?? cityName;

      final weather = await _weatherService.fetchWeather(location.latitude, location.longitude);
      final summary = await _assistantService.getInsightfulSummary(weather, city);

      return {
        'weather': weather,
        'city': city,
        'summary': summary,
      };
    } catch (e) {
      throw e;
    }
  }
}