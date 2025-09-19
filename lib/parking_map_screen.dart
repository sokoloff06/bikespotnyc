import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'parking_spot.dart';
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

  bool _isLoading = true;
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
    _fetchParkingSpots();
  }

  Future<void> _determineInitialPosition() async {
    LocationPermission permission;
    bool serviceEnabled;
    LatLng initialLatLng = _nycCenter; // Default to NYC

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled. We'll use the default NYC location.
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied. We'll use the default NYC location.
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied. We'll use the default NYC location.
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // If we reach here, permissions are granted.
      final position = await Geolocator.getCurrentPosition();
      initialLatLng = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error determining initial position: $e");
    } finally {
      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: initialLatLng,
            zoom: initialLatLng == _nycCenter
                ? 11.0
                : 14.0, // Zoom in more if it's user location
          );
          _isLoading = false;
        });
      }
    }
  }

  void _fetchParkingSpots() async {
    try {
      final spots = await _apiService.fetchParkingSpots();
      if (!mounted) return;
      setState(() {
        for (final spot in spots) {
          _markers.add(
            Marker(
              markerId: MarkerId('${spot.latitude}_${spot.longitude}'),
              position: LatLng(spot.latitude, spot.longitude),
              clusterManagerId: const ClusterManagerId('parking-spots'),
              infoWindow: InfoWindow(
                title: spot.location,
                snippet: spot.borough,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParkingSpotDetails(parkingSpot: spot),
                  ),
                );
              },
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Error fetching parking spots: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NYC Bike Parking')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              clusterManagers: {
                ClusterManager(
                  clusterManagerId: const ClusterManagerId('parking-spots'),
                  onClusterTap: (cluster) {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(cluster.position, 14),
                    );
                  },
                ),
              },
            ),
    );
  }
}
