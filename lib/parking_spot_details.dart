import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class ParkingSpotDetails extends StatelessWidget {
  final ParkingSpot parkingSpot;

  const ParkingSpotDetails({super.key, required this.parkingSpot});

  Future<void> _launchMaps() async {
    final lat = parkingSpot.latitude;
    final lng = parkingSpot.longitude;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=bicycling');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Spot Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parkingSpot.location,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(
                Icons.image,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Borough: ${parkingSpot.borough}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Year Installed: ${parkingSpot.yrInstalled}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _launchMaps,
                child: const Text('Navigate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
