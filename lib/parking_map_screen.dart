import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myapp/api_service.dart';
import 'package:provider/provider.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  late GoogleMapController _mapController;
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  String? _mapStyle;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadParkingSpots();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
  }

  Future<void> _loadParkingSpots() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final spots = await apiService.fetchParkingSpots();

    setState(() {
      for (final spot in spots) {
        final markerId = MarkerId('${spot.assetId}-${spot.latitude}-${spot.longitude}');
        final marker = Marker(
          markerId: markerId,
          position: LatLng(spot.latitude, spot.longitude),
          infoWindow: InfoWindow(
            title: spot.location,
            snippet: 'Borough: ${spot.borough}',
          ),
        );
        _markers[markerId] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NYC Bicycle Parking'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _mapController.setMapStyle(_mapStyle);
        },
        markers: Set<Marker>.of(_markers.values),
      ),
    );
  }
}
