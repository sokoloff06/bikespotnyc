import 'dart:io';
import 'dart:ui';
import 'package:bikespotnyc/parking_map_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: hide token
  String accessToken = String.fromEnvironment("MAPBOX_ACCESS_TOKEN");
  // MapboxOptions.setAccessToken(
  //   "pk.eyJ1Ijoidmlzb2tvbG92IiwiYSI6ImNtaHJ5enh0ODBjYnQyanF6d3V1YWJnNngifQ.BHKojIdapZ8feUb4WUyXOg",
  // );
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // TODO: Investigate
    print("Second main() run");
  }

  // Define options for your camera
  CameraOptions camera = CameraOptions(
    center: Point(coordinates: Position(-98.0, 39.5)),
    zoom: 2,
    bearing: 0,
    pitch: 0,
  );

  // Run your application, passing your CameraOptions to the MapWidget
  runApp(MaterialApp(home: MapWidget(cameraOptions: camera)));

  // runApp(
  //   Provider<ApiService>(create: (_) => ApiService(), child: const MyApp()),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoApp(
        title: 'NYC Bicycle Parking',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: const ParkingMapScreen(),
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        title: 'NYC Bicycle Parking',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const ParkingMapScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
}
