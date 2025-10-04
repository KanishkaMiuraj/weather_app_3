# ☀️ Smart Weather Assistant

![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Language-Dart-0175C2?logo=dart\&logoColor=white)
![Open-Meteo](https://img.shields.io/badge/API-Open--Meteo-00BFFF?logo=cloud\&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=google\&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

A modern, **location-aware weather application** built with **Flutter**, powered by **real-time data from Open-Meteo** and **intelligent contextual insights from the Gemini API**.

This app goes beyond raw data — it delivers **actionable insights** tailored for **Sri Lankan conditions**, such as **cultivation guidance** and **driving tips**.

---

## ✨ Key Features

The **Smart Weather Assistant** fuses a **beautiful, dynamic UI** with **AI-powered insights** and **accurate real-time weather data**.

| Icon | Feature                          | Description                                                                                                           |
| ---- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 🤖   | **AI-Powered Tactical Insights** | Generates **five sharp and helpful tips** using Gemini API (eco-friendly living, farming advice, road safety alerts). |
| 🌍   | **Location & City Search**       | Auto-detects your location via GPS or lets you **search forecasts** for any Sri Lankan city.                          |
| 🎨   | **Dynamic UI & Animations**      | Background gradients, icons, and UI **adapt dynamically** to weather and **day/night cycles**.                        |
| 📊   | **Detailed Current Metrics**     | Instantly see **temperature, humidity, wind speed/direction, rainfall**.                                              |
| 🗓️  | **7-Day Forecast**               | Weekly forecast with **max/min temperatures** and clear summaries.                                                    |
| ☀️   | **Sunrise & Sunset Tracker**     | A custom-painted, **animated sun path widget** showing daily progress.                                                |

---

## 🛠 Technologies Used

| Category                    | Technology                          | Purpose                                  |
| --------------------------- | ----------------------------------- | ---------------------------------------- |
| **Framework**               | Flutter / Dart                      | Cross-platform UI development            |
| **Artificial Intelligence** | Gemini API (`google_generative_ai`) | Context-aware 5-point weather insights   |
| **Weather Data**            | Open-Meteo API                      | Real-time forecasts & current weather    |
| **Location Services**       | geolocator, geocoding               | GPS and reverse geocoding for city names |
| **Configuration**           | flutter_dotenv                      | Secure management of API keys            |

---

## 📸 Screenshots

🚧 *Coming soon — UI previews, insights cards, and weather-driven backgrounds.*

---

## 🚀 Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/smart-weather-assistant.git
   cd smart-weather-assistant
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   * Create a `.env` file in the root folder.
   * Add your Gemini API key:

     ```env
     GEMINI_API_KEY=your_api_key_here
     ```

4. **Run the application**

   ```bash
   flutter run
   ```

---

## 📌 Roadmap

* [ ] 🌐 Add **Sinhala & Tamil support**
* [ ] 📶 Implement **offline mode with cached forecasts**
* [ ] 🌍 Extend beyond Sri Lanka for **global use cases**
* [ ] 💬 Add voice-based AI insights

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a new branch (`feature/new-feature`)
3. Commit changes
4. Submit a Pull Request 🎉

---

## 📜 License

This project is licensed under the **MIT License**.

---

🌱 *Smart Weather Assistant — helping Sri Lankans make **smarter, safer, and greener** choices every day.*
