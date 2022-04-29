// ignore_for_file: avoid_print, prefer_const_declarations, unnecessary_brace_in_string_interps, library_prefixes, unnecessary_new, prefer_const_constructors, prefer_typing_uninitialized_variables, sized_box_for_whitespace, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:core';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Weather App'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final API_KEY = '';
  // ignore: unused_field
  Object _weatherData = 'placeholder';
  // ignore: unused_field
  String _city = '';
  String _country = '';
  final DateFormat weekdayFormatter = DateFormat('EEEE');
  final DateFormat dateFormatter = DateFormat('d. MMMM y');
  Future _fetchData(String city) async {
    if (city == 'No city' || city == '') return;
    final apiURL =
        'http://api.weatherapi.com/v1/forecast.json?key=&q=$API_KEY&days=3&aqi=no';

    final response = await http.get(Uri.parse(apiURL));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _weatherData = data;
        _country = data['location']['country'];
      });
      return data;
    } else {
      throw Exception('Couldn\'t load weather - Try inputting a valid city');
    }
  }

  Future _getCity() async {
    final prefs = await SharedPreferences.getInstance();
    String? city = prefs.getString('city');
    city ??= 'No city';
    if (city == 'No city') return;
    setState(() {
      _fetchData(city!).then((value) {
        _country = value['location']['country'];
      });
      _city = city.replaceFirst(city[0], city[0].toUpperCase());
    });
  }

  Future<void> _setCity(city) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('city', city);
  }

  TextEditingController userInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCity();
  }

  @override
  void dispose() {
    _weatherData = 'placeholder';
    _city = '';
    _country = '';
    userInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(1),
            padding: EdgeInsets.all(1),
            height: 100,
            width: 250,
            child: TextField(
              controller: userInput,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'City',
                helperText: 'Enter a city',
              ),
              onSubmitted: (String city) {
                setState(() {
                  _fetchData(city);
                  _setCity(city.replaceFirst(city[0], city[0].toUpperCase()));
                  _city = city.replaceFirst(city[0], city[0].toUpperCase());
                });
              },
            ),
          ),
          Text('Showing weather for $_city, $_country\n',
              style: Theme.of(context).textTheme.headline6),
          Container(
            child: FutureBuilder(
              future: _fetchData(_city),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = json.decode(json.encode(snapshot.data!));
                  return ListTile(
                    leading: Image.network(
                        'https:${data['current']['condition']['icon']}'),
                    title: Text('Current'),
                    subtitle: Text(
                        'Temperature: ${data['current']['temp_c']}°C\n'
                        'Wind: ${data['current']['wind_kph']}km/h\n'
                        'Humidity: ${data['current']['humidity']}%\n'
                        'Condition: ${data['current']['condition']['text']}\n'
                        'Rain: ${data['current']['precip_mm']}mm\n'
                        'RealFeel: ${data['current']['feelslike_c']}°C\n'
                        'UV Index: ${data['current']['uv']}'),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
          Text(''),
          Expanded(
            child: FutureBuilder(
              future: _fetchData(_city),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = json.decode(json.encode(snapshot.data!));
                  return ListView.builder(
                    itemCount: data['forecast']['forecastday'].length,
                    itemBuilder: (context, index) {
                      var dateData = data['forecast']['forecastday'][index]
                              ['date']
                          .split('-');
                      Intl.defaultLocale = 'en_US';
                      var date = DateTime(int.parse(dateData[0]),
                          int.parse(dateData[1]), int.parse(dateData[2]));
                      final String weekday = weekdayFormatter.format(date);
                      final String dateFormatted = dateFormatter.format(date);
                      return ListTile(
                        leading: Image.network(
                            'https:${data['forecast']['forecastday'][index]['day']['condition']['icon']}'),
                        title: Text('$weekday\n$dateFormatted'),
                        subtitle: Text(
                            'Min. temperature: ${data['forecast']['forecastday'][index]['day']['mintemp_c']}°C\n'
                            'Average temperature: ${data['forecast']['forecastday'][index]['day']['avgtemp_c']}\n'
                            'Max. temperature: ${data['forecast']['forecastday'][index]['day']['maxtemp_c']}°C\n'
                            'Condition: ${data['forecast']['forecastday'][index]['day']['condition']['text']}\n'
                            'Will it rain? ${(data['forecast']['forecastday'][index]['day']['daily_will_it_rain']).toString().replaceFirst('1', 'yep').replaceFirst('0', 'nope')}\n'
                            'Chance of rain: ${data['forecast']['forecastday'][index]['day']['daily_chance_of_rain']}%\n'
                            'Sunrise: ${data['forecast']['forecastday'][index]['astro']['sunrise']}\n'
                            'Sunset: ${data['forecast']['forecastday'][index]['astro']['sunset']}\n'
                            'Moonrise: ${data['forecast']['forecastday'][index]['astro']['moonrise']}\n'
                            'Moonset: ${data['forecast']['forecastday'][index]['astro']['moonset']}\n'
                            'UV-Index: ${data['forecast']['forecastday'][index]['day']['uv']}'),
                        onTap: () {
                          String date =
                              data['forecast']['forecastday'][index]['date'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DetailPage(
                                    data['forecast']['forecastday'][index],
                                    date)),
                          );
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const Text('Loading...');
              },
            ),
          )
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const DetailPage(this.data, this.date);
  final data;
  final date;
  @override
  Widget build(BuildContext context) {
    var dateData = this.date.split('-');
    Intl.defaultLocale = 'en_US';
    var date = DateTime(
        int.parse(dateData[0]), int.parse(dateData[1]), int.parse(dateData[2]));

    final DateFormat dateFormatter = DateFormat('d. MMMM y');
    final DateFormat weekdayFormatter = DateFormat('EEEE');
    final String weekday = weekdayFormatter.format(date);
    final String dateFormatted = dateFormatter.format(date);
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather on $weekday, $dateFormatted'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: data['hour'].length,
          itemBuilder: (context, index) {
            var dateData1 = data['hour'][index]['time'].split('-');
            var hour = dateData1[2].split(' ')[1];

            return ListTile(
              leading: Image.network(
                  'https:${data['hour'][index]['condition']['icon']}'),
              title: Text(
                hour,
              ),
              subtitle: Text('Temperature: ${data['hour'][index]['temp_c']}°C\n'
                  'Wind: ${data['hour'][index]['wind_kph']}km/h\n'
                  'Humidity: ${data['hour'][index]['humidity']}%\n'
                  'Rain: ${data['hour'][index]['precip_mm']}mm\n'
                  'Condition: ${data['hour'][index]['condition']['text']}\n'
                  'Chance of rain: ${data['hour'][index]['chance_of_rain']}%\n'
                  'RealFeel: ${data['hour'][index]['feelslike_c']}°C\n'
                  'UV Index: ${data['hour'][index]['uv']}'),
            );
          },
        ),
      ),
    );
  }
}
