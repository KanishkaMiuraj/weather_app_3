import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/weather_model.dart';
import '../helpers/weather_condition_helper.dart';

class WeatherAssistantService {
  final GenerativeModel _model;

  WeatherAssistantService(String apiKey)
      : _model = GenerativeModel(
    // Using the stable 'gemini-1.5-flash' model
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  /// ---------------------------------------------------------
  /// DAILY WEATHER SUMMARY (Generic Helper)
  /// ---------------------------------------------------------
  Future<String> getInsightfulSummary(Weather weather, String city) async {
    final currentCondition = getWeatherCondition(weather.weatherCode);

    // Extract max 2-3 day forecast conditions
    final nextFewDaysConditions = weather.forecast.take(3).map((f) {
      return getWeatherCondition(f.weatherCode);
    }).join(', ');

    final prompt = '''
      You are a helpful weather assistant. Provide **five** extremely short, sharp, and useful tips.
      
      Format as **EXACTLY FIVE SENTENCES**, each sentence on a separate line. 
      **CRITICALLY: Each sentence must be a maximum of 8 words.** Be direct and concise. Do not use markdown or numbers.
      
      1. Summarize the day's vibe (e.g., "Perfect day for a walk outside.").
      2. Give a tactical tip (e.g., "Carry an umbrella just in case.").
      3. Give a general eco-friendly tip.
      4. Give a gardening/planting tip relevant to the weather.
      5. Give a driving safety tip.

      **Current Data for $city:**
      - Temperature: ${weather.temperature.toStringAsFixed(1)}°C
      - Condition: $currentCondition
      - Rain: ${weather.rain.toStringAsFixed(1)}mm
      - Humidity: ${weather.humidity.toStringAsFixed(0)}%
      - Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h
      - Forecast: $nextFewDaysConditions
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      final processedText = response.text
          ?.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(5)
          .join('\n');

      return processedText ?? "Weather insights are currently unavailable.";
    } catch (e) {
      print('Gemini API Error: $e');
      return 'Error fetching weather insights.';
    }
  }

  /// ---------------------------------------------------------
  /// JOURNEY ADVISOR (Travel Assistant)
  /// ---------------------------------------------------------
  Future<String> getJourneySummary(String startCity, String endCity, List<Weather> routeWeather, String duration) async {
    String weatherLog = "";

    // Construct a log of the weather at the sampled points
    if (routeWeather.isNotEmpty) {
      weatherLog += "Start ($startCity): ${getWeatherCondition(routeWeather[0].weatherCode)}, ${routeWeather[0].temperature}°C\n";
    }
    if (routeWeather.length > 2) {
      final midIndex = routeWeather.length ~/ 2;
      weatherLog += "Middle of Trip: ${getWeatherCondition(routeWeather[midIndex].weatherCode)}, ${routeWeather[midIndex].temperature}°C\n";
    }
    if (routeWeather.length > 1) {
      weatherLog += "Destination ($endCity): ${getWeatherCondition(routeWeather.last.weatherCode)}, ${routeWeather.last.temperature}°C\n";
    }

    // Get current time to advise on timing
    final now = DateTime.now();
    final timeString = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final prompt = '''
    User is planning a drive from $startCity to $endCity.
    Estimated Duration: $duration.
    Current Time: $timeString.
    
    Here is the weather forecast along the route:
    $weatherLog

    Act as a friendly, knowledgeable, and professional travel assistant (do not use a character persona).
    Provide a personalized travel briefing.
    
    **Instructions:**
    1.  **Tone:** Warm, practical, and conversational. Use simple English. Avoid robotic phrases like "Based on the data...".
    2.  **Structure:** Provide a list of **minimum 5 and maximum 8 points**. 
    3.  **Content Requirements:**
        * **Time Check:** Acknowledge the current time ($timeString). Suggest if they should leave now or wait (e.g., "It is currently $timeString. Since it's late, maybe wait for sunrise," or "Perfect time to hit the road!").
        * **Weather Overview:** Briefly describe what the drive will feel like (e.g., "You'll see clear skies mostly, but expect rain near the end.").
        * **Driving Conditions:** Specific advice based on weather (e.g., "Watch out for slippery turns if it rains," "Glare might be an issue driving west.").
        * **Environment/Landscape:** Mention the likely scenery or environmental factors based on the route context (e.g., "The misty hills might be beautiful but foggy," "It's hot in the dry zone, keep hydrated.").
        * **Preparation:** Practical items to pack (water, sunglasses, umbrella).
        * **Warnings:** Any specific weather alerts if applicable (thunderstorms, high winds).
        * **Closing:** A nice wish for the journey.

    **Format:**
    - Use bullet points (*) for each point.
    - Keep each point under 20 words for easy reading while planning.
    - No bold formatting or markdown symbols other than the bullet point.
    - Do NOT number the list.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Drive safely and check the forecast!";
    } catch (e) {
      print('Gemini Journey Error: $e');
      return "Please drive carefully and check road conditions.";
    }
  }
}