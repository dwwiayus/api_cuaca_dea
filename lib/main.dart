import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App In Japan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String apiKey = '3a0a93abc0e173fbe501622d27cdbe1e'; \
  final List<String> cities = ['Yokohama', 'Tokyo', 'Kyoto', 'Osaka', 'Hiroshima', 'Saitama', 'Nagasaki', 'Tottori',];
  List<Map<String, dynamic>> weatherData = [];
  List<Map<String, dynamic>> filteredData = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    List<Map<String, dynamic>> tempData = [];
    for (String city in cities) {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        tempData.add({
          'city': city,
          'temperature': data['main']['temp'] - 273.15, 
          'description': data['weather'][0]['description'],
          'details': data['main'],
          'wind': data['wind'],
        });
      } else {
        print('Failed to load weather data for $city');
      }
    }
    setState(() {
      weatherData = tempData;
      filteredData = tempData;
    });
  }

  void filterData(String query) {
    setState(() {
      searchQuery = query;
      filteredData = weatherData
          .where((item) =>
              item['city'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  double calculateAverageTemperature() {
    if (filteredData.isEmpty) return 0;
    double totalTemp = filteredData
        .map((item) => item['temperature'])
        .reduce((a, b) => a + b);
    return totalTemp / filteredData.length;
  }

  void showWeatherDetails(Map<String, dynamic> details, Map<String, dynamic> wind) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Weather Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temperature: ${details['temp'] - 273.15}°C'),
              Text('Wind Speed: ${wind['speed']} m/s'),
              Text('Wind Direction: ${wind['deg']}°'),
              SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App In Japan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Prefektur',
                border: OutlineInputBorder(),
              ),
              onChanged: filterData,
            ),
            SizedBox(height: 16),
            Expanded(
              child: weatherData.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final item = filteredData[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['city']),
                            subtitle: Text(item['description']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${item['temperature'].toStringAsFixed(1)}°C'),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.info),
                                  onPressed: () => showWeatherDetails(item['details'], item['wind']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),
            Text(
              'Average Temperature: ${calculateAverageTemperature().toStringAsFixed(2)}°C',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
