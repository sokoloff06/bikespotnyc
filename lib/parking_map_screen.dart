import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'api_service.dart';
import 'parking_spot_details.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  late GoogleMapController _mapController;
  final LatLng _nycCenter = const LatLng(40.7128, -74.0060);
  final Set<Marker> _markers = {};
  final ApiService _apiService = ApiService();
  final ClusterManagerId clusterManagerId = ClusterManagerId('parking-spots');
  late final ClusterManager clusterManager;

  @override
  void initState() {
    super.initState();
    clusterManager = ClusterManager(clusterManagerId: clusterManagerId);
    _fetchParkingSpots();
  }

  void _fetchParkingSpots() async {
    try {
      _apiService.fetchParkingSpots().then(
        (spots) => {
          setState(() {
            for (final spot in spots) {
              _markers.add(
                Marker(
                  markerId: MarkerId(spot.siteId),
                  position: LatLng(spot.latitude, spot.longitude),
                  clusterManagerId: clusterManagerId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ParkingSpotDetails(parkingSpot: spot),
                      ),
                    );
                  },
                ),
              );
            }
          }),
        },
      );
    } catch (e) {
      debugPrint("Error fetching parking spots: $e");
    }
  }

  Future<void> _requestLocationAndMoveCamera() async {
    LocationPermission permission;
    bool serviceEnabled;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // If we reach here, permissions are granted.
      final position = await Geolocator.getCurrentPosition();
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _requestLocationAndMoveCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NYC Bike Parking')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _nycCenter, zoom: 11.0),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        clusterManagers: {clusterManager},
        markers: _markers,
      ),
    );
  }
}
