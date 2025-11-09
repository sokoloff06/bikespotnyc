import 'dart:io';
import 'package:bikespotnyc/adaptive_details_body.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'parking_spot.dart';

class ParkingSpotDetails extends StatelessWidget {
  final ParkingSpot parkingSpot;

  const ParkingSpotDetails({super.key, required this.parkingSpot});

  Future<void> _showMapSelection(BuildContext context) async {
    FirebaseAnalytics.instance.logEvent(
      name: 'navigation',
      parameters: <String, Object>{
        'borough': parkingSpot.borough,
        'site_id': parkingSpot.siteId,
      },
    );

    final lat = parkingSpot.latitude;
    final lng = parkingSpot.longitude;
    final title = "Parking Spot: ${parkingSpot.siteId}";

    if (!context.mounted) return;

    if (Platform.isIOS) {
      final availableMaps = await MapLauncher.installedMaps;
      // Use CupertinoActionSheet for iOS
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Open in Maps'),
          message: const Text('Select a map to get directions'),
          actions: <CupertinoActionSheetAction>[
            for (var map in availableMaps)
              CupertinoActionSheetAction(
                child: Text(map.mapName),
                onPressed: () {
                  Navigator.pop(context);
                  map.showDirections(
                    destination: Coords(lat, lng),
                    destinationTitle: title,
                    directionsMode: DirectionsMode.bicycling,
                  );
                },
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      // Use the Google Maps navigation intent for turn-by-turn directions.
      // This is a specific Android intent that includes the travel mode.
      final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($title)');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback if the specific intent fails (e.g., Google Maps not installed).
          // We can open the location in any available map app.
          await MapLauncher.showMarker(
            mapType: (await MapLauncher.installedMaps).first.mapType,
            coords: Coords(lat, lng),
            title: title,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch maps. No map apps installed?'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AdaptiveDetailsBody(
      parkingSpot: parkingSpot,
      onNavigatePressed: () => _showMapSelection(context),
    );

    FirebaseAnalytics.instance.logEvent(
      name: 'parking_details',
      parameters: <String, Object>{
        'borough': parkingSpot.borough,
        'site_id': parkingSpot.siteId,
      },
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Parking Spot Details'),
        ),
        // Set background color to match the Material theme for consistency
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parking Spot Details')),
      body: body,
    );
  }
}
