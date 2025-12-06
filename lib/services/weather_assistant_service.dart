// services/weather_assistant_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/weather_model.dart';
import '../helpers/weather_condition_helper.dart';

class WeatherAssistantService {
  final GenerativeModel _model;

  WeatherAssistantService(String apiKey)
      : _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  /// ---------------------------------------------------------
  /// PERSONA 1: AVANI (Daily Weather Guide)
  /// Friendly, professional, and practical.
  /// ---------------------------------------------------------
  Future<String> getInsightfulSummary(Weather weather, String city) async {
    final currentCondition = getWeatherCondition(weather.weatherCode);

    // Extract max 2-3 day forecast conditions
    final nextFewDaysConditions = weather.forecast.take(3).map((f) {
      return getWeatherCondition(f.weatherCode);
    }).join(', ');

    final prompt = '''
      You are Avani, an expert, friendly, and kind weather guide. Provide **five** extremely short, sharp, and useful tips, speaking with a warm, helpful tone.
      
      You must format your entire response as **EXACTLY FIVE SENTENCES**, each sentence on a separate line. **CRITICALLY: Each sentence must be a maximum of 8 words.** Be direct, kind, and highly concise. Do not use markdown, numbers, or conversational fillers.
      
      1. **First sentence (Day's Nature):** Summarize the day's vibe. (e.g., "It's a beautiful day for a walk!")
      2. **Second sentence (Tactical Advice):** Give one short, actionable suggestion. (e.g., "Don't forget your sunglasses today.")
      3. **Third sentence (General Eco Tip):** Give one short, general environment tip. (e.g., "It's best to save water for later.")
      4. **Fourth sentence (SL Cultivation Tip):** Give a short, specific Sri Lankan planting tip. (e.g., "Plant those small chili seeds now.")
      5. **Fifth sentence (Driver's Road Tip):** Offer one critical tip for drivers. (e.g., "Watch out for road puddles.")

      **Current Data for $city, Sri Lanka:**
      - Temperature: ${weather.temperature.toStringAsFixed(1)}°C
      - Condition: $currentCondition
      - Rain: ${weather.rain.toStringAsFixed(1)}mm
      - Humidity: ${weather.humidity.toStringAsFixed(0)}%
      - Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h
      - Next 3-day conditions: $nextFewDaysConditions
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      // Ensure the output is clean and limited to 5 lines
      final processedText = response.text
          ?.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(5)
          .join('\n');

      return processedText ?? "Avani is currently offline.";
    } catch (e) {
      print('Gemini API Error: $e');
      return 'Error fetching Avani\'s insights.';
    }
  }

  /// ---------------------------------------------------------
  /// PERSONA 2: KADE AUNTY (Journey Advisor)
  /// Caring, slightly strict, uses Sri Lankan English flavor.
  /// ---------------------------------------------------------
  Future<String> getJourneySummary(String startCity, String endCity, List<Weather> routeWeather, String duration) async {
    String weatherLog = "";

    // Construct a log of the weather at the sampled points
    if (routeWeather.isNotEmpty) {
      weatherLog += "Start ($startCity): ${getWeatherCondition(routeWeather[0].weatherCode)}, ${routeWeather[0].temperature}°C\n";
    }
    if (routeWeather.length > 2) {
      // The middle point is roughly the halfway mark of the list
      final midIndex = routeWeather.length ~/ 2;
      weatherLog += "Middle of Trip: ${getWeatherCondition(routeWeather[midIndex].weatherCode)}, ${routeWeather[midIndex].temperature}°C\n";
    }
    if (routeWeather.length > 1) {
      weatherLog += "Destination ($endCity): ${getWeatherCondition(routeWeather.last.weatherCode)}, ${routeWeather.last.temperature}°C\n";
    }

    final prompt = '''
    User is driving from $startCity to $endCity (Duration: $duration).
    Here is the weather forecast for the start, middle, and end of the road:
    $weatherLog

    Act as 'Kade Aunty', a wise, caring, but slightly strict Sri Lankan auntie. 
    Analyze the trip weather and give exactly **3 short, distinct warnings/tips**.
    
    Rules:
    - Max 10 words per tip.
    - Use Sri Lankan English flavor (e.g. "Child", "careful ah", "Ane", "putha").
    - No bold formatting or markdown symbols.
    
    Format:
    1. [Safety Warning based on weather]
    2. [Preparation Tip (umbrella/water/food)]
    3. [A warm blessing or mood check]
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Drive safe, putha! Don't speed!";
    } catch (e) {
      print('Gemini Journey Error: $e');
      return "Drive carefully and check the road!";
    }
  }
}