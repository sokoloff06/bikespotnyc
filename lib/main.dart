import 'package:flutter/material.dart';
import 'api_service.dart';
import 'parking_map_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    Provider<ApiService>(create: (_) => ApiService(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYC Bicycle Parking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ParkingMapScreen(),
    );
  }
}
