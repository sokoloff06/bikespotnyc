import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<void> _initializeAndCacheSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUpdated = prefs.getString('last_updated_timestamp');

    try {
      final storageRef = FirebaseStorage.instance
          .ref('/files')
          .child('bike_spots.geojson');
      final metadata = await storageRef.getMetadata();
      final remoteUpdated = metadata.updated;

      // If we have local data and the remote data hasn't changed, we're good.
      if (remoteUpdated != null &&
          lastUpdated == remoteUpdated.toIso8601String()) {
        print("Local cache is up to date.");
        return;
      }

      print("Fetching updated spots from Firebase Storage...");

      // Download to a temporary file to avoid in-memory buffer limitations.
      File geojsonFile = await getGeoJsonFile();
      await storageRef.writeToFile(geojsonFile);

      if (remoteUpdated != null) {
        await prefs.setString(
          'last_updated_timestamp',
          remoteUpdated.toIso8601String(),
        );
      }
    } catch (e) {
      print("Error downloading spots from Firebase: $e");
    }
  }

  Future<File> getGeoJsonFile() async {
    final dir = await getApplicationSupportDirectory();
    final geojsonFile = File('${dir.path}/bike_spots.geojson');
    return geojsonFile;
  }

  Future<String> getGeoJson() async {
    await _initializeAndCacheSpots();
    final geojsonFile = await getGeoJsonFile();
    return await geojsonFile.readAsString();
  }
}
