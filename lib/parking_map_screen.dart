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
  final LatLng _center = const LatLng(40.7128, -74.0060);
  final Set<Marker> _markers = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchParkingSpots();
  }

  void _fetchParkingSpots() async {
    try {
      final spots = await _apiService.fetchParkingSpots();
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
      // Handle error
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NYC Bike Parking'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        clusterManagers: {
          ClusterManager(
            clusterManagerId: const ClusterManagerId('parking-spots'),
            onClusterTap: (cluster) {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  cluster.position,
                  14,
                ),
              );
            },
          )
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
