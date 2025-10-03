// weather_model.dart
class Weather {
  final int weatherCode;
  final double temperature;
  final double humidity;
  final double rain;
  final double windSpeed;
  final DateTime sunrise;
  final DateTime sunset;
  final List<Forecast> forecast;

  Weather({
    required this.weatherCode,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Parse current weather
    final current = json['current_weather'];
    final daily = json['daily'];

    List<Forecast> forecasts = [];
    final dates = daily['time'] as List<dynamic>;
    final weatherCodes = daily['weathercode'] as List<dynamic>;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>;
    final rains = daily['precipitation_sum'] as List<dynamic>;

    for (int i = 0; i < dates.length; i++) {
      forecasts.add(Forecast(
        date: dates[i],
        weatherCode: weatherCodes[i],
        maxTemp: (maxTemps[i] as num).toDouble(),
        minTemp: (minTemps[i] as num).toDouble(),
        rain: (rains[i] as num).toDouble(),
      ));
    }

    // Parse sunrise and sunset times for today
    final sunriseStr = daily['sunrise'][0] as String;
    final sunsetStr = daily['sunset'][0] as String;

    return Weather(
      weatherCode: current['weathercode'],
      temperature: (current['temperature'] as num).toDouble(),
      humidity: (json['hourly']['relativehumidity_2m'][0] as num).toDouble(),
      rain: (json['hourly']['precipitation'][0] as num).toDouble(),
      windSpeed: (current['windspeed'] as num).toDouble(),
      sunrise: DateTime.parse(sunriseStr),
      sunset: DateTime.parse(sunsetStr),
      forecast: forecasts,
    );
  }
}

class Forecast {
  final String date; // e.g. "2023-06-27"
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final double rain;

  Forecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.rain,
  });
}
