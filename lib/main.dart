import 'package:flutter/material.dart';
import 'package:myapp/api_service.dart';
import 'package:myapp/parking_map_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    Provider<ApiService>(
      create: (_) => ApiService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYC Bicycle Parking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ParkingDataInitializer(),
    );
  }
}

class ParkingDataInitializer extends StatelessWidget {
  const ParkingDataInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ApiService>(context, listen: false).fetchParkingSpots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const ParkingMapScreen();
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
