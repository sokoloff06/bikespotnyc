import 'package:bikespotnyc/parking_map_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // TODO: Investigate
    print("Second main() run");
  }
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
      debugShowCheckedModeBanner: false,
    );
  }
}
