import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import 'parking_spot_details.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  late GoogleMapController mapController;
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
    mapController = controller;
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
      ),
    );
  }
}
