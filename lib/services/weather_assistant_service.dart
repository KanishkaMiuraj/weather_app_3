// services/weather_assistant_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
// Ensure these imports match your project structure
import '../models/weather_model.dart';
import '../helpers/weather_condition_helper.dart';

class WeatherAssistantService {
  final GenerativeModel _model;

  WeatherAssistantService(String apiKey)
      : _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  /// Generates five extremely short, friendly, and tactical weather insights using Gemini.
  Future<String> getInsightfulSummary(Weather weather, String city) async {
    final currentCondition = getWeatherCondition(weather.weatherCode);
    final windDirection = weather.getWindDirection();

    // Extract max 2-3 day forecast conditions
    final nextFewDaysConditions = weather.forecast.take(3).map((f) {
      return getWeatherCondition(f.weatherCode);
    }).join(', ');


    final prompt = '''
      You are an expert, friendly, and kind weather guide. Provide **five** extremely short, sharp, and useful tips, speaking with a warm, helpful tone.
      
      You must format your entire response as **EXACTLY FIVE SENTENCES**, each sentence on a separate line. **CRITICALLY: Each sentence must be a maximum of 8 words.** Be direct, kind, and highly concise. Do not use markdown, numbers, or conversational fillers.
      
      1. **First sentence (Day's Nature):** Summarize the day's vibe. (e.g., "It's a beautiful day for a walk!")
      
      2. **Second sentence (Tactical Advice):** Give one short, actionable suggestion. (e.g., "Don't forget your sunglasses today.")
      
      3. **Third sentence (General Eco Tip):** Give one short, general environment tip. (e.g., "It's best to save water for later.")

      4. **Fourth sentence (SL Cultivation Tip):** Give a short, specific Sri Lankan planting tip. (e.g., "Plant those small chili seeds now.")
      
      5. **Fifth sentence (Driver's Road Tip):** Offer one critical tip for drivers. (e.g., "Watch out for road puddles and slippery areas.")

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

      return processedText ?? "AI summary currently unavailable.";
    } catch (e) {
      print('Gemini API Error: $e');
      return 'Error fetching weather insights: Failed to connect to the AI service.';
    }
  }
}