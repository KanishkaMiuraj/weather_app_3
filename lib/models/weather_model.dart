class Weather {
  final int weatherCode;
  final double temperature;
  final double humidity;
  final double rain;
  final double windSpeed;
  final double windDirection;
  final DateTime sunrise;
  final DateTime sunset;
  final List<Forecast> forecast;

  Weather({
    required this.weatherCode,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.windSpeed,
    required this.windDirection,
    required this.sunrise,
    required this.sunset,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // 1. Safe parsing of Current Weather
    final current = json['current_weather'] ?? {};
    final daily = json['daily'] ?? {};
    final hourly = json['hourly'] ?? {};

    // 2. Safe parsing of Forecast Lists
    List<Forecast> forecasts = [];
    final dates = (daily['time'] as List?) ?? [];
    final weatherCodes = (daily['weathercode'] as List?) ?? [];
    final maxTemps = (daily['temperature_2m_max'] as List?) ?? [];
    final minTemps = (daily['temperature_2m_min'] as List?) ?? [];
    final rains = (daily['precipitation_sum'] as List?) ?? [];

    // Ensure we don't go out of bounds if lists have different lengths
    final minLength = [dates.length, weatherCodes.length, maxTemps.length].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < minLength; i++) {
      forecasts.add(Forecast(
        date: dates[i].toString(),
        weatherCode: weatherCodes[i] as int? ?? 0,
        maxTemp: (maxTemps[i] as num?)?.toDouble() ?? 0.0,
        minTemp: (minTemps[i] as num?)?.toDouble() ?? 0.0,
        rain: (rains[i] as num?)?.toDouble() ?? 0.0,
      ));
    }

    // 3. Safe Parsing of Sunrise/Sunset (Fallback to current time if missing to prevent crash)
    final sunriseList = daily['sunrise'] as List?;
    final sunsetList = daily['sunset'] as List?;

    final sunriseStr = (sunriseList != null && sunriseList.isNotEmpty)
        ? sunriseList[0] as String
        : DateTime.now().toIso8601String();

    final sunsetStr = (sunsetList != null && sunsetList.isNotEmpty)
        ? sunsetList[0] as String
        : DateTime.now().toIso8601String();

    // 4. Safe Parsing of Hourly Data
    final humidityList = hourly['relativehumidity_2m'] as List?;
    final rainList = hourly['precipitation'] as List?;

    final currentHumidity = (humidityList != null && humidityList.isNotEmpty)
        ? (humidityList[0] as num).toDouble()
        : 0.0;

    final currentRain = (rainList != null && rainList.isNotEmpty)
        ? (rainList[0] as num).toDouble()
        : 0.0;

    return Weather(
      weatherCode: current['weathercode'] as int? ?? 0,
      temperature: (current['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: currentHumidity,
      rain: currentRain,
      windSpeed: (current['windspeed'] as num?)?.toDouble() ?? 0.0,
      windDirection: (current['winddirection'] as num?)?.toDouble() ?? 0.0,
      sunrise: DateTime.parse(sunriseStr),
      sunset: DateTime.parse(sunsetStr),
      forecast: forecasts,
    );
  }

  String getWindDirection() {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'N';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'NE';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'E';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'SE';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'S';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'SW';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'W';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'NW';
    return '-';
  }
}

class Forecast {
  final String date;
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