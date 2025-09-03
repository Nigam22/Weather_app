import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_forecast_item.dart';
import 'package:weather_app/hourly_forecast_item.dart' show HourlyForecastItem;
import 'package:http/http.dart' as http;
import 'package:weather_app/secrets.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();
  String cityName = ""; // default city

  @override
  void initState() {
    super.initState();
    getCurrentWeather(cityName); // load default city
  }

  Map<String, dynamic>? weatherData;

  Future<Map<String, dynamic>> getCurrentWeather(cityname) async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$cityname&appid=$openWeatherAPIKEY",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('weather data loaded succesfully');
        return data;
      } else {
        throw (" ${res.statusCode}");
      }
    } catch (e) {
      throw ("PLease check the city name!");
    }
  }

  IconData getWeatherIcon(String condition) {
    switch (condition) {
      case 'Clouds':
        return WeatherIcons.cloud; // ☁️
      case 'Rain':
        return WeatherIcons.rain; // 🌧️
      case 'Clear':
        return WeatherIcons.day_sunny; // ☀️
      case 'Snow':
        return WeatherIcons.snow; //🌨
      case 'Thunderstorm':
        return WeatherIcons.thunderstorm; // 🌩
      case 'Drizzle':
        return Icons.grain; // 🌦️
      case 'fog':
        return WeatherIcons.fog; // 🌫 Fog/Mist
      default:
        return Icons.wb_cloudy; // fallback
    }
  }

  Color getBackgroundColor(String condition, bool isDark) {
    if (condition == "Clear") {
      return isDark ? Colors.indigo[900]! : Colors.blue[200]!;
    } else if (condition == "Rain") {
      return isDark ? Colors.blueGrey[900]! : Colors.blueGrey[200]!;
    } else if (condition == "Clouds") {
      return isDark ? Colors.grey[850]! : Colors.grey[500]!;
    } else if (condition == "Snow") {
      return isDark ? Colors.blueGrey[100]! : Colors.white;
    } else {
      return isDark ? Colors.black : Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final condition = weatherData?['list'][0]['weather'][0]['main'] ?? "Clear";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: getBackgroundColor(condition, isDark),
      appBar: AppBar(
        backgroundColor: Colors.white70,
        centerTitle: true,
        title: TextField(
          controller: _cityController,
          decoration: InputDecoration(
            hintText: "Enter city name",
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            setState(() {
              cityName = value;
            });
            getCurrentWeather(cityName);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                cityName = _cityController.text;
              });
              getCurrentWeather(cityName);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder(
        future: getCurrentWeather(cityName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No Weather Data Available'));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          final currentTemp = (currentWeatherData['main']['temp'] - 273.15)
              .toStringAsFixed(1);
          final currentSky = currentWeatherData['weather'][0]['main'];
          final currentPressure = currentWeatherData['main']['pressure'];
          final currentWind = currentWeatherData['wind']['speed'];
          final currentHumidity = currentWeatherData['main']['humidity'];

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final backgroundColor = getBackgroundColor(
            currentSky,
            isDark,
          ); // ✅ use live condition

          return Container(
            color: backgroundColor,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          // color: const Color.fromARGB(255, 45, 40, 52),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                              child: Padding(
                                padding: const EdgeInsets.all(16),

                                child: Column(
                                  children: [
                                    Text(
                                      '$currentTemp ˚C',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Icon(getWeatherIcon(currentSky), size: 64),
                                    const SizedBox(height: 16),
                                    Text(
                                      currentSky,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Hourly Forecast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < 9; i++)
                              HourlyForecastItem(
                                time: DateFormat.jm().format(
                                  DateTime.parse(
                                    data['list'][i + 1]['dt_txt'].toString(),
                                  ),
                                ),
                                icon: getWeatherIcon(
                                  data['list'][i + 1]['weather'][0]['main'],
                                ),
                                temperature:
                                    '${(data['list'][i + 1]['main']['temp'] - 273.15).toStringAsFixed(1)}˚C',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Additional Information',

                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInfoItem(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: currentHumidity.toString(),
                          ),

                          AdditionalInfoItem(
                            icon: Icons.air,
                            label: 'Wind Speed',
                            value: currentWind.toString(),
                          ),

                          AdditionalInfoItem(
                            icon: Icons.speed,
                            label: 'Pressure',
                            value: currentPressure.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
