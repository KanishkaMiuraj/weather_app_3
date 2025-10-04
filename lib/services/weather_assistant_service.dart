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

  /// Generates a clear, short, and direct weather summary for the user using Gemini.
  Future<String> getInsightfulSummary(Weather weather, String city) async {
    final currentCondition = getWeatherCondition(weather.weatherCode);
    final windDirection = weather.getWindDirection();

    // Extract max 2-3 day forecast conditions for the best planting advice
    final nextFewDaysConditions = weather.forecast.take(3).map((f) {
      return getWeatherCondition(f.weatherCode);
    }).join(', ');


    final prompt = '''
      You are an expert, friendly weather guide. Your goal is to give three extremely short, sweet, and 100% real-world helpful points.
      
      You must format your entire response as EXACTLY THREE SENTENCES, each sentence on a separate line. Do not use markdown, numbers, or conversational fillers.
      
      **Sentence 1 (Day's Nature):** Summarize the day's vibe (e.g., "Expect a bright but breezy afternoon," or "The morning will feel damp, with clearer skies later.")
      
      **Sentence 2 (Tactical Advice):** Provide one short, actionable suggestion for leaving home (e.g., "Bring sunglasses and a light jacket," or "Delay any heavy outdoor chores until the evening.")
      
      **Sentence 3 (Eco/Planting Tip):** Give one short, organic food cultivation tip relevant to the $city climate and current weather (e.g., "The upcoming rain makes it a great day to transplant basil seedlings," or "Hold off on watering your indoor herbs as humidity is high.")

      **Current Data for $city:**
      - Temperature: ${weather.temperature.toStringAsFixed(1)}°C
      - Condition: $currentCondition
      - Rain: ${weather.rain.toStringAsFixed(1)}mm
      - Humidity: ${weather.humidity.toStringAsFixed(0)}%
      - Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h
      - Next 3-day conditions: $nextFewDaysConditions
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      // Post-process to ensure only three lines are returned, just in case.
      final processedText = response.text
          ?.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .join('\n');

      return processedText ?? "AI summary currently unavailable.";
    } catch (e) {
      print('Gemini API Error: $e');
      return 'Error fetching weather insights: Failed to connect to the AI service.';
    }
  }
}