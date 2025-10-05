import 'dart:async';
import 'dart:io';

import 'package:bikespotnyc/adaptive_fab.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  final MapController _mapController = MapController();
  final LatLng _nycCenter = LatLng(40.7128, -74.0060);
  List<Marker> _markers = [];
  Timer? _debounce;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
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
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        17.0,
        // _mapController.camera.zoom,
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

  Future<void> _updateMarkers(LatLngBounds? bounds) async {
    if (bounds == null) return;

    try {
      final spots = await _apiService.getSpotsInBounds(
        bounds.south,
        bounds.north,
        bounds.west,
        bounds.east,
      );

      final markers = spots
          .map(
            (spot) => Marker(
              point: LatLng(spot.latitude, spot.longitude),
              width: 30.0,
              height: 30.0,
              child: GestureDetector(
                onTap: () => _navigateToDetails(spot),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 30.0,
                ),
              ),
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          print("Markers added");
          _markers = markers;
        });
      }
    } catch (e) {
      // TODO: Add Web implementation
      // https://stackoverflow.com/questions/57182634/how-can-i-read-and-write-files-in-flutter-web
      debugPrint("Error updating markers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _nycCenter,
        initialZoom: 12.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          print("Map is ready");
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _updateMarkers(_mapController.camera.visibleBounds);
          });
        },
        onPositionChanged: (position, hasGesture) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _updateMarkers(position.visibleBounds);
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 100,
            maxZoom: 21,
            size: const Size(40, 40),
            spiderfyCluster: false,
            markers: _markers,
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 80,
                height: 80,
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blueAccent,
                  size: 40.0,
                ),
              ),
            ],
          ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          mapWidget,
          // On Android, the FAB is part of the Scaffold, but on iOS it's a
          // positioned widget inside the body. This Stack makes it work for both.
          if (Platform.isIOS) AdaptiveFab(onPressed: _centerOnUser),
        ],
      ),
      floatingActionButton: !Platform.isIOS
          ? AdaptiveFab(onPressed: _centerOnUser)
          : null,
    );
  }
}
