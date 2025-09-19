
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ParkingSpot {
  final String borough;
  final String assetId;
  final String location;
  final int yrInstalled;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.borough,
    required this.assetId,
    required this.location,
    required this.yrInstalled,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      borough: json['borough'] ?? '',
      assetId: json['asset_id'] ?? '',
      location: json['location'] ?? '',
      yrInstalled: int.tryParse(json['yr_install'] ?? '0') ?? 0,
      latitude: double.tryParse(json['latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude'] ?? '0') ?? 0.0,
    );
  }
}

class ApiService {
  final String _url =
      'https://data.cityofnewyork.us/resource/592z-n7dk.json?\$limit=1000';

  Future<List<ParkingSpot>> fetchParkingSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetched = prefs.getInt('last_fetched_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Fetch new data if cache is older than a day
    if (now - lastFetched > 24 * 60 * 60 * 1000) {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        await prefs.setString('parking_data', response.body);
        await prefs.setInt('last_fetched_timestamp', now);
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ParkingSpot.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load parking spots');
      }
    } else {
      final cachedData = prefs.getString('parking_data');
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => ParkingSpot.fromJson(json)).toList();
      } else {
        // Fallback to fetching if cache is missing for some reason
        return fetchParkingSpots();
      }
    }
  }
}
