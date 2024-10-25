import 'package:flutter/material.dart';
import 'package:flutter_application_1/lapTimes.dart';
import 'package:flutter_application_1/telemEV.dart';
import 'package:flutter_application_1/telemQB.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BottomNavigationBarTest(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
    );
  }
}

class BottomNavigationBarTest extends StatefulWidget {
  const BottomNavigationBarTest({super.key});

  @override
  State<BottomNavigationBarTest> createState() =>
      _BottomNavigationBarState();
}

class _BottomNavigationBarState
    extends State<BottomNavigationBarTest> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    // placeholders for page values
    LiveTelemetry(),
    LiveTelemetryEV(),
    LapTime(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  StatefulWidget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
      height: MediaQuery.of(context).size.height - kBottomNavigationBarHeight,
      child: SingleChildScrollView(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
    ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Gas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.battery_charging_full),
            label: 'EV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Lap Times',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}