
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
  final String _baseUrl =
      'https://data.cityofnewyork.us/resource/592z-n7dk.json';

  Future<List<ParkingSpot>> fetchParkingSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetched = prefs.getInt('last_fetched_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Fetch new data if cache is older than a day
    if (now - lastFetched > 24 * 60 * 60 * 1000) {
      List<ParkingSpot> allSpots = [];
      int offset = 0;
      const int limit = 1000;
      bool hasMoreData = true;

      while (hasMoreData) {
        final response = await http.get(Uri.parse('$_baseUrl?\$limit=$limit&\$offset=$offset'));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          if (jsonList.isEmpty) {
            hasMoreData = false;
          } else {
            allSpots.addAll(jsonList.map((json) => ParkingSpot.fromJson(json)).toList());
            if (jsonList.length < limit) {
              hasMoreData = false;
            } else {
              offset += limit;
            }
          }
        } else {
          throw Exception('Failed to load parking spots');
        }
      }

      await prefs.setString('parking_data', json.encode(allSpots.map((spot) => {
        'borough': spot.borough,
        'asset_id': spot.assetId,
        'location': spot.location,
        'yr_install': spot.yrInstalled.toString(),
        'latitude': spot.latitude.toString(),
        'longitude': spot.longitude.toString(),
      }).toList()));
      await prefs.setInt('last_fetched_timestamp', now);
      return allSpots;
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
