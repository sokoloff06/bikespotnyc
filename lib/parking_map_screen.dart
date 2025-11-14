import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bikespotnyc/adaptive_fab.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'api_service.dart';
import 'parking_spot_details.dart';
import 'parking_spot.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final ApiService _apiService = ApiService();
  mapbox.MapboxMap? _mapboxMap;
  final mapbox.Position _nycCenter = mapbox.Position(-74.0060, 40.7128);
  bool _locationInitialized = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  @override
  void dispose() {
    _mapboxMap?.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error getting current position: $e");
    }

    _positionStreamSubscription = Geolocator.getPositionStream().listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 17.0,
        ),
        null,
      );
    }
  }

  void _navigateToDetails(ParkingSpot spot) {
    final route = Platform.isIOS
        ? CupertinoPageRoute(
            builder: (context) => ParkingSpotDetails(parkingSpot: spot),
          )
        : MaterialPageRoute(
            builder: (context) => ParkingSpotDetails(parkingSpot: spot),
          );
    Navigator.push(context, route);
  }

  Future<void> _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final ByteData bytes = await rootBundle.load('assets/bike_icon.png');
    final Uint8List list = bytes.buffer.asUint8List();
    _mapboxMap?.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ),
    );
    loadMarkers();
  }

  Future<void> _onMapIdle(mapbox.MapIdleEventData eventData) async {
    print("Map Idle");
  }

  @override
  Widget build(BuildContext context) {
    const accessToken = String.fromEnvironment("MAPBOX_ACCESS_TOKEN");
    mapbox.MapboxOptions.setAccessToken(accessToken);

    final initialCamera = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: _nycCenter),
      zoom: 12.0,
    );

    final mapWidget = mapbox.MapWidget(
      key: const ValueKey("mapboxMap"),
      cameraOptions: initialCamera,
      styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
      onMapIdleListener: _onMapIdle,
    );

    return Scaffold(
      body: Stack(
        children: [
          mapWidget,
          if (Platform.isIOS) AdaptiveFab(onPressed: _centerOnUser),
        ],
      ),
      floatingActionButton: !Platform.isIOS
          ? AdaptiveFab(onPressed: _centerOnUser)
          : null,
    );
  }

  void loadMarkers() async {
    //TODO: leverage ApiService
    var data = await rootBundle.loadString('assets/spots.geojson');
    await _mapboxMap!.style.addSource(
      mapbox.GeoJsonSource(id: "spots", data: data, cluster: true),
    );
    await _mapboxMap!.style.addLayer(
      mapbox.CircleLayer(
        id: "spots_clusters",
        sourceId: "spots",
        filter: ['has', 'point_count'],
        circleColorExpression: [
          'step',
          ['get', 'point_count'],
          '#51bbd6',
          100,
          '#f1f075',
          750,
          '#f28cb1',
        ],
        circleRadiusExpression: [
          'step',
          ['get', 'point_count'],
          20,
          100,
          30,
          750,
          40,
        ],
      ),
    );

    // Cluster count symbol
    await _mapboxMap!.style.addLayer(
      mapbox.SymbolLayer(
        id: 'spots-count',
        sourceId: 'spots',
        filter: ['has', 'point_count'],
        textFieldExpression: ['get', 'point_count'],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
      ),
    );
    // Unclustered points
    await _mapboxMap!.style.addLayer(
      mapbox.CircleLayer(
        id: 'spots-singles',
        sourceId: 'spots',
        filter: [
          '!',
          ['has', 'point_count'],
        ],
        circleColor: 0xFF000000,
        circleRadius: 7,
        circleStrokeWidth: 1,
        circleStrokeColor: 0xFFFF,
      ),
    );
    _mapboxMap!.addInteraction(
      mapbox.TapInteraction(
        mapbox.FeaturesetDescriptor(layerId: 'spots-singles'),
        (feature, context) {
          // Handle tap when a feature
          // from "polygons" is tapped.
          final properties = feature.properties;
          final parkingSpot = ParkingSpot.fromJson(properties);
          _navigateToDetails(parkingSpot);
        },
      ),
      interactionID: "single-spot-tap",
    );
  }
}
